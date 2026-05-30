import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/tournees_repository.dart';

void main() {
  late AppDatabase db;
  late TourneesRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = TourneesRepository(db);
  });

  tearDown(() async => db.close());

  Future<int> seedTournee(String nom) async {
    return db.into(db.tournees).insert(TourneesCompanion.insert(
        nom: nom,
        date: DateTime(2026, 5, 30),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D'));
  }

  Future<void> seedStop(int tId, String statut, {String? nom}) async {
    await db.into(db.stops).insert(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        nomClient: Value(nom),
        statutLivraison: Value(statut),
        raisonEchec: statut == 'echec' ? const Value('absent') : const Value.absent()));
  }

  group('cloneEchecsToDate (#284)', () {
    test('copie uniquement les echecs, reset statut a_livrer', () async {
      final src = await seedTournee('Lun');
      await seedStop(src, 'echec', nom: 'Mme A');
      await seedStop(src, 'livre');
      await seedStop(src, 'echec', nom: 'M B');
      await seedStop(src, 'a_livrer');
      final tgt = DateTime(2026, 5, 31);
      final newId = await repo.cloneEchecsToDate(
        sourceId: src,
        targetDate: tgt,
      );
      final clones = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(newId)))
          .get();
      expect(clones, hasLength(2));
      expect(clones.every((s) => s.statutLivraison == 'a_livrer'), isTrue);
      expect(clones.every((s) => s.raisonEchec == null), isTrue);
    });

    test('throw si aucun echec', () async {
      final src = await seedTournee('Lun');
      await seedStop(src, 'livre');
      expect(
        () => repo.cloneEchecsToDate(
          sourceId: src,
          targetDate: DateTime(2026, 5, 31),
        ),
        throwsStateError,
      );
    });

    test('throw si source introuvable', () async {
      expect(
        () => repo.cloneEchecsToDate(
          sourceId: 99999,
          targetDate: DateTime(2026, 5, 31),
        ),
        throwsStateError,
      );
    });
  });
}
