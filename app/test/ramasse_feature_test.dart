import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stats_service.dart';
import 'package:opti_route/data/stop_types.dart';
import 'package:opti_route/data/stops_repository.dart';

/// Tests de la feature ramasses (2026-05-18) :
/// - constantes + helpers stop_types.dart
/// - colonne `type` Stops avec default 'livraison'
/// - setType repository
/// - stats split nbLivraisons / nbRamasses dans TourneeStats
/// - CSV export inclut les nouvelles colonnes

void main() {
  group('Stop types - constantes + helpers', () {
    test('valeurs autorisees', () {
      expect(kStopTypeLivraison, 'livraison');
      expect(kStopTypeRamasse, 'ramasse');
      expect(kStopTypeValues, [kStopTypeLivraison, kStopTypeRamasse]);
    });

    test('stopActionVerbInfinitif', () {
      expect(stopActionVerbInfinitif(kStopTypeLivraison), 'livre');
      expect(stopActionVerbInfinitif(kStopTypeRamasse), 'ramasse');
      // Type inconnu = fallback livraison.
      expect(stopActionVerbInfinitif('inconnu'), 'livre');
    });

    test('stopTypeLabelUpper', () {
      expect(stopTypeLabelUpper(kStopTypeLivraison), 'LIVRAISON');
      expect(stopTypeLabelUpper(kStopTypeRamasse), 'RAMASSE');
    });

    test('stopTypeLabel', () {
      expect(stopTypeLabel(kStopTypeLivraison), 'Livraison');
      expect(stopTypeLabel(kStopTypeRamasse), 'Ramasse');
    });
  });

  group('Stops.type DB - default + persistence', () {
    late AppDatabase db;
    late StopsRepository repo;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = StopsRepository(db);
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 18),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
    });

    tearDown(() async => db.close());

    test('insert sans type -> default livraison', () async {
      final id = await repo.create(StopsCompanion.insert(
        tourneeId: 1,
        adresseBrute: '1 rue A',
      ));
      final stop = await repo.getById(id);
      expect(stop!.type, kStopTypeLivraison);
    });

    test('insert avec type=ramasse persistance', () async {
      final id = await repo.create(StopsCompanion.insert(
        tourneeId: 1,
        adresseBrute: '1 rue A',
        type: const Value(kStopTypeRamasse),
      ));
      final stop = await repo.getById(id);
      expect(stop!.type, kStopTypeRamasse);
    });

    test('setType bascule livraison -> ramasse', () async {
      final id = await repo.create(StopsCompanion.insert(
        tourneeId: 1,
        adresseBrute: '1 rue A',
      ));
      await repo.setType(id, kStopTypeRamasse);
      final stop = await repo.getById(id);
      expect(stop!.type, kStopTypeRamasse);
    });

    test('setType bascule ramasse -> livraison', () async {
      final id = await repo.create(StopsCompanion.insert(
        tourneeId: 1,
        adresseBrute: '1 rue A',
        type: const Value(kStopTypeRamasse),
      ));
      await repo.setType(id, kStopTypeLivraison);
      final stop = await repo.getById(id);
      expect(stop!.type, kStopTypeLivraison);
    });

    test('setType preserve le statut et les autres champs', () async {
      final id = await repo.create(StopsCompanion.insert(
        tourneeId: 1,
        adresseBrute: '1 rue A',
        nomClient: const Value('Mme Dupont'),
        nbColis: const Value(3),
      ));
      // Marquer livre puis convertir en ramasse : le statut + nbColis
      // doivent rester intacts.
      await repo.markLivre(id);
      await repo.setType(id, kStopTypeRamasse);
      final stop = await repo.getById(id);
      expect(stop!.type, kStopTypeRamasse);
      expect(stop.statutLivraison, 'livre');
      expect(stop.nbColis, 3);
      expect(stop.nomClient, 'Mme Dupont');
    });
  });

  group('StatsService - split livraisons / ramasses', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 18),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
              statut: const Value('terminee'),
            ),
          );
    });

    tearDown(() async => db.close());

    Future<void> seedStop({
      required String statut,
      String type = kStopTypeLivraison,
      int nbColis = 1,
    }) async {
      await db.into(db.stops).insert(StopsCompanion.insert(
            tourneeId: 1,
            adresseBrute: 'addr',
            type: Value(type),
            statutLivraison: Value(statut),
            nbColis: Value(nbColis),
          ));
    }

    test('aucun stop -> nbLivraisons=0, nbRamasses=0', () async {
      final s = await stats.compute(since: DateTime(2026, 5, 1));
      expect(s.nbLivraisons, 0);
      expect(s.nbRamasses, 0);
      expect(s.nbLivres, 0);
    });

    test('mix 3 livraisons + 2 ramasses tous reussis', () async {
      await seedStop(statut: 'livre');
      await seedStop(statut: 'livre');
      await seedStop(statut: 'livre');
      await seedStop(statut: 'livre', type: kStopTypeRamasse);
      await seedStop(statut: 'livre', type: kStopTypeRamasse);

      final s = await stats.compute(since: DateTime(2026, 5, 1));
      expect(s.nbLivraisons, 3);
      expect(s.nbRamasses, 2);
      // nbLivres = total (livraisons + ramasses) pour back-compat.
      expect(s.nbLivres, 5);
    });

    test('ramasse echec NE compte PAS dans nbRamasses', () async {
      // Un ramasse qui n'a pas pu etre fait reste un echec, pas compte
      // dans nbRamasses (qui = ramasses reussis seulement).
      await seedStop(statut: 'echec', type: kStopTypeRamasse);
      await seedStop(statut: 'livre', type: kStopTypeRamasse);

      final s = await stats.compute(since: DateTime(2026, 5, 1));
      expect(s.nbRamasses, 1);
      expect(s.nbEchecs, 1);
    });

    test('computeFromBundle applique aussi le split', () async {
      await seedStop(statut: 'livre');
      await seedStop(statut: 'livre', type: kStopTypeRamasse);
      final bundle = await stats.computeBundle(since: DateTime(2026, 5, 1));
      final s = StatsService.computeFromBundle(
        bundle,
        since: DateTime(2026, 5, 1),
      );
      expect(s.nbLivraisons, 1);
      expect(s.nbRamasses, 1);
    });
  });

  group('StatsService.exportCsvTournees - colonnes ramasses', () {
    test('CSV header inclut nb_livraisons et nb_ramasses', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final stats = StatsService(db);
      try {
        final csv = await stats.exportCsvTournees(
          since: DateTime(2026, 5, 1),
        );
        expect(csv, contains('nb_livraisons'));
        expect(csv, contains('nb_ramasses'));
      } finally {
        await db.close();
      }
    });

    test('CSV data row : compte separe livraisons / ramasses', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final stats = StatsService(db);
      try {
        await db.into(db.tournees).insert(TourneesCompanion.insert(
              nom: 'Test',
              date: DateTime(2026, 5, 18),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: const Value('terminee'),
            ));
        // 2 livraisons reussies, 1 ramasse reussie, 1 echec.
        await db.into(db.stops).insert(StopsCompanion.insert(
              tourneeId: 1,
              adresseBrute: 'a',
              statutLivraison: const Value('livre'),
            ));
        await db.into(db.stops).insert(StopsCompanion.insert(
              tourneeId: 1,
              adresseBrute: 'b',
              statutLivraison: const Value('livre'),
            ));
        await db.into(db.stops).insert(StopsCompanion.insert(
              tourneeId: 1,
              adresseBrute: 'c',
              statutLivraison: const Value('livre'),
              type: const Value(kStopTypeRamasse),
            ));
        await db.into(db.stops).insert(StopsCompanion.insert(
              tourneeId: 1,
              adresseBrute: 'd',
              statutLivraison: const Value('echec'),
              type: const Value(kStopTypeRamasse),
            ));

        final csv = await stats.exportCsvTournees(
          since: DateTime(2026, 5, 1),
        );
        // Format : date,nom,statut,arrets,colis,nb_livraisons,nb_ramasses,...
        // -> chercher ",2,1," pour nb_livraisons=2, nb_ramasses=1
        expect(csv, contains(',2,1,'));
      } finally {
        await db.close();
      }
    });
  });
}
