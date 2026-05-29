import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/sheets_repository.dart';

// Complete sheets_repository_test : getById sur id inconnu, watchByStop
// tri par id, multi-stops isoles, delete retourne le count, totalColis
// avec mix de stops.
void main() {
  late AppDatabase db;
  late SheetsRepository repo;
  late int stopA;
  late int stopB;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = SheetsRepository(db);
    final tId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 5, 29),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
          ),
        );
    stopA = await db.into(db.stops).insert(
          StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'),
        );
    stopB = await db.into(db.stops).insert(
          StopsCompanion.insert(tourneeId: tId, adresseBrute: 'B'),
        );
  });

  tearDown(() async {
    await db.close();
  });

  group('SheetsRepository — gardes', () {
    test('getById sur id inconnu : null', () async {
      expect(await repo.getById(99999), isNull);
    });

    test('getByStop sur stop sans sheets : liste vide', () async {
      expect(await repo.getByStop(stopA), isEmpty);
    });

    test('delete sur id inconnu : 0', () async {
      expect(await repo.delete(99999), 0);
    });

    test('delete sur id existant : 1', () async {
      final id = await repo.create(
        SheetsCompanion.insert(
          stopId: stopA,
          expediteur: 'X',
          nbColis: const Value(1),
        ),
      );
      expect(await repo.delete(id), 1);
    });
  });

  group('SheetsRepository — isolation multi-stops', () {
    test('sheets stopA vs stopB : pas de pollution', () async {
      await repo.create(SheetsCompanion.insert(
          stopId: stopA, expediteur: 'A1', nbColis: const Value(1)));
      await repo.create(SheetsCompanion.insert(
          stopId: stopB, expediteur: 'B1', nbColis: const Value(2)));
      await repo.create(SheetsCompanion.insert(
          stopId: stopB, expediteur: 'B2', nbColis: const Value(3)));

      final a = await repo.getByStop(stopA);
      final b = await repo.getByStop(stopB);
      expect(a, hasLength(1));
      expect(b, hasLength(2));
      expect(a.first.expediteur, 'A1');
    });

    test('totalColisForStop : isole sur le stop demande', () async {
      await repo.create(SheetsCompanion.insert(
          stopId: stopA, expediteur: 'A1', nbColis: const Value(5)));
      await repo.create(SheetsCompanion.insert(
          stopId: stopB, expediteur: 'B1', nbColis: const Value(100)));
      expect(await repo.totalColisForStop(stopA), 5,
          reason: 'le total de B (100) ne doit pas etre comptee dans A');
    });
  });

  group('SheetsRepository.watchByStop — ordre id asc', () {
    test('emit tri par id ascendant (ordre de creation)', () async {
      final id1 = await repo.create(SheetsCompanion.insert(
          stopId: stopA, expediteur: 'Premier', nbColis: const Value(1)));
      final id2 = await repo.create(SheetsCompanion.insert(
          stopId: stopA, expediteur: 'Deuxieme', nbColis: const Value(2)));
      final id3 = await repo.create(SheetsCompanion.insert(
          stopId: stopA, expediteur: 'Troisieme', nbColis: const Value(3)));
      final emitted = await repo.watchByStop(stopA).first;
      expect(emitted.map((s) => s.id).toList(), [id1, id2, id3]);
      expect(emitted.map((s) => s.expediteur).toList(),
          ['Premier', 'Deuxieme', 'Troisieme']);
    });

    test('watchByStop : ne emet pas pour les sheets d\'un autre stop',
        () async {
      // Insert dans stopA puis dans stopB ; le stream pour stopA ne
      // doit pas inclure ceux de stopB.
      await repo.create(SheetsCompanion.insert(
          stopId: stopA, expediteur: 'A1', nbColis: const Value(1)));
      await repo.create(SheetsCompanion.insert(
          stopId: stopB, expediteur: 'B1', nbColis: const Value(99)));
      final emitted = await repo.watchByStop(stopA).first;
      expect(emitted, hasLength(1));
      expect(emitted.first.expediteur, 'A1');
    });
  });

  group('SheetsRepository.update — multi-champs', () {
    test('update modifie plusieurs champs simultanement', () async {
      final id = await repo.create(SheetsCompanion.insert(
          stopId: stopA, expediteur: 'X', nbColis: const Value(1)));
      final n = await repo.update(
        id,
        SheetsCompanion(
          expediteur: const Value('Y'),
          nbColis: const Value(5),
        ),
      );
      expect(n, 1);
      final updated = await repo.getById(id);
      expect(updated!.expediteur, 'Y');
      expect(updated.nbColis, 5);
    });

    test('update sur id inconnu : 0 (no-op)', () async {
      final n = await repo.update(
        99999,
        SheetsCompanion(expediteur: const Value('X')),
      );
      expect(n, 0);
    });
  });
}
