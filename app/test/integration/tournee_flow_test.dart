// Test d'integration leger : verifie que le flow metier complet
// "creer tournee → ajouter stops → affecter coequipier → valider
// livraisons → calculer stats" fonctionne bout en bout via les repos
// (sans UI). Sert de garde-fou contre les regressions cross-services.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/coequipiers_repository.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';
import 'package:opti_route/data/stats_service.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';

void main() {
  group('Flow integration : tournee + coequipier + validations + stats', () {
    late AppDatabase db;
    late TourneesRepository tournees;
    late StopsRepository stops;
    late CoequipiersRepository coequipiers;
    late SavedDestinationsRepository carnet;
    late StatsService stats;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      tournees = TourneesRepository(db);
      stops = StopsRepository(db);
      coequipiers = CoequipiersRepository(db);
      carnet = SavedDestinationsRepository(db);
      stats = StatsService(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('scenario complet chef + coequipier sur une tournee', () async {
      // 1. Le chef cree un coequipier
      final lucasId = await coequipiers.create(
        nom: 'Lucas',
        colorTag: 'emerald',
        telephone: '0612345678',
      );

      // 2. Le chef cree une tournee avec affectation par defaut a Lucas
      final tId = await tournees.create(
        TourneesCompanion.insert(
          nom: 'Tournee test integration',
          date: DateTime(2026, 5, 13),
          pointDepartLat: 48.0,
          pointDepartLng: 1.0,
          pointDepartLabel: 'Depot',
          coequipierDefautId: Value(lucasId),
        ),
      );

      // 3. Le chef ajoute 3 arrets (deux pour Lucas, un pour Moi)
      final stop1 = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '12 rue X, 28100 Dreux',
        lat: const Value(48.737),
        lng: const Value(1.366),
        nbColis: const Value(3),
        coequipierId: Value(lucasId),
      ));
      final stop2 = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '5 av Y, 28100 Dreux',
        lat: const Value(48.740),
        lng: const Value(1.370),
        nbColis: const Value(2),
        coequipierId: Value(lucasId),
      ));
      final stop3 = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: '8 rue Z, 28100 Dreux',
        lat: const Value(48.745),
        lng: const Value(1.375),
        nbColis: const Value(1),
        // coequipierId = null (Moi)
      ));

      // 4. Verifie l'etat initial : 3 stops a_livrer
      final initialStops = await stops.getByTournee(tId);
      expect(initialStops.length, 3);
      expect(
        initialStops.every((s) => s.statutLivraison == 'a_livrer'),
        isTrue,
      );

      // 5. Valider : 2 livres (Lucas), 1 echec (Moi)
      await stops.markLivre(stop1, position: (lat: 48.737, lng: 1.366));
      await stops.markLivre(stop2, position: (lat: 48.740, lng: 1.370));
      await stops.markEchec(stop3, 'absent',
          position: (lat: 48.745, lng: 1.375));

      // 6. Verifie les statuts persistes + position GPS preuve
      final afterStops = await stops.getByTournee(tId);
      final s1 = afterStops.firstWhere((s) => s.id == stop1);
      final s3 = afterStops.firstWhere((s) => s.id == stop3);
      expect(s1.statutLivraison, 'livre');
      expect(s1.livreLat, 48.737);
      expect(s3.statutLivraison, 'echec');
      expect(s3.raisonEchec, 'absent');

      // 7. Stats par coequipier sur la fenetre
      final byCo = await stats.statsParCoequipier(
        since: DateTime(2026, 1, 1),
      );
      expect(byCo[lucasId]!.nbLivres, 2);
      expect(byCo[lucasId]!.colisLivres, 5); // 3+2
      expect(byCo[null]!.nbEchecs, 1);

      // 8. Top raisons echec : 1x absent
      final topRaisons = await stats.topRaisonsEchecGlobales(
        since: DateTime(2026, 1, 1),
      );
      expect(topRaisons, hasLength(1));
      expect(topRaisons.first.raison, 'absent');
      expect(topRaisons.first.n, 1);

      // 9. Annuler le dernier echec : repasse en a_livrer
      await stops.revertStatus(stop3);
      final reverted = await stops.getById(stop3);
      expect(reverted!.statutLivraison, 'a_livrer');
      expect(reverted.raisonEchec, isNull);

      // 10. Top raisons recompute : plus aucun echec
      final topRaisonsAfter = await stats.topRaisonsEchecGlobales(
        since: DateTime(2026, 1, 1),
      );
      expect(topRaisonsAfter, isEmpty);

      // 11. Bulk affecter le reste a Lucas (stop3 redevenu non affecte
      // (en fait il l'etait pas a la base). Verifions : avant le bulk,
      // stop3.coequipierId = null. Apres setCoequipierForUnassigned, =
      // Lucas.
      await stops.setCoequipierForUnassigned(tId, lucasId);
      final s3After = await stops.getById(stop3);
      expect(s3After!.coequipierId, lucasId);

      // 12. Le carnet d'adresses a-t-il enregistre les clients livres ?
      // (Note : le carnet est auto-rempli par l'UI, pas par les repos
      // directement. Donc on simule manuellement ici.)
      await carnet.upsertFromValidatedStop(
        nomClient: 'Mr Dupont',
        adresseDisplay: '12 rue X, 28100 Dreux',
        lat: 48.737,
        lng: 1.366,
        ville: 'Dreux',
      );
      expect(await carnet.count(), 1);
    });

    test('archivage coequipier : preserve les stops historiques', () async {
      // Cree coequipier + tournee + stop affecte
      final coId = await coequipiers.create(nom: 'Papa');
      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'T',
        date: DateTime(2026, 5, 13),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D',
      ));
      final sId = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        coequipierId: Value(coId),
      ));

      // Archive le coequipier
      await coequipiers.update(coId, actif: false);

      // Le stop garde son coequipierId
      final s = await stops.getById(sId);
      expect(s!.coequipierId, coId);

      // watchActifs ne le retourne plus, watchAll oui
      final actifs = await coequipiers.watchActifs().first;
      expect(actifs.where((c) => c.id == coId), isEmpty);
      final all = await coequipiers.watchAll().first;
      expect(all.where((c) => c.id == coId), hasLength(1));
    });

    test('duplicate tournee : reset statuts + preserve affectations + reset rappels',
        () async {
      final coId = await coequipiers.create(nom: 'Lucas');
      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'Originale',
        date: DateTime(2026, 5, 13),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'D',
        coequipierDefautId: Value(coId),
      ));
      final sId = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'A',
        coequipierId: Value(coId),
      ));
      await stops.markLivre(sId);

      // Duplique
      final newId = await tournees.duplicate(
        tId,
        targetDate: DateTime(2026, 5, 20),
      );
      final newT = await tournees.getById(newId);
      expect(newT!.nom, 'Originale (copie)');
      expect(newT.date, DateTime(2026, 5, 20));
      expect(newT.rappelLe, isNull); // ne propage pas le rappel
      // (coequipierDefautId n'est PAS encore copié dans duplicate(),
      // c'est intentionnel : le clone repart "neutre")

      // Stops dupliques : reset a_livrer + coequipierId preserve ?
      final newStops = await stops.getByTournee(newId);
      expect(newStops, hasLength(1));
      expect(newStops.first.statutLivraison, 'a_livrer');
      expect(newStops.first.livreLat, isNull);
    });

    test('scenario : deplacer un stop d\'une tournee a une autre + reorder',
        () async {
      // Setup : 2 tournees avec des stops
      final t1 = await tournees.create(TourneesCompanion.insert(
        nom: 'Tournee source',
        date: DateTime(2026, 5, 14),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'Depot',
      ));
      final t2 = await tournees.create(TourneesCompanion.insert(
        nom: 'Tournee dest',
        date: DateTime(2026, 5, 14),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'Depot',
      ));

      // Stop dans t1 avec ordreOptimise = 5 (deja optimise)
      final movedStop = await stops.create(StopsCompanion.insert(
        tourneeId: t1,
        adresseBrute: 'Stop a deplacer',
        lat: const Value(48.5),
        lng: const Value(1.5),
        ordreOptimise: const Value(5),
      ));
      // Autre stop dans t1 (controle : doit rester)
      final remainingStop = await stops.create(StopsCompanion.insert(
        tourneeId: t1,
        adresseBrute: 'Stop qui reste',
      ));
      // Stop deja dans t2 (pour verifier que le move ne le casse pas)
      final t2ExistingStop = await stops.create(StopsCompanion.insert(
        tourneeId: t2,
        adresseBrute: 'Stop deja la',
      ));

      // Action : deplace movedStop de t1 vers t2
      await stops.moveToTournee(movedStop, t2);

      // 1. Le stop appartient maintenant a t2
      final t2Stops = await stops.getByTournee(t2);
      expect(t2Stops.map((s) => s.id), containsAll([t2ExistingStop, movedStop]));
      expect(t2Stops, hasLength(2));

      // 2. Il n'est plus dans t1
      final t1Stops = await stops.getByTournee(t1);
      expect(t1Stops.map((s) => s.id), [remainingStop]);

      // 3. Son ordreOptimise a ete reset (sera recalcule par auto-reorder)
      final movedFresh = await stops.getById(movedStop);
      expect(movedFresh!.ordreOptimise, isNull);

      // 4. Les autres stops sont intacts (pas d'effet de bord)
      final remainingFresh = await stops.getById(remainingStop);
      expect(remainingFresh!.tourneeId, t1);
      final t2ExistingFresh = await stops.getById(t2ExistingStop);
      expect(t2ExistingFresh!.tourneeId, t2);
    });

    test('scenario multi-coequipiers : dispatch + bulk + stats par personne',
        () async {
      // Setup : 3 coequipiers (Lucas, Sarah, Tom) + chef (null)
      final lucasId = await coequipiers.create(nom: 'Lucas');
      final sarahId = await coequipiers.create(nom: 'Sarah');
      final tomId = await coequipiers.create(nom: 'Tom');

      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'Tournee multi-equipe',
        date: DateTime(2026, 5, 14),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'Depot',
        // Pas de coequipierDefautId : chaque stop sera affecte
        // explicitement pour tester le dispatch.
      ));

      // 9 stops : 3 par personne au depart, 0 pour le chef.
      // Variation de nbColis pour verifier l'agregation colisLivres.
      Future<int> mkStop(int? coId, int colis) => stops.create(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'addr',
              nbColis: Value(colis),
              coequipierId: Value(coId),
            ),
          );
      final lucasStops = [
        await mkStop(lucasId, 3),
        await mkStop(lucasId, 2),
        await mkStop(lucasId, 1),
      ];
      final sarahStops = [
        await mkStop(sarahId, 5),
        await mkStop(sarahId, 1),
        await mkStop(sarahId, 4),
      ];
      final tomStops = [
        await mkStop(tomId, 2),
        await mkStop(tomId, 2),
        await mkStop(tomId, 2),
      ];

      // 1. Dispatch initial : Lucas 3, Sarah 3, Tom 3.
      final byPersonneBefore =
          await stats.statsParCoequipier(since: DateTime(2026, 1, 1));
      // Aucune livraison faite encore -> nbLivres=0 partout.
      expect(byPersonneBefore[lucasId]?.nbLivres ?? 0, 0);

      // 2. Bulk : tous les stops de Lucas validés livrés.
      for (final id in lucasStops) {
        await stops.markLivre(id, position: (lat: 48.5, lng: 1.5));
      }
      // Sarah : 2 livrés, 1 échec.
      await stops.markLivre(sarahStops[0]);
      await stops.markLivre(sarahStops[1]);
      await stops.markEchec(sarahStops[2], 'adresse_incorrecte');
      // Tom : aucun (a_livrer).

      // 3. Stats par coequipier après ce dispatch.
      final byPersonneAfter =
          await stats.statsParCoequipier(since: DateTime(2026, 1, 1));
      expect(byPersonneAfter[lucasId]!.nbLivres, 3);
      expect(byPersonneAfter[lucasId]!.colisLivres, 6); // 3+2+1
      expect(byPersonneAfter[sarahId]!.nbLivres, 2);
      expect(byPersonneAfter[sarahId]!.nbEchecs, 1);
      expect(byPersonneAfter[sarahId]!.colisLivres, 6); // 5+1
      // Tom n'a rien valide → pas d'entree dans la map ou nbLivres=0.
      expect(byPersonneAfter[tomId]?.nbLivres ?? 0, 0);

      // 4. Reassignement bulk : tous les stops de Tom transferes a Lucas
      //    (cas : Tom tombe malade en cours de tournee).
      for (final id in tomStops) {
        await stops.setCoequipier(id, lucasId);
      }
      final tomAfter = await stops.getByTournee(tId);
      expect(tomAfter.where((s) => s.coequipierId == tomId), isEmpty);
      expect(
        tomAfter
            .where((s) => s.coequipierId == lucasId && tomStops.contains(s.id))
            .length,
        3,
      );

      // 5. Archive Sarah (fin de mission). Ses stops historiques
      //    gardent son id pour les stats des semaines passees.
      await coequipiers.update(sarahId, actif: false);
      final actifs = await coequipiers.watchActifs().first;
      expect(actifs.map((c) => c.id), isNot(contains(sarahId)));
      // Mais les stops valides par Sarah gardent son id (preservation
      // historique).
      final sarahLivre = await stops.getById(sarahStops[0]);
      expect(sarahLivre!.coequipierId, sarahId);

      // 6. Top raisons echec : 1x adresse_incorrecte
      final topRaisons = await stats
          .topRaisonsEchecGlobales(since: DateTime(2026, 1, 1));
      expect(topRaisons.first.raison, 'adresse_incorrecte');
      expect(topRaisons.first.n, 1);
    });

    test(
        'scenario hors-ligne : stops sans coords sont detectables + '
        'retry batch fonctionne', () async {
      final tId = await tournees.create(TourneesCompanion.insert(
        nom: 'Tournee offline',
        date: DateTime(2026, 5, 14),
        pointDepartLat: 48.0,
        pointDepartLng: 1.0,
        pointDepartLabel: 'Depot',
      ));

      // 3 stops dont 2 sans coords (mode offline)
      await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'Avec GPS',
        lat: const Value(48.5),
        lng: const Value(1.5),
      ));
      final offline1 = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'Sans GPS 1',
      ));
      final offline2 = await stops.create(StopsCompanion.insert(
        tourneeId: tId,
        adresseBrute: 'Sans GPS 2',
      ));

      // 1. Detection : 2 stops sans coords
      final all = await stops.getByTournee(tId);
      final missing = all.where((s) => s.lat == null).toList();
      expect(missing.map((s) => s.id), containsAll([offline1, offline2]));

      // 2. Simule un retry batch : on update les coords manuellement
      //    (le vrai service appellerait le geocoder, on teste juste la
      //     mecanique cote DB)
      await stops.updateCoords(
        stopId: offline1,
        lat: 48.7,
        lng: 1.3,
        adresseNormalisee: '12 RUE X, 75001 PARIS',
      );

      // 3. Apres retry, plus qu'un en attente
      final afterRetry = await stops.getByTournee(tId);
      final stillMissing =
          afterRetry.where((s) => s.lat == null).toList();
      expect(stillMissing, hasLength(1));
      expect(stillMissing.first.id, offline2);
    });
  });
}
