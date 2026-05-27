import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/chef_carte_service.dart';
import 'package:opti_route/data/database.dart';

/// Tests de la fonction pure [ChefCarteJour.computeFromBundle] (epopee
/// #88, [#88·3]) : depots (1 par tournee) + stops geolocalises, les
/// arrets sans coordonnees etant ignores.
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTournee({
    required String nom,
    double lat = 48.45,
    double lng = 1.49,
  }) {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: nom,
            date: DateTime.now(),
            pointDepartLat: lat,
            pointDepartLng: lng,
            pointDepartLabel: 'Depot $nom',
            statut: const Value('en_cours'),
          ),
        );
  }

  Future<void> seedStop(
    int tourneeId, {
    double? lat,
    double? lng,
    String statut = 'a_livrer',
  }) async {
    final sId = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: 'A',
            lat: Value(lat),
            lng: Value(lng),
          ),
        );
    if (statut != 'a_livrer') {
      final row = await (db.select(db.stops)
            ..where((s) => s.id.equals(sId)))
          .getSingle();
      await db.update(db.stops).replace(
            row.copyWith(statutLivraison: statut),
          );
    }
  }

  Future<ChefCarteJour> compute() async {
    final tournees = await db.select(db.tournees).get();
    final stops = await db.select(db.stops).get();
    return ChefCarteJour.computeFromBundle(
      tournees: tournees,
      stops: stops,
    );
  }

  test('vide -> empty', () {
    final c = ChefCarteJour.computeFromBundle(
      tournees: const [],
      stops: const [],
    );
    expect(c.isEmpty, isTrue);
  });

  test('1 depot par tournee', () async {
    await seedTournee(nom: 'A', lat: 48.0, lng: 1.0);
    await seedTournee(nom: 'B', lat: 49.0, lng: 2.0);

    final c = await compute();
    expect(c.nbDepots, 2);
    expect(c.nbStops, 0);
    final depots =
        c.points.where((p) => p.type == ChefPointType.depot).toList();
    expect(depots.map((d) => d.label).toSet(), {'A', 'B'});
  });

  test('stops geolocalises inclus, non geocodes ignores', () async {
    final t = await seedTournee(nom: 'T');
    await seedStop(t, lat: 48.46, lng: 1.50, statut: 'livre');
    await seedStop(t, lat: 48.47, lng: 1.51, statut: 'echec');
    await seedStop(t); // pas de coords -> ignore

    final c = await compute();
    expect(c.nbStops, 2);
    final statuts = c.points
        .where((p) => p.type == ChefPointType.stop)
        .map((p) => p.statut)
        .toSet();
    expect(statuts, {'livre', 'echec'});
  });

  test('coordonnees du depot remontees correctement', () async {
    await seedTournee(nom: 'T', lat: 48.123, lng: 1.456);
    final c = await compute();
    final depot =
        c.points.firstWhere((p) => p.type == ChefPointType.depot);
    expect(depot.lat, 48.123);
    expect(depot.lng, 1.456);
  });
}
