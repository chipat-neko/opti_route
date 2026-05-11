import 'assistant_suggestion.dart';
import 'tour_context.dart';

/// Interface qu'implementent les regles de l'assistant. Chaque regle
/// recoit un snapshot de l'etat de la tournee (position GPS, heure,
/// arrets restants, parametres) et retourne au plus une suggestion.
///
/// Si plusieurs regles produisent une suggestion, le `TourAssistant`
/// garde celle qui a le `priority` le plus haut.
abstract class AssistantRule {
  const AssistantRule();

  /// Identifie la regle (utile pour les stats de calibration et la
  /// detection de cooldown).
  SuggestionKind get kind;

  /// Evalue le contexte et retourne une suggestion ou null si rien
  /// d'utile a proposer maintenant.
  AssistantSuggestion? evaluate(TourContext ctx);
}
