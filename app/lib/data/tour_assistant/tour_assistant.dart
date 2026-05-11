import 'assistant_rule.dart';
import 'assistant_suggestion.dart';
import 'proximity_rule.dart';
import 'tour_context.dart';

/// Service central de l'assistant intelligent de tournee. Agit en
/// surcouche du moteur d'optim (VROOM/ORS) : la sequence est calculee
/// une fois par VROOM, et le `TourAssistant` produit des **suggestions
/// live** pendant l'execution (livraison au passage, urgence fenetre
/// horaire, etc.).
///
/// Approche systeme expert : un ensemble de regles `AssistantRule`
/// evaluees a chaque tick (position GPS / changement d'arret /
/// reprise apres pause). Une seule suggestion est exposee a la fois
/// (la plus prioritaire).
///
/// Un mecanisme de **cooldown** evite le harcelement : apres un refus
/// utilisateur pour un (kind, stopId), on attend `cooldownMinutes`
/// avant de re-proposer.
class TourAssistant {
  TourAssistant({List<AssistantRule>? rules})
      : _rules = rules ?? const [ProximityRule()];

  final List<AssistantRule> _rules;
  final Map<String, DateTime> _cooldowns = {};

  /// Evalue toutes les regles et retourne la suggestion la plus
  /// prioritaire, ou null si rien a proposer / tout est en cooldown.
  AssistantSuggestion? evaluate(TourContext ctx) {
    final candidates = <AssistantSuggestion>[];
    for (final rule in _rules) {
      final suggestion = rule.evaluate(ctx);
      if (suggestion == null) continue;
      if (_isInCooldown(suggestion, ctx.now)) continue;
      candidates.add(suggestion);
    }
    if (candidates.isEmpty) return null;
    candidates.sort((a, b) => b.priority.compareTo(a.priority));
    return candidates.first;
  }

  /// L'utilisateur a refuse la suggestion. On pose un cooldown pour
  /// ce (kind, stopId) pendant `ctx.params.cooldownMinutes`.
  void recordRefuse(
    AssistantSuggestion suggestion,
    DateTime now, {
    required int cooldownMinutes,
  }) {
    final key = _cooldownKey(suggestion);
    _cooldowns[key] = now.add(Duration(minutes: cooldownMinutes));
  }

  /// L'utilisateur a accepte la suggestion. On retire le cooldown
  /// eventuel (pas necessaire en pratique mais propre).
  void recordAccept(AssistantSuggestion suggestion) {
    _cooldowns.remove(_cooldownKey(suggestion));
  }

  /// Reset complet (typiquement a la fin d'une tournee).
  void resetCooldowns() {
    _cooldowns.clear();
  }

  bool _isInCooldown(AssistantSuggestion s, DateTime now) {
    final until = _cooldowns[_cooldownKey(s)];
    if (until == null) return false;
    if (now.isAfter(until)) {
      _cooldowns.remove(_cooldownKey(s));
      return false;
    }
    return true;
  }

  static String _cooldownKey(AssistantSuggestion s) =>
      '${s.kind.name}:${s.stop.id}';
}
