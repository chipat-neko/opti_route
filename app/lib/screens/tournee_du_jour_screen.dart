import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import 'ajout_arret_screen.dart';
import 'tournee_form_screen.dart';

class TourneeDuJourScreen extends ConsumerWidget {
  const TourneeDuJourScreen({super.key, required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopsAsync = ref.watch(stopsByTourneeProvider(tournee.id));

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
      body: stopsAsync.when(
        data: (stops) => _Body(tournee: tournee, stops: stops),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AjoutArretScreen(tourneeId: tournee.id),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un arret'),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.tournee, required this.stops});

  final Tournee tournee;
  final List<Stop> stops;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x18,
        AppSpacing.x8,
        AppSpacing.x18,
        AppSpacing.x18,
      ),
      children: [
        _Header(tournee: tournee),
        const SizedBox(height: AppSpacing.x16),
        _StatRow(arretsCount: stops.length),
        const SizedBox(height: AppSpacing.x18),
        if (stops.isEmpty)
          const _StopsPlaceholder()
        else
          _StopsList(stops: stops),
      ],
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
  const _StatRow({required this.arretsCount});

  final int arretsCount;

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
          const _StatTile(label: 'Distance', value: '0.0', unit: 'km'),
          const _StatDivider(),
          const _StatTile(label: 'Restant', value: '—'),
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

class _StopsList extends ConsumerWidget {
  const _StopsList({required this.stops});

  final List<Stop> stops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < stops.length; i++) ...[
            _StopRow(
              stop: stops[i],
              index: i + 1,
              onDelete: () => _confirmDelete(context, ref, stops[i]),
            ),
            if (i < stops.length - 1)
              const Divider(height: 1, indent: AppSpacing.x16),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Stop stop,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet arret ?'),
        content: Text(
          stop.nomClient != null && stop.nomClient!.isNotEmpty
              ? '${stop.nomClient} - ${stop.adresseBrute}'
              : stop.adresseBrute,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(stopsRepositoryProvider).delete(stop.id);
    }
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.index,
    required this.onDelete,
  });

  final Stop stop;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tags = _buildTags(stop);
    return Dismissible(
      key: ValueKey('stop-${stop.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.red.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x22),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false; // on gere via le dialog, pas de dismiss instant
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x14,
          vertical: AppSpacing.x14,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _IndexChip(index: index, priorite: stop.priorite),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _primaryLine(stop),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.ink,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_secondaryLine(stop) != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      _secondaryLine(stop)!,
                      style: appMonoStyle(
                        fontSize: 11,
                        color: AppColors.textMute,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (tags.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.x8),
                    Wrap(
                      spacing: AppSpacing.x6,
                      runSpacing: AppSpacing.x4,
                      children: tags,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _primaryLine(Stop s) {
    if (s.nomClient != null && s.nomClient!.isNotEmpty) {
      return s.nomClient!;
    }
    return s.adresseBrute.split(',').first.trim();
  }

  String? _secondaryLine(Stop s) {
    if (s.nomClient != null && s.nomClient!.isNotEmpty) {
      // Si on a un client en primary, mettre l'adresse abregee en sub.
      return s.adresseBrute.split(',').take(2).join(',').trim();
    }
    if (s.notes != null && s.notes!.isNotEmpty) return s.notes;
    return null;
  }

  List<Widget> _buildTags(Stop s) {
    final out = <Widget>[];
    final priority = _priorityTag(s.priorite);
    if (priority != null) out.add(priority);
    if (s.nbColis > 1) {
      out.add(_Tag(
        label: '${s.nbColis} colis',
        bg: AppColors.creamSoft,
        fg: AppColors.ink,
      ));
    }
    if (s.fenetreDebut != null || s.fenetreFin != null) {
      final start = s.fenetreDebut ?? '--:--';
      final end = s.fenetreFin ?? '--:--';
      out.add(_Tag(
        label: '$start → $end',
        bg: const Color(0x33F2A341),
        fg: const Color(0xFF7A4F0E),
        mono: true,
      ));
    }
    return out;
  }

  Widget? _priorityTag(String priorite) {
    return switch (priorite) {
      'obligatoire_premier' => const _Tag(
          label: 'En 1er',
          bg: AppColors.lime,
          fg: AppColors.ink,
        ),
      'obligatoire_dernier' => const _Tag(
          label: 'En dernier',
          bg: AppColors.lime,
          fg: AppColors.ink,
        ),
      'eviter_si_possible' => _Tag(
          label: 'Eviter',
          bg: AppColors.amber.withValues(alpha: 0.25),
          fg: const Color(0xFF7A4F0E),
        ),
      _ => null,
    };
  }
}

class _IndexChip extends StatelessWidget {
  const _IndexChip({required this.index, required this.priorite});

  final int index;
  final String priorite;

  @override
  Widget build(BuildContext context) {
    final isActive =
        priorite == 'obligatoire_premier' || priorite == 'obligatoire_dernier';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? AppColors.ink : AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: appMonoStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.lime : AppColors.ink,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.bg,
    required this.fg,
    this.mono = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final style = mono
        ? appMonoStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)
        : TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.4,
          );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label.toUpperCase(),
        style: style,
      ),
    );
  }
}
