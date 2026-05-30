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
    tId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 5, 30),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
          ),
        );
  });

  tearDown(() async => db.close());

  group('Stop.memoVocal (#280)', () {
    test('memoVocal null par defaut', () async {
      final id = await repo
          .create(StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      final s = await repo.getById(id);
      expect(s!.memoVocal, isNull);
    });

    test('update memoVocal -> persiste + relisible', () async {
      final id = await repo
          .create(StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      await repo.update(
        id,
        const StopsCompanion(
            memoVocal: Value('sonnette HS, passer par l\'arriere')),
      );
      final s = await repo.getById(id);
      expect(s!.memoVocal, 'sonnette HS, passer par l\'arriere');
    });

    test('clear memoVocal (Value(null)) -> null', () async {
      final id = await repo
          .create(StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      await repo.update(
        id,
        const StopsCompanion(memoVocal: Value('temp')),
      );
      await repo.update(
        id,
        const StopsCompanion(memoVocal: Value(null)),
      );
      final s = await repo.getById(id);
      expect(s!.memoVocal, isNull);
    });
  });
}
