import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/osrm_route_service.dart';
import 'package:opti_route/data/route_metrics_auto_updater.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTournee() {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 5, 30),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
          ),
        );
  }

  Future<Stop> seedStop(int tId, {double? lat, double? lng}) async {
    final id = await db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tId,
            adresseBrute: 'A',
            lat: lat != null ? Value(lat) : const Value.absent(),
            lng: lng != null ? Value(lng) : const Value.absent(),
          ),
        );
    return (db.select(db.stops)..where((s) => s.id.equals(id))).getSingle();
  }

  String okBody(int meters, int seconds) => jsonEncode({
        'routes': [
          {'distance': meters, 'duration': seconds},
        ],
      });

  group('RouteMetricsAutoUpdater.forceUpdate', () {
    test('parcours valide : DB updated avec meters + seconds', () async {
      final tId = await seedTournee();
      final s1 = await seedStop(tId, lat: 48.01, lng: 1.01);
      final s2 = await seedStop(tId, lat: 48.02, lng: 1.02);

      final osrm = OsrmRouteService(
        client: MockClient((req) async => http.Response(okBody(5000, 600), 200)),
      );
      final updater = RouteMetricsAutoUpdater(db: db, osrm: osrm);
      await updater.forceUpdate(tId, [s1, s2]);

      final t = await (db.select(db.tournees)..where((t) => t.id.equals(tId)))
          .getSingle();
      expect(t.distanceTotaleM, 5000);
      expect(t.dureeTotaleS, 600);
    });

    test('aucun stop geocode : pas d\'appel OSRM, pas d\'update DB',
        () async {
      final tId = await seedTournee();
      final s = await seedStop(tId, lat: null, lng: null);
      var called = false;
      final osrm = OsrmRouteService(
        client: MockClient((req) async {
          called = true;
          return http.Response(okBody(1, 1), 200);
        }),
      );
      final updater = RouteMetricsAutoUpdater(db: db, osrm: osrm);
      await updater.forceUpdate(tId, [s]);
      expect(called, isFalse);
      final t = await (db.select(db.tournees)..where((t) => t.id.equals(tId)))
          .getSingle();
      expect(t.distanceTotaleM, isNull);
    });

    test('OSRM retourne null (reseau down) : DB inchangee', () async {
      final tId = await seedTournee();
      // Pre-seed valeurs anciennes pour verifier qu'on ne les ecrase pas
      await (db.update(db.tournees)..where((t) => t.id.equals(tId)))
          .write(const TourneesCompanion(
        distanceTotaleM: Value(99999),
        dureeTotaleS: Value(8888),
      ));
      final s1 = await seedStop(tId, lat: 48.01, lng: 1.01);
      final s2 = await seedStop(tId, lat: 48.02, lng: 1.02);

      final osrm = OsrmRouteService(
        client: MockClient((req) async => http.Response('err', 500)),
      );
      final updater = RouteMetricsAutoUpdater(db: db, osrm: osrm);
      await updater.forceUpdate(tId, [s1, s2]);

      final t = await (db.select(db.tournees)..where((t) => t.id.equals(tId)))
          .getSingle();
      expect(t.distanceTotaleM, 99999, reason: 'pas ecrase si OSRM null');
      expect(t.dureeTotaleS, 8888);
    });

    test('tournee inexistante : no-op silencieux', () async {
      final osrm = OsrmRouteService(
        client: MockClient((req) async => http.Response(okBody(1, 1), 200)),
      );
      final updater = RouteMetricsAutoUpdater(db: db, osrm: osrm);
      await updater.forceUpdate(99999, []);
      // Pas de throw
    });

    test('depot + 1 stop : 2 waypoints suffisent (depot -> stop)', () async {
      final tId = await seedTournee();
      final s = await seedStop(tId, lat: 48.01, lng: 1.01);
      Uri? captured;
      final osrm = OsrmRouteService(
        client: MockClient((req) async {
          captured = req.url;
          return http.Response(okBody(1500, 180), 200);
        }),
      );
      final updater = RouteMetricsAutoUpdater(db: db, osrm: osrm);
      await updater.forceUpdate(tId, [s]);
      // 2 points dans l'URL : depot + stop
      expect(captured!.path.split(';').length, 2);
      final t = await (db.select(db.tournees)..where((t) => t.id.equals(tId)))
          .getSingle();
      expect(t.distanceTotaleM, 1500);
    });
  });

  group('RouteMetricsAutoUpdater.requestUpdate — debounce', () {
    test('plusieurs appels rapides : 1 seul appel OSRM apres debounce',
        () async {
      final tId = await seedTournee();
      final s = await seedStop(tId, lat: 48.01, lng: 1.01);

      var callCount = 0;
      final osrm = OsrmRouteService(
        client: MockClient((req) async {
          callCount++;
          return http.Response(okBody(1000, 100), 200);
        }),
      );
      final updater = RouteMetricsAutoUpdater(
        db: db,
        osrm: osrm,
        debounce: const Duration(milliseconds: 50),
      );
      // 5 appels rapides
      updater.requestUpdate(tId, [s]);
      updater.requestUpdate(tId, [s]);
      updater.requestUpdate(tId, [s]);
      updater.requestUpdate(tId, [s]);
      updater.requestUpdate(tId, [s]);
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(callCount, 1);
    });

    test('dispose annule un debounce en cours', () async {
      final tId = await seedTournee();
      final s = await seedStop(tId, lat: 48.01, lng: 1.01);
      var called = false;
      final osrm = OsrmRouteService(
        client: MockClient((req) async {
          called = true;
          return http.Response(okBody(1, 1), 200);
        }),
      );
      final updater = RouteMetricsAutoUpdater(
        db: db,
        osrm: osrm,
        debounce: const Duration(milliseconds: 100),
      );
      updater.requestUpdate(tId, [s]);
      updater.dispose();
      await Future<void>.delayed(const Duration(milliseconds: 200));
      expect(called, isFalse);
    });
  });
}
