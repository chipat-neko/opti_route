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

    test('duplicate avec targetDate : la date du clone = targetDate',
        () async {
      final id = await seedTournee();
      final target = DateTime(2026, 6, 1, 9, 30);
      final newId = await repo.duplicate(id, targetDate: target);
      final t = await repo.getById(newId);
      expect(t!.date, target);
    });

    test('duplicate sans targetDate : date du clone proche de now', () async {
      final id = await seedTournee();
      final newId = await repo.duplicate(id);
      final t = await repo.getById(newId);
      final delta = DateTime.now().difference(t!.date).inSeconds.abs();
      expect(delta, lessThan(5),
          reason:
              'La date du clone devrait etre a moins de 5s de now()');
    });

    test('duplicate copie profilOrs + eviterPeages + capacite', () async {
      // Mise a jour de la tournee source avec un profil HGV + peages
      // evites.
      final id = await seedTournee();
      await db.into(db.tournees).insertOnConflictUpdate(
            TourneesCompanion(
              id: Value(id),
              nom: const Value('Source'),
              date: Value(DateTime(2026, 5, 1)),
              pointDepartLat: const Value(48.0),
              pointDepartLng: const Value(1.0),
              pointDepartLabel: const Value('Depot Paris 11'),
              vehiculeCapaciteColis: const Value(20),
              profilOrs: const Value('driving-hgv'),
              eviterPeages: const Value(true),
            ),
          );

      final newId = await repo.duplicate(id);
      final t = await repo.getById(newId);
      expect(t!.profilOrs, 'driving-hgv');
      expect(t.eviterPeages, isTrue);
      expect(t.vehiculeCapaciteColis, 20);
    });

    test('toggleTemplate : false -> true -> false', () async {
      final id = await seedTournee();
      // Init isTemplate = false par defaut.
      var t = await repo.getById(id);
      expect(t!.isTemplate, isFalse);

      await repo.toggleTemplate(id);
      t = await repo.getById(id);
      expect(t!.isTemplate, isTrue);

      await repo.toggleTemplate(id);
      t = await repo.getById(id);
      expect(t!.isTemplate, isFalse);
    });

    test('toggleTemplate sur tournee inconnue : 0 (no-op)', () async {
      final n = await repo.toggleTemplate(99999);
      expect(n, 0);
    });

    test('invalidateOptimization : reset metrics + trace mais pas statut',
        () async {
      final id = await seedTournee();
      // Pose des metrics
      await db.into(db.tournees).insertOnConflictUpdate(
            TourneesCompanion(
              id: Value(id),
              nom: const Value('Source'),
              date: Value(DateTime(2026, 5, 1)),
              pointDepartLat: const Value(48.0),
              pointDepartLng: const Value(1.0),
              pointDepartLabel: const Value('Depot Paris 11'),
              distanceTotaleM: const Value(45000),
              dureeTotaleS: const Value(3600),
              optimiseeLe: Value(DateTime(2026, 5, 1, 10)),
              traceGeojson: const Value('[]'),
              statut: const Value('en_cours'),
            ),
          );

      await repo.invalidateOptimization(id);

      final t = await repo.getById(id);
      expect(t!.distanceTotaleM, isNull);
      expect(t.dureeTotaleS, isNull);
      expect(t.optimiseeLe, isNull);
      expect(t.traceGeojson, isNull);
      // Statut reste a 'en_cours' (on ne fait pas revenir en brouillon).
      expect(t.statut, 'en_cours');
    });

    test('duplicate : (copie 2) -> (copie 3) -> (copie 4)', () async {
      // Couvre la regex de comptage : on doit incrementer correctement
      // meme apres plusieurs cycles.
      final id = await seedTournee(nom: 'T (copie 2)');
      final n1 = await repo.duplicate(id);
      expect((await repo.getById(n1))!.nom, 'T (copie 3)');

      final id4 = await seedTournee(nom: 'T (copie 9)');
      final n2 = await repo.duplicate(id4);
      expect((await repo.getById(n2))!.nom, 'T (copie 10)');
    });

    test('countOlderThan + deleteOlderThan : nettoyage historique', () async {
      // 3 tournees : 2 vieilles (avant cutoff), 1 recente (apres).
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Vieille 1',
              date: DateTime(2025, 1, 1),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Vieille 2',
              date: DateTime(2025, 6, 1),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Recente',
              date: DateTime(2026, 5, 10),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );

      final cutoff = DateTime(2026, 1, 1);
      expect(await repo.countOlderThan(cutoff), 2);

      final deleted = await repo.deleteOlderThan(cutoff);
      expect(deleted, 2);

      // Seule la recente survit.
      expect(await repo.countOlderThan(cutoff), 0);
      final all = await repo.watchAll().first;
      expect(all, hasLength(1));
      expect(all.first.nom, 'Recente');
    });

    test('duplicate avec targetDate explicite', () async {
      final id = await seedTournee();
      final target = DateTime(2030, 12, 25);
      final newId = await repo.duplicate(id, targetDate: target);
      final t = await repo.getById(newId);
      expect(t!.date, target);
    });

    test('pauseTournee : pose le timestamp pauseeLe', () async {
      final id = await seedTournee();
      final before = DateTime.now();
      await repo.pauseTournee(id);
      final t = await repo.getById(id);
      expect(t!.pauseeLe, isNotNull);
      expect(t.pauseeLe!.isAfter(before.subtract(const Duration(seconds: 1))),
          isTrue);
    });

    test('reprendreTournee : ajoute la duree pausee a pauseeSeconds',
        () async {
      final id = await seedTournee();
      // Pose pauseeLe a il y a 5 secondes
      await db.into(db.tournees).insertOnConflictUpdate(
            TourneesCompanion(
              id: Value(id),
              nom: const Value('T'),
              date: Value(DateTime(2026, 5, 12)),
              pointDepartLat: const Value(48.0),
              pointDepartLng: const Value(1.0),
              pointDepartLabel: const Value('D'),
              pauseeLe: Value(DateTime.now()
                  .subtract(const Duration(seconds: 5))),
              pauseeSeconds: const Value(120), // deja 2 min de pause cumulee
            ),
          );
      await repo.reprendreTournee(id);
      final t = await repo.getById(id);
      expect(t!.pauseeLe, isNull);
      // pauseeSeconds = 120 + ~5 = ~125
      expect(t.pauseeSeconds, greaterThanOrEqualTo(125));
      expect(t.pauseeSeconds, lessThan(130));
    });

    test('reprendreTournee sur tournee pas en pause : no-op', () async {
      final id = await seedTournee();
      final n = await repo.reprendreTournee(id);
      expect(n, 0);
      final t = await repo.getById(id);
      expect(t!.pauseeLe, isNull);
      expect(t.pauseeSeconds, 0);
    });

    test('duplicate ne copie PAS rappelLe (chaque clone reprogramme '
        'son propre rappel)', () async {
      final id = await seedTournee();
      await db.into(db.tournees).insertOnConflictUpdate(
            TourneesCompanion(
              id: Value(id),
              nom: const Value('Source'),
              date: Value(DateTime(2026, 5, 1)),
              pointDepartLat: const Value(48.0),
              pointDepartLng: const Value(1.0),
              pointDepartLabel: const Value('Depot Paris 11'),
              rappelLe: Value(DateTime(2026, 5, 1, 6, 45)),
            ),
          );

      final newId = await repo.duplicate(id);
      final t = await repo.getById(newId);
      expect(t!.rappelLe, isNull);
    });
  });
}
