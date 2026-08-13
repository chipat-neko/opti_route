import 'package:flutter/material.dart';

/// AppBar contextuel du mode selection multiple du carnet (carte #104) :
/// compteur de fiches cochees + actions en masse (favori / etiquette
/// couleur / suppression). Les 3 actions sont desactivees tant que rien
/// n'est coche.
///
/// Extrait de `carnet_adresses_screen.dart` (refactor F27) : etait la
/// methode privee `_buildSelectionAppBar`. Les handlers restent dans
/// l'ecran parent (ils ont besoin de la selection courante + ref).
class CarnetSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CarnetSelectionAppBar({
    super.key,
    required this.count,
    required this.onExit,
    required this.onFavori,
    required this.onColorTag,
    required this.onDelete,
  });

  /// Nombre de fiches actuellement cochees.
  final int count;

  final VoidCallback onExit;
  final VoidCallback onFavori;
  final VoidCallback onColorTag;
  final VoidCallback onDelete;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Quitter la selection',
        onPressed: onExit,
      ),
      title: Text('$count selectionne${count > 1 ? "s" : ""}'),
      actions: [
        IconButton(
          icon: const Icon(Icons.star_outline),
          tooltip: 'Marquer favori',
          onPressed: count == 0 ? null : onFavori,
        ),
        IconButton(
          icon: const Icon(Icons.palette_outlined),
          tooltip: 'Etiquette couleur',
          onPressed: count == 0 ? null : onColorTag,
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: 'Supprimer',
          onPressed: count == 0 ? null : onDelete,
        ),
      ],
    );
  }
}
