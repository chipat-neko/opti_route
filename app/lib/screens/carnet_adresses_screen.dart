import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud_error_humanizer.dart';
import '../data/carnet_backfill_service.dart';
import '../data/carnet_export_service.dart';
import '../data/carnet_import_service.dart';
import '../data/carnet_vcard_export_service.dart';
import '../data/database.dart';
import '../data/saved_destinations_repository.dart';
import '../providers/database_providers.dart';
import '../providers/geocoding_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/voice_input_button.dart';
import 'carnet_adresses/carnet_migration_banner.dart';
import 'carnet_adresses/carnet_tile.dart';
import 'carnet_adresses/filter_chips.dart';
import 'carnet_adresses/providers.dart';
import 'carnet_doublons_screen.dart';
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
  /// Controller du champ recherche : indispensable pour que la dictee
  /// vocale puisse pousser son texte (sans controller le TextField ne
  /// peut pas etre rempli programmatiquement).
  final _searchCtrl = TextEditingController();
  String _query = '';
  /// Filtre couleur actif (`colorTag`). Null = tous. 'favoris' = uniquement
  /// les `isFavori = true` (cas special pour faciliter le tri).
  String? _colorFilter;
  /// Filtre tag libre (`tagsJson`). Null = aucun filtre tag.
  String? _tagFilter;

  /// Filtre periode d'ajout (`creeLe`). Null = pas de filtre.
  /// '30d' = derniers 30 jours, '6m' = derniers 6 mois, '1y' = derniere annee.
  /// Carte Trello #105.
  String? _periodeFilter;

  /// Filtre regularite (`useCount`). Null = pas de filtre.
  /// 'reguliers' = useCount >= 5, 'uniques' = useCount == 1.
  /// Carte Trello #105.
  String? _regulariteFilter;

  /// Mode selection multiple (carte #104). Active par appui long sur une
  /// tile. `_selectedIds` = ids des fiches cochees.
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _enterSelection(int id) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelect(int id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
      if (_selectedIds.isEmpty) _selectionMode = false;
    });
  }

  /// AppBar contextuel du mode selection (carte #104) : compteur +
  /// actions en masse (favori / couleur / suppression).
  PreferredSizeWidget _buildSelectionAppBar() {
    final n = _selectedIds.length;
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Quitter la selection',
        onPressed: _exitSelection,
      ),
      title: Text('$n selectionne${n > 1 ? "s" : ""}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.star_outline),
          tooltip: 'Marquer favori',
          onPressed: n == 0 ? null : _bulkFavori,
        ),
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Etiquette couleur',
          onPressed: n == 0 ? null : _bulkColorTag,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Supprimer',
          onPressed: n == 0 ? null : _bulkDelete,
        ),
      ],
    );
  }

  Future<void> _bulkFavori() async {
    final messenger = ScaffoldMessenger.of(context);
    final ids = _selectedIds.toList();
    await ref
        .read(savedDestinationsRepositoryProvider)
        .setFavoriBulk(ids, true);
    _exitSelection();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${ids.length} fiche(s) marquees favori'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  Future<void> _bulkColorTag() async {
    final p = context.palette;
    final picked = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.r22)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Etiquette couleur',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              Wrap(
                spacing: AppSpacing.x10,
                runSpacing: AppSpacing.x10,
                children: [
                  for (final (tag, color) in colorTagOptions)
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(tag),
                      child: CircleAvatar(
                        backgroundColor: color,
                        radius: 20,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.x14),
              TextButton(
                onPressed: () => Navigator.of(context).pop('__none__'),
                child: const Text('Retirer l\'etiquette'),
              ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return; // sheet ferme sans choix
    final messenger = ScaffoldMessenger.of(context);
    final ids = _selectedIds.toList();
    await ref
        .read(savedDestinationsRepositoryProvider)
        .setColorTagBulk(ids, picked == '__none__' ? null : picked);
    _exitSelection();
    messenger.showSnackBar(
      SnackBar(
        content: Text('${ids.length} fiche(s) mises a jour'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  Future<void> _bulkDelete() async {
    final ids = _selectedIds.toList();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Supprimer ${ids.length} fiche(s) ?'),
        content: const Text(
          'Les fiches selectionnees seront supprimees du carnet local. '
          'Action irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red.withValues(alpha: 0.15),
              foregroundColor: AppColors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(savedDestinationsRepositoryProvider)
        .deleteBulk(ids);
    _exitSelection();
    messenger.showSnackBar(
      SnackBar(content: Text('${ids.length} fiche(s) supprimees')),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Applique le texte dicte : remplit le champ + lance la recherche
  /// immediatement (sans debounce, l'user attend deja le retour vocal).
  void _applyVoiceResult(String spoken) {
    final cleaned = spoken.trim();
    if (cleaned.isEmpty) return;
    _searchCtrl.text = cleaned;
    _searchCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: cleaned.length),
    );
    setState(() => _query = cleaned.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final stream = ref.watch(carnetStreamProvider);

    return Scaffold(
      appBar: _selectionMode
          ? _buildSelectionAppBar()
          : AppBar(
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'Importer / peupler',
            onSelected: (value) {
              if (value == 'csv') _onImportPressed();
              if (value == 'csv_geo') _onImportGeocodePressed();
              if (value == 'vcard') _onImportVcardPressed();
              if (value == 'backfill') _onBackfillPressed();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'vcard',
                child: ListTile(
                  leading: Icon(Icons.contact_phone_outlined),
                  title: Text('Importer vCard'),
                  subtitle: Text(
                    'Contacts Google / Android (.vcf), geocode auto',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'csv',
                child: ListTile(
                  leading: Icon(Icons.upload_file_outlined),
                  title: Text('Importer CSV complet'),
                  subtitle: Text(
                    'CSV avec lat/lng (export precedent)',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'csv_geo',
                child: ListTile(
                  leading: Icon(Icons.add_location_outlined),
                  title: Text('Importer CSV simplifie'),
                  subtitle: Text(
                    'Nom + adresse, geocodage auto BAN',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'backfill',
                child: ListTile(
                  leading: Icon(Icons.history_outlined),
                  title: Text('Depuis l\'historique'),
                  subtitle: Text(
                    'Tous mes arrets deja faits',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
          // Banniere doublons (carte #103) : visible seulement si des
          // paires sont detectees. Tap -> ecran de revue / fusion.
          const _DoublonsBanner(),
          // Banner migration carnet -> cloud (carte #365). S'auto-masque
          // si pas d'entreprise / plus d'adresses privees / deja fait.
          const CarnetMigrationBanner(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x18,
              AppSpacing.x14,
              AppSpacing.x18,
              AppSpacing.x4,
            ),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Rechercher un client / une adresse',
                // Bouton micro mains-libres : dicte la recherche au
                // volant. Aligne sur le pattern Spoke route planner.
                suffixIcon: VoiceInputButton(
                  tooltip: 'Dicter la recherche',
                  onResult: _applyVoiceResult,
                ),
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
          // Troisieme row : periode d'ajout + regularite (carte Trello
          // #105). Compacte : 1 SizedBox 36, 5 chips max (Tous / 30j /
          // 6 mois / 1 an / reguliers / uniques).
          SizedBox(
            height: 36,
            child: ListView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x18,
              ),
              scrollDirection: Axis.horizontal,
              children: [
                TagFilterChip(
                  label: 'periode: toutes',
                  selected: _periodeFilter == null,
                  onSelected: () => setState(() => _periodeFilter = null),
                ),
                const SizedBox(width: 8),
                TagFilterChip(
                  label: '30 jours',
                  selected: _periodeFilter == '30d',
                  onSelected: () => setState(() => _periodeFilter = '30d'),
                ),
                const SizedBox(width: 8),
                TagFilterChip(
                  label: '6 mois',
                  selected: _periodeFilter == '6m',
                  onSelected: () => setState(() => _periodeFilter = '6m'),
                ),
                const SizedBox(width: 8),
                TagFilterChip(
                  label: '1 an',
                  selected: _periodeFilter == '1y',
                  onSelected: () => setState(() => _periodeFilter = '1y'),
                ),
                const SizedBox(width: 16),
                TagFilterChip(
                  label: 'clients reguliers (>=5)',
                  selected: _regulariteFilter == 'reguliers',
                  onSelected: () => setState(() => _regulariteFilter =
                      _regulariteFilter == 'reguliers' ? null : 'reguliers'),
                ),
                const SizedBox(width: 8),
                TagFilterChip(
                  label: 'jamais reutilises',
                  selected: _regulariteFilter == 'uniques',
                  onSelected: () => setState(() => _regulariteFilter =
                      _regulariteFilter == 'uniques' ? null : 'uniques'),
                ),
              ],
            ),
          ),
          // Badge "X filtres actifs" + bouton reset, visible uniquement
          // si au moins 1 filtre est en place. Carte Trello #105.
          if (_activeFiltersCount() > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x18,
                AppSpacing.x4,
                AppSpacing.x18,
                0,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt,
                    size: 14,
                    color: context.palette.textMute,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_activeFiltersCount()} filtre${_activeFiltersCount() > 1 ? "s" : ""} actif${_activeFiltersCount() > 1 ? "s" : ""}',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.palette.textMute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _resetAllFilters,
                    icon: const Icon(Icons.refresh, size: 14),
                    label: const Text(
                      'Reinitialiser',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x8,
                      ),
                      minimumSize: const Size(0, 28),
                    ),
                  ),
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
                  itemBuilder: (context, i) {
                    final e = filtered[i];
                    return CarnetTile(
                      entry: e,
                      selectionMode: _selectionMode,
                      selected: _selectedIds.contains(e.id),
                      onSelectToggle: () => _toggleSelect(e.id),
                      onEnterSelection: () => _enterSelection(e.id),
                    );
                  },
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur a l\'import : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Import CSV simplifie : accepte un CSV minimal (nom_client, rue,
  /// code_postal, ville) sans lat/lng et geocode automatiquement via
  /// BAN. Idem que [_onImportPressed] mais le constructeur du service
  /// recoit un geocoder.
  Future<void> _onImportGeocodePressed() async {
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
        title: const Text('Import simplifie ?'),
        content: Text(
          'Le CSV doit avoir au moins les colonnes nom_client, rue, '
          'code_postal, ville. L\'app geocode chaque ligne via BAN '
          '(France) -- compte ~1 seconde par client.\n\n'
          'Les doublons (meme nom ou meme position) seront fusionnes.\n\n'
          '${picked.files.first.name}',
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

    // Spinner non-bloquant pendant le geocodage (peut prendre 1-2 min
    // pour 100 lignes).
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Geocodage en cours, patiente...'),
        duration: Duration(seconds: 120),
      ),
    );
    try {
      final service = CarnetImportService(
        ref.read(savedDestinationsRepositoryProvider),
        geocoder: ref.read(geocodingServiceProvider),
      );
      final result = await service.importFromFile(File(path));
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      final summary = [
        if (result.created > 0) '${result.created} ajoutee(s)',
        if (result.merged > 0) '${result.merged} fusionnee(s)',
        if (result.rejected > 0) '${result.rejected} non geocodee(s)',
      ].join(' · ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary.isEmpty ? 'Aucune entree' : summary),
          backgroundColor:
              result.rejected > 0 ? AppColors.amber : AppColors.emerald,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'import : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Import vCard (.vcf) depuis Google Contacts (carte #102). Geocode
  /// les contacts sans coords GEO via BAN. Les contacts sans adresse
  /// exploitable sont ignores (le carnet = adresses de livraison).
  Future<void> _onImportVcardPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['vcf'],
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
        title: const Text('Importer ce vCard ?'),
        content: Text(
          'Les contacts du fichier (export Google Contacts / Contacts '
          'Android) seront ajoutes au carnet. L\'app geocode via BAN les '
          'adresses sans coordonnees. Les contacts sans adresse sont '
          'ignores. Doublons (meme nom / position) fusionnes.\n\n'
          '${picked.files.first.name}',
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

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Import + geocodage en cours, patiente...'),
        duration: Duration(seconds: 120),
      ),
    );
    try {
      final service = CarnetImportService(
        ref.read(savedDestinationsRepositoryProvider),
        geocoder: ref.read(geocodingServiceProvider),
      );
      final result = await service.importVcardFromFile(File(path));
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      final summary = [
        if (result.created > 0) '${result.created} ajoute(s)',
        if (result.merged > 0) '${result.merged} fusionne(s)',
        if (result.rejected > 0) '${result.rejected} sans adresse',
      ].join(' · ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary.isEmpty ? 'Aucun contact' : summary),
          backgroundColor:
              result.rejected > 0 ? AppColors.amber : AppColors.emerald,
          duration: const Duration(seconds: 6),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'import : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Backfill du carnet depuis l'historique des arrets deja faits dans
  /// toutes les tournees (cf [CarnetBackfillService]). Idempotent.
  Future<void> _onBackfillPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final shouldRun = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Peupler depuis l\'historique ?'),
        content: const Text(
          'L\'app va scanner toutes les tournees deja faites et ajouter '
          'chaque adresse au carnet. Les doublons sont fusionnes (pas '
          'de duplication).\n\n'
          'Operation locale, instantanee, idempotente (rejouable).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Lancer'),
          ),
        ],
      ),
    );
    if (shouldRun != true || !mounted) return;
    try {
      final service = CarnetBackfillService(
        ref.read(appDatabaseProvider),
        ref.read(savedDestinationsRepositoryProvider),
      );
      final result = await service.backfillFromStops();
      if (!mounted) return;
      final summary = [
        '${result.totalStops} arret(s) scanne(s)',
        if (result.created > 0) '${result.created} ajoutee(s)',
        if (result.merged > 0) '${result.merged} fusionnee(s)',
        if (result.skipped > 0) '${result.skipped} skipped',
      ].join(' · ');
      messenger.showSnackBar(
        SnackBar(
          content: Text(summary),
          backgroundColor:
              result.created > 0 ? AppColors.emerald : AppColors.amber,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur backfill : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur a l\'export : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur a l\'export vCard : ${humanizeAnyError(e)}')),
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
    // Carte Trello #105 : filtre periode d'ajout (creeLe).
    final pf = _periodeFilter;
    if (pf != null) {
      final cutoff = _periodeCutoff(pf);
      filtered = filtered.where((d) => d.creeLe.isAfter(cutoff));
    }
    // Carte Trello #105 : filtre regularite (useCount).
    final rf = _regulariteFilter;
    if (rf == 'reguliers') {
      filtered = filtered.where((d) => d.useCount >= 5);
    } else if (rf == 'uniques') {
      filtered = filtered.where((d) => d.useCount == 1);
    }
    if (q.isEmpty) return filtered.toList();
    final norm = _normalize(q);
    return filtered.where((d) {
      final hay = _normalize([
        d.nomClient ?? '',
        d.adresseDisplay,
        d.ville ?? '',
        d.codePostal ?? '',
      ].join(' '));
      return hay.contains(norm);
    }).toList();
  }

  /// Borne inferieure du filtre periode. Exposee pour les tests.
  static DateTime _periodeCutoff(String periode) {
    final now = DateTime.now();
    return switch (periode) {
      '30d' => now.subtract(const Duration(days: 30)),
      '6m' => now.subtract(const Duration(days: 30 * 6)),
      '1y' => now.subtract(const Duration(days: 365)),
      _ => DateTime(1970),
    };
  }

  /// Compte les filtres actifs hors recherche texte (utilise pour le
  /// badge "X filtres actifs"). Carte Trello #105.
  int _activeFiltersCount() {
    var n = 0;
    if (_colorFilter != null) n++;
    if (_tagFilter != null) n++;
    if (_periodeFilter != null) n++;
    if (_regulariteFilter != null) n++;
    return n;
  }

  /// Reset tous les filtres en un coup (sauf la recherche texte).
  /// Carte Trello #105.
  void _resetAllFilters() {
    setState(() {
      _colorFilter = null;
      _tagFilter = null;
      _periodeFilter = null;
      _regulariteFilter = null;
    });
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

/// Banniere "X doublons potentiels detectes" affichee en tete du carnet
/// (carte #103). Masquee si aucun doublon. Tap -> CarnetDoublonsScreen.
class _DoublonsBanner extends ConsumerWidget {
  const _DoublonsBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.watch(carnetDoublonsProvider).asData?.value.length ?? 0;
    if (n == 0) return const SizedBox.shrink();
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x18,
        AppSpacing.x12,
        AppSpacing.x18,
        0,
      ),
      child: Material(
        color: AppColors.amber.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CarnetDoublonsScreen(),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x14,
              vertical: AppSpacing.x12,
            ),
            child: Row(
              children: [
                const Icon(Icons.merge_type, size: 18, color: AppColors.amber),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Text(
                    '$n doublon${n > 1 ? "s" : ""} potentiel'
                    '${n > 1 ? "s" : ""} detecte${n > 1 ? "s" : ""}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
                Text(
                  'Voir',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.emerald,
                  ),
                ),
                const Icon(Icons.chevron_right, size: 18,
                    color: AppColors.emerald),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
