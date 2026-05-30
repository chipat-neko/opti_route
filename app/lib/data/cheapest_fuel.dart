import 'geo_utils.dart';

/// Trouve la station-service la moins chere parmi un set de candidats
/// dans un rayon donne autour du trajet. Carte #309 "Plein malin".
///
/// Strategie : filter par rayon depuis origine (ou rayon depuis un
/// point central du trajet), puis trier par prix croissant.
class CheapestFuel {
  CheapestFuel._();

  /// Filtre les stations dans [radiusMeters] autour de [around] et
  /// retourne la moins chere (price minimum). Null si aucune match.
  static FuelStation? findCheapestNearby({
    required ({double lat, double lng}) around,
    required List<FuelStation> stations,
    double radiusMeters = 5000,
  }) {
    final candidats = <FuelStation>[];
    for (final s in stations) {
      final d = GeoUtils.haversineMeters(
        lat1: around.lat,
        lon1: around.lng,
        lat2: s.lat,
        lon2: s.lng,
      );
      if (d <= radiusMeters) candidats.add(s);
    }
    if (candidats.isEmpty) return null;
    candidats.sort((a, b) => a.pricePerLiter.compareTo(b.pricePerLiter));
    return candidats.first;
  }

  /// Difference de prix vs reference (typiquement prix moyen ou prix
  /// du carburant deja paye par Noah). Retourne un montant negatif si
  /// la station est moins chere que la ref. Pour le bandeau "-0,12 EUR/L".
  static double deltaPerLiter({
    required double stationPrice,
    required double referencePrice,
  }) =>
      stationPrice - referencePrice;
}

class FuelStation {
  const FuelStation({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.pricePerLiter,
  });

  final String id;
  final String name;
  final double lat;
  final double lng;
  final double pricePerLiter;
}
