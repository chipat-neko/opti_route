import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';

void main() {
  late AppDatabase db;
  late StopsRepository repo;
  late int tId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = StopsRepository(db);
    tId = await db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48,
        pointDepartLng: 1,
        pointDepartLabel: 'D'));
  });
  tearDown(() async => db.close());

  group('notationEmoji (#324)', () {
    test('default null', () async {
      final id = await repo.create(
          StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      final s = await repo.getById(id);
      expect(s!.notationEmoji, isNull);
    });

    test('set happy/neutral/angry', () async {
      final id = await repo.create(
          StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      for (final v in ['happy', 'neutral', 'angry']) {
        await repo.update(
          id,
          StopsCompanion(notationEmoji: Value(v)),
        );
        expect((await repo.getById(id))!.notationEmoji, v);
      }
    });
  });
}
