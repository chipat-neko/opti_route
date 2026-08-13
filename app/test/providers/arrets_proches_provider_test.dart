import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/providers/database_providers.dart';
import 'package:opti_route/providers/location_providers.dart';

import '../helpers/test_db.dart';

/// Tests du branchement de `ProximityChecker` sur l'interface (carte
/// #285) : la fonction pure [selectArretsProches] (ce que le bandeau
/// affiche) puis le provider derive [arretsProchesProvider] (position +
/// tournee + arrets -> bandeau ou rien du tout).
///
/// `ProximityChecker.findNearby` a deja ses propres tests
/// (test/data/proximity_checker_test.dart) : on ne les rejoue pas, on
/// verifie uniquement ce qui s'ajoute par-dessus (selection du plus
/// proche, comptage des autres, garde-fous du provider).
///
/// Deux arbitrages du proprietaire y sont documentes :
/// - la PAUSE ne masque plus le bandeau ;
/// - le PROCHAIN arret planifie (`firstAlivrerWithCoords`, la source de
///   verite de `ProchainArretCard`) est exclu : le bandeau ne parle que
///   d'un arret proche hors sequence.
void main() {
  group('selectArretsProches (fonction pure)', () {
    late AppDatabase db;
    late int tId;

    setUp(() async {
      db = makeTestDb();
      tId = await seedTournee(db);
    });

    tearDown(() async => db.close());

    test('aucun arret dans le rayon -> null (pas de bandeau vide)',
        () async {
      final loin = await _insertStop(db, tId, lat: 49.0, lng: 1.0);
      final res = selectArretsProches(
        lat: 48.0,
        lng: 1.0,
        stops: [loin],
      );
      expect(res, isNull);
    });

    test('un arret a ~50 m -> plus proche + distance arrondie + 0 autre',
        () async {
      // ~50 m au nord (meme repere que proximity_checker_test).
      final proche = await _insertStop(
        db,
        tId,
        lat: 48.00045,
        lng: 1.0,
        nomClient: 'Dupont',
      );
      final loin = await _insertStop(db, tId, lat: 49.0, lng: 1.0);
      final res = selectArretsProches(
        lat: 48.0,
        lng: 1.0,
        stops: [loin, proche],
      );
      expect(res, isNotNull);
      expect(res!.plusProche.id, proche.id);
      expect(res.plusProche.nomClient, 'Dupont');
      expect(res.distanceMeters, closeTo(50, 5));
      expect(res.autresCount, 0);
    });

    test('plusieurs arrets proches -> le plus proche + compteur des autres',
        () async {
      final moyen = await _insertStop(db, tId, lat: 48.0003, lng: 1.0);
      final loin = await _insertStop(db, tId, lat: 48.0006, lng: 1.0);
      final tresProche = await _insertStop(db, tId, lat: 48.00005, lng: 1.0);
      final res = selectArretsProches(
        lat: 48.0,
        lng: 1.0,
        // Ordre d'entree volontairement melange : c'est findNearby qui
        // trie, pas l'appelant.
        stops: [moyen, loin, tresProche],
      );
      expect(res, isNotNull);
      expect(res!.plusProche.id, tresProche.id);
      expect(res.autresCount, 2);
    });

    test('arrets deja traites / sans GPS exclus du compteur', () async {
      final proche = await _insertStop(db, tId, lat: 48.00005, lng: 1.0);
      final livre = await _insertStop(
        db,
        tId,
        lat: 48.0001,
        lng: 1.0,
        statut: 'livre',
      );
      final sansCoords = await _insertStop(db, tId);
      final res = selectArretsProches(
        lat: 48.0,
        lng: 1.0,
        stops: [proche, livre, sansCoords],
      );
      expect(res, isNotNull);
      expect(res!.plusProche.id, proche.id);
      expect(res.autresCount, 0);
    });

    test('arret exclu : ni plus proche, ni compte dans les autres',
        () async {
      // L'arret exclu est le prochain arret planifie : `ProchainArretCard`
      // affiche deja sa distance juste en dessous du bandeau. On passe
      // donc au suivant des proches, et le compteur "+N autres" ne doit
      // pas le compter non plus (sinon il ne correspond plus a ce qui
      // est affiche).
      final tresProche = await _insertStop(db, tId, lat: 48.00005, lng: 1.0);
      final moyen = await _insertStop(db, tId, lat: 48.0003, lng: 1.0);
      final autre = await _insertStop(db, tId, lat: 48.0004, lng: 1.0);
      final res = selectArretsProches(
        lat: 48.0,
        lng: 1.0,
        stops: [tresProche, moyen, autre],
        exclureStopId: tresProche.id,
      );
      expect(res, isNotNull);
      expect(res!.plusProche.id, moyen.id);
      expect(res.autresCount, 1);
    });

    test('exclure le seul arret proche -> null (rien a apprendre)',
        () async {
      final seul = await _insertStop(db, tId, lat: 48.00005, lng: 1.0);
      expect(
        selectArretsProches(
          lat: 48.0,
          lng: 1.0,
          stops: [seul],
          exclureStopId: seul.id,
        ),
        isNull,
      );
    });

    test('rayon personnalise respecte', () async {
      // ~111 m : hors du rayon par defaut (80 m), dedans a 200 m.
      final stop = await _insertStop(db, tId, lat: 48.001, lng: 1.0);
      expect(
        selectArretsProches(lat: 48.0, lng: 1.0, stops: [stop]),
        isNull,
      );
      expect(
        selectArretsProches(
          lat: 48.0,
          lng: 1.0,
          stops: [stop],
          radiusMeters: 200,
        ),
        isNotNull,
      );
    });

    test('deux fixes GPS qui donnent le meme affichage sont egaux', () async {
      final stop = await _insertStop(db, tId, lat: 48.00045, lng: 1.0);
      // Deux positions differentes de quelques centimetres : la distance
      // arrondie au metre ne bouge pas -> resultats egaux -> aucun rebuild
      // repropage par Riverpod.
      final a = selectArretsProches(lat: 48.0, lng: 1.0, stops: [stop]);
      final b =
          selectArretsProches(lat: 48.0000001, lng: 1.0, stops: [stop]);
      expect(a, isNotNull);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });
  });

  group('arretsProchesProvider', () {
    late AppDatabase db;
    late int tId;

    setUp(() async {
      db = makeTestDb();
      tId = await seedTournee(db);
    });

    tearDown(() async => db.close());

    Future<void> demarrerTournee() async {
      await (db.update(db.tournees)..where((t) => t.id.equals(tId))).write(
        TourneesCompanion(
          statut: const Value('en_cours'),
          demareeLe: Value(DateTime(2026, 5, 30, 8)),
        ),
      );
    }

    ProviderContainer makeContainer({({double lat, double lng})? position}) {
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          // On court-circuite le GPS a la frontiere geolocator : le test
          // n'a besoin que d'un couple lat/lng.
          currentLatLngProvider.overrideWith((ref) => position),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    /// Insere le prochain arret PLANIFIE (premier `a_livrer` geocode de
    /// la liste, cf `firstAlivrerWithCoords`) tres loin de la position de
    /// test : il ne rentre jamais dans le rayon, et il absorbe le role de
    /// "prochain arret" pour que les arrets proches inseres ensuite
    /// soient bien des arrets HORS SEQUENCE.
    Future<Stop> insererProchainPlanifieLoin() =>
        _insertStop(db, tId, lat: 49.0, lng: 1.0);

    test('tournee en cours + position sur place -> arret proche expose',
        () async {
      await demarrerTournee();
      await insererProchainPlanifieLoin();
      final proche = await _insertStop(
        db,
        tId,
        lat: 48.00045,
        lng: 1.0,
        nomClient: 'Dupont',
      );

      final container = makeContainer(position: (lat: 48.0, lng: 1.0));
      final res =
          await _bandeauApresChargement(container, tId, stopsAttendus: 2);
      expect(res, isNotNull);
      expect(res!.plusProche.id, proche.id);
      expect(res.plusProche.nomClient, 'Dupont');
      expect(res.distanceMeters, closeTo(50, 5));
      expect(res.autresCount, 0);
    });

    test('tournee pas demarree -> rien, meme en etant sur place', () async {
      await insererProchainPlanifieLoin();
      await _insertStop(db, tId, lat: 48.0, lng: 1.0);
      final container = makeContainer(position: (lat: 48.0, lng: 1.0));

      final res =
          await _bandeauApresChargement(container, tId, stopsAttendus: 2);
      expect(res, isNull);
    });

    test('tournee en pause -> bandeau toujours affiche', () async {
      // Arbitrage du proprietaire : la pause ne masque plus le bandeau.
      // Noah coupe souvent son dej juste devant un client -- l'info reste
      // vraie, c'est lui qui decide s'il y va tout de suite.
      await demarrerTournee();
      await (db.update(db.tournees)..where((t) => t.id.equals(tId))).write(
        TourneesCompanion(pauseeLe: Value(DateTime(2026, 5, 30, 12))),
      );
      await insererProchainPlanifieLoin();
      final proche = await _insertStop(db, tId, lat: 48.0, lng: 1.0);

      final container = makeContainer(position: (lat: 48.0, lng: 1.0));
      final res =
          await _bandeauApresChargement(container, tId, stopsAttendus: 2);
      expect(res, isNotNull);
      expect(res!.plusProche.id, proche.id);
    });

    test('position absente (permission refusee / pas de fix) -> rien',
        () async {
      await demarrerTournee();
      await insererProchainPlanifieLoin();
      await _insertStop(db, tId, lat: 48.0, lng: 1.0);

      final container = makeContainer(position: null);
      final res =
          await _bandeauApresChargement(container, tId, stopsAttendus: 2);
      expect(res, isNull);
    });

    test('le plus proche est le prochain planifie -> on passe au suivant',
        () async {
      // `ProchainArretCard` affiche deja "PROCHAIN + 5 m" pour le premier
      // arret de la sequence : le bandeau ne le repete pas et annonce
      // l'autre arret a portee, que rien d'autre ne signale.
      await demarrerTournee();
      await _insertStop(db, tId, lat: 48.00005, lng: 1.0);
      final horsSequence = await _insertStop(db, tId, lat: 48.0003, lng: 1.0);

      final container = makeContainer(position: (lat: 48.0, lng: 1.0));
      final res =
          await _bandeauApresChargement(container, tId, stopsAttendus: 2);
      expect(res, isNotNull);
      expect(res!.plusProche.id, horsSequence.id);
      expect(res.autresCount, 0);
    });

    test('seul le prochain planifie est a proximite -> rien (doublon)',
        () async {
      await demarrerTournee();
      await _insertStop(db, tId, lat: 48.00005, lng: 1.0);

      final container = makeContainer(position: (lat: 48.0, lng: 1.0));
      final res =
          await _bandeauApresChargement(container, tId, stopsAttendus: 1);
      expect(res, isNull);
    });

    test('aucun arret dans le rayon -> rien', () async {
      await demarrerTournee();
      await _insertStop(db, tId, lat: 49.0, lng: 1.0);

      final container = makeContainer(position: (lat: 48.0, lng: 1.0));
      final res =
          await _bandeauApresChargement(container, tId, stopsAttendus: 1);
      expect(res, isNull);
    });
  });
}

/// Insere un arret et le relit (on a besoin de la data class `Stop`,
/// pas juste de son id).
Future<Stop> _insertStop(
  AppDatabase db,
  int tourneeId, {
  double? lat,
  double? lng,
  String statut = 'a_livrer',
  String? nomClient,
}) async {
  final id = await db.into(db.stops).insert(
        StopsCompanion.insert(
          tourneeId: tourneeId,
          adresseBrute: 'Adresse',
          lat: lat == null ? const Value.absent() : Value(lat),
          lng: lng == null ? const Value.absent() : Value(lng),
          statutLivraison: Value(statut),
          nomClient:
              nomClient == null ? const Value.absent() : Value(nomClient),
        ),
      );
  return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
}

/// Souscrit au bandeau (ce qui souscrit toute sa chaine de dependances),
/// attend que les 2 streams Drift aient emis, puis rend la valeur courante
/// du bandeau -- `null` voulant dire "rien a afficher".
///
/// Deux raisons a cette gymnastique :
/// - sans listener actif un provider est "auto-paused" : les streams dont
///   il depend ne sont jamais souscrits (meme constat que dans
///   `test/aujourdhui_resume_provider_test.dart`) ;
/// - le watch Drift n'est pas resolu de facon synchrone apres un insert :
///   sans attendre, on ne saurait pas distinguer "pas encore charge" de
///   "rien a afficher".
Future<ArretsProches?> _bandeauApresChargement(
  ProviderContainer container,
  int tourneeId, {
  required int stopsAttendus,
}) async {
  final subBandeau = container.listen(
    arretsProchesProvider(tourneeId),
    (_, _) {},
    fireImmediately: true,
  );
  final subTournee = container.listen(
    tourneeByIdProvider(tourneeId),
    (_, _) {},
    fireImmediately: true,
  );
  final subStops = container.listen(
    stopsByTourneeProvider(tourneeId),
    (_, _) {},
    fireImmediately: true,
  );
  try {
    await _pollUntil(() {
      final tournee = subTournee.read().asData?.value;
      final stops = subStops.read().asData?.value;
      return tournee != null && stops != null && stops.length == stopsAttendus;
    });
    return subBandeau.read();
  } finally {
    subBandeau.close();
    subTournee.close();
    subStops.close();
  }
}

/// Poll toutes les 20 ms jusqu'a ce que [pret] soit vrai, ou timeout.
Future<void> _pollUntil(
  bool Function() pret, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (pret()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw StateError('Timeout : condition jamais atteinte');
}
