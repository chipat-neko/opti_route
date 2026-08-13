import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../theme/app_tokens.dart';
import 'carnet_tile.dart';

/// Liste scrollable des fiches du carnet, ou l'etat vide quand il n'y
/// a rien a afficher.
///
/// Extrait de `carnet_adresses_screen.dart` (refactor F27) : etait le
/// `data:` du `stream.when` inline dans le body.
///
/// Recoit [entries] DEJA filtrees par l'ecran parent (qui watch le
/// carnet et applique `filterCarnet`) plutot que de re-watch : la
/// liste ne connait ni les filtres ni la recherche, juste ce qu'elle
/// doit peindre. [hasQuery] sert uniquement a choisir le bon texte
/// d'etat vide ("Aucun resultat" vs "Carnet vide").
class CarnetList extends StatelessWidget {
  const CarnetList({
    super.key,
    required this.entries,
    required this.hasQuery,
    required this.selectionMode,
    required this.selectedIds,
    required this.onSelectToggle,
    required this.onEnterSelection,
  });

  final List<SavedDestination> entries;
  final bool hasQuery;

  /// Mode selection multiple actif (carte #104).
  final bool selectionMode;
  final Set<int> selectedIds;

  /// (De)coche la fiche dont l'id est passe.
  final ValueChanged<int> onSelectToggle;

  /// Appui long : entre en mode selection avec cette fiche pre-cochee.
  final ValueChanged<int> onEnterSelection;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return CarnetEmptyState(hasQuery: hasQuery);
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x14,
        AppSpacing.x4,
        AppSpacing.x14,
        AppSpacing.x18,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return CarnetTile(
          entry: e,
          selectionMode: selectionMode,
          selected: selectedIds.contains(e.id),
          onSelectToggle: () => onSelectToggle(e.id),
          onEnterSelection: () => onEnterSelection(e.id),
        );
      },
    );
  }
}
