import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/mark_livre_service.dart';
import 'package:opti_route/data/stops_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';

import '../helpers/test_db.dart';

/// Tests de [MarkLivreService], extrait des deux copies divergentes qui
/// vivaient dans `StopRowActions` et `ProchainArretCard`.
///
/// Ce qui est verifie ici, c'est la bascule automatique du statut de la
/// tournee : elle etait jusqu'ici couverte uniquement en passant par un
/// widget, donc jamais directement.
void main() {
  late AppDatabase db;
  late StopsRepository stopsRepo;
  late TourneesRepository tourneesRepo;
  late _FakeNotifications notifs;
  late int tId;
  // Nombre d'appels au capteur GPS : le batch doit n'en faire qu'UN
  // seul pour tout le lot.
  late int gpsCalls;

  setUp(() async {
    db = makeTestDb();
    stopsRepo = StopsRepository(db);
    tourneesRepo = TourneesRepository(db);
    notifs = _FakeNotifications();
    gpsCalls = 0;
    tId = await seedTournee(db);
    await tourneesRepo.update(
      tId,
      const TourneesCompanion(statut: Value('en_cours')),
    );
  });

  tearDown(() async => db.close());

  /// Service branche sur la DB de test, avec un GPS simule (le vrai
  /// passe par geolocator, indisponible en test) et des notifications
  /// enregistrees au lieu d'etre poussees au plugin. [position] null =
  /// permission refusee / pas de fix.
  MarkLivreService makeService({GpsFix? position}) {
    return MarkLivreService(
      stopsRepo,
      tourneesRepo,
      capturerGps: () async {
        gpsCalls++;
        return position;
      },
      notifications: notifs,
    );
  }

  Future<Stop> insertStop({String statut = 'a_livrer'}) async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tId,
            adresseBrute: 'Adresse',
            statutLivraison: Value(statut),
          ),
        );
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  Future<String> statutTournee() async =>
      (await tourneesRepo.getById(tId))!.statut;

  group('markLivre', () {
    test('dernier arret -> tournee terminee + rappels annules', () async {
      await insertStop(statut: 'echec');
      final dernier = await insertStop();

      final res =
          await makeService(position: (lat: 48.5, lng: 1.5)).markLivre(dernier);

      expect(res, StatutTourneeChange.terminee);
      expect(await statutTournee(), 'terminee');
      final relu = await stopsRepo.getById(dernier.id);
      expect(relu!.statutLivraison, 'livre');
      // La position capturee sert de preuve de passage.
      expect(relu.livreLat, 48.5);
      expect(relu.livreLng, 1.5);
      // Union des deux implementations : recap de fin de tournee ET les
      // DEUX rappels annules (l'ancienne version de ProchainArretCard
      // n'annulait que le rappel du matin, sans recap).
      expect(notifs.recaps, hasLength(1));
      expect(notifs.recaps.single.nbLivres, 1);
      expect(notifs.recaps.single.nbEchecs, 1);
      expect(notifs.rappelsAnnules, [tId]);
      expect(notifs.nonTermineeAnnules, [tId]);
    });

    test('il reste un arret -> statut inchange, aucune notif', () async {
      final premier = await insertStop();
      await insertStop();

      final res = await makeService().markLivre(premier);

      expect(res, StatutTourneeChange.inchange);
      expect(await statutTournee(), 'en_cours');
      expect(notifs.recaps, isEmpty);
      expect(notifs.rappelsAnnules, isEmpty);
      expect(notifs.nonTermineeAnnules, isEmpty);
    });

    test('GPS indisponible -> arret quand meme livre, sans coords',
        () async {
      final stop = await insertStop();

      await makeService().markLivre(stop);

      final relu = await stopsRepo.getById(stop.id);
      expect(relu!.statutLivraison, 'livre');
      expect(relu.livreLat, isNull);
      expect(relu.livreLng, isNull);
    });

    test('la signature s\'ouvre AVANT l\'ecriture du statut', () async {
      // Le callback tourne pendant la capture GPS : au moment ou il est
      // appele, l'arret ne doit pas encore etre passe en livre (sinon on
      // aurait valide la livraison avant que le destinataire signe).
      final stop = await insertStop();
      String? statutPendantSignature;

      await makeService().markLivre(
        stop,
        pendantCaptureGps: () async {
          statutPendantSignature =
              (await stopsRepo.getById(stop.id))!.statutLivraison;
        },
      );

      expect(statutPendantSignature, 'a_livrer');
      expect((await stopsRepo.getById(stop.id))!.statutLivraison, 'livre');
    });
  });

  group('markEchec', () {
    test('dernier arret -> tournee terminee (un echec est definitif)',
        () async {
      await insertStop(statut: 'livre');
      final dernier = await insertStop();

      final res = await makeService(position: (lat: 48.5, lng: 1.5))
          .markEchec(dernier, 'absent');

      // La re-synchronisation compte 'livre' ET 'echec' : echouer sur le
      // dernier arret cloture la tournee comme le livrer. Avant, la
      // commande vocale "echec" appelait le repository nu, donc dire
      // "echec" sur le dernier arret ne terminait jamais la tournee.
      expect(res, StatutTourneeChange.terminee);
      expect(await statutTournee(), 'terminee');
      final relu = await stopsRepo.getById(dernier.id);
      expect(relu!.statutLivraison, 'echec');
      expect(relu.raisonEchec, 'absent');
      // Position transmise au repository : preuve de passage, meme sur
      // un echec (le vocal n'en enregistrait aucune).
      expect(gpsCalls, 1);
      expect(relu.livreLat, 48.5);
      expect(relu.livreLng, 1.5);
      expect(notifs.recaps, hasLength(1));
      expect(notifs.recaps.single.nbLivres, 1);
      expect(notifs.recaps.single.nbEchecs, 1);
      expect(notifs.rappelsAnnules, [tId]);
      expect(notifs.nonTermineeAnnules, [tId]);
    });

    test('il reste un arret -> statut inchange, aucune notif', () async {
      final premier = await insertStop();
      await insertStop();

      final res = await makeService().markEchec(premier, 'absent');

      expect(res, StatutTourneeChange.inchange);
      expect(await statutTournee(), 'en_cours');
      expect((await stopsRepo.getById(premier.id))!.statutLivraison, 'echec');
      expect(notifs.recaps, isEmpty);
      expect(notifs.rappelsAnnules, isEmpty);
      expect(notifs.nonTermineeAnnules, isEmpty);
    });

    test('GPS indisponible -> echec quand meme enregistre, sans coords',
        () async {
      final stop = await insertStop();

      await makeService().markEchec(stop, 'refuse');

      final relu = await stopsRepo.getById(stop.id);
      expect(relu!.statutLivraison, 'echec');
      expect(relu.raisonEchec, 'refuse');
      expect(relu.livreLat, isNull);
      expect(relu.livreLng, isNull);
    });
  });

  group('markLivreBatch', () {
    test('tout le lot livre avec UNE SEULE capture GPS', () async {
      final lot = [
        await insertStop(),
        await insertStop(),
        await insertStop(),
      ];

      final res = await makeService(position: (lat: 48.5, lng: 1.5))
          .markLivreBatch(lot);

      // Un seul fix pour les 3 arrets : l'utilisateur n'a pas bouge, et
      // 3 fix a 4 s de timeout, c'est 12 s d'attente pour rien.
      expect(gpsCalls, 1);
      for (final s in lot) {
        final relu = await stopsRepo.getById(s.id);
        expect(relu!.statutLivraison, 'livre');
        expect(relu.livreLat, 48.5);
        expect(relu.livreLng, 1.5);
      }
      expect(res.change, StatutTourneeChange.terminee);
      expect(await statutTournee(), 'terminee');
      // Ce que l'ancienne copie de batchLivre oubliait : le recap et le
      // rappel "tournee non terminee >8h" (elle n'annulait que le
      // rappel du matin).
      expect(notifs.recaps, hasLength(1));
      expect(notifs.recaps.single.nbLivres, 3);
      expect(notifs.rappelsAnnules, [tId]);
      expect(notifs.nonTermineeAnnules, [tId]);
    });

    test('rend le statut de la tournee AVANT la bascule', () async {
      await tourneesRepo.update(
        tId,
        const TourneesCompanion(statut: Value('optimisee')),
      );
      final lot = [await insertStop()];

      final res = await makeService().markLivreBatch(lot);

      // Rendu tel quel, pas normalise : l'undo doit pouvoir remettre la
      // tournee dans l'etat exact d'ou elle vient.
      expect(res.statutAvant, 'optimisee');
      expect(res.change, StatutTourneeChange.terminee);
    });

    test('il reste un arret hors du lot -> statut inchange', () async {
      final lot = [await insertStop()];
      await insertStop(); // pas dans le lot

      final res = await makeService().markLivreBatch(lot);

      expect(res.change, StatutTourneeChange.inchange);
      expect(res.statutAvant, 'en_cours');
      expect(await statutTournee(), 'en_cours');
      expect(notifs.recaps, isEmpty);
      expect(notifs.rappelsAnnules, isEmpty);
      expect(notifs.nonTermineeAnnules, isEmpty);
    });

    test('lot vide -> aucune capture GPS, rien touche', () async {
      final seul = await insertStop();

      final res = await makeService().markLivreBatch([]);

      expect(gpsCalls, 0);
      expect(res.change, StatutTourneeChange.inchange);
      expect(res.statutAvant, isNull);
      expect((await stopsRepo.getById(seul.id))!.statutLivraison, 'a_livrer');
      expect(await statutTournee(), 'en_cours');
    });

    test('le resultat permet de rejouer l\'undo du batch (#115)', () async {
      // Deroule ce que fait le SnackBar "Annuler" de StopsBulkActions :
      // markAaLivrerBatch + restauration du statut d'avant. Le lot doit
      // revenir a l'etat initial exact, pas a 'optimisee'.
      final lot = [await insertStop(), await insertStop()];

      final res = await makeService().markLivreBatch(lot);
      expect(res.change, StatutTourneeChange.terminee);
      expect(await statutTournee(), 'terminee');

      await stopsRepo.markAaLivrerBatch(lot.map((s) => s.id).toList());
      final statutAvant = res.statutAvant;
      final aCloture = res.change == StatutTourneeChange.terminee;
      if (aCloture && statutAvant != null) {
        await tourneesRepo.update(
          tId,
          TourneesCompanion(statut: Value(statutAvant)),
        );
      }

      expect(await statutTournee(), 'en_cours');
      for (final s in lot) {
        expect((await stopsRepo.getById(s.id))!.statutLivraison, 'a_livrer');
      }
    });
  });

  group('syncStatutTournee', () {
    test('statut annule apres coup -> tournee rouverte en optimisee',
        () async {
      final stop = await insertStop();
      await makeService().markLivre(stop);
      expect(await statutTournee(), 'terminee');

      await stopsRepo.markAaLivrer(stop.id);
      final res = await makeService().syncStatutTournee(tId);

      expect(res, StatutTourneeChange.rouverte);
      expect(await statutTournee(), 'optimisee');
    });

    test('tournee deja terminee -> pas de seconde notif', () async {
      await insertStop(statut: 'livre');
      await tourneesRepo.update(
        tId,
        const TourneesCompanion(statut: Value('terminee')),
      );

      final res = await makeService().syncStatutTournee(tId);

      expect(res, StatutTourneeChange.inchange);
      expect(notifs.recaps, isEmpty);
      expect(notifs.rappelsAnnules, isEmpty);
    });

    test('tournee sans aucun arret -> no-op', () async {
      final res = await makeService().syncStatutTournee(tId);

      expect(res, StatutTourneeChange.inchange);
      expect(await statutTournee(), 'en_cours');
      expect(notifs.recaps, isEmpty);
    });
  });

  // Deroule ce que fait `StopsBulkActions.undoLastStatus` : revert du
  // dernier statut pose, puis re-synchronisation. C'est ce dernier
  // appel qui manquait -- l'undo fabriquait l'etat degenere "tournee
  // terminee alors qu'il reste un arret a livrer".
  group('undo du dernier statut', () {
    test('tournee terminee -> revert -> la tournee rouvre', () async {
      final premier = await insertStop();
      final dernier = await insertStop();
      final service = makeService();
      await service.markLivre(premier);
      expect(await service.markLivre(dernier), StatutTourneeChange.terminee);
      expect(await statutTournee(), 'terminee');

      // revertStatus, l'appel exact de l'undo (et pas markAaLivrer :
      // seul le label d'historique differe). On vise l'arret
      // directement plutot que via getLastTransitionedStop, dont le tri
      // repose sur un timestamp a la seconde -- deux transitions posees
      // dans le meme test seraient a egalite.
      await stopsRepo.revertStatus(dernier.id);
      final res = await service.syncStatutTournee(tId);

      expect(res, StatutTourneeChange.rouverte);
      expect(await statutTournee(), 'optimisee');
      expect(
        (await stopsRepo.getById(dernier.id))!.statutLivraison,
        'a_livrer',
      );
    });

    test('tournee encore ouverte -> revert -> statut inchange', () async {
      // L'autre sens : la re-synchronisation ajoutee a l'undo ne doit
      // rien changer quand la tournee n'avait jamais ete cloturee. Une
      // tournee 'en_cours' ne doit pas se retrouver en 'optimisee' au
      // passage.
      final premier = await insertStop();
      await insertStop();
      final service = makeService();
      await service.markLivre(premier);
      expect(await statutTournee(), 'en_cours');

      await stopsRepo.revertStatus(premier.id);
      final res = await service.syncStatutTournee(tId);

      expect(res, StatutTourneeChange.inchange);
      expect(await statutTournee(), 'en_cours');
      expect(notifs.recaps, isEmpty);
    });
  });
}

/// Enregistre les notifications au lieu de les pousser au plugin
/// (`NotificationsService` est un singleton branche sur
/// flutter_local_notifications, non montable en test unitaire).
class _FakeNotifications implements MarkLivreNotifications {
  final List<({int nbLivres, int nbEchecs, int dureeTotaleMin})> recaps = [];
  final List<int> rappelsAnnules = [];
  final List<int> nonTermineeAnnules = [];

  @override
  Future<void> showEndOfRouteSummary({
    required int tourneeId,
    required String nomTournee,
    required int nbLivres,
    required int nbEchecs,
    required int dureeTotaleMin,
  }) async {
    recaps.add((
      nbLivres: nbLivres,
      nbEchecs: nbEchecs,
      dureeTotaleMin: dureeTotaleMin,
    ));
  }

  @override
  Future<void> cancelTourneeRappel(int tourneeId) async {
    rappelsAnnules.add(tourneeId);
  }

  @override
  Future<void> cancelTourneeNonTermineeReminder(int tourneeId) async {
    nonTermineeAnnules.add(tourneeId);
  }
}
