import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/carnet_export_service.dart';
import '../data/carnet_import_service.dart';
import '../data/carnet_vcard_export_service.dart';
import '../data/database.dart';
import '../data/saved_destinations_repository.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import 'carnet_adresses/carnet_tile.dart';
import 'carnet_adresses/filter_chips.dart';
import 'carnet_adresses/providers.dart';
import 'unified_search_screen.dart';

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
  /// Filtre tag libre (`tagsJson`). Null = aucun filtre tag.
  String? _tagFilter;

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(carnetStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carnet d\'adresses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Recherche universelle',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const UnifiedSearchScreen(),
              ),
            ),
          ),
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
                ColorFilterChip(
                  label: 'Tous',
                  selected: _colorFilter == null,
                  onSelected: () => setState(() => _colorFilter = null),
                ),
                const SizedBox(width: 8),
                ColorFilterChip(
                  label: 'Favoris',
                  selected: _colorFilter == 'favoris',
                  color: AppColors.amber,
                  onSelected: () =>
                      setState(() => _colorFilter = 'favoris'),
                ),
                const SizedBox(width: 8),
                for (final (tag, color) in colorTagOptions) ...[
                  ColorFilterChip(
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
          // Deuxieme row : tags libres (uniquement ceux presents dans
          // le carnet). Cachee si aucun tag.
          Consumer(
            builder: (context, ref, _) {
              final allEntries =
                  ref.watch(carnetStreamProvider).asData?.value ?? const [];
              final allTags = <String>{};
              for (final e in allEntries) {
                allTags.addAll(
                  SavedDestinationsRepository.parseTags(e.tagsJson),
                );
              }
              if (allTags.isEmpty) return const SizedBox.shrink();
              final sorted = allTags.toList()..sort();
              return SizedBox(
                height: 36,
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x18,
                  ),
                  scrollDirection: Axis.horizontal,
                  children: [
                    TagFilterChip(
                      label: 'tag: tous',
                      selected: _tagFilter == null,
                      onSelected: () =>
                          setState(() => _tagFilter = null),
                    ),
                    const SizedBox(width: 8),
                    for (final t in sorted) ...[
                      TagFilterChip(
                        label: t,
                        selected: _tagFilter == t,
                        onSelected: () =>
                            setState(() => _tagFilter = t),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              );
            },
          ),
          Expanded(
            child: stream.when(
              data: (all) {
                final filtered = _filter(all, _query);
                if (filtered.isEmpty) {
                  return CarnetEmptyState(hasQuery: _query.isNotEmpty);
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
                      CarnetTile(entry: filtered[i]),
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
    final picked = await FilePicker.pickFiles(
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
      ].join(' · ');
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
    final tf = _tagFilter;
    if (tf != null) {
      filtered = filtered.where((d) {
        final tags = SavedDestinationsRepository.parseTags(d.tagsJson);
        return tags.any((t) => t.toLowerCase() == tf.toLowerCase());
      });
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
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ÿ': 'y', 'ý': 'y',
      'ñ': 'n',
      'Å“': 'oe', 'æ': 'ae',
    };
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }
}
