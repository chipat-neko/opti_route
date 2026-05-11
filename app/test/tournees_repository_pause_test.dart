import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/tournees_repository.dart';

/// Tests cibles sur le cycle pause / reprise d'une tournee (migration
/// drift v15 : champs `pausedAtLast` + `pausedTotalS`).
void main() {
  group('TourneesRepository - pause / resume', () {
    late AppDatabase db;
    late TourneesRepository repo;
    late int tId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = TourneesRepository(db);
      tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 11),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
              statut: const Value('en_cours'),
              demareeLe: Value(DateTime.now()),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('etat initial : pausedAtLast = null, pausedTotalS = 0', () async {
      final t = await repo.getById(tId);
      expect(t!.pausedAtLast, isNull);
      expect(t.pausedTotalS, 0);
    });

    test('pause pose pausedAtLast = now (sans toucher pausedTotalS)',
        () async {
      final before = DateTime.now();
      await repo.pauseTournee(tId);
      final t = await repo.getById(tId);
      expect(t!.pausedAtLast, isNotNull);
      expect(
        t.pausedAtLast!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
      expect(t.pausedTotalS, 0);
    });

    test('pause deja en pause = no-op (idempotence)', () async {
      await repo.pauseTournee(tId);
      final t1 = await repo.getById(tId);
      // 2e tap pause -> no-op, le timestamp ne doit pas bouger.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.pauseTournee(tId);
      final t2 = await repo.getById(tId);
      expect(t2!.pausedAtLast, equals(t1!.pausedAtLast));
    });

    test('resume sans pause = no-op', () async {
      await repo.resumeTournee(tId);
      final t = await repo.getById(tId);
      expect(t!.pausedAtLast, isNull);
      expect(t.pausedTotalS, 0);
    });

    test('cycle pause + resume : pausedTotalS = duree de la pause', () async {
      await repo.pauseTournee(tId);
      // Attendre un peu pour que (now - pausedAtLast) >= 1 seconde
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await repo.resumeTournee(tId);

      final t = await repo.getById(tId);
      expect(t!.pausedAtLast, isNull);
      expect(t.pausedTotalS, inInclusiveRange(1, 5));
    });

    test('2 cycles pause/resume : pausedTotalS cumule', () async {
      await repo.pauseTournee(tId);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await repo.resumeTournee(tId);
      final first = (await repo.getById(tId))!.pausedTotalS;

      await repo.pauseTournee(tId);
      await Future<void>.delayed(const Duration(milliseconds: 1100));
      await repo.resumeTournee(tId);
      final second = (await repo.getById(tId))!.pausedTotalS;

      // 2e cumul doit etre au moins egal au 1er + ~1s
      expect(second, greaterThanOrEqualTo(first + 1));
    });
  });
}
