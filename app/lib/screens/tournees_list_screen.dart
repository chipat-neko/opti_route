import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import 'tournee_du_jour_screen.dart';
import 'tournee_form_screen.dart';

class TourneesListScreen extends ConsumerWidget {
  const TourneesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourneesAsync = ref.watch(tourneesStreamProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerBadgeIcon(),
        title: const Text('Historique des tournees'),
      ),
      body: tourneesAsync.when(
        data: (tournees) => tournees.isEmpty
            ? const _EmptyState()
            : _TourneesList(tournees: tournees),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle tournee'),
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Tournee? tournee}) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TourneeFormScreen(initial: tournee),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.creamSoft,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_shipping_outlined,
                size: 44,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x18),
            Text(
              'Aucune tournee',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              'Tape sur "+" en bas pour creer ta premiere tournee.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textMute,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TourneesList extends ConsumerWidget {
  const _TourneesList({required this.tournees});

  final List<Tournee> tournees;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tri en 2 sections : actives en haut (brouillon / optimisee /
    // en_cours), terminees en bas (statut == 'terminee'). A l'interieur
    // de chaque section, ordre par date decroissante.
    final actives = tournees
        .where((t) => t.statut != 'terminee')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final terminees = tournees
        .where((t) => t.statut == 'terminee')
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final items = <Widget>[];
    if (actives.isNotEmpty) {
      items.add(const _SectionHeader('En cours / a venir'));
      for (final t in actives) {
        items.add(_TourneeRow(tournee: t));
      }
    }
    if (terminees.isNotEmpty) {
      items.add(const _SectionHeader('Terminees'));
      for (final t in terminees) {
        items.add(_TourneeRow(tournee: t));
      }
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x10,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => items[i],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x6,
        AppSpacing.x14,
        AppSpacing.x6,
        AppSpacing.x8,
      ),
      child: Text(
        label.toUpperCase(),
        style: appMonoStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMute,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _TourneeRow extends ConsumerWidget {
  const _TourneeRow({required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('EEE d MMM', 'fr');
    final isTerminee = tournee.statut == 'terminee';
    final hasStats = isTerminee &&
        tournee.distanceTotaleM != null &&
        tournee.dureeTotaleS != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Dismissible(
        key: ValueKey('tournee-${tournee.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x22),
          child: const Icon(Icons.delete_outline, color: AppColors.red),
        ),
        confirmDismiss: (_) => _confirmDelete(context, tournee),
        onDismissed: (_) async {
          await ref.read(tourneesRepositoryProvider).delete(tournee.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tournee "${tournee.nom}" supprimee')),
          );
        },
        child: Material(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TourneeDuJourScreen(tournee: tournee),
              ),
            ),
            onLongPress: () => _showActions(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Row(
                children: [
                  _StatutBadge(statut: tournee.statut),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournee.nom,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          dateFormat.format(tournee.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMute,
                          ),
                        ),
                        if (hasStats) ...[
                          const SizedBox(height: AppSpacing.x6),
                          Text(
                            '${(tournee.distanceTotaleM! / 1000).toStringAsFixed(1)} km · ${_formatDuration(tournee.dureeTotaleS!)}',
                            style: appMonoStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.textFaint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet d'actions sur une tournee (long press) : Editer la
  /// fiche / Dupliquer en nouveau template / (la suppression reste sur
  /// le swipe lateral comme avant).
  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x18,
            AppSpacing.x14,
            AppSpacing.x18,
            AppSpacing.x18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: AppColors.inkLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                tournee.nom,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.x14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.paper,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(0, 52),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TourneeFormScreen(initial: tournee),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Modifier la fiche tournee',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppSpacing.x8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.ink,
                  minimumSize: const Size(0, 52),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    final newId = await ref
                        .read(tourneesRepositoryProvider)
                        .duplicate(tournee.id);
                    if (!context.mounted) return;
                    final newTournee = await ref
                        .read(tourneesRepositoryProvider)
                        .getById(newId);
                    if (!context.mounted || newTournee == null) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Duplique en "${newTournee.nom}"',
                        ),
                        backgroundColor: AppColors.emerald,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TourneeDuJourScreen(tournee: newTournee),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Erreur duplication : $e')),
                    );
                  }
                },
                icon: const Icon(Icons.content_copy_outlined),
                label: const Text(
                  'Dupliquer comme template',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  Future<bool?> _confirmDelete(BuildContext context, Tournee t) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette tournee ?'),
        content: Text(
          '"${t.nom}" et tous ses arrets seront supprimes definitivement.',
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
  }
}

class _StatutBadge extends StatelessWidget {
  const _StatutBadge({required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    // Couleurs alignees sur les tokens du handoff :
    // - active : ink + halo lime
    // - terminee : emerald
    // - optimisee : creamSoft + ink
    // - brouillon (default) : paper + outline ink
    final (letter, bg, fg, border) = switch (statut) {
      'optimisee' =>
        ('O', AppColors.creamSoft, AppColors.ink, AppColors.inkLine),
      'en_cours' => ('E', AppColors.ink, AppColors.lime, null),
      'terminee' => ('T', AppColors.emerald, AppColors.paper, null),
      _ => ('B', AppColors.paper, AppColors.ink, AppColors.inkLine),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r10),
        border: border != null ? Border.all(color: border, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}
