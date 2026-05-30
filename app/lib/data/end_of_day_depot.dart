import 'database.dart';

/// Helpers fin de tournee (carte #314) :
/// 1. **Retour dépôt** : décide si l'optim doit fermer la boucle au
///    dépôt (default ON) ou laisser libre.
/// 2. **Tournée enchaînée J+J+1** : décide le point de départ de la
///    tournée du lendemain depuis la position de fin de la veille.
class EndOfDayDepot {
  EndOfDayDepot._();

  /// Distance haversine au-dessus de laquelle on propose de partir
  /// depuis la position d'hier soir plutôt que du dépôt (gain trajet
  /// à vide). 8 km par défaut.
  static const double dropToDepotMinMeters = 8000;

  /// Décide le point de départ pour la tournée du lendemain en
  /// fonction de la position de fin de la veille + dépôt habituel.
  /// Retourne `(lat, lng, sourceLabel)`.
  static DepotProposal proposeNextDayDepot({
    required double normalDepotLat,
    required double normalDepotLng,
    required String normalDepotLabel,
    double? endOfDayLat,
    double? endOfDayLng,
  }) {
    if (endOfDayLat == null || endOfDayLng == null) {
      return DepotProposal(
        lat: normalDepotLat,
        lng: normalDepotLng,
        label: normalDepotLabel,
        savedKm: 0,
      );
    }
    final distMeters = _haversine(
      normalDepotLat,
      normalDepotLng,
      endOfDayLat,
      endOfDayLng,
    );
    if (distMeters < dropToDepotMinMeters) {
      return DepotProposal(
        lat: normalDepotLat,
        lng: normalDepotLng,
        label: normalDepotLabel,
        savedKm: 0,
      );
    }
    return DepotProposal(
      lat: endOfDayLat,
      lng: endOfDayLng,
      label: 'Position hier soir',
      savedKm: (distMeters / 1000.0 * 2).round(),
      // x2 = aller + retour évités
    );
  }

  /// True si l'option "boucle fermée au dépôt" doit être activée par
  /// défaut pour cette tournée. Toujours true pour le MVP (gain
  /// systématique 10-15 km/jour).
  static bool defaultEndAtDepot({required Tournee tournee}) => true;

  // Haversine duplicable de GeoUtils pour ne pas créer une dépendance
  // cyclique sur tests pure.
  static double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0;
    double toRad(double d) => d * 3.141592653589793 / 180;
    final dLat = toRad(lat2 - lat1);
    final dLng = toRad(lng2 - lng1);
    final a = _sin2(dLat / 2) +
        _cos(toRad(lat1)) * _cos(toRad(lat2)) * _sin2(dLng / 2);
    return 2 * r * _asinSqrt(a);
  }

  static double _sin2(double x) {
    final s = _sin(x);
    return s * s;
  }

  static double _sin(double x) {
    // Taylor 5 termes, suffisant pour delta lat/lng petit
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120);
  }

  static double _cos(double x) {
    final x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24;
  }

  static double _asinSqrt(double a) {
    final s = _sqrtNewton(a);
    // asin(s) approx s + s^3/6 pour s petit
    final s3 = s * s * s;
    return s + s3 / 6;
  }

  static double _sqrtNewton(double v) {
    if (v <= 0) return 0;
    var x = v;
    for (var i = 0; i < 16; i++) {
      x = 0.5 * (x + v / x);
    }
    return x;
  }
}

class DepotProposal {
  const DepotProposal({
    required this.lat,
    required this.lng,
    required this.label,
    required this.savedKm,
  });

  final double lat;
  final double lng;
  final String label;

  /// Km estimés économisés en partant d'ici plutôt que du dépôt
  /// normal (aller + retour).
  final int savedKm;

  bool get isFromYesterday => savedKm > 0;
}
