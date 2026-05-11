import '../database.dart';

/// Type de suggestion proposee par le TourAssistant. Sert a categoriser
/// la regle qui l'a produite (pour les stats de calibration et pour
/// permettre a l'utilisateur d'activer/desactiver par categorie).
enum SuggestionKind {
  /// "Tu passes devant Y, livre-le ?" (regle de proximite GPS).
  proximity,

  /// "Y a une fenetre horaire qui finit dans X min, urgent" (regle de
  /// fenetre horaire — pas encore implementee).
  timeWindow,

  /// "X est absent, le voisin Y est a 200m, le livrer maintenant ?"
  /// (regle apres echec — pas encore implementee).
  nearestAfterFail,

  /// "Capacite vehicule sature, retour depot avant la suite" (regle
  /// capacite — pas encore implementee).
  capacity,
}

/// Suggestion active proposee a l'utilisateur. Une seule suggestion
/// est affichee a la fois (la plus prioritaire). L'utilisateur peut
/// l'accepter (= action proposee) ou la refuser (= ignorer + ne plus
/// proposer cet arret pour ce kind pendant un cooldown).
class AssistantSuggestion {
  const AssistantSuggestion({
    required this.kind,
    required this.stop,
    required this.message,
    required this.priority,
    this.distanceMeters,
    this.minutesUrgent,
  });

  final SuggestionKind kind;
  final Stop stop;

  /// Texte affiche dans le banner. Doit etre court et orienter action.
  final String message;

  /// Score de priorite pour trancher quand plusieurs suggestions sont
  /// candidates simultanement (0-100). Plus haut = plus prioritaire.
  final int priority;

  /// Distance haversine entre la position courante et le stop (pour
  /// SuggestionKind.proximity). Sert a afficher "180m" et a tracer la
  /// metrique de calibration.
  final double? distanceMeters;

  /// Minutes restantes avant la fin de la fenetre horaire du stop
  /// (pour SuggestionKind.timeWindow).
  final int? minutesUrgent;
}
