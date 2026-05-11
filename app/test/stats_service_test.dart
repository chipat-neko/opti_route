import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stats_service.dart';

void main() {
  group('StatsService.compute', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee({
      required DateTime date,
      String statut = 'terminee',
      int? distanceM,
      int? dureeS,
    }) async {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T-${date.toIso8601String()}',
              date: date,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
              statut: Value(statut),
              distanceTotaleM: Value(distanceM),
              dureeTotaleS: Value(dureeS),
            ),
          );
    }

    Future<int> seedStop({
      required int tourneeId,
      required String statut,
      int nbColis = 1,
    }) async {
      return db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'addr',
              statutLivraison: Value(statut),
              nbColis: Value(nbColis),
            ),
          );
    }

    test('aucune tournee dans la fenetre -> stats empty', () async {
      // Tournee vieille de 2 ans, on demande les 7 derniers jours.
      await seedTournee(
        date: DateTime.now().subtract(const Duration(days: 730)),
      );
      final s = await stats.compute(
        since: DateTime.now().subtract(const Duration(days: 7)),
      );
      expect(s.nbTournees, 0);
      expect(s.nbColisLivres, 0);
    });

    test('agregations correctes sur 2 tournees recentes', () async {
      final now = DateTime.now();
      final t1 = await seedTournee(
        date: now.subtract(const Duration(days: 2)),
        distanceM: 50000,
        dureeS: 7200,
      );
      final t2 = await seedTournee(
        date: now.subtract(const Duration(days: 5)),
        distanceM: 30000,
        dureeS: 3600,
      );

      // t1 : 3 stops livres (5+2+1=8 colis), 1 echec
      await seedStop(tourneeId: t1, statut: 'livre', nbColis: 5);
      await seedStop(tourneeId: t1, statut: 'livre', nbColis: 2);
      await seedStop(tourneeId: t1, statut: 'livre', nbColis: 1);
      await seedStop(tourneeId: t1, statut: 'echec', nbColis: 3);

      // t2 : 2 stops livres (4+1=5 colis), 0 echec
      await seedStop(tourneeId: t2, statut: 'livre', nbColis: 4);
      await seedStop(tourneeId: t2, statut: 'livre', nbColis: 1);

      final s = await stats.compute(
        since: now.subtract(const Duration(days: 7)),
      );

      expect(s.nbTournees, 2);
      expect(s.nbTourneesTerminees, 2);
      expect(s.nbArrets, 6);
      expect(s.nbLivres, 5);
      expect(s.nbEchecs, 1);
      expect(s.nbColisLivres, 13); // 5+2+1+4+1
      expect(s.distanceMeters, 80000);
      expect(s.durationSeconds, 10800);
      // 5 livres / (5+1) tentatives = 0.833...
      expect(s.tauxReussite, closeTo(5 / 6, 0.001));
    });

    test('exclu les tournees hors fenetre', () async {
      final now = DateTime.now();
      // Une dans la fenetre 7j
      final t1 = await seedTournee(
        date: now.subtract(const Duration(days: 3)),
      );
      await seedStop(tourneeId: t1, statut: 'livre');

      // Une hors fenetre 7j (mais dans 30j)
      final t2 = await seedTournee(
        date: now.subtract(const Duration(days: 15)),
      );
      await seedStop(tourneeId: t2, statut: 'livre');

      final s7 = await stats.compute(
        since: now.subtract(const Duration(days: 7)),
      );
      final s30 = await stats.compute(
        since: now.subtract(const Duration(days: 30)),
      );

      expect(s7.nbTournees, 1);
      expect(s30.nbTournees, 2);
    });

    test('tauxReussite = 0 quand aucune tentative validee', () async {
      final now = DateTime.now();
      final t = await seedTournee(date: now.subtract(const Duration(days: 1)));
      // Que des arrets a livrer (pas encore valides).
      await seedStop(tourneeId: t, statut: 'a_livrer');
      final s = await stats.compute(
        since: now.subtract(const Duration(days: 7)),
      );
      expect(s.tauxReussite, 0);
    });
  });

  group('StatsService.colisParJourDeSemaine', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTourneeAt(DateTime date) async {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: date,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
    }

    Future<void> seedStop({
      required int tourneeId,
      int colis = 1,
      String statut = 'livre',
    }) async {
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'A',
              nbColis: Value(colis),
              statutLivraison: Value(statut),
            ),
          );
    }

    test('aucune tournee : map vide', () async {
      final out = await stats.colisParJourDeSemaine(
        since: DateTime(2026, 5, 1),
      );
      expect(out, isEmpty);
    });

    test('1 tournee lundi avec 3 colis livres : map = {1: 3}', () async {
      // Lundi 11 mai 2026
      final t = await seedTourneeAt(DateTime(2026, 5, 11));
      await seedStop(tourneeId: t, colis: 3);
      final out = await stats.colisParJourDeSemaine(
        since: DateTime(2026, 5, 1),
      );
      expect(out, {1: 3});
    });

    test('colis pas livre (a_livrer) : exclu', () async {
      final t = await seedTourneeAt(DateTime(2026, 5, 12)); // mardi
      await seedStop(tourneeId: t, colis: 2, statut: 'a_livrer');
      await seedStop(tourneeId: t, colis: 5, statut: 'echec');
      await seedStop(tourneeId: t, colis: 1, statut: 'livre');
      final out = await stats.colisParJourDeSemaine(
        since: DateTime(2026, 5, 1),
      );
      expect(out, {2: 1}); // mardi : seulement le 1 colis livre
    });

    test('plusieurs jours : agrege par weekday', () async {
      final lundi = await seedTourneeAt(DateTime(2026, 5, 11));
      final vendredi = await seedTourneeAt(DateTime(2026, 5, 15));
      final autreVendredi = await seedTourneeAt(DateTime(2026, 5, 8));
      await seedStop(tourneeId: lundi, colis: 2);
      await seedStop(tourneeId: vendredi, colis: 4);
      await seedStop(tourneeId: autreVendredi, colis: 3);
      final out = await stats.colisParJourDeSemaine(
        since: DateTime(2026, 5, 1),
      );
      // Lundi=1, Vendredi=5. 2 vendredis cumulent.
      expect(out, {1: 2, 5: 7});
    });
  });

  group('StatsService.distanceTotaleMeters', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee({
      required DateTime date,
      int? distance,
    }) {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: date,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
              distanceTotaleM: Value(distance),
            ),
          );
    }

    test('aucune tournee : 0', () async {
      final d = await stats.distanceTotaleMeters(since: DateTime(2026, 1, 1));
      expect(d, 0);
    });

    test('cumule plusieurs distances', () async {
      await seedTournee(date: DateTime(2026, 5, 1), distance: 10000);
      await seedTournee(date: DateTime(2026, 5, 5), distance: 25000);
      await seedTournee(date: DateTime(2026, 5, 10), distance: 5000);
      final d = await stats.distanceTotaleMeters(
        since: DateTime(2026, 4, 1),
      );
      expect(d, 40000);
    });

    test('tournee sans distance (null) : ignoree dans le cumul', () async {
      await seedTournee(date: DateTime(2026, 5, 1), distance: 10000);
      await seedTournee(date: DateTime(2026, 5, 5)); // null
      final d = await stats.distanceTotaleMeters(
        since: DateTime(2026, 4, 1),
      );
      expect(d, 10000);
    });

    test('respecte la fenetre since', () async {
      await seedTournee(date: DateTime(2026, 3, 1), distance: 10000);
      await seedTournee(date: DateTime(2026, 5, 1), distance: 5000);
      final d = await stats.distanceTotaleMeters(
        since: DateTime(2026, 4, 1),
      );
      expect(d, 5000); // mars exclu
    });
  });

  group('TourneeStats - constante empty', () {
    test('TourneeStats.empty : tout a zero', () {
      const s = TourneeStats.empty;
      expect(s.nbTournees, 0);
      expect(s.nbTourneesTerminees, 0);
      expect(s.nbArrets, 0);
      expect(s.nbColisLivres, 0);
      expect(s.nbLivres, 0);
      expect(s.nbEchecs, 0);
      expect(s.distanceMeters, 0);
      expect(s.durationSeconds, 0);
      expect(s.tauxReussite, 0);
    });
  });
}
