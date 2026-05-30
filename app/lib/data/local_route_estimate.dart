import 'database.dart';
import 'geo_utils.dart';

/// Estimation locale de la distance + duree totales d'une tournee, SANS
/// passer par VROOM/ORS. Sert d'affichage de fallback quand la tournee
/// n'a pas encore ete optimisee (ou que l'utilisateur ne veut pas brûler
/// son quota ORS pour un parcours d'1 ou 2 arrets).
///
/// **Methode** : haversine (vol d'oiseau) entre chaque point de la
/// liste, en partant du depot vers le 1er stop, puis stop a stop. La
/// duree est inferee a une vitesse moyenne urbaine de 30 km/h
/// (compromis entre boulevard 50 et centre-ville 15).
///
/// **Inexactitude** : ~20 a 30 % sous-estimation typique vs distance
/// routiere reelle, car ne suit pas les rues. C'est un affichage
/// "ordre de grandeur" pour Noah, marque comme estimation dans l'UI
/// avec le prefixe `~`.
///
/// **Quand utiliser** : si `tournee.distanceTotaleM` / `dureeTotaleS`
/// sont `null` (jamais optimise) ou `0`, le caller peut substituer
/// par `LocalRouteEstimate.compute(...)` pour ne pas afficher " - ".
class LocalRouteEstimate {
  const LocalRouteEstimate({
    required this.meters,
    required this.seconds,
  });

  final int meters;
  final int seconds;

  /// Vitesse moyenne urbaine en km/h. Calibre pour France livraison
  /// (typiquement 30 vs 50 sur boulevard car arrets fréquents).
  static const double avgSpeedKmh = 30;

  /// Calcule l'estimation pour [stops] dans leur ordre courant, en
  /// partant du depot de [tournee]. Stops sans coords (lat/lng null)
  /// sont ignores.
  ///
  /// Si 0 stop geocode : retourne (0, 0). Si 1 stop : juste le
  /// segment depot -> ce stop.
  static LocalRouteEstimate compute({
    required Tournee tournee,
    required List<Stop> stops,
  }) {
    final geocoded =
        stops.where((s) => s.lat != null && s.lng != null).toList();
    if (geocoded.isEmpty) {
      return const LocalRouteEstimate(meters: 0, seconds: 0);
    }

    double totalMeters = 0;
    var prevLat = tournee.pointDepartLat;
    var prevLng = tournee.pointDepartLng;
    for (final s in geocoded) {
      totalMeters += GeoUtils.haversineMeters(
        lat1: prevLat,
        lon1: prevLng,
        lat2: s.lat!,
        lon2: s.lng!,
      );
      prevLat = s.lat!;
      prevLng = s.lng!;
    }

    final seconds = (totalMeters / 1000 / avgSpeedKmh * 3600).round();
    return LocalRouteEstimate(meters: totalMeters.round(), seconds: seconds);
  }
}
