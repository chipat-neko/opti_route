import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud_error_humanizer.dart';
import 'carnet_adresses/app_bar_menus.dart';
import 'carnet_adresses/bulk_actions.dart';
import 'carnet_adresses/carnet_filters.dart';
import 'carnet_adresses/carnet_list.dart';
import 'carnet_adresses/carnet_migration_banner.dart';
import 'carnet_adresses/doublons_banner.dart';
import 'carnet_adresses/export_actions.dart';
import 'carnet_adresses/filters_section.dart';
import 'carnet_adresses/import_actions.dart';
import 'carnet_adresses/providers.dart';
import 'carnet_adresses/selection_app_bar.dart';
import 'unified_search_screen.dart';

/// Liste des entrees du carnet d'adresses local. Recherche en haut,
/// tap sur une entree -> ecran d'edition. Swipe -> supprimer.
///
/// L'ecran ne fait plus que composer les briques du dossier
/// `carnet_adresses/` (refactor F27, 1098 lignes -> ~215) : il garde
/// l'etat (recherche, [CarnetFilters], mode selection multiple) et
/// delegue l'affichage aux sous-widgets et les actions aux classes
/// `CarnetImportActions` / `CarnetExportActions` / `CarnetBulkActions`.
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

  /// Recherche texte courante, deja trim + lowercase.
  String _query = '';

  /// Filtres couleur / tag / periode / regularite (cf [CarnetFilters]).
  CarnetFilters _filters = CarnetFilters.none;

  /// Mode selection multiple (carte #104). Active par appui long sur une
  /// tile. `_selectedIds` = ids des fiches cochees.
  bool _selectionMode = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _exitSelection() {
    if (!mounted) return;
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
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Banniere doublons (carte #103) : visible seulement si des
          // paires sont detectees. Tap -> ecran de revue / fusion.
          const DoublonsBanner(),
          // Banner migration carnet -> cloud (carte #365). S'auto-masque
          // si pas d'entreprise / plus d'adresses privees / deja fait.
          const CarnetMigrationBanner(),
          // Recherche + les 3 rangees de chips + badge "N filtres".
          CarnetFiltersSection(
            searchController: _searchCtrl,
            onQueryChanged: (v) =>
                setState(() => _query = v.trim().toLowerCase()),
            onVoiceResult: _applyVoiceResult,
            filters: _filters,
            onFiltersChanged: (f) => setState(() => _filters = f),
          ),
          Expanded(
            child: stream.when(
              data: (all) => CarnetList(
                entries: filterCarnet(all, _filters, _query),
                hasQuery: _query.isNotEmpty,
                selectionMode: _selectionMode,
                selectedIds: _selectedIds,
                onSelectToggle: _toggleSelect,
                onEnterSelection: _enterSelection,
              ),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur : ${humanizeAnyError(e)}')),
            ),
          ),
        ],
      ),
    );
  }

  /// AppBar contextuel du mode selection multiple (carte #104), sinon
  /// l'AppBar normal : titre + recherche universelle + les 2 menus
  /// import / export.
  ///
  /// Une methode plutot qu'un `?:` inline dans le `Scaffold` : les deux
  /// branches n'ont pas le meme type concret, seul le type de retour
  /// declare ici garantit un `PreferredSizeWidget`.
  PreferredSizeWidget _buildAppBar() {
    if (_selectionMode) {
      return CarnetSelectionAppBar(
        count: _selectedIds.length,
        onExit: _exitSelection,
        onFavori: _bulkFavori,
        onColorTag: _bulkColorTag,
        onDelete: _bulkDelete,
      );
    }
    return AppBar(
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
        CarnetImportMenu(onAction: _onImportAction),
        CarnetExportMenu(onAction: _onExportAction),
      ],
    );
  }

  /// Dispatch du menu "Importer / peupler" vers [CarnetImportActions].
  /// Le menu vit dans [CarnetImportMenu] et remonte juste un enum.
  void _onImportAction(CarnetImportAction action) {
    switch (action) {
      case CarnetImportAction.vcard:
        CarnetImportActions.importVcard(context: context, ref: ref);
      case CarnetImportAction.csv:
        CarnetImportActions.importCsv(context: context, ref: ref);
      case CarnetImportAction.csvGeocode:
        CarnetImportActions.importCsvGeocode(context: context, ref: ref);
      case CarnetImportAction.backfill:
        CarnetImportActions.backfillDepuisHistorique(
          context: context,
          ref: ref,
        );
    }
  }

  /// Dispatch du menu "Exporter" vers [CarnetExportActions].
  void _onExportAction(CarnetExportAction action) {
    switch (action) {
      case CarnetExportAction.csv:
        CarnetExportActions.exportCsv(context: context, ref: ref);
      case CarnetExportAction.vcard:
        CarnetExportActions.exportVcard(context: context, ref: ref);
    }
  }

  // Actions en masse du mode selection : la selection courante vit ici,
  // le reste (dialogs + ecriture + SnackBar) dans [CarnetBulkActions].

  Future<void> _bulkFavori() => CarnetBulkActions.marquerFavori(
        context: context,
        ref: ref,
        ids: _selectedIds.toList(),
        onDone: _exitSelection,
      );

  Future<void> _bulkColorTag() => CarnetBulkActions.choisirColorTag(
        context: context,
        ref: ref,
        ids: _selectedIds.toList(),
        onDone: _exitSelection,
      );

  Future<void> _bulkDelete() => CarnetBulkActions.confirmerSuppression(
        context: context,
        ref: ref,
        ids: _selectedIds.toList(),
        onDone: _exitSelection,
      );
}
