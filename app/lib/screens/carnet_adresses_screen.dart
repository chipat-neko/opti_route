import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/carnet_export_service.dart';
import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'carnet_edit_screen.dart';

/// Liste des entrees du carnet d'adresses local. Recherche en haut,
/// tap sur une entree -> ecran d'edition. Swipe -> supprimer.
class CarnetAdressesScreen extends ConsumerStatefulWidget {
  const CarnetAdressesScreen({super.key});

  @override
  ConsumerState<CarnetAdressesScreen> createState() =>
      _CarnetAdressesScreenState();
}

class _CarnetAdressesScreenState extends ConsumerState<CarnetAdressesScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(carnetStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet d\'adresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exporter en CSV',
            onPressed: _onExportPressed,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x18,
              AppSpacing.x14,
              AppSpacing.x18,
              AppSpacing.x10,
            ),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un client / une adresse',
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: stream.when(
              data: (all) {
                final filtered = _filter(all, _query);
                if (filtered.isEmpty) {
                  return _EmptyState(hasQuery: _query.isNotEmpty);
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x14,
                    AppSpacing.x4,
                    AppSpacing.x14,
                    AppSpacing.x18,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) =>
                      _CarnetTile(entry: filtered[i]),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : $e')),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onExportPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = CarnetExportService(
        ref.read(savedDestinationsRepositoryProvider),
      );
      final count = await service.exportAndShare();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? '$count entree(s) exportee(s) en CSV'
              : 'Carnet vide, rien a exporter'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'export : $e')),
      );
    }
  }

  List<SavedDestination> _filter(List<SavedDestination> all, String q) {
    if (q.isEmpty) return all;
    final norm = _normalize(q);
    return all.where((d) {
      final hay = _normalize([
        d.nomClient ?? '',
        d.adresseDisplay,
        d.ville ?? '',
      ].join(' '));
      return hay.contains(norm);
    }).toList();
  }

  static String _normalize(String s) {
    final lower = s.toLowerCase().trim();
    const map = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ÿ': 'y', 'ý': 'y',
      'ñ': 'n',
      'œ': 'oe', 'æ': 'ae',
    };
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }
}

/// Provider local : on n'a pas besoin de l'exposer ailleurs.
final carnetStreamProvider =
    StreamProvider.autoDispose<List<SavedDestination>>((ref) {
  return ref.watch(savedDestinationsRepositoryProvider).watchAll();
});

class _CarnetTile extends ConsumerWidget {
  const _CarnetTile({required this.entry});
  final SavedDestination entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nom = entry.nomClient?.trim() ?? '';
    final hasNom = nom.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Dismissible(
        key: ValueKey('carnet-${entry.id}'),
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
        confirmDismiss: (_) async {
          return await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Supprimer du carnet ?'),
                  content: Text(
                    hasNom
                        ? '"$nom" sera supprime du carnet d\'adresses local.'
                        : '"${entry.adresseDisplay}" sera supprime du '
                            'carnet d\'adresses local.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.red.withValues(alpha: 0.15),
                        foregroundColor: AppColors.red,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (_) async {
          await ref
              .read(savedDestinationsRepositoryProvider)
              .delete(entry.id);
        },
        child: Material(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CarnetEditScreen(entry: entry),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: AppColors.lime,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.bookmark, color: AppColors.ink,
                        size: 18),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasNom)
                          Text(
                            nom,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          entry.adresseDisplay,
                          style: TextStyle(
                            fontSize: hasNom ? 12 : 14,
                            color: hasNom
                                ? AppColors.textMute
                                : AppColors.ink,
                            fontWeight:
                                hasNom ? FontWeight.w500 : FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.useCount > 1
                              ? 'Livre ${entry.useCount} fois'
                              : 'Livre 1 fois',
                          style: appMonoStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: AppColors.textFaint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasQuery});

  final bool hasQuery;

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
                Icons.bookmark_outline,
                size: 44,
                color: AppColors.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x18),
            Text(
              hasQuery ? 'Aucun resultat' : 'Carnet vide',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              hasQuery
                  ? 'Aucune adresse ne correspond a ta recherche.'
                  : 'Le carnet se remplit automatiquement a chaque arret '
                      'valide. Reviens ici plus tard pour modifier ou '
                      'supprimer une entree.',
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
