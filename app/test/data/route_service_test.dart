import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:opti_route/data/route_service.dart';

/// Tests du parsing JSON GeoJSON ORS de [RouteService] sans appel
/// reseau reel (mock via `http.testing.MockClient`).
void main() {
  group('RouteService.fetchRoute', () {
    test('reponse 200 valide -> RouteData{polyline, steps}', () async {
      final mock = MockClient((req) async {
        return http.Response(_validGeojson, 200, headers: {
          'content-type': 'application/json',
        });
      });
      final svc = RouteService(apiKey: 'fake-key', client: mock);
      final data = await svc.fetchRoute(
        from: const LatLng(48.0, 1.0),
        to: const LatLng(48.5, 1.5),
      );
      expect(data, isNotNull);
      expect(data!.polyline, hasLength(3));
      expect(data.polyline.first.latitude, closeTo(48.0, 0.001));
      expect(data.steps, hasLength(2));
      expect(data.steps.first.instruction,
          contains('Continuez'));
      // Pivot du 1er step = coord au way_points[1] = index 1 dans polyline.
      expect(data.steps.first.pivot.latitude,
          closeTo(data.polyline[1].latitude, 0.001));
    });

    test('HTTP 401 (cle invalide) -> null', () async {
      final mock = MockClient(
        (req) async => http.Response('{"error": "invalid key"}', 401),
      );
      final svc = RouteService(apiKey: 'bad-key', client: mock);
      final data = await svc.fetchRoute(
        from: const LatLng(48.0, 1.0),
        to: const LatLng(48.5, 1.5),
      );
      expect(data, isNull);
    });

    test('timeout -> null (swallow exception)', () async {
      final mock = MockClient((req) async {
        await Future<void>.delayed(const Duration(seconds: 20));
        return http.Response('', 200);
      });
      final svc = RouteService(apiKey: 'k', client: mock);
      // fetchRoute a un timeout interne de 15s. Le test doit se terminer
      // sans throw mais retourner null.
      final data = await svc.fetchRoute(
        from: const LatLng(48.0, 1.0),
        to: const LatLng(48.5, 1.5),
      );
      expect(data, isNull);
    }, timeout: const Timeout(Duration(seconds: 25)));

    test('JSON mal forme (features vide) -> null', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({'features': <Map<String, dynamic>>[]}),
          200,
        );
      });
      final svc = RouteService(apiKey: 'k', client: mock);
      final data = await svc.fetchRoute(
        from: const LatLng(48.0, 1.0),
        to: const LatLng(48.5, 1.5),
      );
      expect(data, isNull);
    });

    test('polyline < 2 coords -> null', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'features': [
              {
                'geometry': {
                  'coordinates': [
                    [1.0, 48.0],
                  ],
                },
                'properties': {'segments': []},
              },
            ],
          }),
          200,
        );
      });
      final svc = RouteService(apiKey: 'k', client: mock);
      final data = await svc.fetchRoute(
        from: const LatLng(48.0, 1.0),
        to: const LatLng(48.5, 1.5),
      );
      expect(data, isNull);
    });

    test('body inclut language=fr et instructions=true', () async {
      String? capturedBody;
      final mock = MockClient((req) async {
        capturedBody = req.body;
        return http.Response(_validGeojson, 200);
      });
      final svc = RouteService(apiKey: 'k', client: mock);
      await svc.fetchRoute(
        from: const LatLng(48.0, 1.0),
        to: const LatLng(48.5, 1.5),
      );
      final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(decoded['language'], 'fr');
      expect(decoded['instructions'], true);
    });

    test('eviterPeages=true ajoute options.avoid_features tollways',
        () async {
      String? capturedBody;
      final mock = MockClient((req) async {
        capturedBody = req.body;
        return http.Response(_validGeojson, 200);
      });
      final svc = RouteService(apiKey: 'k', client: mock);
      await svc.fetchRoute(
        from: const LatLng(48.0, 1.0),
        to: const LatLng(48.5, 1.5),
        eviterPeages: true,
      );
      final decoded = jsonDecode(capturedBody!) as Map<String, dynamic>;
      expect(decoded['options'], isA<Map<String, dynamic>>());
      expect(
        (decoded['options'] as Map<String, dynamic>)['avoid_features'],
        contains('tollways'),
      );
    });
  });
}

/// GeoJSON minimal mais valide pour les tests : 3 coords, 2 steps.
const _validGeojson = '''
{
  "features": [
    {
      "geometry": {
        "coordinates": [
          [1.0, 48.0],
          [1.25, 48.25],
          [1.5, 48.5]
        ]
      },
      "properties": {
        "segments": [
          {
            "steps": [
              {
                "distance": 100.0,
                "duration": 12.0,
                "instruction": "Continuez tout droit",
                "type": 6,
                "way_points": [0, 1]
              },
              {
                "distance": 50.0,
                "duration": 6.0,
                "instruction": "Tournez a droite",
                "type": 1,
                "way_points": [1, 2]
              }
            ]
          }
        ]
      }
    }
  ]
}
''';
