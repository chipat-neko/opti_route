import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/sheets_repository.dart';

void main() {
  group('SheetsRepository', () {
    late AppDatabase db;
    late SheetsRepository repo;
    late int stopId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = SheetsRepository(db);
      final tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      stopId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('create + getById round-trip', () async {
      final id = await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'Chronopost',
        nbColis: const Value(3),
      ));
      final s = await repo.getById(id);
      expect(s, isNotNull);
      expect(s!.expediteur, 'Chronopost');
      expect(s.nbColis, 3);
      expect(s.statut, 'a_livrer'); // defaut
    });

    test('getByStop : retourne toutes les sheets', () async {
      await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'Chronopost',
      ));
      await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'Colissimo',
      ));
      final list = await repo.getByStop(stopId);
      expect(list, hasLength(2));
      expect(list.map((s) => s.expediteur), containsAll([
        'Chronopost',
        'Colissimo',
      ]));
    });

    test('totalColisForStop : somme les nbColis', () async {
      await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'A',
        nbColis: const Value(3),
      ));
      await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'B',
        nbColis: const Value(2),
      ));
      await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'C',
        nbColis: const Value(5),
      ));
      expect(await repo.totalColisForStop(stopId), 10);
    });

    test('totalColisForStop : 0 si aucune sheet', () async {
      expect(await repo.totalColisForStop(stopId), 0);
    });

    test('update : modifie un champ', () async {
      final id = await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'Chronopost',
        nbColis: const Value(1),
      ));
      await repo.update(id, const SheetsCompanion(nbColis: Value(5)));
      final s = await repo.getById(id);
      expect(s!.nbColis, 5);
      expect(s.expediteur, 'Chronopost'); // pas touche
    });

    test('delete : retire une sheet', () async {
      final id = await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'A',
      ));
      await repo.delete(id);
      expect(await repo.getById(id), isNull);
    });

    test('cascade : suppression du stop -> suppression des sheets',
        () async {
      await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'A',
      ));
      await (db.delete(db.stops)..where((s) => s.id.equals(stopId))).go();
      expect(await repo.getByStop(stopId), isEmpty);
    });

    test('watchByStop : stream pousse a chaque insert', () async {
      final stream = repo.watchByStop(stopId);
      // Snapshot initial vide
      expect((await stream.first), isEmpty);

      await repo.create(SheetsCompanion.insert(
        stopId: stopId,
        expediteur: 'A',
      ));
      // Snapshot suivant : 1 entree
      final later = await stream.first;
      expect(later, hasLength(1));
    });
  });
}
