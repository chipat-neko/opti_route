/// Post-traitement d'un ordre propose pour respecter les arrets
/// verrouilles (carte #114).
///
/// Un arret "verrouille" (`Stop.positionLocked`) doit rester a sa
/// position COURANTE quoi qu'il arrive : le tri rapide local, l'optim
/// VROOM et le drag&drop calculent un ordre ideal pour les autres
/// arrets, puis cette fonction re-injecte les arrets verrouilles a leur
/// index d'origine et place les non-verrouilles (dans l'ordre propose)
/// dans les emplacements restants.
///
/// Fonction PURE : prend des listes d'ids, retourne une liste d'ids.
/// Testable sans DB.
class LockOrdering {
  LockOrdering._();

  /// [currentOrder] : ordre courant des ids (donne l'index ou chaque
  ///   arret verrouille doit rester).
  /// [proposedOrder] : ordre ideal calcule par l'algo (doit couvrir le
  ///   meme ensemble d'ids que [currentOrder]).
  /// [lockedIds] : ids des arrets verrouilles.
  ///
  /// Retourne le nouvel ordre : arrets verrouilles a leur index de
  /// [currentOrder], les autres dans l'ordre de [proposedOrder].
  ///
  /// Si aucun arret n'est verrouille, retourne [proposedOrder] tel quel.
  /// Robustesse : si les deux listes ne couvrent pas le meme ensemble
  /// (ne devrait pas arriver), on retombe sur [proposedOrder] pour ne
  /// jamais perdre ni dupliquer un arret.
  static List<int> respectLocks({
    required List<int> currentOrder,
    required List<int> proposedOrder,
    required Set<int> lockedIds,
  }) {
    if (lockedIds.isEmpty) return proposedOrder;
    final n = currentOrder.length;
    if (proposedOrder.length != n ||
        currentOrder.toSet().length != n ||
        !currentOrder.toSet().containsAll(proposedOrder)) {
      return proposedOrder;
    }

    // Emplacements verrouilles : index -> id (selon l'ordre courant).
    final result = List<int?>.filled(n, null);
    final lockedHere = <int>{};
    for (var i = 0; i < n; i++) {
      final id = currentOrder[i];
      if (lockedIds.contains(id)) {
        result[i] = id;
        lockedHere.add(id);
      }
    }

    // File des non-verrouilles dans l'ordre propose.
    final queue = <int>[
      for (final id in proposedOrder)
        if (!lockedHere.contains(id)) id,
    ];

    var qi = 0;
    for (var i = 0; i < n; i++) {
      if (result[i] == null) {
        result[i] = queue[qi++];
      }
    }
    return result.cast<int>();
  }
}
