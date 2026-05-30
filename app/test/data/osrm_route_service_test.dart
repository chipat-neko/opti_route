import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:opti_route/data/osrm_route_service.dart';

void main() {
  group('OsrmRouteService.fetchRoute', () {
    test('< 2 points : null sans appel reseau', () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      });
      final r = await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1)]);
      expect(r, isNull);
      expect(called, isFalse);
    });

    test('liste vide : null', () async {
      final mock = MockClient((req) async => http.Response('{}', 200));
      expect(await OsrmRouteService(client: mock).fetchRoute(const []),
          isNull);
    });

    test('reponse 200 valide : parse distance + duree', () async {
      final body = jsonEncode({
        'code': 'Ok',
        'routes': [
          {'distance': 12345.6, 'duration': 678.9},
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await OsrmRouteService(client: mock).fetchRoute(const [
        LatLng(48, 1),
        LatLng(48.01, 1.01),
      ]);
      expect(r, isNotNull);
      expect(r!.meters, 12346); // arrondi
      expect(r.seconds, 679);
    });

    test('URL : lng avant lat (WKT/OSRM standard)', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"routes": []}', 200);
      });
      await OsrmRouteService(client: mock).fetchRoute(const [
        LatLng(48.5, 1.5),
        LatLng(49.0, 2.0),
      ]);
      // Format attendu : "1.5,48.5;2.0,49.0"
      expect(captured!.path, contains('1.5,48.5;2.0,49.0'));
    });

    test('URL : overview=false + alternatives=false + steps=false (perf)',
        () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"routes": []}', 200);
      });
      await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1), LatLng(49, 2)]);
      expect(captured!.queryParameters['overview'], 'false');
      expect(captured!.queryParameters['alternatives'], 'false');
      expect(captured!.queryParameters['steps'], 'false');
    });

    test('User-Agent envoye', () async {
      String? ua;
      final mock = MockClient((req) async {
        ua = req.headers['User-Agent'];
        return http.Response('{"routes": []}', 200);
      });
      await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1), LatLng(49, 2)]);
      expect(ua, contains('opti_route'));
    });

    test('status 500 : null silencieux', () async {
      final mock = MockClient((req) async => http.Response('err', 500));
      final r = await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1), LatLng(49, 2)]);
      expect(r, isNull);
    });

    test('reseau down (throw) : null silencieux', () async {
      final mock = MockClient((req) async {
        throw Exception('connection refused');
      });
      final r = await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1), LatLng(49, 2)]);
      expect(r, isNull);
    });

    test('JSON non-Map : null', () async {
      final mock = MockClient(
          (req) async => http.Response(jsonEncode('hello'), 200));
      final r = await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1), LatLng(49, 2)]);
      expect(r, isNull);
    });

    test('routes absent : null', () async {
      final mock = MockClient(
          (req) async => http.Response(jsonEncode({'code': 'Ok'}), 200));
      final r = await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1), LatLng(49, 2)]);
      expect(r, isNull);
    });

    test('routes vide : null', () async {
      final mock = MockClient(
          (req) async => http.Response(jsonEncode({'routes': []}), 200));
      final r = await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1), LatLng(49, 2)]);
      expect(r, isNull);
    });

    test('distance null dans routes[0] : null', () async {
      final body = jsonEncode({
        'routes': [
          {'duration': 100.0},
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await OsrmRouteService(client: mock)
          .fetchRoute(const [LatLng(48, 1), LatLng(49, 2)]);
      expect(r, isNull);
    });

    test('3 waypoints OK', () async {
      Uri? captured;
      final body = jsonEncode({
        'routes': [{'distance': 5000.0, 'duration': 600.0}],
      });
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response(body, 200);
      });
      final r = await OsrmRouteService(client: mock).fetchRoute(const [
        LatLng(48, 1),
        LatLng(48.5, 1.5),
        LatLng(49, 2),
      ]);
      expect(r, isNotNull);
      expect(r!.meters, 5000);
      // 3 coords dans l'URL
      expect(captured!.path.split(';').length, 3);
    });
  });

  group('OsrmRouteResult', () {
    test('expose meters + seconds', () {
      const r = OsrmRouteResult(meters: 12345, seconds: 678);
      expect(r.meters, 12345);
      expect(r.seconds, 678);
    });
  });
}
