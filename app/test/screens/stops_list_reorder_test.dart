import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/screens/tournee_du_jour/stops_list.dart';

/// Tests de la reconstruction d'ordre après drag quand les arrêts terminés
/// sont parqués/masqués en bas (carte A Noah). Garantit qu'on persiste
/// TOUJOURS la liste complète des ids (sinon collisions d'ordreOptimise).
void main() {
  group('rebuildOrderAfterReorder', () {
    test('déplacer un restant vers le bas + ré-append les terminés masqués',
        () {
      final r = rebuildOrderAfterReorder(
        displayIds: [1, 2, 3],
        hiddenDoneIds: [9, 8],
        oldIndex: 0,
        newIndex: 2, // descend l'item 1 d'un cran (ajustement -1)
      );
      expect(r, [2, 1, 3, 9, 8]);
    });

    test('déplacer un restant vers le haut', () {
      final r = rebuildOrderAfterReorder(
        displayIds: [1, 2, 3],
        hiddenDoneIds: [9],
        oldIndex: 2,
        newIndex: 0,
      );
      expect(r, [3, 1, 2, 9]);
    });

    test('terminés dépliés (hiddenDone vide) : pas de double ajout', () {
      // _showDone = true -> display contient déjà les terminés, hidden vide.
      final r = rebuildOrderAfterReorder(
        displayIds: [1, 2, 9],
        hiddenDoneIds: const [],
        oldIndex: 0,
        newIndex: 2,
      );
      expect(r, [2, 1, 9]);
    });

    test('un seul restant + un terminé masqué : ordre stable', () {
      final r = rebuildOrderAfterReorder(
        displayIds: [5],
        hiddenDoneIds: [7],
        oldIndex: 0,
        newIndex: 0,
      );
      expect(r, [5, 7]);
    });

    test('aucun id perdu ni dupliqué', () {
      final r = rebuildOrderAfterReorder(
        displayIds: [1, 2, 3, 4],
        hiddenDoneIds: [10, 11],
        oldIndex: 1,
        newIndex: 4,
      );
      expect(r.toSet(), {1, 2, 3, 4, 10, 11});
      expect(r.length, 6);
    });
  });
}
