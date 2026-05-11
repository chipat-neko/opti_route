import 'package:geolocator/geolocator.dart';

import '../database.dart';

/// Snapshot des donnees disponibles pour qu'une regle d'assistant
/// puisse evaluer si elle a une suggestion a proposer.
class TourContext {
  const TourContext({
    required this.tournee,
    required this.stops,
    required this.currentPosition,
    required this.now,
    required this.params,
  });

  final Tournee tournee;
  final List<Stop> stops;
  final Position? currentPosition;
  final DateTime now;
  final TourAssistantParams params;
}

/// Parametres dynamiques du TourAssistant : seuils, sensibilites,
/// kinds actifs. Charges depuis ParametresRepository et regules par
/// la calibration progressive.
class TourAssistantParams {
  const TourAssistantParams({
    this.enabled = true,
    this.proximityEnabled = true,
    this.proximityThresholdM = 300,
    this.cooldownMinutes = 5,
  });

  /// Master switch : si false, aucune suggestion n'est produite.
  final bool enabled;

  /// Si false, la regle proximity est skip.
  final bool proximityEnabled;

  /// Rayon de proximite en metres pour la regle Proximity. Ajuste
  /// automatiquement par la calibration progressive (entre 100 et 800).
  final int proximityThresholdM;

  /// Apres un refus de l'utilisateur pour un (kind, stopId), on
  /// n'affichera plus cette suggestion pendant N minutes pour eviter
  /// le harcelement.
  final int cooldownMinutes;
}
