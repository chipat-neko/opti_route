import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/stats_service.dart';
import '../providers/database_providers.dart';
import 'carnet_adresses_screen.dart' show carnetStreamProvider;
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

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
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: const [
          _StatsCard(label: '7 DERNIERS JOURS', days: 7),
          SizedBox(height: AppSpacing.x14),
          _StatsCard(label: '30 DERNIERS JOURS', days: 30),
          SizedBox(height: AppSpacing.x14),
          _StatsCard(label: 'DEPUIS 1 AN', days: 365),
          SizedBox(height: AppSpacing.x14),
          _JoursSemaineCard(),
          SizedBox(height: AppSpacing.x14),
          _TopClientsCard(),
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
    final p = context.palette;
    final async = ref.watch(statsProvider(days));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
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
    final p = context.palette;
    if (stats.nbTournees == 0) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x10),
        child: Text(
          'Aucune tournee dans cette periode.',
          style: TextStyle(color: p.textMute),
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
                    '${stats.nbLivres} livres Â· ${stats.nbEchecs} echecs',
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
    if (totalSeconds == 0) return 'â€”';
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
    final p = context.palette;
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
              color: p.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.ink,
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
    final p = context.palette;
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
              color: p.textMute,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: appMonoStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.ink,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textMute,
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
              style: TextStyle(
                fontSize: 10,
                color: p.textMute,
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
      Container(width: 1, height: 32, color: context.palette.divider);
}

/// Carte qui affiche la repartition des colis livres par jour de la
/// semaine sur les 30 derniers jours. Affiche un mini barchart "ASCII"
/// horizontal (proportionnel au max). Aide a reperer les jours
/// charges -> potentiellement bouger une tournee recurrente.
class _JoursSemaineCard extends ConsumerWidget {
  const _JoursSemaineCard();

  static const _jourLabels = [
    null, // index 0 non utilise (weekday = 1..7)
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(colisParJourProvider(30));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COLIS PAR JOUR (30 J)',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          async.when(
            data: (map) {
              if (map.isEmpty) {
                return Text(
                  'Aucun colis livre cette periode.',
                  style: TextStyle(color: p.textMute),
                );
              }
              final maxVal = map.values.fold<int>(
                0,
                (m, v) => v > m ? v : m,
              );
              return Column(
                children: [
                  for (var wd = 1; wd <= 7; wd++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _BarRow(
                        label: _jourLabels[wd]!,
                        value: map[wd] ?? 0,
                        max: maxVal,
                      ),
                    ),
                ],
              );
            },
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

/// Top N des clients les plus livres, lu directement du carnet
/// d'adresses (`saved_destinations.use_count`). Sert a Noah pour
/// reconnaitre ses recurrents.
class _TopClientsCard extends ConsumerWidget {
  const _TopClientsCard();

  static const _topN = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final stream = ref.watch(carnetStreamProvider);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP $_topN CLIENTS',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          stream.when(
            data: (all) {
              if (all.isEmpty) {
                return Text(
                  'Aucun client dans le carnet.',
                  style: TextStyle(color: p.textMute),
                );
              }
              final sorted = [...all]..sort(
                  (a, b) => b.useCount.compareTo(a.useCount),
                );
              final top = sorted.take(_topN).toList();
              return Column(
                children: [
                  for (var i = 0; i < top.length; i++) ...[
                    _TopClientRow(rank: i + 1, client: top[i]),
                    if (i < top.length - 1) const Divider(height: 1),
                  ],
                ],
              );
            },
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

class _TopClientRow extends StatelessWidget {
  const _TopClientRow({required this.rank, required this.client});

  final int rank;
  final SavedDestination client;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final nom = (client.nomClient?.trim().isNotEmpty ?? false)
        ? client.nomClient!.trim()
        : client.adresseDisplay;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank == 1 ? AppColors.lime : p.creamSoft,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: appMonoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              nom,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Text(
            '${client.useCount}x',
            style: appMonoStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = max == 0 ? 0.0 : value / max;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: p.creamSoft,
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(AppRadius.r6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.x10),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: appMonoStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ),
      ],
    );
  }
}
