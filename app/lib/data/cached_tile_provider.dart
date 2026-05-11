import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// `TileProvider` flutter_map qui :
/// - Sert les tuiles depuis le disque local si elles ont deja ete
///   telechargees (utile en zone faible 4G, ou hors-ligne complet).
/// - Telecharge depuis le serveur OSM si la tuile n'est pas en cache,
///   puis la sauve pour les visites suivantes.
/// - Retourne une 1x1 transparente si la tuile manque ET pas d'internet
///   -> la carte affiche "blanc" sur les zones jamais visitees, sans
///   crasher.
///
/// Cache stocke dans `<temp>/osm_tiles/{z}/{x}/{y}.png`. Pas de TTL
/// (les tuiles OSM bougent rarement ; si Noah veut purger, on ajoute
/// un bouton dans Parametres plus tard).
class CachedTileProvider extends TileProvider {
  CachedTileProvider({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;
  Directory? _cacheDir;

  /// 1x1 PNG transparente -- placeholder pour tuiles indisponibles
  /// (offline + jamais vues). Genere a la volee dans Flutter via
  /// `decodeImageFromList` mais on a besoin des bytes ici.
  static final Uint8List _transparentPng = Uint8List.fromList([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41,
    0x54, 0x78, 0x9C, 0x62, 0x00, 0x01, 0x00, 0x00,
    0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00,
    0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE,
    0x42, 0x60, 0x82,
  ]);

  Future<Directory> _getCacheDir() async {
    if (_cacheDir != null) return _cacheDir!;
    final base = await getApplicationCacheDirectory();
    final dir = Directory('${base.path}/osm_tiles');
    if (!await dir.exists()) await dir.create(recursive: true);
    _cacheDir = dir;
    return dir;
  }

  Future<File> _fileForTile(int z, int x, int y) async {
    final dir = await _getCacheDir();
    return File('${dir.path}/$z/$x/$y.png');
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _CachedTileImage(
      provider: this,
      url: getTileUrl(coordinates, options),
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
    );
  }

  /// Charge la tuile via le cache disque ou le reseau. Sauvegarde
  /// automatiquement pour les visites futures.
  Future<Uint8List> loadBytes(int z, int x, int y, String url) async {
    final file = await _fileForTile(z, x, y);
    if (await file.exists()) {
      try {
        return await file.readAsBytes();
      } catch (_) {
        // Fichier corrupt : on retombe sur le download.
      }
    }
    // Pas en cache : on tente le reseau.
    try {
      final resp = await _client
          .get(Uri.parse(url), headers: {'User-Agent': 'opti_route/0.1'})
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200 && resp.bodyBytes.isNotEmpty) {
        // Sauve en cache (best-effort, on n'attend pas l'ecriture).
        unawaited(_safeWrite(file, resp.bodyBytes));
        return resp.bodyBytes;
      }
    } catch (_) {
      // Reseau down / timeout : on tombe sur la transparente.
    }
    return _transparentPng;
  }

  Future<void> _safeWrite(File file, Uint8List bytes) async {
    try {
      await file.parent.create(recursive: true);
      await file.writeAsBytes(bytes, flush: false);
    } catch (_) {
      // Best-effort : si l'ecriture echoue (disque plein, permission),
      // tant pis, la prochaine fois on retentera le download.
    }
  }

  /// Estimation de la taille du cache disque (somme des fichiers). Sert
  /// au bouton "Vider le cache des cartes" dans Parametres.
  Future<int> cacheSizeBytes() async {
    final dir = await _getCacheDir();
    int total = 0;
    if (!await dir.exists()) return 0;
    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        try {
          total += await entity.length();
        } catch (_) {}
      }
    }
    return total;
  }

  Future<void> clearCache() async {
    final dir = await _getCacheDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    _cacheDir = null;
  }
}

/// `ImageProvider` qui pointe sur le cache disque + fallback reseau.
/// Implementation manuelle car flutter_map utilise un ImageProvider et
/// non pas un Future&lt;Uint8List&gt; direct.
class _CachedTileImage extends ImageProvider<_CachedTileImage> {
  _CachedTileImage({
    required this.provider,
    required this.url,
    required this.z,
    required this.x,
    required this.y,
  });

  final CachedTileProvider provider;
  final String url;
  final int z;
  final int x;
  final int y;

  @override
  Future<_CachedTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  @override
  ImageStreamCompleter loadImage(
    _CachedTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadCodec(decode),
      scale: 1.0,
      debugLabel: 'CachedTile($z/$x/$y)',
    );
  }

  Future<Codec> _loadCodec(ImageDecoderCallback decode) async {
    final bytes = await provider.loadBytes(z, x, y, url);
    final buffer = await ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) =>
      other is _CachedTileImage &&
      other.z == z &&
      other.x == x &&
      other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);
}
