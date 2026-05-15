import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/stops_repository.dart';

void main() {
  group('StopsRepository - statut livraison', () {
    late AppDatabase db;
    late StopsRepository repo;
    late int stopId;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      repo = StopsRepository(db);
      final tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 10),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      stopId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: '14 Impasse Bois',
              lat: const Value(48.4),
              lng: const Value(1.5),
            ),
          );
    });

    tearDown(() async {
      await db.close();
    });

    test('default : statut = a_livrer, raisonEchec = null', () async {
      final s = await repo.getById(stopId);
      expect(s!.statutLivraison, 'a_livrer');
      expect(s.raisonEchec, isNull);
    });

    test('markLivre : statut -> livre, raisonEchec -> null', () async {
      await repo.markEchec(stopId, 'absent'); // setup pour verif reset
      await repo.markLivre(stopId);
      final s = await repo.getById(stopId);
      expect(s!.statutLivraison, 'livre');
      expect(s.raisonEchec, isNull);
    });

    test('markEchec : statut -> echec, raisonEchec persistee', () async {
      await repo.markEchec(stopId, 'refuse');
      final s = await repo.getById(stopId);
      expect(s!.statutLivraison, 'echec');
      expect(s.raisonEchec, 'refuse');
    });

    test('markAaLivrer : reset complet', () async {
      await repo.markEchec(stopId, 'autre');
      await repo.markAaLivrer(stopId);
      final s = await repo.getById(stopId);
      expect(s!.statutLivraison, 'a_livrer');
      expect(s.raisonEchec, isNull);
    });

    test('markLivre avec position GPS : coords + timestamp persistes',
        () async {
      final before = DateTime.now();
      await repo.markLivre(
        stopId,
        position: (lat: 48.4307, lng: 1.4892),
      );
      final s = await repo.getById(stopId);
      expect(s!.livreLat, 48.4307);
      expect(s.livreLng, 1.4892);
      expect(s.livreLe, isNotNull);
      expect(
        s.livreLe!.isAfter(before.subtract(const Duration(seconds: 1))),
        isTrue,
      );
    });

    test('markLivre sans position : livreLat/livreLng restent null',
        () async {
      await repo.markLivre(stopId);
      final s = await repo.getById(stopId);
      expect(s!.livreLat, isNull);
      expect(s.livreLng, isNull);
      expect(s.livreLe, isNotNull); // le timestamp est toujours pose
    });

    test('markAaLivrer efface aussi la position + timestamp', () async {
      await repo.markLivre(stopId, position: (lat: 1.0, lng: 2.0));
      await repo.markAaLivrer(stopId);
      final s = await repo.getById(stopId);
      expect(s!.livreLat, isNull);
      expect(s.livreLng, isNull);
      expect(s.livreLe, isNull);
    });

    test('changement de statut n\'affecte pas les autres champs', () async {
      // Donnees significatives sur le stop avant validation.
      await (db.update(db.stops)..where((s) => s.id.equals(stopId))).write(
        const StopsCompanion(
          nbColis: Value(7),
          notes: Value('code 1234B'),
        ),
      );
      await repo.markLivre(stopId);
      final s = await repo.getById(stopId);
      expect(s!.nbColis, 7);
      expect(s.notes, 'code 1234B');
    });
  });

  group('StopsRepository - undo dernier statut', () {
    late AppDatabase db;
    late StopsRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = StopsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    Future<(int, int)> seedTourneeWithStop() async {
      final tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 10),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      final sId = await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A',
              lat: const Value(48.5),
              lng: const Value(1.5),
            ),
          );
      return (tId, sId);
    }

    test('getLastTransitionedStop : null si aucun stop transitionne',
        () async {
      final (tId, _) = await seedTourneeWithStop();
      final last = await repo.getLastTransitionedStop(tId);
      expect(last, isNull);
    });

    test('getLastTransitionedStop : retourne le dernier livre/echec',
        () async {
      final (tId, sId) = await seedTourneeWithStop();
      await repo.markLivre(sId);
      final last = await repo.getLastTransitionedStop(tId);
      expect(last, isNotNull);
      expect(last!.id, sId);
    });

    test('revertStatus : repasse a_livrer + reset raisonEchec',
        () async {
      final (_, sId) = await seedTourneeWithStop();
      await repo.markEchec(sId, 'absent');
      var s = await repo.getById(sId);
      expect(s!.statutLivraison, 'echec');
      expect(s.raisonEchec, 'absent');

      await repo.revertStatus(sId);
      s = await repo.getById(sId);
      expect(s!.statutLivraison, 'a_livrer');
      expect(s.raisonEchec, isNull);
    });

    test('revertStatus log dans history avec action revert', () async {
      final (_, sId) = await seedTourneeWithStop();
      await repo.markLivre(sId);
      await repo.revertStatus(sId);
      final hist = await repo.getHistory(sId);
      expect(hist, isNotEmpty);
      final revert = hist.firstWhere((h) => h.action == 'revert');
      expect(revert.fromStatus, 'livre');
      expect(revert.toStatus, 'a_livrer');
    });

    test('revertStatus efface aussi preuvePhotoPath + coords + livreLe',
        () async {
      // Regression : avant le fix 2026-05-14, revertStatus oubliait
      // preuvePhotoPath -> la photo restait orpheline sur un stop
      // repassé en a_livrer (incoherent avec markAaLivrer).
      final (_, sId) = await seedTourneeWithStop();
      await repo.markLivre(
        sId,
        position: (lat: 48.0, lng: 1.0),
        preuvePhotoPath: '/p/photo.jpg',
      );
      await repo.revertStatus(sId);
      final s = await repo.getById(sId);
      expect(s!.preuvePhotoPath, isNull,
          reason: 'revertStatus doit reset la photo');
      expect(s.livreLat, isNull);
      expect(s.livreLng, isNull);
      expect(s.livreLe, isNull);
    });

    test('getHistory : log les 3 transitions livre/echec/revert',
        () async {
      final (_, sId) = await seedTourneeWithStop();
      await repo.markLivre(sId);
      await repo.markEchec(sId, 'absent');
      await repo.revertStatus(sId);
      final hist = await repo.getHistory(sId);
      // 3 evenements logges, ordre exact peut depender de la precision
      // de stockage Drift sur la milli. On verifie juste la presence.
      expect(hist, hasLength(3));
      final actions = hist.map((h) => h.action).toSet();
      expect(actions, containsAll(['mark_livre', 'mark_echec', 'revert']));
    });

    test('applyOptimizedOrder : ecrit ordre_optimise 1-based dans l\'ordre',
        () async {
      final tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 10),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      // 3 stops sans ordre.
      final ids = <int>[];
      for (var i = 0; i < 3; i++) {
        ids.add(await db.into(db.stops).insert(
              StopsCompanion.insert(
                tourneeId: tId,
                adresseBrute: 'stop-$i',
              ),
            ));
      }
      // On applique un ordre inverse : [id2, id1, id0]
      await repo.applyOptimizedOrder([ids[2], ids[1], ids[0]]);

      final s0 = await repo.getById(ids[0]);
      final s1 = await repo.getById(ids[1]);
      final s2 = await repo.getById(ids[2]);
      expect(s2!.ordreOptimise, 1); // 1ere position
      expect(s1!.ordreOptimise, 2);
      expect(s0!.ordreOptimise, 3);
    });

    test('countByTournee : 0 si vide, n apres seed', () async {
      final tId = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'T',
              date: DateTime(2026, 5, 10),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
            ),
          );
      expect(await repo.countByTournee(tId), 0);
      await db.into(db.stops).insert(
            StopsCompanion.insert(tourneeId: tId, adresseBrute: 'A'),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(tourneeId: tId, adresseBrute: 'B'),
          );
      expect(await repo.countByTournee(tId), 2);
    });

    test('markLivre avec preuvePhotoPath : persiste le chemin', () async {
      final (_, sId) = await seedTourneeWithStop();
      await repo.markLivre(
        sId,
        preuvePhotoPath: '/data/app/preuves/12_1234.jpg',
      );
      final s = await repo.getById(sId);
      expect(s!.preuvePhotoPath, '/data/app/preuves/12_1234.jpg');
    });

    test('markEchec avec preuvePhotoPath : persiste le chemin', () async {
      final (_, sId) = await seedTourneeWithStop();
      await repo.markEchec(
        sId,
        'absent',
        preuvePhotoPath: '/data/app/preuves/echec.jpg',
      );
      final s = await repo.getById(sId);
      expect(s!.preuvePhotoPath, '/data/app/preuves/echec.jpg');
    });

    test('setPreuvePhoto : ajoute apres coup, sans toucher au statut',
        () async {
      final (_, sId) = await seedTourneeWithStop();
      await repo.markLivre(sId);
      await repo.setPreuvePhoto(sId, '/p/photo.jpg');
      final s = await repo.getById(sId);
      expect(s!.preuvePhotoPath, '/p/photo.jpg');
      // Le statut n'est pas modifie
      expect(s.statutLivraison, 'livre');
    });

    test('setPreuvePhoto null : retire la photo', () async {
      final (_, sId) = await seedTourneeWithStop();
      await repo.markLivre(sId, preuvePhotoPath: '/old.jpg');
      await repo.setPreuvePhoto(sId, null);
      final s = await repo.getById(sId);
      expect(s!.preuvePhotoPath, isNull);
    });

    test('markAaLivrer : efface aussi la preuvePhotoPath', () async {
      final (_, sId) = await seedTourneeWithStop();
      await repo.markLivre(sId, preuvePhotoPath: '/p.jpg');
      await repo.markAaLivrer(sId);
      final s = await repo.getById(sId);
      expect(s!.preuvePhotoPath, isNull);
    });

    test('updateCoords : met a jour lat/lng + adresseNormalisee uniquement',
        () async {
      final (_, sId) = await seedTourneeWithStop();
      // Set des notes + nbColis avant le re-geocodage
      await repo.update(
        sId,
        StopsCompanion(
          notes: const Value('garde-meuble'),
          nbColis: const Value(7),
        ),
      );
      await repo.updateCoords(
        stopId: sId,
        lat: 48.9999,
        lng: 1.9999,
        adresseNormalisee: '14 rue X, 28000 Chartres',
      );
      final s = await repo.getById(sId);
      expect(s!.lat, 48.9999);
      expect(s.lng, 1.9999);
      expect(s.adresseNormalisee, '14 rue X, 28000 Chartres');
      // Les autres champs (notes, nbColis) sont preserves.
      expect(s.notes, 'garde-meuble');
      expect(s.nbColis, 7);
    });
  });
}
