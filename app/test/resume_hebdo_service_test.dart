import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/resume_hebdo_service.dart';

import 'helpers/test_db.dart';

/// Tests du ResumeHebdoService (carte Trello #101).
void main() {
  group('ResumeHebdoService.weekStart', () {
    test('lundi reste lundi 00:00', () {
      final lundi = DateTime(2026, 5, 25, 14, 30); // un lundi
      final r = ResumeHebdoService.weekStart(lundi);
      expect(r, DateTime(2026, 5, 25));
    });

    test('dimanche -> lundi precedent', () {
      final dimanche = DateTime(2026, 5, 31, 22); // un dimanche
      final r = ResumeHebdoService.weekStart(dimanche);
      expect(r, DateTime(2026, 5, 25), reason: 'lundi de la meme semaine');
    });

    test('mercredi -> lundi precedent', () {
      final mercredi = DateTime(2026, 5, 27, 9);
      final r = ResumeHebdoService.weekStart(mercredi);
      expect(r, DateTime(2026, 5, 25));
    });

    test('tronque l\'heure a 00:00', () {
      final r = ResumeHebdoService.weekStart(
        DateTime(2026, 5, 25, 23, 59, 58),
      );
      expect(r.hour, 0);
      expect(r.minute, 0);
      expect(r.second, 0);
    });
  });

  group('ResumeHebdoService.computeWeek', () {
    late AppDatabase db;
    late ResumeHebdoService svc;

    setUp(() {
      db = makeTestDb();
      // Horloge figee (F8a) : ces tests passent tous une `reference`
      // explicite, mais on coupe quand meme le service de l'horloge
      // systeme pour qu'aucun ajout futur ne redevienne dependant du
      // jour de run.
      svc = ResumeHebdoService(db, now: () => DateTime(2026, 5, 27, 9));
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTournee({
      required DateTime date,
      String nom = 'T',
      String statut = 'terminee',
      int? distanceM,
      int? dureeS,
    }) async {
      return db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: nom,
              date: date,
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'D',
              statut: Value(statut),
              distanceTotaleM: Value(distanceM),
              dureeTotaleS: Value(dureeS),
            ),
          );
    }

    Future<void> seedStop({
      required int tourneeId,
      String statut = 'livre',
      String? nomClient,
      int nbColis = 1,
      int? coequipierId,
      String? preuvePhotoPath,
    }) async {
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'A',
              statutLivraison: Value(statut),
              nbColis: Value(nbColis),
              nomClient: Value(nomClient),
              coequipierId: Value(coequipierId),
              preuvePhotoPath: Value(preuvePhotoPath),
            ),
          );
    }

    test('semaine vide -> isEmpty', () async {
      final r = await svc.computeWeek(reference: DateTime(2026, 5, 26));
      expect(r.isEmpty, isTrue);
      expect(r.nbTournees, 0);
      expect(r.tauxReussite, 0);
      expect(r.topClients(), isEmpty);
      expect(r.coequipierLePlusActif(), isNull);
      expect(r.alertes(), isEmpty);
    });

    test('agregation simple : 2 tournees, 5 livres, 1 echec', () async {
      // Semaine du 2026-05-25 (lundi) au 2026-05-31 (dimanche).
      final t1 = await seedTournee(
        date: DateTime(2026, 5, 26),
        nom: 'Mardi',
        distanceM: 30000,
        dureeS: 3600,
      );
      final t2 = await seedTournee(
        date: DateTime(2026, 5, 28),
        nom: 'Jeudi',
        distanceM: 20000,
        dureeS: 1800,
      );
      await seedStop(tourneeId: t1, nomClient: 'Garage Aguilar', nbColis: 3);
      await seedStop(tourneeId: t1, nomClient: 'Garage Aguilar');
      await seedStop(tourneeId: t1, statut: 'echec', nomClient: 'Cafe Bleu');
      await seedStop(tourneeId: t2, nomClient: 'Amazon Auneau', nbColis: 5);
      await seedStop(tourneeId: t2, nomClient: 'Amazon Auneau', nbColis: 2);
      await seedStop(tourneeId: t2, nomClient: 'Garage Aguilar');

      final r = await svc.computeWeek(reference: DateTime(2026, 5, 27));
      expect(r.nbTournees, 2);
      expect(r.nbTourneesTerminees, 2);
      expect(r.nbStops, 6);
      expect(r.nbLivres, 5);
      expect(r.nbEchecs, 1);
      expect(r.nbColisLivres, 3 + 1 + 5 + 2 + 1);
      expect(r.distanceMeters, 50000);
      expect(r.durationSeconds, 5400);
      expect(r.tauxReussite, closeTo(5 / 6, 0.001));

      final top = r.topClients();
      expect(top.first.nomClient, 'Garage Aguilar');
      expect(top.first.nbLivraisons, 3,
          reason: 'Garage : 2x t1 + 1x t2');
      expect(top[1].nomClient, 'Amazon Auneau');
      expect(top[1].nbLivraisons, 2);
      // Cafe Bleu : seul echec, exclu du top
      expect(top.length, 2);
    });

    test('exclut tournees hors semaine (avant et apres)', () async {
      // Semaine ref : lundi 2026-05-25 -> dimanche 2026-05-31
      // Tournee dimanche precedent (24/05) : exclue
      final tAvant = await seedTournee(date: DateTime(2026, 5, 24));
      await seedStop(tourneeId: tAvant);
      // Tournee mardi 26/05 : incluse
      final tDedans = await seedTournee(date: DateTime(2026, 5, 26));
      await seedStop(tourneeId: tDedans);
      // Tournee lundi suivant 01/06 : exclue
      final tApres = await seedTournee(date: DateTime(2026, 6, 1));
      await seedStop(tourneeId: tApres);

      final r = await svc.computeWeek(reference: DateTime(2026, 5, 26));
      expect(r.nbTournees, 1, reason: 'seule la tournee du mardi compte');
      expect(r.nbStops, 1);
    });

    test('coequipierLePlusActif null si solo (que Noah)', () async {
      final t = await seedTournee(date: DateTime(2026, 5, 26));
      await seedStop(tourneeId: t);
      await seedStop(tourneeId: t);
      final r = await svc.computeWeek(reference: DateTime(2026, 5, 26));
      expect(r.coequipierLePlusActif(), isNull);
    });

    test('coequipierLePlusActif renvoie le plus livre', () async {
      final t = await seedTournee(date: DateTime(2026, 5, 26));
      // Moi : 1 livre
      await seedStop(tourneeId: t);
      // Lucas (id 1) : 3 livres
      for (var i = 0; i < 3; i++) {
        await seedStop(tourneeId: t, coequipierId: 1);
      }
      // Marc (id 2) : 2 livres
      for (var i = 0; i < 2; i++) {
        await seedStop(tourneeId: t, coequipierId: 2);
      }
      final r = await svc.computeWeek(reference: DateTime(2026, 5, 26));
      final top = r.coequipierLePlusActif();
      expect(top, isNotNull);
      expect(top!.coequipierId, 1);
      expect(top.nbLivres, 3);
    });

    test('alertes : taux reussite < 70%', () async {
      final t = await seedTournee(date: DateTime(2026, 5, 26));
      // 1 livre, 2 echecs : taux 33%
      await seedStop(tourneeId: t);
      await seedStop(tourneeId: t, statut: 'echec');
      await seedStop(tourneeId: t, statut: 'echec');
      final r = await svc.computeWeek(reference: DateTime(2026, 5, 26));
      expect(r.alertes(), isNotEmpty);
      expect(
        r.alertes().any((a) => a.toLowerCase().contains('reussite')),
        isTrue,
      );
    });

    test('alertes : 5+ echecs dans une seule tournee', () async {
      final t = await seedTournee(date: DateTime(2026, 5, 26), nom: 'Catastrophe');
      // 10 livres + 5 echecs -> taux 66% (declenche aussi alerte taux)
      // mais on doit AUSSI avoir l'alerte tournee
      for (var i = 0; i < 10; i++) {
        await seedStop(tourneeId: t);
      }
      for (var i = 0; i < 5; i++) {
        await seedStop(tourneeId: t, statut: 'echec');
      }
      final r = await svc.computeWeek(reference: DateTime(2026, 5, 26));
      final alertesT = r.alertes().where((a) => a.contains('Catastrophe'));
      expect(alertesT, isNotEmpty);
    });

    test('variation vs semaine precedente', () async {
      // Semaine precedente (lundi 2026-05-18) : 2 livres
      final tPrev = await seedTournee(date: DateTime(2026, 5, 19));
      await seedStop(tourneeId: tPrev);
      await seedStop(tourneeId: tPrev);
      // Semaine courante : 4 livres -> +100%
      final tCur = await seedTournee(date: DateTime(2026, 5, 26));
      for (var i = 0; i < 4; i++) {
        await seedStop(tourneeId: tCur);
      }
      final r = await svc.computeWeek(reference: DateTime(2026, 5, 26));
      expect(r.variationVsPrev('nb_livres'), closeTo(1.0, 0.001));
      expect(r.previousValue('nb_livres'), 2);
    });

    test('variation null si semaine precedente nulle', () async {
      final t = await seedTournee(date: DateTime(2026, 5, 26));
      await seedStop(tourneeId: t);
      final r = await svc.computeWeek(reference: DateTime(2026, 5, 26));
      // Pas de semaine precedente seedee
      expect(r.variationVsPrev('nb_livres'), isNull);
      expect(r.previousValue('nb_livres'), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────────
  // F8a — `computeWeek()` SANS reference : c'est le seul chemin qui
  // lisait l'horloge. Avant l'injection, ces cas n'etaient pas
  // testables : le resultat dependait du jour (et de l'heure) ou
  // tournait la suite -- un run le dimanche a 23h59 ne resumait pas la
  // meme semaine qu'une minute plus tard.
  // ────────────────────────────────────────────────────────────────
  group('ResumeHebdoService.computeWeek - horloge injectee (F8a)', () {
    late AppDatabase db;

    setUp(() {
      db = makeTestDb();
    });

    tearDown(() async {
      await db.close();
    });

    /// Service cale sur une horloge figee a [fixed].
    ResumeHebdoService svcAt(DateTime fixed) =>
        ResumeHebdoService(db, now: () => fixed);

    /// Un arret livre sur la tournee [tourneeId].
    Future<void> seedLivre(int tourneeId) async {
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tourneeId,
              adresseBrute: 'A',
              statutLivraison: const Value('livre'),
            ),
          );
    }

    test('sans reference : cale sur la semaine de l horloge injectee',
        () async {
      // Mardi 26 mai 2026, 09h00 -> semaine du lundi 25/05.
      final r = await svcAt(DateTime(2026, 5, 26, 9)).computeWeek();
      expect(r.semaineDebut, DateTime(2026, 5, 25));
      expect(r.semaineFin, DateTime(2026, 5, 31, 23, 59, 59));
    });

    test('dimanche 23h59 et lundi 00h00 : deux semaines distinctes',
        () async {
      // Une seule tournee, le dimanche 31/05.
      final tId = await seedTournee(db, date: DateTime(2026, 5, 31));
      await seedLivre(tId);

      final avantMinuit =
          await svcAt(DateTime(2026, 5, 31, 23, 59, 59)).computeWeek();
      expect(avantMinuit.semaineDebut, DateTime(2026, 5, 25));
      expect(avantMinuit.nbTournees, 1);
      expect(avantMinuit.nbLivres, 1);

      // Une minute plus tard, on a bascule de semaine : la semaine
      // courante est vide et la tournee du dimanche est comptee dans
      // la semaine PRECEDENTE.
      final apresMinuit = await svcAt(DateTime(2026, 6, 1)).computeWeek();
      expect(apresMinuit.semaineDebut, DateTime(2026, 6, 1));
      expect(apresMinuit.isEmpty, isTrue);
      expect(apresMinuit.previousValue('nb_livres'), 1);
      expect(apresMinuit.variationVsPrev('nb_livres'), closeTo(-1.0, 0.001));
    });

    test('semaine a cheval sur deux mois (29 juin -> 5 juillet)', () async {
      // Le lundi 29/06/2026 et le mercredi 01/07/2026 sont dans la
      // MEME semaine : le calage lundi ne doit pas se faire couper par
      // la fin de mois.
      final tJuin = await seedTournee(db, date: DateTime(2026, 6, 30));
      await seedLivre(tJuin);
      final tJuillet = await seedTournee(db, date: DateTime(2026, 7, 1));
      await seedLivre(tJuillet);

      final r = await svcAt(DateTime(2026, 7, 1, 8)).computeWeek();
      expect(r.semaineDebut, DateTime(2026, 6, 29));
      expect(r.semaineFin, DateTime(2026, 7, 5, 23, 59, 59));
      expect(r.nbTournees, 2);
      expect(r.nbLivres, 2);
    });
  });
}
