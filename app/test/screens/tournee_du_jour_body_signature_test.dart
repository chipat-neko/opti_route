import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/screens/tournee_du_jour/body.dart';

import '../helpers/test_db.dart';

/// F25 volet 2 : `routeSignature` est ce qui decide si Body redemande
/// un recalcul OSRM. Elle ne doit dependre QUE de ce qui change le
/// trace (point de depart + coordonnees des arrets, dans l'ordre), et
/// surtout PAS des champs cosmetiques : sinon on rappelle OSRM pour un
/// arret passe en "livre" ou un nom de client corrige.
void main() {
  late AppDatabase db;
  late Tournee tournee;

  setUp(() async {
    db = makeTestDb();
    final id = await seedTournee(db);
    tournee = await (db.select(db.tournees)..where((t) => t.id.equals(id)))
        .getSingle();
  });

  tearDown(() async {
    await db.close();
  });

  Future<Stop> seedStop({double? lat, double? lng}) async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tournee.id,
            adresseBrute: 'A',
            lat: Value(lat),
            lng: Value(lng),
          ),
        );
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  group('routeSignature', () {
    test('champs cosmetiques : signature inchangee', () async {
      final s1 = await seedStop(lat: 48.01, lng: 1.01);
      final s2 = await seedStop(lat: 48.02, lng: 1.02);
      final avant = routeSignature(tournee, [s1, s2]);

      // Tout ce qui n'entre pas dans le calcul OSRM.
      final s1bis = s1.copyWith(
        nomClient: const Value('Dupont'),
        nbColis: 42,
        statutLivraison: 'livre',
        priorite: 'haute',
        notes: const Value('sonner 2 fois'),
        positionLocked: true,
      );
      expect(routeSignature(tournee, [s1bis, s2]), avant);
    });

    test('ordre des arrets inverse : signature differente', () async {
      final s1 = await seedStop(lat: 48.01, lng: 1.01);
      final s2 = await seedStop(lat: 48.02, lng: 1.02);
      expect(
        routeSignature(tournee, [s2, s1]),
        isNot(routeSignature(tournee, [s1, s2])),
      );
    });

    test('coordonnees d\'un arret modifiees : signature differente',
        () async {
      final s1 = await seedStop(lat: 48.01, lng: 1.01);
      final avant = routeSignature(tournee, [s1]);
      final deplace = s1.copyWith(lat: const Value(48.5));
      expect(routeSignature(tournee, [deplace]), isNot(avant));
    });

    test('point de depart deplace : signature differente', () async {
      final s1 = await seedStop(lat: 48.01, lng: 1.01);
      final avant = routeSignature(tournee, [s1]);
      final autreDepot = tournee.copyWith(pointDepartLat: 49.0);
      expect(routeSignature(autreDepot, [s1]), isNot(avant));
    });

    test('arret non geocode : ignore (filtre aussi cote service)',
        () async {
      final s1 = await seedStop(lat: 48.01, lng: 1.01);
      final sansCoords = await seedStop();
      expect(
        routeSignature(tournee, [s1, sansCoords]),
        routeSignature(tournee, [s1]),
      );
    });

    test('ajout d\'un arret geocode : signature differente', () async {
      final s1 = await seedStop(lat: 48.01, lng: 1.01);
      final s2 = await seedStop(lat: 48.02, lng: 1.02);
      expect(
        routeSignature(tournee, [s1, s2]),
        isNot(routeSignature(tournee, [s1])),
      );
    });

    test('meme liste, deux appels : signature stable', () async {
      final s1 = await seedStop(lat: 48.01, lng: 1.01);
      expect(routeSignature(tournee, [s1]), routeSignature(tournee, [s1]));
    });
  });
}
