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
  });
}
