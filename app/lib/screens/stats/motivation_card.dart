import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/stats_service.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Carte de motivation cumulative — header lime de l'ecran stats.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche les compteurs annuels (colis livres, tournees, km) + 2
/// badges qui peuvent se cumuler :
///   - taux de reussite annuel (>=95% emerald, >=85% ink/lime,
///     <85% amber) ;
///   - streak de tournees consecutives sans incident.
///
/// Visuel chaud (gradient lime) pour donner un coup de boost quand
/// Noah ouvre l'ecran. Si aucune tournee enregistree, affiche un
/// message d'invitation a la 1ere tournee.
class MotivationCard extends ConsumerWidget {
  const MotivationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(motivationStatsProvider);
    final stats = async.asData?.value ?? MotivationStats.empty;
    final hasData = stats.tourneesAnnee > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.lime,
            AppColors.lime.withValues(alpha: 0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_fire_department,
                  color: AppColors.ink, size: 20),
              const SizedBox(width: AppSpacing.x8),
              Text(
                hasData ? 'CETTE ANNEE' : 'EN ATTENTE DE TA 1RE TOURNEE',
                style: appMonoStyle(
                  fontSize: 11,
                  color: AppColors.ink,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          if (hasData) ...[
            Text(
              '${stats.colisLivresAnnee} colis livres',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${stats.tourneesAnnee} tournees, '
              '${stats.kmAnnee.toStringAsFixed(0)} km parcourus',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            Wrap(
              spacing: AppSpacing.x6,
              runSpacing: AppSpacing.x6,
              children: [
                // Badge taux de reussite annuel. Seuils :
                // >= 95 % -> emerald, >= 85 % -> ink/lime, < 85 % -> amber.
                if (stats.nbLivresAnnee + stats.nbEchecsAnnee > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x10,
                      vertical: AppSpacing.x6,
                    ),
                    decoration: BoxDecoration(
                      color: stats.tauxReussiteAnnee >= 0.95
                          ? AppColors.emerald
                          : stats.tauxReussiteAnnee >= 0.85
                              ? AppColors.ink
                              : AppColors.amber,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Text(
                      '${(stats.tauxReussiteAnnee * 100).toStringAsFixed(0)}% reussite annuelle',
                      style: appMonoStyle(
                        fontSize: 12,
                        color: stats.tauxReussiteAnnee >= 0.85
                            ? AppColors.lime
                            : AppColors.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                if (stats.streakSansEchec > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x10,
                      vertical: AppSpacing.x6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.ink,
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                    ),
                    child: Text(
                      '${stats.streakSansEchec} tournee${stats.streakSansEchec > 1 ? "s" : ""} sans incident',
                      style: appMonoStyle(
                        fontSize: 12,
                        color: AppColors.lime,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
          ] else
            Text(
              'Cree ta premiere tournee pour voir tes stats motivantes !',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.ink.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
        ],
      ),
    );
  }
}
