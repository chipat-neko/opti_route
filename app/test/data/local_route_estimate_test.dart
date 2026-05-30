import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/local_route_estimate.dart';

// Tests de LocalRouteEstimate.compute (fonction pure, haversine + 30km/h).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<(Tournee, List<Stop>)> seed({
    required (double, double) depot,
    required List<({double? lat, double? lng})> specs,
  }) async {
    final tId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 5, 30),
            pointDepartLat: depot.$1,
            pointDepartLng: depot.$2,
            pointDepartLabel: 'D',
          ),
        );
    for (var i = 0; i < specs.length; i++) {
      await db.into(db.stops).insert(
            StopsCompanion.insert(
              tourneeId: tId,
              adresseBrute: 'A$i',
              lat: specs[i].lat != null
                  ? Value(specs[i].lat)
                  : const Value.absent(),
              lng: specs[i].lng != null
                  ? Value(specs[i].lng)
                  : const Value.absent(),
            ),
          );
    }
    final tournee =
        await (db.select(db.tournees)..where((t) => t.id.equals(tId)))
            .getSingle();
    final stops =
        await (db.select(db.stops)..where((s) => s.tourneeId.equals(tId))).get();
    return (tournee, stops);
  }

  group('LocalRouteEstimate.compute', () {
    test('0 stop : (0, 0)', () async {
      final (t, s) = await seed(depot: (48, 1), specs: []);
      final e = LocalRouteEstimate.compute(tournee: t, stops: s);
      expect(e.meters, 0);
      expect(e.seconds, 0);
    });

    test('tous stops sans coords : (0, 0)', () async {
      final (t, s) = await seed(
        depot: (48, 1),
        specs: [(lat: null, lng: null), (lat: null, lng: null)],
      );
      final e = LocalRouteEstimate.compute(tournee: t, stops: s);
      expect(e.meters, 0);
      expect(e.seconds, 0);
    });

    test('1 stop a ~1km : meters ~1000, seconds ~120 (30 km/h)', () async {
      // Depot (48, 1) -> stop (48.009, 1) = ~1 km nord
      final (t, s) = await seed(
        depot: (48, 1),
        specs: [(lat: 48.009, lng: 1)],
      );
      final e = LocalRouteEstimate.compute(tournee: t, stops: s);
      expect(e.meters, closeTo(1000, 100));
      // 1 km / 30 km/h = 120 s
      expect(e.seconds, closeTo(120, 20));
    });

    test('2 stops alignes : segments cumulent', () async {
      // Depot (48,1) -> stop A (48.009, 1) [1km] -> stop B (48.018, 1) [1km]
      // Total ~2 km
      final (t, s) = await seed(
        depot: (48, 1),
        specs: [(lat: 48.009, lng: 1), (lat: 48.018, lng: 1)],
      );
      final e = LocalRouteEstimate.compute(tournee: t, stops: s);
      expect(e.meters, closeTo(2000, 200));
    });

    test('stops sans coords ignores (mix avec geocodes)', () async {
      final (t, s) = await seed(
        depot: (48, 1),
        specs: [
          (lat: 48.009, lng: 1),
          (lat: null, lng: null), // ignore
          (lat: 48.018, lng: 1),
        ],
      );
      final e = LocalRouteEstimate.compute(tournee: t, stops: s);
      // = depot -> stop1 + stop1 -> stop3 = ~2 km
      expect(e.meters, closeTo(2000, 200));
    });

    test('avgSpeedKmh = 30 (constante metier)', () {
      expect(LocalRouteEstimate.avgSpeedKmh, 30);
    });
  });
}
