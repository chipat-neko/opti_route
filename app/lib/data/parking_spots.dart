import 'geo_utils.dart';

/// Spot de parking discret/gratuit memorise par Noah (carte #330).
/// In-memory pour le MVP - le storage Drift suivra dans une PR
/// dediee (necessite migration schema).
class ParkingSpot {
  const ParkingSpot({
    required this.id,
    required this.lat,
    required this.lng,
    required this.label,
    this.notes,
  });

  final String id;
  final double lat;
  final double lng;
  final String label;
  final String? notes;
}

/// Helpers pure fn pour le carnet de spots parking.
class ParkingSpotsHelper {
  ParkingSpotsHelper._();

  /// Spots dans le rayon [radiusMeters] (default 50) autour d'un
  /// point, triés par distance.
  static List<({ParkingSpot spot, double distanceMeters})> findNearby({
    required double centerLat,
    required double centerLng,
    required List<ParkingSpot> spots,
    double radiusMeters = 50,
  }) {
    final out = <({ParkingSpot spot, double distanceMeters})>[];
    for (final s in spots) {
      final d = GeoUtils.haversineMeters(
        lat1: centerLat,
        lon1: centerLng,
        lat2: s.lat,
        lon2: s.lng,
      );
      if (d <= radiusMeters) out.add((spot: s, distanceMeters: d));
    }
    out.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
    return out;
  }
}
