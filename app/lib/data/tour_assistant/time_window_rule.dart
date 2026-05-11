import 'dart:math' as math;

import '../database.dart';
import 'assistant_rule.dart';
import 'assistant_suggestion.dart';
import 'tour_context.dart';

/// Regle "Urgence fenetre horaire" : si un arret `a_livrer` a une
/// `fenetreFin` qui se ferme dans moins de `timeWindowUrgencyMinutes`,
/// on suggere de le passer en priorite (au lieu de risquer un echec
/// pour fenetre depassee).
///
/// Priorite tres elevee (85-100) : ce genre de cas est plus urgent
/// qu'un simple detour de proximite. En cas de conflit dans le
/// dispatcher, on l'emporte sur ProximityRule.
///
/// Filtres :
/// - Tournee `en_cours`.
/// - >= 2 stops `a_livrer`.
/// - Stop avec `fenetreFin` non null.
/// - `fenetreFin` non encore depassee (sinon foutu de toute facon).
/// - Stop != le 1er restant (= le prochain deja prevu).
/// - Priorite != `eviter_si_possible`.
class TimeWindowRule extends AssistantRule {
  const TimeWindowRule();

  @override
  SuggestionKind get kind => SuggestionKind.timeWindow;

  @override
  AssistantSuggestion? evaluate(TourContext ctx) {
    if (!ctx.params.enabled || !ctx.params.timeWindowEnabled) return null;
    if (ctx.tournee.statut != 'en_cours') return null;

    final remaining = ctx.stops
        .where((s) => s.statutLivraison == 'a_livrer')
        .toList(growable: false);
    if (remaining.length < 2) return null;

    Stop? best;
    int bestMinutesLeft = ctx.params.timeWindowUrgencyMinutes + 1;
    // Skip le 1er (prochain prevu) : pas la peine de proposer ce qu'il
    // va deja faire.
    for (var i = 1; i < remaining.length; i++) {
      final stop = remaining[i];
      if (stop.priorite == 'eviter_si_possible') continue;
      if (stop.fenetreFin == null) continue;
      final fin = _parseHHmm(stop.fenetreFin!, ctx.now);
      if (fin == null) continue;
      final minutesLeft = fin.difference(ctx.now).inMinutes;
      if (minutesLeft < 0) continue; // deja depasse
      if (minutesLeft > ctx.params.timeWindowUrgencyMinutes) continue;
      if (minutesLeft < bestMinutesLeft) {
        bestMinutesLeft = minutesLeft;
        best = stop;
      }
    }
    if (best == null) return null;

    final label =
        best.nomClient != null && best.nomClient!.trim().isNotEmpty
            ? best.nomClient!.trim()
            : best.adresseBrute.split(',').first.trim();
    // Priorite : plus on est proche de la cloture, plus c'est urgent.
    // Echelle : 0 min restantes -> 100, 30 min restantes -> 85.
    final priority = math.max(85, 100 - (bestMinutesLeft / 2).round());

    return AssistantSuggestion(
      kind: kind,
      stop: best,
      message:
          '$label ferme dans $bestMinutesLeft min. Le passer en premier ?',
      priority: priority,
      minutesUrgent: bestMinutesLeft,
    );
  }

  /// Parse "HH:mm" en DateTime dans la journee courante. Retourne null
  /// si format invalide.
  static DateTime? _parseHHmm(String hhmm, DateTime now) {
    if (hhmm.isEmpty) return null;
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return DateTime(now.year, now.month, now.day, h, m);
  }
}
