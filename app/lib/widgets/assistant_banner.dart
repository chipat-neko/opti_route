import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/tour_assistant/assistant_suggestion.dart';
import '../providers/database_providers.dart';
import '../providers/tour_assistant_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/stop_action_sheet.dart';

/// Banner orange affiche en tete de la liste arrets quand le
/// `TourAssistant` a une suggestion active a proposer (typiquement :
/// "Tu passes a 180m de Y, le livrer avant ?").
///
/// 2 actions :
/// - `Livrer Y` : ouvre la `StopActionSheet` pour valider la livraison
///   de l'arret suggere. Calibration += accept.
/// - `Plus tard` : pose un cooldown (5 min par defaut) sur ce (kind,
///   stopId). Calibration += refuse.
class AssistantBanner extends ConsumerWidget {
  const AssistantBanner({super.key, required this.tourneeId});

  final int tourneeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestion = ref.watch(assistantSuggestionProvider(tourneeId));
    if (suggestion == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x12),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x14,
        AppSpacing.x12,
        AppSpacing.x10,
        AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.auto_awesome,
                color: AppColors.amber,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  suggestion.message,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.emerald,
                    foregroundColor: AppColors.paper,
                    minimumSize: const Size(0, 40),
                  ),
                  onPressed: () => _onAccept(context, ref, suggestion),
                  child: const Text(
                    'Livrer maintenant',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(0, 40),
                ),
                onPressed: () => _onRefuse(ref, suggestion),
                child: const Text(
                  'Plus tard',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onAccept(
    BuildContext context,
    WidgetRef ref,
    AssistantSuggestion suggestion,
  ) async {
    final assistant = ref.read(tourAssistantProvider);
    final calibration = ref.read(assistantCalibrationProvider);
    assistant.recordAccept(suggestion);
    await calibration.recordAccept(suggestion.kind);

    if (!context.mounted) return;
    final action = await StopActionSheet.show(context, suggestion.stop);
    if (action == null || !context.mounted) return;

    final repo = ref.read(stopsRepositoryProvider);
    switch (action) {
      case MarkLivreAction():
        await repo.markLivre(suggestion.stop.id);
      case MarkEchecAction(raison: final r):
        await repo.markEchec(suggestion.stop.id, r);
      case MarkAaLivrerAction():
        await repo.markAaLivrer(suggestion.stop.id);
      case OpenDetailsAction():
        // L'utilisateur a clique "details" : on ne fait rien de plus,
        // la navigation ouvre l'ecran d'edition cote action sheet.
        break;
    }
  }

  Future<void> _onRefuse(
    WidgetRef ref,
    AssistantSuggestion suggestion,
  ) async {
    final assistant = ref.read(tourAssistantProvider);
    final calibration = ref.read(assistantCalibrationProvider);
    final params = await ref
        .read(parametresRepositoryProvider)
        .assistantCooldownMinutes();
    assistant.recordRefuse(
      suggestion,
      DateTime.now(),
      cooldownMinutes: params,
    );
    await calibration.recordRefuse(suggestion.kind);
  }
}
