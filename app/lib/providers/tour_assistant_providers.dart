import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tour_assistant/assistant_calibration.dart';
import '../data/tour_assistant/assistant_suggestion.dart';
import '../data/tour_assistant/nearest_after_fail_rule.dart';
import '../data/tour_assistant/proximity_rule.dart';
import '../data/tour_assistant/time_window_rule.dart';
import '../data/tour_assistant/tour_assistant.dart';
import '../data/tour_assistant/tour_context.dart';
import 'database_providers.dart';
import 'location_providers.dart';

/// Singleton du `TourAssistant` pour la session : conserve l'etat des
/// cooldowns entre les ticks GPS. Reset attendu en debut de tournee.
///
/// Ordre des regles = ordre d'evaluation. Le dispatcher prend la
/// suggestion qui a la priorite numerique la plus haute, donc l'ordre
/// ici n'influence pas le choix, juste la lisibilite du code.
final tourAssistantProvider = Provider<TourAssistant>((ref) {
  return TourAssistant(rules: const [
    TimeWindowRule(),       // priorite 85-100 (le plus urgent)
    NearestAfterFailRule(), // priorite 80
    ProximityRule(),        // priorite 30-90 (selon distance)
  ]);
});

/// Wrapper de calibration : lit/ecrit les compteurs accept/reject et
/// ajuste le seuil de proximite quand le palier est atteint.
final assistantCalibrationProvider = Provider<AssistantCalibration>((ref) {
  return AssistantCalibration(ref.watch(parametresRepositoryProvider));
});

/// Stream des parametres TourAssistant : master + toggles regles +
/// seuils. Recompute des qu'un parametre change.
final assistantParamsStreamProvider =
    StreamProvider<TourAssistantParams>((ref) async* {
  final repo = ref.watch(parametresRepositoryProvider);
  await for (final _ in repo.watchAssistantEnabled()) {
    final enabled = await repo.isAssistantEnabled();
    final proximityEnabled = await repo.isAssistantProximityEnabled();
    final threshold = await repo.assistantProximityThresholdM();
    final cooldown = await repo.assistantCooldownMinutes();
    final timeWindowEnabled = await repo.isAssistantTimeWindowEnabled();
    final nearestAfterFailEnabled =
        await repo.isAssistantNearestAfterFailEnabled();
    yield TourAssistantParams(
      enabled: enabled,
      proximityEnabled: proximityEnabled,
      proximityThresholdM: threshold,
      cooldownMinutes: cooldown,
      timeWindowEnabled: timeWindowEnabled,
      nearestAfterFailEnabled: nearestAfterFailEnabled,
    );
  }
});

/// Suggestion active pour une tournee donnee. Recomputee a chaque
/// changement de position GPS / stops / parametres. Une seule
/// suggestion exposee a la fois (la plus prioritaire, voir
/// `TourAssistant.evaluate`).
final assistantSuggestionProvider =
    Provider.family<AssistantSuggestion?, int>((ref, tourneeId) {
  final assistant = ref.watch(tourAssistantProvider);
  final allTournees =
      ref.watch(tourneesStreamProvider).asData?.value ?? const [];
  final tournee = allTournees.where((t) => t.id == tourneeId).firstOrNull;
  if (tournee == null) return null;
  final stops =
      ref.watch(stopsByTourneeProvider(tourneeId)).asData?.value ?? const [];
  final position = ref.watch(currentPositionProvider).asData?.value;
  final params = ref.watch(assistantParamsStreamProvider).asData?.value ??
      const TourAssistantParams();

  return assistant.evaluate(TourContext(
    tournee: tournee,
    stops: stops,
    currentPosition: position,
    now: DateTime.now(),
    params: params,
  ));
});
