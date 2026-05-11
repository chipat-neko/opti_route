import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
          _DailyBarChart(days: 14),
          SizedBox(height: AppSpacing.x14),
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

/// Mini bar chart custom : une barre par jour sur les [days] derniers
/// jours, hauteur proportionnelle au max de la fenetre. Une pastille
/// rouge au-dessus si la journee a un echec. Pas de package externe :
/// juste des Containers Flutter pour rester leger.
class _DailyBarChart extends ConsumerWidget {
  const _DailyBarChart({required this.days});

  final int days;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(dailyStatsProvider(days));
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
            '$days DERNIERS JOURS',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          const Text(
            'Colis livres par jour',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          async.when(
            data: (list) => _BarChartBody(stats: list),
            loading: () => const SizedBox(
              height: 130,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
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

class _BarChartBody extends StatelessWidget {
  const _BarChartBody({required this.stats});

  final List<DailyStat> stats;

  static const _barAreaHeight = 110.0;

  @override
  Widget build(BuildContext context) {
    final maxColis = stats.fold<int>(0, (m, s) => s.colis > m ? s.colis : m);
    final total = stats.fold<int>(0, (sum, s) => sum + s.colis);
    final totalEchecs =
        stats.fold<int>(0, (sum, s) => sum + s.echecs);

    if (total == 0 && totalEchecs == 0) {
      return const SizedBox(
        height: _barAreaHeight,
        child: Center(
          child: Text(
            'Aucune activite sur cette periode.',
            style: TextStyle(color: AppColors.textMute, fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _barAreaHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final s in stats)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: _DailyBar(
                      stat: s,
                      maxColis: maxColis,
                      areaHeight: _barAreaHeight,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        // Bandeau labels jours (1ere lettre du jour de la semaine).
        Row(
          children: [
            for (final s in stats)
              Expanded(
                child: Text(
                  _dayLabel(s.day),
                  textAlign: TextAlign.center,
                  style: appMonoStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textFaint,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.x10),
        Row(
          children: [
            Container(width: 10, height: 10, color: AppColors.emerald),
            const SizedBox(width: 6),
            Text(
              '$total colis',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(width: AppSpacing.x14),
            if (totalEchecs > 0) ...[
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.red,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '$totalEchecs echec${totalEchecs > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ],
            const Spacer(),
            if (maxColis > 0)
              Text(
                'Max : $maxColis / jour',
                style: appMonoStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMute,
                ),
              ),
          ],
        ),
      ],
    );
  }

  static String _dayLabel(DateTime d) {
    // 1ere lettre du jour de semaine en francais (L M M J V S D).
    final raw = DateFormat('EEEEE', 'fr').format(d);
    return raw.toUpperCase();
  }
}

class _DailyBar extends StatelessWidget {
  const _DailyBar({
    required this.stat,
    required this.maxColis,
    required this.areaHeight,
  });

  final DailyStat stat;
  final int maxColis;
  final double areaHeight;

  @override
  Widget build(BuildContext context) {
    final ratio = maxColis == 0 ? 0.0 : stat.colis / maxColis;
    final h = (ratio * areaHeight).clamp(0.0, areaHeight);
    final isToday = _isSameDay(stat.day, DateTime.now());
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Pastille rouge si echec dans la journee.
        if (stat.echecs > 0)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.red,
                shape: BoxShape.circle,
              ),
            ),
          ),
        Container(
          height: h < 2 && stat.colis == 0 ? 2 : (h < 2 ? 2 : h),
          decoration: BoxDecoration(
            color: stat.colis == 0
                ? AppColors.creamSoft
                : (isToday ? AppColors.lime : AppColors.emerald),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(3),
            ),
          ),
        ),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
