import 'package:drift/drift.dart' show OrderingTerm, Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/tournees_repository.dart';

void main() {
  group('TourneesRepository.duplicate', () {
    late AppDatabase db;
    late TourneesRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = TourneesRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee({String nom = 'Mardi 12/05'}) async {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: nom,
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot Paris 11',
              vehiculeCapaciteColis: const Value(20),
              statut: const Value('terminee'),
              distanceTotaleM: const Value(50000),
              dureeTotaleS: const Value(7200),
              optimiseeLe: Value(DateTime(2026, 5, 12, 8, 30)),
              traceGeojson: const Value('[[1,48],[2,49]]'),
            ),
          );
    }

    test('copie le nom avec suffixe (copie)', () async {
      final id = await seedTournee(nom: 'Tournee A');
      final newId = await repo.duplicate(id);
      final t = await repo.getById(newId);
      expect(t!.nom, 'Tournee A (copie)');
    });

    test('numerote si copie deja existante : (copie 2), (copie 3)...',
        () async {
      final id = await seedTournee(nom: 'Tournee A (copie)');
      final newId = await repo.duplicate(id);
      final t = await repo.getById(newId);
      expect(t!.nom, 'Tournee A (copie 2)');
    });

    test('reset des metriques + statut brouillon par defaut', () async {
      final id = await seedTournee();
      final newId = await repo.duplicate(id);
      final t = await repo.getById(newId);
      expect(t!.statut, 'brouillon');
      expect(t.distanceTotaleM, isNull);
      expect(t.dureeTotaleS, isNull);
      expect(t.optimiseeLe, isNull);
      expect(t.traceGeojson, isNull);
    });

    test('copie de la capacite + point de depart', () async {
      final id = await seedTournee();
      final newId = await repo.duplicate(id);
      final t = await repo.getById(newId);
      expect(t!.vehiculeCapaciteColis, 20);
      expect(t.pointDepartLat, 48.0);
      expect(t.pointDepartLng, 1.0);
      expect(t.pointDepartLabel, 'Depot Paris 11');
    });

    test('copie les stops avec statuts reset a a_livrer', () async {
      final id = await seedTournee();
      // 2 stops avec statuts a livrer / livre / echec
      await db.into(db.stops).insert(StopsCompanion.insert(
            tourneeId: id,
            adresseBrute: 'A',
            nbColis: const Value(3),
            statutLivraison: const Value('livre'),
            ordreOptimise: const Value(1),
            ordrePriorite: const Value(2),
          ));
      await db.into(db.stops).insert(StopsCompanion.insert(
            tourneeId: id,
            adresseBrute: 'B',
            nbColis: const Value(5),
            statutLivraison: const Value('echec'),
            raisonEchec: const Value('absent'),
            ordreOptimise: const Value(2),
          ));

      final newId = await repo.duplicate(id);

      final stops = await (db.select(db.stops)
            ..where((s) => s.tourneeId.equals(newId))
            ..orderBy([(s) => OrderingTerm.asc(s.id)]))
          .get();
      expect(stops, hasLength(2));
      // Tous les statuts ont ete reset.
      expect(stops.every((s) => s.statutLivraison == 'a_livrer'), isTrue);
      expect(stops.every((s) => s.raisonEchec == null), isTrue);
      expect(stops.every((s) => s.ordreOptimise == null), isTrue);
      // Mais les contenus metier sont preserves (adresse, colis, prio).
      expect(stops[0].adresseBrute, 'A');
      expect(stops[0].nbColis, 3);
      expect(stops[0].ordrePriorite, 2);
      expect(stops[1].nbColis, 5);
    });

    test('source introuvable -> StateError', () async {
      expect(() => repo.duplicate(99999),
          throwsA(isA<StateError>()));
    });
  });
}
