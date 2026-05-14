import 'dart:async';
import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import 'cached_tile_provider.dart';

/// ════════════════════════════════════════════════════════════════
/// Pre-telechargement des tuiles OSM dans la bbox d'une tournee.
/// ════════════════════════════════════════════════════════════════
///
/// Etape 4 du plan GPS turn-by-turn integre (cf
/// `docs/plan-gps-integre.md`). Quand le livreur sait qu'il va dans
/// une zone faible 4G (campagne, parking sous-terrain, immeuble),
/// il appuie sur "Telecharger pour hors-ligne" et l'app rapatrie
/// toutes les tuiles OSM couvrant la bbox depot+arrets aux zooms
/// utiles a la navigation (13-16). Les tuiles sont stockees dans le
/// meme cache disque que celui utilise par [CachedTileProvider] :
/// la carte les sert alors instant, meme sans reseau.
///
/// **Limite de securite** : si la bbox demande > 5000 tuiles
/// (livreur national), on refuse pour eviter de saturer le disque
/// et de DDoS le serveur OSM (qui plafonne a ~2 req/s par client).
class TilePrefetchService {
  TilePrefetchService(this._tileProvider);

  final CachedTileProvider _tileProvider;

  /// Plafond absolu pour eviter de telecharger 50k tuiles par megarde
  /// (livreur qui ajoute un arret a Marseille dans une tournee de
  /// Lille). Au-dela on demande a l'utilisateur de scinder.
  static const int maxTiles = 5000;

  /// Telecharge toutes les tuiles couvrant la bbox de [points] aux
  /// zooms [minZoom..maxZoom]. Appelle [onProgress] (downloaded, total)
  /// apres chaque tuile (succes ou echec).
  ///
  /// [concurrency] = nombre de telechargements en parallele. OSM
  /// recommande 2 req/s max, on reste prudent a 4 (rapide en pratique
  /// car les tuiles sont en CDN).
  ///
  /// Retourne le total de tuiles effectivement telechargees (ou deja
  /// en cache). Une tuile qui echoue n'est pas comptee.
  ///
  /// Throw [TilePrefetchError] si :
  /// - points est vide
  /// - la bbox depasse [maxTiles]
  Future<int> prefetchBbox({
    required List<LatLng> points,
    int minZoom = 13,
    int maxZoom = 16,
    void Function(int downloaded, int total)? onProgress,
    int concurrency = 4,
  }) async {
    if (points.isEmpty) {
      throw TilePrefetchError('Aucun point a pre-telecharger.');
    }

    final tiles = _computeTiles(
      points: points,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    if (tiles.length > maxTiles) {
      throw TilePrefetchError(
        'Zone trop large : ${tiles.length} tuiles. Limite $maxTiles. '
        'Reduis la plage de zoom ou divise la tournee.',
      );
    }

    final total = tiles.length;
    var downloaded = 0;
    onProgress?.call(0, total);

    // Pool de [concurrency] workers : on consomme une queue partagee
    // sans semaphore (Dart est mono-thread).
    final queue = List<TileXYZ>.from(tiles);
    Future<void> worker() async {
      while (queue.isNotEmpty) {
        final t = queue.removeLast();
        try {
          final ok = await _tileProvider.prefetchTile(t.z, t.x, t.y);
          if (ok) downloaded++;
        } catch (_) {/* tuile ratee, on continue */}
        onProgress?.call(downloaded, total);
      }
    }

    await Future.wait([for (var i = 0; i < concurrency; i++) worker()]);
    return downloaded;
  }

  /// Estime le nombre de tuiles avant de lancer le download. Utilise
  /// pour afficher "X tuiles, ~Y MB a telecharger" dans la dialog de
  /// confirmation.
  ///
  /// 1 tuile PNG OSM = ~20 KB (variable selon densite urbaine).
  static TilePrefetchEstimate estimate({
    required List<LatLng> points,
    int minZoom = 13,
    int maxZoom = 16,
  }) {
    if (points.isEmpty) {
      return const TilePrefetchEstimate(tiles: 0, estimatedBytes: 0);
    }
    final tiles = _computeTiles(
      points: points,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    return TilePrefetchEstimate(
      tiles: tiles.length,
      estimatedBytes: tiles.length * 20 * 1024,
    );
  }

  /// Calcul de la liste des tuiles (z, x, y) couvrant la bbox des
  /// [points] aux zooms [minZoom..maxZoom]. Formules OSM standard
  /// (cf https://wiki.openstreetmap.org/wiki/Slippy_map_tilenames).
  static List<TileXYZ> _computeTiles({
    required List<LatLng> points,
    required int minZoom,
    required int maxZoom,
  }) {
    var minLat = points.first.latitude;
    var maxLat = minLat;
    var minLng = points.first.longitude;
    var maxLng = minLng;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final out = <TileXYZ>[];
    for (var z = minZoom; z <= maxZoom; z++) {
      final xMin = _lng2tileX(minLng, z);
      final xMax = _lng2tileX(maxLng, z);
      // ATTENTION : y est inverse (lat haute = y bas en OSM).
      final yMin = _lat2tileY(maxLat, z);
      final yMax = _lat2tileY(minLat, z);
      for (var x = xMin; x <= xMax; x++) {
        for (var y = yMin; y <= yMax; y++) {
          out.add(TileXYZ(z, x, y));
        }
      }
    }
    return out;
  }

  static int _lng2tileX(double lng, int z) {
    return ((lng + 180.0) / 360.0 * (1 << z)).floor();
  }

  static int _lat2tileY(double lat, int z) {
    final r = lat * math.pi / 180.0;
    return ((1.0 - math.log(math.tan(r) + 1.0 / math.cos(r)) / math.pi) /
            2.0 *
            (1 << z))
        .floor();
  }
}

class TileXYZ {
  const TileXYZ(this.z, this.x, this.y);
  final int z;
  final int x;
  final int y;
}

class TilePrefetchEstimate {
  const TilePrefetchEstimate({
    required this.tiles,
    required this.estimatedBytes,
  });
  final int tiles;
  final int estimatedBytes;

  String get estimatedSizeLabel {
    if (estimatedBytes < 1024 * 1024) {
      return '${(estimatedBytes / 1024).toStringAsFixed(0)} KB';
    }
    return '${(estimatedBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }
}

class TilePrefetchError implements Exception {
  TilePrefetchError(this.message);
  final String message;
  @override
  String toString() => message;
}
