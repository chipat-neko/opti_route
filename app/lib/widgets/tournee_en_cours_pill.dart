import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';

/// Pill lime "EN COURS" a afficher dans `actions:` des AppBar des
/// ecrans pousses sur la stack (Parametres, Carnet, Stats...) pour que
/// le livreur n'oublie pas qu'une tournee tourne en arriere-plan.
///
/// - N'affiche rien si aucune tournee `statut == 'en_cours'` en base.
/// - Au tap : `popUntil(isFirst)` -> retour a la HomeScreen, qui
///   affichera automatiquement la tournee active (cf
///   `currentTourneeProvider`).
class TourneeEnCoursPill extends ConsumerWidget {
  const TourneeEnCoursPill({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEnCours = ref.watch(hasTourneeEnCoursProvider);
    if (!hasEnCours) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.x12),
      child: Center(
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x10,
              vertical: AppSpacing.x4,
            ),
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.fiber_manual_record,
                  size: 8,
                  color: AppColors.ink,
                ),
                SizedBox(width: AppSpacing.x6),
                Text(
                  'EN COURS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
