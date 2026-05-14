import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/facturation_service.dart';
import 'package:opti_route/data/parametres_repository.dart';

void main() {
  group('FacturationService.calculer', () {
    late AppDatabase db;
    late ParametresRepository params;
    late FacturationService svc;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      params = ParametresRepository(db);
      svc = FacturationService(db, params);
      // Defaults : 1.85 EUR/L, 7 L/100km (defaut du repo).
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTourneeTerminee({
      String nom = 'T',
      DateTime? date,
      int distanceM = 50000,
    }) async {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: nom,
              date: date ?? DateTime(2026, 5, 13),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: const Value('terminee'),
              distanceTotaleM: Value(distanceM),
            ),
          );
    }

    test('aucune tournee : facture vide', () async {
      final f = await svc.calculer(
        since: DateTime(2026, 5, 1),
        until: DateTime(2026, 6, 1),
      );
      expect(f.isEmpty, isTrue);
      expect(f.nbTournees, 0);
      expect(f.totalHt, 0);
    });

    test('tournee brouillon : exclue (seules les terminees comptent)',
        () async {
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 13),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              // statut defaut = 'brouillon'
            ),
          );
      final f = await svc.calculer(
        since: DateTime(2026, 5, 1),
        until: DateTime(2026, 6, 1),
      );
      expect(f.nbTournees, 0);
    });

    test('1 tournee 50km, 5 arrets livres, 12 colis -> facture nominale',
        () async {
      final tId = await seedTourneeTerminee();
      for (var i = 0; i < 5; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tId,
                adresseBrute: 'a-$i',
                statutLivraison: const Value('livre'),
                nbColis: const Value(2),
              ),
            );
      }
      // 5 stops, 10 colis. On ajoute un 6e livre avec 2 colis -> 12 total
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'a-bonus',
              statutLivraison: const Value('livre'),
              nbColis: const Value(2),
            ),
          );

      final f = await svc.calculer(
        since: DateTime(2026, 5, 1),
        until: DateTime(2026, 6, 1),
        tarifParArretEur: 1.5,
        tarifParColisEur: 0.3,
        tarifKilometriqueEur: 0.8,
      );
      expect(f.nbTournees, 1);
      expect(f.nbArretsLivres, 6);
      expect(f.nbColisLivres, 12);
      expect(f.kmTotal, 50);
      // mtArrets = 6 * 1.5 = 9 EUR
      // mtColis = 12 * 0.3 = 3.6 EUR
      // mtKm = 50 * 0.8 = 40 EUR
      // total = 52.6 EUR
      expect(f.mtArrets, closeTo(9.0, 0.01));
      expect(f.mtColis, closeTo(3.6, 0.01));
      expect(f.mtKm, closeTo(40.0, 0.01));
      expect(f.totalHt, closeTo(52.6, 0.01));

      // Cout carburant : 50 km * 7 L/100 = 3.5 L * 1.85 EUR = 6.475
      expect(f.coutCarburantEur, closeTo(6.475, 0.01));
      // Marge brute = 52.6 - 6.475 = 46.125
      expect(f.margeBruteEstimee, closeTo(46.125, 0.01));
    });

    test('filtre coequipier : exclut les stops d autres', () async {
      final tId = await seedTourneeTerminee();
      // Stop pour Moi (null), stop pour Lucas (id 1)
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'moi',
              statutLivraison: const Value('livre'),
              nbColis: const Value(3),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'lucas',
              statutLivraison: const Value('livre'),
              nbColis: const Value(5),
              coequipierId: const Value(1),
            ),
          );

      // Filtre sur coequipier 1
      final f = await svc.calculer(
        since: DateTime(2026, 5, 1),
        until: DateTime(2026, 6, 1),
        coequipierIdFilter: 1,
        tarifParColisEur: 1.0,
      );
      expect(f.nbColisLivres, 5);
      expect(f.mtColis, closeTo(5.0, 0.01));
    });

    test('hors fenetre : tournee de la veille ne compte pas', () async {
      await seedTourneeTerminee(date: DateTime(2026, 4, 30));
      final f = await svc.calculer(
        since: DateTime(2026, 5, 1),
        until: DateTime(2026, 6, 1),
      );
      expect(f.nbTournees, 0);
    });

    test('tarifs nuls : totalHt = 0 mais cout carburant calcule',
        () async {
      final tId = await seedTourneeTerminee(distanceM: 100000); // 100 km
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'a',
              statutLivraison: const Value('livre'),
            ),
          );
      // Aucun tarif fourni
      final f = await svc.calculer(
        since: DateTime(2026, 5, 1),
        until: DateTime(2026, 6, 1),
      );
      expect(f.totalHt, 0);
      // 100 km * 7L/100 * 1.85 EUR = 12.95 EUR
      expect(f.coutCarburantEur, closeTo(12.95, 0.01));
      // Marge negative car total facturable = 0
      expect(f.margeBruteEstimee, closeTo(-12.95, 0.01));
    });

    test('isEmpty getter', () {
      final empty = FactureMensuelle.empty(
        since: DateTime(2026, 5, 1),
        until: DateTime(2026, 6, 1),
      );
      expect(empty.isEmpty, isTrue);
      expect(empty.totalHt, 0);
    });
  });
}
