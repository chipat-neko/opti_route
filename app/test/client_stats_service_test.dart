import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/client_stats_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

void main() {
  group('ClientStatsService.computeFor', () {
    late AppDatabase db;
    late SavedDestinationsRepository carnetRepo;
    late ClientStatsService stats;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      carnetRepo = SavedDestinationsRepository(db);
      stats = ClientStatsService(db);

      // Une tournee pour avoir des stops attachables.
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 10),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    Future<SavedDestination> seedClient({
      String nomClient = 'Mme Dupont',
      double lat = 48.43,
      double lng = 1.49,
    }) async {
      await carnetRepo.upsertFromValidatedStop(
        nomClient: nomClient,
        adresseDisplay: '12 Rue Foo, 28000 Chartres',
        lat: lat,
        lng: lng,
      );
      final found = await carnetRepo.search(nomClient);
      return found.first;
    }

    Future<void> seedStop({
      required String statut,
      String? nomClient,
      String? raison,
      double? lat,
      double? lng,
    }) async {
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: 1,
              adresseBrute: 'addr',
              nomClient: Value(nomClient),
              statutLivraison: Value(statut),
              raisonEchec: Value(raison),
              lat: Value(lat),
              lng: Value(lng),
            ),
          );
    }

    test('aucun stop -> stats empty', () async {
      final c = await seedClient();
      final s = await stats.computeFor(c);
      expect(s.isEmpty, isTrue);
      expect(s.nbLivraisons, 0);
    });

    test('match par nom (case-insensitive)', () async {
      final c = await seedClient(nomClient: 'Mme Dupont');
      await seedStop(statut: 'livre', nomClient: 'MME DUPONT');
      await seedStop(statut: 'livre', nomClient: 'mme dupont');
      await seedStop(statut: 'echec', nomClient: 'Mme Dupont', raison: 'absent');
      final s = await stats.computeFor(c);
      expect(s.nbLivraisons, 2);
      expect(s.nbEchecs, 1);
      expect(s.tauxReussite, closeTo(2 / 3, 0.001));
    });

    test('match par coords (~110m)', () async {
      final c = await seedClient(lat: 48.4300, lng: 1.4900);
      // Stop sans le bon nom mais avec coords proches
      await seedStop(
        statut: 'livre',
        nomClient: 'Autre nom',
        lat: 48.4302,
        lng: 1.4901,
      );
      // Stop avec coords trop eloignees (~1 km)
      await seedStop(
        statut: 'livre',
        nomClient: 'Encore autre',
        lat: 48.4500,
        lng: 1.4900,
      );
      final s = await stats.computeFor(c);
      expect(s.nbLivraisons, 1);
    });

    test('top 3 des raisons d\'echec triees par frequence', () async {
      final c = await seedClient();
      for (var i = 0; i < 3; i++) {
        await seedStop(statut: 'echec', nomClient: 'Mme Dupont', raison: 'absent');
      }
      await seedStop(statut: 'echec', nomClient: 'Mme Dupont', raison: 'refuse');
      final s = await stats.computeFor(c);
      expect(s.raisonsEchecCourantes.first.raison, 'absent');
      expect(s.raisonsEchecCourantes.first.n, 3);
      expect(s.raisonsEchecCourantes.length, 2);
    });
  });

  group('ClientStats - tauxReussite + isEmpty', () {
    test('aucune tentative : tauxReussite = 0 / isEmpty = true', () {
      const s = ClientStats.empty;
      expect(s.tauxReussite, 0);
      expect(s.isEmpty, isTrue);
    });

    test('3 livre / 1 echec : taux 0.75', () {
      const s = ClientStats(
        nbLivraisons: 3,
        nbEchecs: 1,
        derniereLivraison: null,
        raisonsEchecCourantes: [],
      );
      expect(s.tauxReussite, closeTo(0.75, 0.001));
      expect(s.isEmpty, isFalse);
    });

    test('100 % livres : 1.0', () {
      const s = ClientStats(
        nbLivraisons: 5,
        nbEchecs: 0,
        derniereLivraison: null,
        raisonsEchecCourantes: [],
      );
      expect(s.tauxReussite, 1.0);
    });
  });
}
