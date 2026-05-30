import 'database.dart';

/// Compare 2 tournées ou un snapshot "prévu vs réalisé" (carte #319).
/// Pure fn pour calculer les deltas chiffrables (stops ajoutés/retirés,
/// distance, durée, taux échec).
class TourneeDiff {
  const TourneeDiff({
    required this.stopsAddedCount,
    required this.stopsRemovedCount,
    required this.distanceDeltaM,
    required this.dureeDeltaS,
    required this.echecDeltaPct,
  });

  /// Nb de stops présents dans B mais pas dans A (clé = id ou adresse).
  final int stopsAddedCount;

  /// Nb de stops présents dans A mais pas dans B.
  final int stopsRemovedCount;

  /// Distance B - distance A (mètres, peut être négatif).
  final int distanceDeltaM;

  /// Durée B - durée A (secondes).
  final int dureeDeltaS;

  /// Différence du taux d'échec (en points de pourcentage).
  final double echecDeltaPct;

  bool get gainSensible => distanceDeltaM < -500 || dureeDeltaS < -300;

  static TourneeDiff compute({
    required Tournee a,
    required List<Stop> stopsA,
    required Tournee b,
    required List<Stop> stopsB,
  }) {
    final keysA = stopsA.map(_stopKey).toSet();
    final keysB = stopsB.map(_stopKey).toSet();
    final added = keysB.difference(keysA).length;
    final removed = keysA.difference(keysB).length;
    final distA = a.distanceTotaleM ?? 0;
    final distB = b.distanceTotaleM ?? 0;
    final durA = a.dureeTotaleS ?? 0;
    final durB = b.dureeTotaleS ?? 0;
    return TourneeDiff(
      stopsAddedCount: added,
      stopsRemovedCount: removed,
      distanceDeltaM: distB - distA,
      dureeDeltaS: durB - durA,
      echecDeltaPct: _echecRate(stopsB) - _echecRate(stopsA),
    );
  }

  static String _stopKey(Stop s) =>
      '${s.adresseBrute.trim().toLowerCase()}|${s.nomClient ?? ''}';

  static double _echecRate(List<Stop> stops) {
    if (stops.isEmpty) return 0;
    final echecs = stops.where((s) => s.statutLivraison == 'echec').length;
    return 100.0 * echecs / stops.length;
  }
}
