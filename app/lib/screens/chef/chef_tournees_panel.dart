import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chef_tournees_service.dart';
import '../../data/cloud_error_humanizer.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Panneau "tournees en cours" du logiciel chef (epopee #88, [#88·2]).
///
/// Liste les tournees du jour (en cours d'abord) avec leur progression
/// (barre + livres/total + echecs) et leur statut. Source :
/// [equipeTourneesEnCoursProvider] (100% local Drift aujourd'hui ; les
/// tournees des coequipiers s'y ajouteront quand le cloud sync equipe
/// sera valide sur device).
class ChefTourneesPanel extends ConsumerWidget {
  const ChefTourneesPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(equipeTourneesEnCoursProvider);
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.route_outlined, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  'Tournees en cours',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              _Tag(label: '[#88·2]'),
            ],
          ),
          const Divider(height: AppSpacing.x22),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  humanizeAnyError(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: p.textMute),
                ),
              ),
              data: (list) => list.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune tournee aujourd\'hui',
                        style:
                            TextStyle(fontSize: 13, color: p.textFaint),
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.zero,
                      itemCount: list.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: AppSpacing.x10),
                      itemBuilder: (_, i) =>
                          _TourneeRow(tournee: list[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TourneeRow extends StatelessWidget {
  const _TourneeRow({required this.tournee});

  final ChefTourneeProgress tournee;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = tournee.progression;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: p.cream,
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  tournee.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              _StatutBadge(statut: tournee.statut, enPause: tournee.enPause),
            ],
          ),
          if (tournee.pointDepartLabel.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              tournee.pointDepartLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: p.textMute),
            ),
          ],
          const SizedBox(height: AppSpacing.x8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: p.creamSoft,
              valueColor: AlwaysStoppedAnimation<Color>(
                pct >= 1 ? AppColors.emerald : AppColors.lime,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            '${tournee.livres} / ${tournee.total} livres'
            '${tournee.echecs > 0 ? " · ${tournee.echecs} echec${tournee.echecs > 1 ? "s" : ""}" : ""}',
            style: appMonoStyle(fontSize: 11, color: p.textMute),
          ),
        ],
      ),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  const _StatutBadge({required this.statut, required this.enPause});

  final String statut;
  final bool enPause;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, color) = switch (statut) {
      'en_cours' => ('EN COURS', AppColors.lime),
      'optimisee' => ('OPTIMISEE', AppColors.emerald),
      'terminee' => ('TERMINEE', AppColors.creamSoft),
      _ => ('BROUILLON', p.inkLine),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: enPause ? AppColors.amber : color,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Text(
        enPause ? 'EN PAUSE' : label,
        style: appMonoStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: p.textMute,
        ),
      ),
    );
  }
}
