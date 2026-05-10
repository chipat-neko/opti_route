import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import 'tournee_form_screen.dart';

class TourneesListScreen extends ConsumerWidget {
  const TourneesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tourneesAsync = ref.watch(tourneesStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes tournees'),
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
    final dateFormat = DateFormat('EEEE d MMMM y', 'fr');

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tournees.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final t = tournees[index];
        return Dismissible(
          key: ValueKey(t.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: Theme.of(context).colorScheme.errorContainer,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Icon(
              Icons.delete_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
          ),
          confirmDismiss: (_) => _confirmDelete(context, t),
          onDismissed: (_) async {
            await ref.read(tourneesRepositoryProvider).delete(t.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Tournee "${t.nom}" supprimee')),
            );
          },
          child: ListTile(
            leading: _StatutBadge(statut: t.statut),
            title: Text(t.nom),
            subtitle: Text(dateFormat.format(t.date)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TourneeFormScreen(initial: t),
              ),
            ),
          ),
        );
      },
    );
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
