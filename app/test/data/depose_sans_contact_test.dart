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
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D'));
  });

  tearDown(() async => db.close());

  group('Stop.deposeSansContact (#287)', () {
    test('default false', () async {
      final id = await repo.create(
          StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      final s = await repo.getById(id);
      expect(s!.deposeSansContact, isFalse);
    });

    test('set true via update + relisible', () async {
      final id = await repo.create(
          StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      await repo.update(
        id,
        const StopsCompanion(deposeSansContact: Value(true)),
      );
      final s = await repo.getById(id);
      expect(s!.deposeSansContact, isTrue);
    });

    test('toggle back to false', () async {
      final id = await repo.create(
          StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      await repo.update(id,
          const StopsCompanion(deposeSansContact: Value(true)));
      await repo.update(id,
          const StopsCompanion(deposeSansContact: Value(false)));
      expect((await repo.getById(id))!.deposeSansContact, isFalse);
    });
  });
}
