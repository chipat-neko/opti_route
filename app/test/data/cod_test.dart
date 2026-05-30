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

  group('Stop COD (#296)', () {
    test('defaults : montantCod null, codPaye false', () async {
      final id = await repo
          .create(StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      final s = await repo.getById(id);
      expect(s!.montantCod, isNull);
      expect(s.codPaye, isFalse);
    });

    test('set montant + paye', () async {
      final id = await repo
          .create(StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'));
      await repo.update(
        id,
        const StopsCompanion(
            montantCod: Value(42.50), codPaye: Value(true)),
      );
      final s = await repo.getById(id);
      expect(s!.montantCod, 42.50);
      expect(s.codPaye, isTrue);
    });

    test('total cod a percevoir sur une tournee = sum des non-payes',
        () async {
      await repo.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        montantCod: const Value(10.0),
      ));
      await repo.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'B',
        montantCod: const Value(25.0),
        codPaye: const Value(true),
      ));
      final stops = await repo.getByTournee(tId);
      final restant = stops
          .where((s) => !s.codPaye && s.montantCod != null)
          .fold<double>(0, (sum, s) => sum + s.montantCod!);
      expect(restant, 10.0);
    });
  });
}
