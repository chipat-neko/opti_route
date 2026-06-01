import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:opti_route/data/route_service.dart';

// Complete route_service_test : headers, URL profil, parsing steps
// (way_points multi/skip), body coords order, et statuts d'erreur
// supplementaires.
void main() {
  final from = const LatLng(48.0, 1.0);
  final to = const LatLng(48.1, 1.1);

  String okBody({
    List<List<num>>? coords,
    List<Map<String, dynamic>>? steps,
  }) {
    return jsonEncode({
      'features': [
        {
          'geometry': {
            'type': 'LineString',
            'coordinates': coords ?? [
              [1.0, 48.0],
              [1.05, 48.05],
              [1.1, 48.1],
            ],
          },
          'properties': {
            'segments': [
              {
                'steps': steps ?? const [],
              },
            ],
          },
        },
      ],
    });
  }

  group('RouteService — headers et URL', () {
    test('URL contient le profil par defaut (driving-car)', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response(okBody(), 200);
      });
      await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(captured!.path,
          '/v2/directions/driving-car/geojson');
    });

    test('URL contient driving-hgv quand profil="driving-hgv"', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response(okBody(), 200);
      });
      await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to, profil: 'driving-hgv');
      expect(captured!.path, '/v2/directions/driving-hgv/geojson');
    });

    test('Authorization header contient la cle ORS', () async {
      String? auth;
      final mock = MockClient((req) async {
        auth = req.headers['Authorization'];
        return http.Response(okBody(), 200);
      });
      await RouteService(apiKey: 'MY_KEY_XYZ', client: mock)
          .fetchRoute(from: from, to: to);
      expect(auth, 'MY_KEY_XYZ');
    });

    test('Content-Type application/json', () async {
      String? ct;
      final mock = MockClient((req) async {
        ct = req.headers['Content-Type'];
        return http.Response(okBody(), 200);
      });
      await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(ct, contains('application/json'));
    });
  });

  group('RouteService — body', () {
    test('body coordinates : [lng, lat] dans cet ordre (GeoJSON)', () async {
      Map<String, dynamic>? body;
      final mock = MockClient((req) async {
        body = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(okBody(), 200);
      });
      await RouteService(apiKey: 'k', client: mock).fetchRoute(
        from: const LatLng(48.5, 1.5),
        to: const LatLng(48.6, 1.6),
      );
      expect(body!['coordinates'], [
        [1.5, 48.5],
        [1.6, 48.6],
      ]);
    });
  });

  group('RouteService — statuts d\'erreur', () {
    test('status 500 (serveur down) -> null', () async {
      final mock = MockClient((req) async => http.Response('err', 500));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r, isNull);
    });

    test('status 429 (quota) -> null', () async {
      final mock = MockClient((req) async => http.Response('quota', 429));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r, isNull);
    });

    test('top-level JSON pas un Map (string) -> null', () async {
      final mock =
          MockClient((req) async => http.Response(jsonEncode('hello'), 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r, isNull);
    });

    test('features list vide -> null', () async {
      final mock = MockClient(
          (req) async => http.Response(jsonEncode({'features': []}), 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r, isNull);
    });
  });

  group('RouteService — parsing coords degradees', () {
    test('coords mixtes (1 valide, 1 a 1 element) : skip degrade', () async {
      // Polyline a 2 LatLng minimum requise -> on en met 3 valides + 1
      // degrade que le service doit ignorer sans crasher.
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'coordinates': [
                [1.0, 48.0],
                [1.05], // a 1 element : skip
                [1.05, 48.05],
                [1.1, 48.1],
              ],
            },
            'properties': {'segments': []},
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r!.polyline, hasLength(3),
          reason: 'la coord a 1 element est skip, 3 valides restent');
    });
  });

  group('RouteService — parsing steps', () {
    test('step sans way_points : skip', () async {
      final body = okBody(steps: [
        {'instruction': 'Sans way_points', 'distance': 100, 'duration': 30},
      ]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r!.steps, isEmpty);
    });

    test('step avec way_points[1] hors limites : skip', () async {
      final body = okBody(steps: [
        {
          'instruction': 'X',
          'distance': 100,
          'duration': 30,
          'type': 1,
          'way_points': [0, 999], // 999 > polyline.length
        },
      ]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r!.steps, isEmpty);
    });

    test('plusieurs steps valides : parses', () async {
      final body = okBody(steps: [
        {
          'instruction': 'Tournez a droite',
          'distance': 100,
          'duration': 30,
          'type': 1,
          'way_points': [0, 1],
        },
        {
          'instruction': 'Arrivee',
          'distance': 50,
          'duration': 15,
          'type': 10,
          'way_points': [1, 2],
        },
      ]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r!.steps, hasLength(2));
      expect(r.steps[0].instruction, 'Tournez a droite');
      expect(r.steps[1].type, 10);
    });

    test('step avec instruction null : prend chaine vide', () async {
      final body = okBody(steps: [
        {
          'distance': 100,
          'duration': 30,
          'type': 1,
          'way_points': [0, 1],
        },
      ]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r!.steps.first.instruction, '');
    });
  });

  // Robustesse parsing externe (durcissement nuit 2026-06-01) : une coord
  // au type inattendu ne doit PAS faire perdre toute la route, et les
  // instructions accentuees doivent survivre (mojibake).
  group('RouteService — robustesse', () {
    test('coord avec String non parsable : skip sans perdre la route',
        () async {
      // Avant : ("abc" as num?) throw -> catch -> route entiere null.
      // Apres : _numToDouble("abc")=null -> coord skip, les 3 autres restent.
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'coordinates': [
                [1.0, 48.0],
                ['abc', 48.05], // type casse : skip
                [1.05, 48.05],
                [1.1, 48.1],
              ],
            },
            'properties': {'segments': []},
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r, isNotNull);
      expect(r!.polyline, hasLength(3));
    });

    test('coord en String numerique ("1.0") : toleree (parsee)', () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'coordinates': [
                ['1.0', '48.0'],
                ['1.1', '48.1'],
              ],
            },
            'properties': {'segments': []},
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r!.polyline, hasLength(2));
      expect(r.polyline.first.latitude, 48.0);
    });

    test('UTF-8 : instruction accentuee preservee (pas de mojibake)',
        () async {
      final jsonStr = jsonEncode({
        'features': [
          {
            'geometry': {
              'coordinates': [
                [1.0, 48.0],
                [1.05, 48.05],
                [1.1, 48.1],
              ],
            },
            'properties': {
              'segments': [
                {
                  'steps': [
                    {
                      'instruction': 'Tournez sur l\'Avenue de l\'Égliseé',
                      'distance': 100,
                      'duration': 30,
                      'type': 1,
                      'way_points': [0, 1],
                    },
                  ],
                },
              ],
            },
          },
        ],
      });
      final mock = MockClient(
        (req) async => http.Response.bytes(utf8.encode(jsonStr), 200),
      );
      final r = await RouteService(apiKey: 'k', client: mock)
          .fetchRoute(from: from, to: to);
      expect(r!.steps, hasLength(1));
      expect(r.steps.first.instruction, 'Tournez sur l\'Avenue de l\'Égliseé');
    });
  });
}
