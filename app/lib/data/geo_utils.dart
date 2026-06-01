import 'dart:math' as math;

/// Helpers de geometrie spherique pour les besoins courants : distance
/// vol d'oiseau entre 2 coords, normalisation d'angles, etc. Pas de
/// dependance Flutter -> testable en pur dart.
class GeoUtils {
  GeoUtils._();

  /// Distance en metres entre 2 coords (lat/lng en degres), formule
  /// haversine sur sphere R = 6371 km. Erreur max ~0.5% pour des
  /// distances < 100 km (acceptable pour livraison locale).
  static double haversineMeters({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    const r = 6371000.0;
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final lat1Rad = _deg2rad(lat1);
    final lat2Rad = _deg2rad(lat2);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return r * c;
  }

  /// Vrai si les 2 coords sont a moins de [thresholdMeters] m l'une de
  /// l'autre. Utilise pour la detection de doublons d'arrets.
  static bool areClose({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
    double thresholdMeters = 30,
  }) {
    return haversineMeters(
          lat1: lat1,
          lon1: lon1,
          lat2: lat2,
          lon2: lon2,
        ) <
        thresholdMeters;
  }

  /// Vrai si (lat, lon) sont dans les bornes géographiques valides
  /// (lat ∈ [-90, 90], lon ∈ [-180, 180]) et non NaN/Infinity. Sert à
  /// rejeter une coordonnée aberrante venue d'une API (ex : 999/-999) qui
  /// corromprait l'optimisation de tournée. Cf audit sécu 2026-06-01.
  static bool isValidLatLon(double lat, double lon) {
    if (lat.isNaN || lon.isNaN || lat.isInfinite || lon.isInfinite) {
      return false;
    }
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }

  static double _deg2rad(double d) => d * math.pi / 180.0;
}
