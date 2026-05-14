import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stats_service.dart';

void main() {
  group('StatsService.computeBundle + computeFromBundle', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('bundle vide si pas de tournee dans la fenetre', () async {
      final b = await stats.computeBundle(since: DateTime(2030, 1, 1));
      expect(b.isEmpty, isTrue);
      expect(b.tournees, isEmpty);
      expect(b.stops, isEmpty);
    });

    test('computeFromBundle filtre in-memory sur sous-fenetre', () async {
      // 3 tournees : J-1, J-10, J-100. Bundle sur 365j.
      final now = DateTime.now();
      Future<int> seed(int daysAgo, int colis) async {
        final tId = await db.into(db.tournees).insert(
              TourneesCompanion.insert(
                nom: 'T-$daysAgo',
                date: now.subtract(Duration(days: daysAgo)),
                pointDepartLat: 48.0,
                pointDepartLng: 1.0,
                pointDepartLabel: 'D',
                statut: const Value('terminee'),
              ),
            );
        final sId = await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tId,
                adresseBrute: 'A',
                nbColis: Value(colis),
              ),
            );
        await db.update(db.stops).replace(
              (await (db.select(db.stops)
                        ..where((s) => s.id.equals(sId)))
                      .getSingle())
                  .copyWith(statutLivraison: 'livre'),
            );
        return tId;
      }

      await seed(1, 3);
      await seed(10, 2);
      await seed(100, 5);

      final bundle = await stats.computeBundle(
        since: now.subtract(const Duration(days: 365)),
      );
      expect(bundle.tournees, hasLength(3));
      expect(bundle.stops, hasLength(3));

      // Fenetre 7j : seule la tournee J-1 compte.
      final stats7 = StatsService.computeFromBundle(
        bundle,
        since: now.subtract(const Duration(days: 7)),
      );
      expect(stats7.nbTournees, 1);
      expect(stats7.nbColisLivres, 3);

      // Fenetre 30j : J-1 + J-10.
      final stats30 = StatsService.computeFromBundle(
        bundle,
        since: now.subtract(const Duration(days: 30)),
      );
      expect(stats30.nbTournees, 2);
      expect(stats30.nbColisLivres, 5); // 3+2

      // Fenetre 365j : les 3.
      final stats365 = StatsService.computeFromBundle(
        bundle,
        since: now.subtract(const Duration(days: 365)),
      );
      expect(stats365.nbTournees, 3);
      expect(stats365.nbColisLivres, 10); // 3+2+5
    });
  });

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

  group('StatsService.heuresParJourDeSemaine', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('aucune tournee : map vide', () async {
      final h = await stats.heuresParJourDeSemaine(
        since: DateTime(2026, 1, 1),
      );
      expect(h, isEmpty);
    });

    test('1 tournee 2h mardi : map {2: 2.0}', () async {
      // 2 mai 2026 = samedi (verifions)
      final mardi = DateTime(2026, 5, 12); // C'est un mardi
      expect(mardi.weekday, 2);
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: mardi,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              dureeTotaleS: const Value(7200), // 2h
            ),
          );
      final h = await stats.heuresParJourDeSemaine(
        since: DateTime(2026, 1, 1),
      );
      expect(h[2], 2.0);
    });

    test('pauseeSeconds soustrait du total', () async {
      // 1h totale, 30 min de pause -> 30 min effectif = 0.5h
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              dureeTotaleS: const Value(3600),
              pauseeSeconds: const Value(1800),
            ),
          );
      final h = await stats.heuresParJourDeSemaine(
        since: DateTime(2026, 1, 1),
      );
      expect(h[2], closeTo(0.5, 0.01));
    });
  });

  group('StatsService.exportCsvTournees', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('vide : juste le header', () async {
      final csv = await stats.exportCsvTournees(since: DateTime(2026, 1, 1));
      final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, 1);
      expect(lines.first, startsWith('date,nom,statut,'));
    });

    test('1 tournee : header + 1 ligne', () async {
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Mardi matin',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              distanceTotaleM: const Value(45000),
              dureeTotaleS: const Value(5400),
            ),
          );
      final csv = await stats.exportCsvTournees(since: DateTime(2026, 1, 1));
      final lines = csv.split('\n').where((l) => l.isNotEmpty).toList();
      expect(lines.length, 2);
      expect(lines[1], contains('Mardi matin'));
      expect(lines[1], contains('45.0')); // km
      expect(lines[1], contains('90')); // 5400s / 60 = 90 min
    });

    test('echappement des virgules dans le nom', () async {
      await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T, special',
              date: DateTime(2026, 5, 12),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
      final csv = await stats.exportCsvTournees(since: DateTime(2026, 1, 1));
      expect(csv, contains('"T, special"'));
    });
  });

  group('StatsService.statsParCoequipier', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee() async {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime.now(),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
    }

    test('aucune tournee : map vide', () async {
      final r = await stats.statsParCoequipier(
        since: DateTime(2026, 1, 1),
      );
      expect(r, isEmpty);
    });

    test('stops sans coequipierId : cle null = Moi', () async {
      final tId = await seedTournee();
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A',
              statutLivraison: const Value('livre'),
              nbColis: const Value(3),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'B',
              statutLivraison: const Value('echec'),
            ),
          );
      final r = await stats.statsParCoequipier(
        since: DateTime(2020, 1, 1),
      );
      expect(r.keys.toList(), [null]);
      final moi = r[null]!;
      expect(moi.nbArrets, 2);
      expect(moi.nbLivres, 1);
      expect(moi.nbEchecs, 1);
      expect(moi.colisLivres, 3);
      expect(moi.tauxReussite, closeTo(0.5, 0.001));
    });

    test('breakdown Moi + 2 coequipiers', () async {
      final tId = await seedTournee();
      // Moi : 2 livres
      for (var i = 0; i < 2; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tId,
                adresseBrute: 'moi-$i',
                statutLivraison: const Value('livre'),
                nbColis: const Value(1),
              ),
            );
      }
      // Lucas (id 1) : 3 livres + 1 echec
      for (var i = 0; i < 3; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tId,
                adresseBrute: 'lucas-$i',
                statutLivraison: const Value('livre'),
                nbColis: const Value(2),
                coequipierId: const Value(1),
              ),
            );
      }
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'lucas-echec',
              statutLivraison: const Value('echec'),
              coequipierId: const Value(1),
            ),
          );
      // Papa (id 2) : 1 livre
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'papa-1',
              statutLivraison: const Value('livre'),
              coequipierId: const Value(2),
            ),
          );

      final r = await stats.statsParCoequipier(
        since: DateTime(2020, 1, 1),
      );
      expect(r.keys.toSet(), {null, 1, 2});
      expect(r[null]!.nbLivres, 2);
      expect(r[1]!.nbLivres, 3);
      expect(r[1]!.nbEchecs, 1);
      expect(r[1]!.colisLivres, 6);
      expect(r[1]!.tauxReussite, closeTo(0.75, 0.001));
      expect(r[2]!.nbLivres, 1);
    });

    test('CoequipierStats.tauxReussite : 0 si aucune tentative', () {
      const s = CoequipierStats(
        coequipierId: 1,
        nbArrets: 1,
        nbLivres: 0,
        nbEchecs: 0,
        colisLivres: 0,
      );
      expect(s.tauxReussite, 0);
    });

    test('CoequipierStats.tauxReussite : 100% livres', () {
      const s = CoequipierStats(
        coequipierId: null,
        nbArrets: 5,
        nbLivres: 5,
        nbEchecs: 0,
        colisLivres: 12,
      );
      expect(s.tauxReussite, 1.0);
    });
  });

  group('StatsService.compteursMotivants', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('aucune tournee : MotivationStats.empty', () async {
      final m = await stats.compteursMotivants();
      expect(m.colisLivresAnnee, 0);
      expect(m.kmAnnee, 0);
      expect(m.streakSansEchec, 0);
    });

    test('1 tournee terminee 100% : streak = 1', () async {
      final now = DateTime.now();
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(now.year, now.month, now.day),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: const Value('terminee'),
              distanceTotaleM: const Value(25000),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: 'A',
              statutLivraison: const Value('livre'),
              nbColis: const Value(3),
            ),
          );
      final m = await stats.compteursMotivants();
      expect(m.streakSansEchec, 1);
      expect(m.colisLivresAnnee, 3);
      expect(m.kmAnnee, 25.0);
      expect(m.tourneesAnnee, 1);
    });

    test('tournee avec un echec : streak = 0', () async {
      final now = DateTime.now();
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(now.year, now.month, now.day),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: const Value('terminee'),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: 'A',
              statutLivraison: const Value('echec'),
            ),
          );
      final m = await stats.compteursMotivants();
      expect(m.streakSansEchec, 0);
    });

    test('MotivationStats.empty est const', () {
      const m = MotivationStats.empty;
      expect(m.colisLivresAnnee, 0);
      expect(m.streakSansEchec, 0);
      expect(m.nbLivresAnnee, 0);
      expect(m.nbEchecsAnnee, 0);
      expect(m.tauxReussiteAnnee, 0);
    });

    test('MotivationStats.tauxReussiteAnnee : 95% emerald threshold', () {
      const m = MotivationStats(
        colisLivresAnnee: 100,
        kmAnnee: 1000,
        tourneesAnnee: 20,
        streakSansEchec: 3,
        nbLivresAnnee: 95,
        nbEchecsAnnee: 5,
      );
      expect(m.tauxReussiteAnnee, closeTo(0.95, 0.001));
    });

    test('MotivationStats.tauxReussiteAnnee : 0 si aucune tentative',
        () {
      const m = MotivationStats(
        colisLivresAnnee: 0,
        kmAnnee: 0,
        tourneesAnnee: 5,
        streakSansEchec: 0,
        nbLivresAnnee: 0,
        nbEchecsAnnee: 0,
      );
      expect(m.tauxReussiteAnnee, 0);
    });

    test('compteursMotivants populate nbLivresAnnee + nbEchecsAnnee',
        () async {
      final now = DateTime.now();
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(now.year, now.month, now.day),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: const Value('terminee'),
            ),
          );
      // 4 livres + 1 echec -> 80% taux
      for (var i = 0; i < 4; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: id,
                adresseBrute: 'livre-$i',
                statutLivraison: const Value('livre'),
                nbColis: const Value(2),
              ),
            );
      }
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: id,
              adresseBrute: 'echec-1',
              statutLivraison: const Value('echec'),
            ),
          );
      final m = await stats.compteursMotivants();
      expect(m.nbLivresAnnee, 4);
      expect(m.nbEchecsAnnee, 1);
      expect(m.colisLivresAnnee, 8); // 4 * 2 colis
      expect(m.tauxReussiteAnnee, closeTo(0.80, 0.001));
    });
  });

  group('StatsService.topRaisonsEchecGlobales', () {
    late AppDatabase db;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee() async {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime.now(),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
            ),
          );
    }

    test('aucune tournee : liste vide', () async {
      final r = await stats.topRaisonsEchecGlobales(
        since: DateTime(2020, 1, 1),
      );
      expect(r, isEmpty);
    });

    test('seulement livres : liste vide (pas d echec a compter)',
        () async {
      final tId = await seedTournee();
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A',
              statutLivraison: const Value('livre'),
            ),
          );
      final r = await stats.topRaisonsEchecGlobales(
        since: DateTime(2020, 1, 1),
      );
      expect(r, isEmpty);
    });

    test('tri par frequence desc + limit applique', () async {
      final tId = await seedTournee();
      // 3 absent + 2 refuse + 1 autre + 1 adresse_fausse
      for (var i = 0; i < 3; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tId,
                adresseBrute: 'absent-$i',
                statutLivraison: const Value('echec'),
                raisonEchec: const Value('absent'),
              ),
            );
      }
      for (var i = 0; i < 2; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tId,
                adresseBrute: 'refuse-$i',
                statutLivraison: const Value('echec'),
                raisonEchec: const Value('refuse'),
              ),
            );
      }
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'autre',
              statutLivraison: const Value('echec'),
              raisonEchec: const Value('autre'),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'fausse',
              statutLivraison: const Value('echec'),
              raisonEchec: const Value('adresse_fausse'),
            ),
          );

      final r = await stats.topRaisonsEchecGlobales(
        since: DateTime(2020, 1, 1),
      );
      expect(r.length, 4);
      expect(r[0].raison, 'absent');
      expect(r[0].n, 3);
      expect(r[1].raison, 'refuse');
      expect(r[1].n, 2);
    });

    test('limit limite a N premiers', () async {
      final tId = await seedTournee();
      for (var i = 0; i < 3; i++) {
        await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tId,
                adresseBrute: 'a-$i',
                statutLivraison: const Value('echec'),
                raisonEchec: Value('r$i'),
              ),
            );
      }
      final r = await stats.topRaisonsEchecGlobales(
        since: DateTime(2020, 1, 1),
        limit: 2,
      );
      expect(r.length, 2);
    });

    test('echec sans raison renseignee : exclu du compte', () async {
      final tId = await seedTournee();
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A',
              statutLivraison: const Value('echec'),
              // raisonEchec laisse null
            ),
          );
      final r = await stats.topRaisonsEchecGlobales(
        since: DateTime(2020, 1, 1),
      );
      expect(r, isEmpty);
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
