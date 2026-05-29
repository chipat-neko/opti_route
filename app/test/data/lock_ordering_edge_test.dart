import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/lock_ordering.dart';

// Complete lock_ordering_test : cas degeneres + robustesse fallback.
void main() {
  group('LockOrdering.respectLocks — cas degeneres', () {
    test('listes vides + locks vides : []', () {
      expect(
        LockOrdering.respectLocks(
          currentOrder: const [],
          proposedOrder: const [],
          lockedIds: const {},
        ),
        isEmpty,
      );
    });

    test('1 element, pas de lock : passe', () {
      expect(
        LockOrdering.respectLocks(
          currentOrder: const [42],
          proposedOrder: const [42],
          lockedIds: const {},
        ),
        const [42],
      );
    });

    test('1 element verrouille : retourne la meme liste', () {
      expect(
        LockOrdering.respectLocks(
          currentOrder: const [42],
          proposedOrder: const [42],
          lockedIds: const {42},
        ),
        const [42],
      );
    });

    test('tous verrouilles : ignore proposedOrder, retourne currentOrder',
        () {
      // Tous fixes -> aucune marge de manoeuvre, l'ordre reste celui
      // du current.
      expect(
        LockOrdering.respectLocks(
          currentOrder: const [1, 2, 3],
          proposedOrder: const [3, 2, 1],
          lockedIds: const {1, 2, 3},
        ),
        const [1, 2, 3],
      );
    });
  });

  group('LockOrdering.respectLocks — patterns', () {
    test('zebra : pair locked, impair libre', () {
      // 1 verrouille (index 0), 3 verrouille (index 2). 2 et 4 libres
      // dans l'ordre [4, 2]
      final out = LockOrdering.respectLocks(
        currentOrder: const [1, 2, 3, 4],
        proposedOrder: const [4, 2, 1, 3],
        lockedIds: const {1, 3},
      );
      expect(out, [1, 4, 3, 2]);
    });

    test('lock du milieu : surround se reordonne', () {
      // 2 verrouille (index 1). 1, 3 reordonne en [3, 1]
      final out = LockOrdering.respectLocks(
        currentOrder: const [1, 2, 3],
        proposedOrder: const [3, 1, 2],
        lockedIds: const {2},
      );
      expect(out, [3, 2, 1]);
    });

    test('lockedIds avec id absent du currentOrder : ignore', () {
      // 99 n'existe pas dans current. La fonction ne doit pas crasher,
      // juste ignorer ce lock-fantome.
      final out = LockOrdering.respectLocks(
        currentOrder: const [1, 2, 3],
        proposedOrder: const [3, 2, 1],
        lockedIds: const {99},
      );
      // 99 n'est dans aucune des deux listes -> aucun slot fixe, et
      // l'algo retombe sur proposedOrder (puisque le set d'ids match).
      expect(out, [3, 2, 1]);
    });
  });

  group('LockOrdering.respectLocks — robustesse fallback', () {
    test('proposedOrder a un id qui n\'existe pas dans current : fallback',
        () {
      // 99 dans proposed mais pas dans current -> fallback sur proposed
      final out = LockOrdering.respectLocks(
        currentOrder: const [1, 2, 3],
        proposedOrder: const [99, 2, 3], // mismatch (99 vs 1)
        lockedIds: const {2},
      );
      expect(out, [99, 2, 3]);
    });

    test('currentOrder contient un doublon : fallback', () {
      // 2 apparait 2x -> set length != list length -> fallback
      final out = LockOrdering.respectLocks(
        currentOrder: const [1, 2, 2],
        proposedOrder: const [2, 1, 2],
        lockedIds: const {1},
      );
      expect(out, [2, 1, 2]);
    });

    test('proposedOrder longueur > current : fallback', () {
      final out = LockOrdering.respectLocks(
        currentOrder: const [1, 2],
        proposedOrder: const [1, 2, 3],
        lockedIds: const {1},
      );
      expect(out, [1, 2, 3]);
    });
  });
}
