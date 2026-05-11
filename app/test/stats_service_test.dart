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

  group('StatsService.computeDaily', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee({required DateTime date}) async {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T-${date.toIso8601String()}',
              date: date,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
    }

    Future<void> seedStop({
      required int tourneeId,
      required String statut,
      int nbColis = 1,
    }) async {
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'addr',
              statutLivraison: Value(statut),
              nbColis: Value(nbColis),
            ),
          );
    }

    test('pas de tournees -> liste de N jours avec colis=0', () async {
      final list = await stats.computeDaily(days: 7);
      expect(list.length, 7);
      expect(list.every((s) => s.colis == 0 && s.echecs == 0), isTrue);
    });

    test('triee chronologiquement (le plus ancien en premier)', () async {
      final list = await stats.computeDaily(days: 5);
      for (var i = 0; i < list.length - 1; i++) {
        expect(list[i].day.isBefore(list[i + 1].day), isTrue);
      }
    });

    test('agrege colis livres + echecs par jour de tournee', () async {
      final today = DateTime.now();
      final hier = today.subtract(const Duration(days: 1));

      final tAujd = await seedTournee(date: today);
      await seedStop(tourneeId: tAujd, statut: 'livre', nbColis: 3);
      await seedStop(tourneeId: tAujd, statut: 'livre', nbColis: 2);
      await seedStop(tourneeId: tAujd, statut: 'echec', nbColis: 1);

      final tHier = await seedTournee(date: hier);
      await seedStop(tourneeId: tHier, statut: 'livre', nbColis: 4);

      final list = await stats.computeDaily(days: 7);
      // Le dernier element correspond a aujourd'hui
      final aujd = list.last;
      expect(aujd.colis, 5); // 3 + 2
      expect(aujd.echecs, 1);

      // L'avant-dernier = hier
      final hierStat = list[list.length - 2];
      expect(hierStat.colis, 4);
      expect(hierStat.echecs, 0);
    });

    test('ignore stops a_livrer (pas encore valides)', () async {
      final today = DateTime.now();
      final t = await seedTournee(date: today);
      await seedStop(tourneeId: t, statut: 'a_livrer', nbColis: 10);

      final list = await stats.computeDaily(days: 3);
      expect(list.every((s) => s.colis == 0 && s.echecs == 0), isTrue);
    });

    test('exclut les tournees hors fenetre', () async {
      final today = DateTime.now();
      // 20 jours en arriere : hors fenetre 7j
      final tVieux = await seedTournee(
        date: today.subtract(const Duration(days: 20)),
      );
      await seedStop(tourneeId: tVieux, statut: 'livre', nbColis: 99);

      final list = await stats.computeDaily(days: 7);
      expect(list.every((s) => s.colis == 0), isTrue);
    });
  });
}
