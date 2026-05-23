// Tests du service de backfill carnet depuis l'historique des stops.

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/carnet_backfill_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

void main() {
  late AppDatabase db;
  late SavedDestinationsRepository repo;
  late CarnetBackfillService backfill;
  late int tourneeId;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = SavedDestinationsRepository(db);
    backfill = CarnetBackfillService(db, repo);
    // Une tournee minimale pour pouvoir creer des stops (FK).
    tourneeId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            date: DateTime(2026, 5, 23),
            nom: 'Test tournee',
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'Depot test',
          ),
        );
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insertStop({
    required String adresseBrute,
    String? nomClient,
    double? lat,
    double? lng,
    String? statut,
  }) {
    return db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: adresseBrute,
            nomClient: Value(nomClient),
            lat: Value(lat),
            lng: Value(lng),
            statutLivraison: Value(statut ?? 'a_livrer'),
          ),
        );
  }

  group('CarnetBackfillService.backfillFromStops', () {
    test('aucun stop -> resultat vide, carnet inchange', () async {
      final result = await backfill.backfillFromStops();
      expect(result.totalStops, 0);
      expect(result.created, 0);
      expect(result.merged, 0);
      expect(result.skipped, 0);
      expect(await repo.count(), 0);
    });

    test('3 stops geocodes uniques -> 3 entrees creees', () async {
      await insertStop(
        adresseBrute: '31 Rue Aristide Briand',
        nomClient: 'GARAGE LANCTIN',
        lat: 48.45,
        lng: 1.24,
      );
      await insertStop(
        adresseBrute: '4 Rue Edouard Branly',
        nomClient: 'GS AUTO',
        lat: 48.46,
        lng: 1.25,
      );
      await insertStop(
        adresseBrute: 'Route du Mans',
        nomClient: 'GUILLERY MOTOCULTURE',
        lat: 48.32,
        lng: 0.93,
      );
      final result = await backfill.backfillFromStops();
      expect(result.totalStops, 3);
      expect(result.created, 3);
      expect(result.merged, 0);
      expect(result.skipped, 0);
      expect(await repo.count(), 3);
    });

    test('stops sans lat/lng -> skipped', () async {
      await insertStop(adresseBrute: 'Adresse sans coords');
      final result = await backfill.backfillFromStops();
      expect(result.totalStops, 0); // exclu de la query (lat null)
      expect(result.created, 0);
      expect(await repo.count(), 0);
    });

    test('stops avec adresse vide -> skipped', () async {
      await insertStop(
        adresseBrute: '',
        nomClient: 'EMPTY ADDR',
        lat: 48.0,
        lng: 1.0,
      );
      final result = await backfill.backfillFromStops();
      expect(result.totalStops, 1);
      expect(result.created, 0);
      expect(result.skipped, 1);
    });

    test('2 stops meme nom client -> 1 cree + 1 merged (dedup nom)',
        () async {
      // Cas reel : Noah livre 2 fois GARAGE LANCTIN dans 2 tournees
      // differentes -> 1 seule entree dans le carnet, useCount = 2.
      await insertStop(
        adresseBrute: '31 Rue Aristide Briand',
        nomClient: 'GARAGE LANCTIN',
        lat: 48.45,
        lng: 1.24,
      );
      await insertStop(
        adresseBrute: '31 RUE ARISTIDE BRIAND', // case different
        nomClient: 'GARAGE LANCTIN',
        lat: 48.45,
        lng: 1.24,
      );
      final result = await backfill.backfillFromStops();
      expect(result.totalStops, 2);
      expect(result.created, 1);
      expect(result.merged, 1);
      expect(await repo.count(), 1);
    });

    test('backfill idempotent : 2eme appel ne cree rien', () async {
      await insertStop(
        adresseBrute: '31 Rue Aristide Briand',
        nomClient: 'GARAGE LANCTIN',
        lat: 48.45,
        lng: 1.24,
      );
      final r1 = await backfill.backfillFromStops();
      expect(r1.created, 1);
      final r2 = await backfill.backfillFromStops();
      expect(r2.created, 0);
      expect(r2.merged, 1);
      expect(await repo.count(), 1);
    });
  });
}
