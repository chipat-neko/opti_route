import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_auto_push_service.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';

/// Petit indicateur discret dans l'AppBar qui montre l'etat de
/// l'auto-push :
/// - idle : invisible (SizedBox.shrink)
/// - pending : icone cloud-sync statique amber (debounce 5s en cours)
/// - pushing : spinner emerald (HTTP en cours)
///
/// Sert a rassurer le user que ses modifs sont en cours de sauvegarde
/// cloud sans pollution visuelle quand rien ne se passe.
///
/// Extrait de [TourneeDuJourScreen] (refactor 2026-05-21) pour
/// alleger le screen principal et permettre la reutilisation eventuelle
/// dans d'autres ecrans (carte, stats) sans copy-paste.
class AutoPushBadge extends ConsumerWidget {
  const AutoPushBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(cloudAutoPushServiceProvider);
    return StreamBuilder<AutoPushState>(
      stream: service.stateStream,
      initialData: service.currentState,
      builder: (context, snap) {
        final state = snap.data ?? AutoPushState.idle;
        switch (state) {
          case AutoPushState.idle:
            return const SizedBox.shrink();
          case AutoPushState.pending:
            return Tooltip(
              message: 'Sauvegarde cloud dans 5s...',
              child: Icon(
                Icons.cloud_sync_outlined,
                size: 16,
                color: AppColors.amber.withValues(alpha: 0.7),
              ),
            );
          case AutoPushState.pushing:
            return const Tooltip(
              message: 'Sauvegarde cloud en cours...',
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.emerald,
                ),
              ),
            );
        }
      },
    );
  }
}
