import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import 'tournee_form_screen.dart';

/// Vue principale lorsque l'utilisateur a une tournee active aujourd'hui.
///
/// Inspire de `screen-list.jsx` du handoff (header + stats + body),
/// mais sans la liste des arrets pour l'instant : ils arrivent au jalon
/// suivant. La structure est posee pour pouvoir les brancher tel quel.
class TourneeDuJourScreen extends ConsumerWidget {
  const TourneeDuJourScreen({super.key, required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Tournee du jour'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier la tournee',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TourneeFormScreen(initial: tournee),
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x18,
          AppSpacing.x8,
          AppSpacing.x18,
          AppSpacing.x18,
        ),
        children: [
          _Header(tournee: tournee),
          const SizedBox(height: AppSpacing.x16),
          const _StatRow(
            arretsCount: 0,
            distanceKm: 0,
            restantLabel: '—',
          ),
          const SizedBox(height: AppSpacing.x18),
          const _StopsPlaceholder(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ecran d\'ajout d\'arrets : prochain jalon (4)',
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un arret'),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE d MMMM', 'fr')
        .format(tournee.date)
        .toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: appMonoStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMute,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          tournee.nom,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          'Depart : ${tournee.pointDepartLabel}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMute,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.arretsCount,
    required this.distanceKm,
    required this.restantLabel,
  });

  final int arretsCount;
  final double distanceKm;
  final String restantLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Row(
        children: [
          _StatTile(label: 'Arrets', value: '$arretsCount'),
          const _StatDivider(),
          _StatTile(
            label: 'Distance',
            value: distanceKm.toStringAsFixed(1),
            unit: 'km',
          ),
          const _StatDivider(),
          _StatTile(label: 'Restant', value: restantLabel),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: AppColors.divider);
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: appMonoStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(text: value),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMute,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMute,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StopsPlaceholder extends StatelessWidget {
  const _StopsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.creamSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_road_outlined,
              color: AppColors.ink,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          const Text(
            'Pas encore d\'arrets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Tape sur "Ajouter un arret" pour commencer a remplir ta tournee.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
