import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/stats_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/tournee_en_cours_pill.dart';

/// Ecran "Statistiques cumulatives" accessible depuis le drawer.
/// Affiche 3 fenetres : 7 derniers jours / 30 jours / 365 jours.
/// Pour chaque fenetre : nombre de tournees, arrets, colis livres,
/// distance, duree, taux de reussite.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
        actions: const [TourneeEnCoursPill()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: const [
          _StatsCard(label: '7 DERNIERS JOURS', days: 7),
          SizedBox(height: AppSpacing.x14),
          _StatsCard(label: '30 DERNIERS JOURS', days: 30),
          SizedBox(height: AppSpacing.x14),
          _StatsCard(label: 'DEPUIS 1 AN', days: 365),
        ],
      ),
    );
  }
}

class _StatsCard extends ConsumerWidget {
  const _StatsCard({required this.label, required this.days});

  final String label;
  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(statsProvider(days));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          async.when(
            data: (stats) => _StatsBody(stats: stats),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.x18),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text(
              'Erreur : $e',
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  const _StatsBody({required this.stats});

  final TourneeStats stats;

  @override
  Widget build(BuildContext context) {
    if (stats.nbTournees == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x10),
        child: Text(
          'Aucune tournee dans cette periode.',
          style: TextStyle(color: AppColors.textMute),
        ),
      );
    }
    final km = (stats.distanceMeters / 1000).toStringAsFixed(1);
    final dur = _formatDuration(stats.durationSeconds);
    final tauxPct = (stats.tauxReussite * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BigNumber(
          value: '${stats.nbColisLivres}',
          label: 'colis livres',
          accent: AppColors.emerald,
        ),
        const SizedBox(height: AppSpacing.x12),
        Row(
          children: [
            Expanded(
              child: _SmallStat(
                label: 'Tournees',
                value: '${stats.nbTourneesTerminees}/${stats.nbTournees}',
                hint: stats.nbTourneesTerminees == stats.nbTournees
                    ? 'toutes terminees'
                    : '${stats.nbTournees - stats.nbTourneesTerminees} en cours / brouillon',
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _SmallStat(
                label: 'Arrets',
                value: '${stats.nbArrets}',
                hint:
                    '${stats.nbLivres} livres · ${stats.nbEchecs} echecs',
              ),
            ),
          ],
        ),
        const Divider(height: AppSpacing.x18),
        Row(
          children: [
            Expanded(
              child: _SmallStat(
                label: 'Distance',
                value: km,
                unit: 'km',
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _SmallStat(
                label: 'Duree',
                value: dur,
              ),
            ),
            const _StatDivider(),
            Expanded(
              child: _SmallStat(
                label: 'Reussite',
                value: '$tauxPct%',
                hint:
                    '${stats.nbLivres} sur ${stats.nbLivres + stats.nbEchecs}',
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatDuration(int totalSeconds) {
    if (totalSeconds == 0) return '—';
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: appMonoStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.label,
    required this.value,
    this.unit,
    this.hint,
  });

  final String label;
  final String value;
  final String? unit;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: appMonoStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMute,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: appMonoStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMute,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textMute,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: AppColors.divider);
}
