import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/carnet_export_service.dart';
import '../data/carnet_import_service.dart';
import '../data/carnet_vcard_export_service.dart';
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
  /// Filtre couleur actif (`colorTag`). Null = tous. 'favoris' = uniquement
  /// les `isFavori = true` (cas special pour faciliter le tri).
  String? _colorFilter;

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(carnetStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet d\'adresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Importer un CSV',
            onPressed: _onImportPressed,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.ios_share),
            tooltip: 'Exporter',
            onSelected: (value) {
              if (value == 'csv') _onExportPressed();
              if (value == 'vcard') _onExportVcardPressed();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Exporter en CSV'),
                  subtitle: Text(
                    'Sauvegarde tableur',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'vcard',
                child: ListTile(
                  leading: Icon(Icons.contact_phone_outlined),
                  title: Text('Exporter en vCard'),
                  subtitle: Text(
                    'Import direct dans Contacts',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
              AppSpacing.x4,
            ),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Rechercher un client / une adresse',
              ),
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
            ),
          ),
          // Chips de filtre par couleur / favoris : un mini scroll
          // horizontal pour ne pas pousser la liste vers le bas.
          SizedBox(
            height: 40,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x18,
              ),
              scrollDirection: Axis.horizontal,
              children: [
                _ColorFilterChip(
                  label: 'Tous',
                  selected: _colorFilter == null,
                  onSelected: () => setState(() => _colorFilter = null),
                ),
                const SizedBox(width: 8),
                _ColorFilterChip(
                  label: 'Favoris',
                  selected: _colorFilter == 'favoris',
                  color: AppColors.amber,
                  onSelected: () =>
                      setState(() => _colorFilter = 'favoris'),
                ),
                const SizedBox(width: 8),
                for (final (tag, color) in colorTagOptions) ...[
                  _ColorFilterChip(
                    label: tag,
                    selected: _colorFilter == tag,
                    color: color,
                    onSelected: () => setState(() => _colorFilter = tag),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
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

  Future<void> _onImportPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Fichier illisible')),
      );
      return;
    }
    if (!mounted) return;
    final shouldImport = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importer ce CSV ?'),
        content: Text(
          'Les entrees du fichier vont s\'ajouter a ton carnet existant. '
          'Les doublons (meme nom client ou meme position GPS) seront '
          'fusionnes, pas dupliques.\n\n${picked.files.first.name}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Importer'),
          ),
        ],
      ),
    );
    if (shouldImport != true || !mounted) return;

    try {
      final service = CarnetImportService(
        ref.read(savedDestinationsRepositoryProvider),
      );
      final result = await service.importFromFile(File(path));
      if (!mounted) return;
      final summary = [
        if (result.created > 0) '${result.created} ajoutee(s)',
        if (result.merged > 0) '${result.merged} fusionnee(s)',
        if (result.rejected > 0) '${result.rejected} rejetee(s)',
      ].join(' Â· ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary.isEmpty ? 'Aucune entree' : summary),
          backgroundColor:
              result.rejected > 0 ? AppColors.amber : AppColors.emerald,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'import : $e')),
      );
    }
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

  Future<void> _onExportVcardPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final service = CarnetVcardExportService(
        ref.read(savedDestinationsRepositoryProvider),
      );
      final count = await service.exportAndShare();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(count > 0
              ? '$count fiche(s) vCard generee(s)'
              : 'Carnet vide, rien a exporter'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'export vCard : $e')),
      );
    }
  }

  List<SavedDestination> _filter(List<SavedDestination> all, String q) {
    Iterable<SavedDestination> filtered = all;
    final cf = _colorFilter;
    if (cf != null) {
      if (cf == 'favoris') {
        filtered = filtered.where((d) => d.isFavori);
      } else {
        filtered = filtered.where((d) => d.colorTag == cf);
      }
    }
    if (q.isEmpty) return filtered.toList();
    final norm = _normalize(q);
    return filtered.where((d) {
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
      'Ã ': 'a', 'Ã¢': 'a', 'Ã¤': 'a', 'Ã¡': 'a', 'Ã£': 'a',
      'Ã§': 'c',
      'Ã¨': 'e', 'Ã©': 'e', 'Ãª': 'e', 'Ã«': 'e',
      'Ã®': 'i', 'Ã¯': 'i', 'Ã­': 'i', 'Ã¬': 'i',
      'Ã´': 'o', 'Ã¶': 'o', 'Ã³': 'o', 'Ãµ': 'o',
      'Ã¹': 'u', 'Ã»': 'u', 'Ã¼': 'u', 'Ãº': 'u',
      'Ã¿': 'y', 'Ã½': 'y',
      'Ã±': 'n',
      'Å“': 'oe', 'Ã¦': 'ae',
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

/// Petit chip cliquable pour filtrer le carnet. Quand selectionne, fond
/// rempli de la couleur, sinon fond cream + bordure. Le label "Tous"
/// special n'a pas de couleur (couleur de fond du chip = cream).
class _ColorFilterChip extends StatelessWidget {
  const _ColorFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bg = selected ? (color ?? p.ink) : p.creamSoft;
    // Texte : noir sur fond clair / accent, blanc sur fond ink quand
    // selectionne sans couleur (cas "Tous").
    final fg = selected
        ? (color == null ? p.paper : AppColors.ink)
        : p.ink;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r22),
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x6,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.r22),
          border: Border.all(
            color: selected ? Colors.transparent : p.inkLine,
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}

class _CarnetTile extends ConsumerWidget {
  const _CarnetTile({required this.entry});
  final SavedDestination entry;

  /// "Livre N fois - dernier le J/M/A" (ou juste "Livre N fois" si la
  /// derniere date est null). Donne du contexte temporel en une ligne
  /// dans la liste sans cliquer pour ouvrir la fiche.
  static String _formatLivreLine(SavedDestination e) {
    final base = e.useCount > 1
        ? 'Livre ${e.useCount} fois'
        : 'Livre 1 fois';
    final df = DateFormat('d MMM yy', 'fr');
    return '$base - dernier ${df.format(e.lastUsedAt)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
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
          color: p.paper,
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
                  GestureDetector(
                    onTap: () => ref
                        .read(savedDestinationsRepositoryProvider)
                        .toggleFavori(entry.id),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        // Priorite : colorTag custom > favori amber >
                        // lime par defaut.
                        color: colorFromTag(
                          entry.colorTag,
                          defaultColor: entry.isFavori
                              ? AppColors.amber
                              : AppColors.lime,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        entry.isFavori ? Icons.star : Icons.bookmark,
                        color: p.ink,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasNom)
                          Text(
                            nom,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          entry.adresseDisplay,
                          style: TextStyle(
                            fontSize: hasNom ? 12 : 14,
                            color: hasNom
                                ? p.textMute
                                : p.ink,
                            fontWeight:
                                hasNom ? FontWeight.w500 : FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatLivreLine(entry),
                          style: appMonoStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: p.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: p.textFaint),
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
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: p.creamSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline,
                size: 44,
                color: p.ink,
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
                    color: p.textMute,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
