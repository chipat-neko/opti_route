import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/app_tokens.dart';
import '../carnet_doublons_screen.dart';
import 'providers.dart';

/// Banniere "X doublons potentiels detectes" affichee en tete du carnet
/// (carte #103). Masquee si aucun doublon. Tap -> CarnetDoublonsScreen.
///
/// Extrait de `carnet_adresses_screen.dart` (refactor F27) : etait le
/// widget prive `_DoublonsBanner` en fin de fichier.
class DoublonsBanner extends ConsumerWidget {
  const DoublonsBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(carnetDoublonsProvider).asData?.value.length ?? 0;
    if (n == 0) return const SizedBox.shrink();
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x18,
        AppSpacing.x12,
        AppSpacing.x18,
        0,
      ),
      child: Material(
        color: AppColors.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CarnetDoublonsScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x14,
              vertical: AppSpacing.x12,
            ),
            child: Row(
              children: [
                const Icon(Icons.merge_type, size: 18, color: AppColors.amber),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Text(
                    '$n doublon${n > 1 ? "s" : ""} potentiel'
                    '${n > 1 ? "s" : ""} detecte${n > 1 ? "s" : ""}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
                Text(
                  'Voir',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18,
                    color: AppColors.emerald),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
