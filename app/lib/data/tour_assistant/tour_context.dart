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
    this.useDirectionFilter = true,
    this.directionToleranceDeg = 90,
    this.minSpeedForHeadingMs = 1.5,
    this.fenetreEarlyMinutes = 30,
    this.timeWindowEnabled = true,
    this.timeWindowUrgencyMinutes = 30,
    this.nearestAfterFailEnabled = true,
    this.failRecentMinutes = 5,
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

  /// Si vrai, on n'affiche la suggestion proximity QUE si le stop est
  /// dans la direction de notre deplacement (cf cap GPS). Eviter les
  /// suggestions pour des arrets situes derriere nous, ce qui obligerait
  /// un demi-tour. Necessite une vitesse minimale (heading peu fiable
  /// a l'arret).
  final bool useDirectionFilter;

  /// Tolerance angulaire en degres : si |cap GPS - bearing(stop)| est
  /// inferieur, le stop est "dans la direction". Default 90 deg (cone
  /// de 180 deg devant nous), valeurs typiques 60-120 deg.
  final int directionToleranceDeg;

  /// Vitesse minimale en m/s (1.5 m/s = ~5.4 km/h) en dessous de
  /// laquelle on considere `heading` non fiable et on desactive le
  /// filtre direction. Evite les faux positifs a l'arret.
  final double minSpeedForHeadingMs;

  /// Si un stop a une fenetre horaire `fenetreDebut`, on ne le suggere
  /// pas avant `fenetreDebut - fenetreEarlyMinutes`. Default 30 min :
  /// au-dela on considere qu'on est trop tot et qu'on peut faire
  /// d'autres arrets en attendant.
  final int fenetreEarlyMinutes;

  /// Activation de la regle TimeWindow (urgence fenetre horaire qui
  /// se ferme). Par defaut active.
  final bool timeWindowEnabled;

  /// Combien de minutes avant fenetreFin on considere l'arret comme
  /// urgent et on propose de le passer en premier. Default 30 min.
  final int timeWindowUrgencyMinutes;

  /// Activation de la regle NearestAfterFail (proposer le voisin le
  /// plus proche apres un echec recent). Par defaut active.
  final bool nearestAfterFailEnabled;

  /// Combien de minutes apres un echec on considere ca comme "recent"
  /// et on declenche la regle NearestAfterFail. Default 5 min.
  final int failRecentMinutes;
}
