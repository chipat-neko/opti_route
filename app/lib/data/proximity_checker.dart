import 'database.dart';
import 'geo_utils.dart';

/// Detection de proximite GPS d'un stop (carte #285). Fonction pure
/// que l'app peut appeler periodiquement (toutes les N sec) avec sa
/// position courante pour savoir si Noah arrive sur un arret pending.
///
/// Pas un service de fond Android (cout pile + complexite plugin
/// geofencing). MVP : check on-demand quand l'app est au foreground.
class ProximityChecker {
  ProximityChecker._();

  /// Seuil par defaut (80 m) pour considerer "on est sur place".
  static const double defaultRadiusMeters = 80;

  /// Retourne les stops a livrer dans le rayon [radiusMeters] autour
  /// de la position courante, tries du plus proche au plus loin.
  /// Ignore les stops sans coords et les livres/echecs.
  static List<({Stop stop, double distanceMeters})> findNearby({
    required double currentLat,
    required double currentLng,
    required List<Stop> stops,
    double radiusMeters = defaultRadiusMeters,
  }) {
    final hits = <({Stop stop, double distanceMeters})>[];
    for (final s in stops) {
      if (s.statutLivraison != 'a_livrer') continue;
      if (s.lat == null || s.lng == null) continue;
      final d = GeoUtils.haversineMeters(
        lat1: currentLat,
        lon1: currentLng,
        lat2: s.lat!,
        lon2: s.lng!,
      );
      if (d <= radiusMeters) hits.add((stop: s, distanceMeters: d));
    }
    hits.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return hits;
  }
}
