import 'database.dart';

/// Une cellule de grille agregee pour la heatmap des livraisons (#98).
class HeatCell {
  const HeatCell({
    required this.lat,
    required this.lng,
    required this.count,
  });

  /// Centre de la cellule (pour poser un cercle sur la carte).
  final double lat;
  final double lng;

  /// Nombre d'arrets geocodes tombant dans cette cellule.
  final int count;
}

/// Agrege des arrets geocodes en cellules de grille pour visualiser les
/// zones les plus livrees (carte #98).
///
/// [aggregate] est une fonction PURE (sans I/O) : on arrondit lat/lng a
/// une grille de [cellDeg] degres (~0.01 deg ≈ 1.1 km a nos latitudes) et
/// on compte les arrets par cellule. Plus la cellule est dense, plus la
/// zone est "chaude".
class HeatmapService {
  HeatmapService._();

  /// Taille de cellule par defaut en degres (~1.1 km). Compromis entre
  /// granularite (voir quartier par quartier) et lisibilite (pas 5000
  /// micro-cellules sur la carte).
  static const double defaultCellDeg = 0.01;

  static List<HeatCell> aggregate(
    List<Stop> stops, {
    double cellDeg = defaultCellDeg,
  }) {
    if (cellDeg <= 0) return const [];
    final counts = <String, int>{};
    final centers = <String, ({double lat, double lng})>{};
    for (final s in stops) {
      final lat = s.lat;
      final lng = s.lng;
      if (lat == null || lng == null) continue;
      final latIdx = (lat / cellDeg).floor();
      final lngIdx = (lng / cellDeg).floor();
      final key = '$latIdx:$lngIdx';
      counts[key] = (counts[key] ?? 0) + 1;
      centers[key] ??= (
        lat: (latIdx + 0.5) * cellDeg,
        lng: (lngIdx + 0.5) * cellDeg,
      );
    }
    return [
      for (final e in counts.entries)
        HeatCell(
          lat: centers[e.key]!.lat,
          lng: centers[e.key]!.lng,
          count: e.value,
        ),
    ];
  }

  /// Plus grand `count` parmi les cellules (sert a normaliser la couleur).
  /// 0 si liste vide.
  static int maxCount(List<HeatCell> cells) {
    var m = 0;
    for (final c in cells) {
      if (c.count > m) m = c.count;
    }
    return m;
  }
}
