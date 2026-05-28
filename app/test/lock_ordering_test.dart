import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/local_reorder_service.dart';
import 'package:opti_route/data/lock_ordering.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';

/// Tests du verrouillage de position (carte #114) : helper pur
/// [LockOrdering.respectLocks] + integration reorder local + persistance.
void main() {
  group('LockOrdering.respectLocks (pur)', () {
    test('aucun lock -> retourne l\'ordre propose tel quel', () {
      final out = LockOrdering.respectLocks(
        currentOrder: [1, 2, 3],
        proposedOrder: [3, 1, 2],
        lockedIds: const {},
      );
      expect(out, [3, 1, 2]);
    });

    test('un arret verrouille garde son index courant', () {
      // 2 est verrouille a l'index 1. L'ordre propose voudrait [3,2,1].
      // Resultat attendu : 2 reste a l'index 1, les autres (3 puis 1
      // dans l'ordre propose) remplissent les index 0 et 2.
      final out = LockOrdering.respectLocks(
        currentOrder: [1, 2, 3],
        proposedOrder: [3, 2, 1],
        lockedIds: const {2},
      );
      expect(out, [3, 2, 1]);
    });

    test('lock en tete : le reste se reordonne autour', () {
      // 1 verrouille a l'index 0. Propose [3,2,1] -> 1 reste index 0,
      // puis 3, 2 dans les index 1 et 2.
      final out = LockOrdering.respectLocks(
        currentOrder: [1, 2, 3, 4],
        proposedOrder: [4, 3, 2, 1],
        lockedIds: const {1},
      );
      expect(out, [1, 4, 3, 2]);
    });

    test('dernier verrouille (finir par ce client)', () {
      // 4 verrouille a l'index 3 (dernier). Propose un ordre qui le
      // mettrait ailleurs -> il doit rester dernier.
      final out = LockOrdering.respectLocks(
        currentOrder: [1, 2, 3, 4],
        proposedOrder: [4, 1, 3, 2],
        lockedIds: const {4},
      );
      expect(out, [1, 3, 2, 4]);
    });

    test('plusieurs verrouilles gardent chacun leur index', () {
      // 1 (index 0) et 3 (index 2) verrouilles. Les non-verrouilles
      // (2,4) prennent l'ordre propose dans les trous (index 1, 3).
      final out = LockOrdering.respectLocks(
        currentOrder: [1, 2, 3, 4],
        proposedOrder: [4, 2, 1, 3],
        lockedIds: const {1, 3},
      );
      expect(out, [1, 4, 3, 2]);
    });

    test('ensembles incoherents -> fallback sur proposedOrder', () {
      final out = LockOrdering.respectLocks(
        currentOrder: [1, 2, 3],
        proposedOrder: [1, 2], // taille differente
        lockedIds: const {1},
      );
      expect(out, [1, 2]);
    });
  });

  group('Integration reorder local + lock (DB memoire)', () {
    late AppDatabase db;
    late StopsRepository stopsRepo;
    late TourneesRepository tourneesRepo;
    late LocalReorderService reorder;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stopsRepo = StopsRepository(db);
      tourneesRepo = TourneesRepository(db);
      reorder = LocalReorderService(stopsRepo, tourneesRepo);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee() {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 28),
              // Depart proche du 1er stop pour un NN deterministe.
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
    }

    Future<int> seedStop(
      int tourneeId, {
      required double lat,
      required double lng,
      required int ordre,
      bool locked = false,
    }) {
      return db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'A',
              lat: Value(lat),
              lng: Value(lng),
              ordreOptimise: Value(ordre),
              positionLocked: Value(locked),
            ),
          );
    }

    test('setPositionLocked persiste le flag', () async {
      final t = await seedTournee();
      final s = await seedStop(t, lat: 48.0, lng: 1.0, ordre: 1);
      await stopsRepo.setPositionLocked(s, true);
      final row = await stopsRepo.getById(s);
      expect(row!.positionLocked, isTrue);
    });

    test('reorder local garde l\'arret verrouille a son index', () async {
      final t = await seedTournee();
      // Geographie : A loin (ordre 1), B proche du depart (ordre 2),
      // C au milieu (ordre 3). Sans lock, le NN remonterait B en 1er.
      // On verrouille A a l'index 0 -> il doit rester 1er.
      final a = await seedStop(t, lat: 49.0, lng: 2.0, ordre: 1, locked: true);
      final b = await seedStop(t, lat: 48.0, lng: 1.0, ordre: 2);
      final c = await seedStop(t, lat: 48.5, lng: 1.5, ordre: 3);

      await reorder.reorder(t);

      final stops = await stopsRepo.getByTournee(t);
      // L'arret verrouille A reste en 1ere position malgre le NN.
      expect(stops.first.id, a);
      // B et C remplissent les positions suivantes.
      expect(stops.map((s) => s.id).toSet(), {a, b, c});
    });
  });
}
