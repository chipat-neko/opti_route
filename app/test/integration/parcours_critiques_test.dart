// Tests d'integration "parcours critiques" (carte #155), au niveau
// repos/services (flutter_test + DB memoire), PAS en device E2E.
//
// Choix assume : les tests integration_test sur device avec les streams
// Drift ne se stabilisent jamais (pumpAndSettle -> timeout, lecon de la
// session 2026-05-27). On couvre donc les parcours critiques bout-en-bout
// au niveau metier (creation -> validation -> stats / undo), ce qui donne
// un vrai filet anti-regression rapide et fiable.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/chef_stats_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';

void main() {
  group('Parcours critiques (#155)', () {
    late AppDatabase db;
    late TourneesRepository tournees;
    late StopsRepository stops;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      tournees = TourneesRepository(db);
      stops = StopsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> creerTournee({
      required String nom,
      DateTime? date,
      String statut = 'brouillon',
    }) {
      return tournees.create(
        TourneesCompanion.insert(
          nom: nom,
          date: date ?? DateTime.now(),
          pointDepartLat: 48.45,
          pointDepartLng: 1.49,
          pointDepartLabel: 'Depot',
          statut: Value(statut),
        ),
      );
    }

    Future<int> ajouterStop(int tId, {double lat = 48.45, double lng = 1.49}) {
      return stops.create(
        StopsCompanion.insert(
          tourneeId: tId,
          adresseBrute: 'Adresse test',
          lat: Value(lat),
          lng: Value(lng),
        ),
      );
    }

    /// Recharge toutes les tournees du jour + leurs stops et calcule le
    /// ChefStatsJour (comme le panneau chef [#88·4]).
    Future<ChefStatsJour> statsDuJour() async {
      final today = DateTime.now();
      final all = await db.select(db.tournees).get();
      final duJour = all
          .where((t) =>
              t.date.year == today.year &&
              t.date.month == today.month &&
              t.date.day == today.day)
          .toList();
      final ids = duJour.map((t) => t.id).toSet();
      final allStops = await db.select(db.stops).get();
      final stopsDuJour =
          allStops.where((s) => ids.contains(s.tourneeId)).toList();
      return ChefStatsJour.computeFromBundle(
        tournees: duJour,
        stops: stopsDuJour,
      );
    }

    test('Solo : creer -> 3 arrets -> 2 livres + 1 echec -> terminer',
        () async {
      final tId = await creerTournee(nom: 'Tournee solo');
      final s1 = await ajouterStop(tId);
      final s2 = await ajouterStop(tId);
      final s3 = await ajouterStop(tId);

      await stops.markLivre(s1);
      await stops.markLivre(s2);
      await stops.markEchec(s3, 'Client absent');

      var stats = await statsDuJour();
      expect(stats.totalStops, 3);
      expect(stats.nbLivres, 2);
      expect(stats.nbEchecs, 1);
      expect(stats.restants, 0);
      expect(stats.tauxReussite, closeTo(2 / 3, 0.001));

      // Terminer la tournee.
      await tournees.update(
        tId,
        const TourneesCompanion(statut: Value('terminee')),
      );
      stats = await statsDuJour();
      expect(stats.nbTourneesTerminees, 1);
    });

    test('Multi-tournee jour : agregation home + en cours', () async {
      // Tournee 1 terminee (2 livres), tournee 2 en cours (1 livre / 2).
      final t1 = await creerTournee(nom: 'Matin', statut: 'terminee');
      await stops.markLivre(await ajouterStop(t1));
      await stops.markLivre(await ajouterStop(t1));

      final t2 = await creerTournee(nom: 'Aprem', statut: 'en_cours');
      await stops.markLivre(await ajouterStop(t2));
      await ajouterStop(t2); // reste a livrer

      final stats = await statsDuJour();
      expect(stats.nbTournees, 2);
      expect(stats.nbTourneesEnCours, 1);
      expect(stats.nbTourneesTerminees, 1);
      expect(stats.totalStops, 4);
      expect(stats.nbLivres, 3);
      expect(stats.restants, 1);
    });

    test('Bulk livre puis undo : retour a l\'etat initial', () async {
      final tId = await creerTournee(nom: 'Bulk', statut: 'en_cours');
      final ids = [
        for (var i = 0; i < 3; i++) await ajouterStop(tId),
      ];

      // Validation massive (equivalent batchLivre).
      for (final id in ids) {
        await stops.markLivre(id);
      }
      var rows = await stops.getByTournee(tId);
      expect(rows.every((s) => s.statutLivraison == 'livre'), isTrue);

      // Undo bulk (#115).
      final reverted = await stops.markAaLivrerBatch(ids);
      expect(reverted, 3);
      rows = await stops.getByTournee(tId);
      expect(rows.every((s) => s.statutLivraison == 'a_livrer'), isTrue);
    });
  });
}
