import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/chef_stats_service.dart';
import '../../data/cloud_error_humanizer.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Panneau "stats du jour" du logiciel chef (epopee #88, [#88·4]).
///
/// Affiche les compteurs agreges de la journee pour toute l'equipe
/// (arrets / livres / restant / echecs + colis + km + taux de reussite)
/// et un bandeau d'alertes (taux d'echec eleve, tournee potentiellement
/// bloquee, tournee a cloturer). Source : [equipeStatsJourProvider].
class ChefStatsPanel extends ConsumerWidget {
  const ChefStatsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final statsAsync = ref.watch(equipeStatsJourProvider);
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
              Icon(Icons.insights_outlined, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  'Stats du jour',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              _Tag(label: '[#88·4]'),
            ],
          ),
          const Divider(height: AppSpacing.x22),
          Expanded(
            child: statsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  humanizeAnyError(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: p.textMute),
                ),
              ),
              data: (stats) => _StatsContent(stats: stats),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.stats});

  final ChefStatsJour stats;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (stats.nbTournees == 0) {
      return Center(
        child: Text(
          'Aucune tournee aujourd\'hui',
          style: TextStyle(fontSize: 13, color: p.textFaint),
        ),
      );
    }
    final tauxPct = (stats.tauxReussite * 100).round();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${stats.nbTournees} tournee'
            '${stats.nbTournees > 1 ? "s" : ""}'
            '${stats.nbTourneesEnCours > 0 ? " — ${stats.nbTourneesEnCours} en cours" : ""}',
            style: appMonoStyle(
              fontSize: 11,
              color: p.textMute,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Wrap(
            spacing: AppSpacing.x10,
            runSpacing: AppSpacing.x10,
            children: [
              _StatChip(label: 'Arrets', value: '${stats.totalStops}'),
              _StatChip(label: 'Livres', value: '${stats.nbLivres}'),
              _StatChip(
                label: 'Restant',
                value: '${stats.restants}',
                color: AppColors.emerald,
              ),
              if (stats.nbEchecs > 0)
                _StatChip(
                  label: 'Echecs',
                  value: '${stats.nbEchecs}',
                  color: AppColors.red,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          Text(
            '${stats.colisLivres} colis livres · '
            '${stats.distanceKm.toStringAsFixed(1)} km · '
            'reussite $tauxPct%',
            style: TextStyle(fontSize: 12, color: p.textMute),
          ),
          if (stats.alertes.isNotEmpty) ...[
            const Divider(height: AppSpacing.x22),
            for (final a in stats.alertes)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x8),
                child: _AlerteRow(alerte: a),
              ),
          ],
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: appMonoStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color ?? p.ink,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: appMonoStyle(
            fontSize: 9,
            color: p.textMute,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AlerteRow extends StatelessWidget {
  const _AlerteRow({required this.alerte});

  final ChefAlerte alerte;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (icon, color) = switch (alerte.severite) {
      ChefAlerteSeverite.critique => (Icons.error_outline, AppColors.red),
      ChefAlerteSeverite.attention =>
        (Icons.warning_amber_outlined, AppColors.amber),
      ChefAlerteSeverite.info => (Icons.info_outline, AppColors.emerald),
    };
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.x8),
        Expanded(
          child: Text(
            alerte.message,
            style: TextStyle(fontSize: 12, color: p.text, height: 1.3),
          ),
        ),
      ],
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
