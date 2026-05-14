import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';

void main() {
  late AppDatabase db;
  late StopsRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = StopsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTournee(String nom) async {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: nom,
            date: DateTime(2026, 5, 14),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'Depot',
          ),
        );
  }

  Future<int> seedStop({
    required int tourneeId,
    int? ordreOptimise,
  }) async {
    return db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: 'Test',
            ordreOptimise: Value(ordreOptimise),
          ),
        );
  }

  group('StopsRepository.moveToTournee', () {
    test('deplace un stop vers une autre tournee', () async {
      final t1 = await seedTournee('Source');
      final t2 = await seedTournee('Dest');
      final stopId = await seedStop(tourneeId: t1);

      await repo.moveToTournee(stopId, t2);

      // Le stop doit maintenant appartenir a t2
      final all = await repo.getByTournee(t2);
      expect(all, hasLength(1));
      expect(all.first.id, stopId);
      expect(all.first.tourneeId, t2);
      // Et plus a t1
      final t1Stops = await repo.getByTournee(t1);
      expect(t1Stops, isEmpty);
    });

    test('reset l\'ordre optimise lors du deplacement', () async {
      final t1 = await seedTournee('Source');
      final t2 = await seedTournee('Dest');
      final stopId = await seedStop(tourneeId: t1, ordreOptimise: 5);

      // Avant : ordreOptimise = 5
      final before = await repo.getById(stopId);
      expect(before!.ordreOptimise, 5);

      await repo.moveToTournee(stopId, t2);

      // Apres : ordreOptimise reset a null (sera recalcule par l'auto-reorder)
      final after = await repo.getById(stopId);
      expect(after!.ordreOptimise, isNull);
    });

    test('ne touche pas aux autres stops de la tournee source', () async {
      final t1 = await seedTournee('Source');
      final t2 = await seedTournee('Dest');
      final s1 = await seedStop(tourneeId: t1);
      final s2 = await seedStop(tourneeId: t1);

      await repo.moveToTournee(s1, t2);

      final t1Stops = await repo.getByTournee(t1);
      expect(t1Stops, hasLength(1));
      expect(t1Stops.first.id, s2);
    });
  });
}
