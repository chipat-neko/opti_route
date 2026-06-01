import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/overpass_poi_service.dart';

http.Response _resp200(Map<String, dynamic> json) => http.Response(
      jsonEncode(json),
      200,
      headers: const {'content-type': 'application/json'},
    );

void main() {
  group('OverpassException', () {
    test('toString = "OverpassException: \$message"', () {
      expect(
        const OverpassException('boom').toString(),
        'OverpassException: boom',
      );
    });
  });

  group('PoiCategory + catalogue', () {
    test('PoiCategory stocke ses 3 champs', () {
      const c = PoiCategory(label: 'X', iconName: 'i', tagFilter: 't');
      expect(c.label, 'X');
      expect(c.iconName, 'i');
      expect(c.tagFilter, 't');
    });

    test('catalogue contient les categories standards', () {
      final cats = OverpassPoiService.categories;
      for (final k in const [
        'pharmacie',
        'boulangerie',
        'supermarche',
        'restaurant',
        'station_service',
        'parking',
      ]) {
        expect(cats.containsKey(k), isTrue, reason: 'manque $k');
      }
      expect(cats['pharmacie']!.tagFilter, contains('amenity'));
      expect(cats['boulangerie']!.tagFilter, contains('shop'));
    });
  });

  group('OverpassPoiService.searchNearby', () {
    test('catégorie inconnue -> OverpassException', () async {
      final svc = OverpassPoiService(
        client: MockClient((_) async => _resp200({'elements': const []})),
      );
      await expectLater(
        svc.searchNearby(
          categoryKey: 'inconnue',
          centerLat: 48.0,
          centerLng: 1.0,
        ),
        throwsA(isA<OverpassException>()),
      );
    });

    test('parse les nodes + tri par distance + filtre name absent', () async {
      final svc = OverpassPoiService(
        client: MockClient((_) async => _resp200({
              'elements': [
                {
                  'type': 'node',
                  'lat': 48.5,
                  'lon': 1.5,
                  'tags': {'name': 'Loin'},
                },
                {
                  'type': 'node',
                  'lat': 48.001,
                  'lon': 1.001,
                  'tags': {'name': 'Proche', 'addr:street': 'rue X'},
                },
                {
                  // sans name -> ignore
                  'type': 'node',
                  'lat': 48.0,
                  'lon': 1.0,
                  'tags': {'addr:street': 'sans nom'},
                },
              ],
            })),
      );
      final r = await svc.searchNearby(
        categoryKey: 'pharmacie',
        centerLat: 48.0,
        centerLng: 1.0,
      );
      expect(r.length, 2);
      expect(r.first.poiName, 'Proche');
      expect(r.last.poiName, 'Loin');
    });

    test('way avec center -> extrait center.lat/lon', () async {
      final svc = OverpassPoiService(
        client: MockClient((_) async => _resp200({
              'elements': [
                {
                  'type': 'way',
                  'center': {'lat': 48.01, 'lon': 1.01},
                  'tags': {'name': 'Super U'},
                },
              ],
            })),
      );
      final r = await svc.searchNearby(
        categoryKey: 'supermarche',
        centerLat: 48.0,
        centerLng: 1.0,
      );
      expect(r.length, 1);
      expect(r.first.lat, 48.01);
      expect(r.first.lon, 1.01);
      expect(r.first.poiName, 'Super U');
    });

    test('statut HTTP 500 -> OverpassException', () async {
      final svc = OverpassPoiService(
        client: MockClient((_) async => http.Response('erreur serveur', 500)),
      );
      await expectLater(
        svc.searchNearby(
          categoryKey: 'pharmacie',
          centerLat: 48.0,
          centerLng: 1.0,
        ),
        throwsA(isA<OverpassException>()),
      );
    });

    test('JSON invalide -> OverpassException', () async {
      final svc = OverpassPoiService(
        client: MockClient((_) async => http.Response('pas du json', 200)),
      );
      await expectLater(
        svc.searchNearby(
          categoryKey: 'pharmacie',
          centerLat: 48.0,
          centerLng: 1.0,
        ),
        throwsA(isA<OverpassException>()),
      );
    });

    test('liste elements vide -> []', () async {
      final svc = OverpassPoiService(
        client: MockClient(
          (_) async => _resp200(const {'elements': <Object?>[]}),
        ),
      );
      final r = await svc.searchNearby(
        categoryKey: 'pharmacie',
        centerLat: 48.0,
        centerLng: 1.0,
      );
      expect(r, isEmpty);
    });
  });

  // Robustesse parsing externe (durcissement nuit 2026-06-01) : un schema
  // OSM inattendu ne doit pas faire planter toute la recherche, et les
  // noms accentues doivent survivre (mojibake).
  group('OverpassPoiService — robustesse', () {
    test('tags=List et name numerique -> elements ignores, pas de crash',
        () async {
      final svc = OverpassPoiService(
        client: MockClient((_) async => _resp200({
              'elements': [
                {'type': 'node', 'lat': 48.0, 'lon': 1.0, 'tags': <Object?>[]},
                {
                  'type': 'node',
                  'lat': 48.001,
                  'lon': 1.001,
                  'tags': {'name': 12345}, // name numerique -> ignore
                },
                {
                  'type': 'node',
                  'lat': 48.002,
                  'lon': 1.002,
                  'tags': {'name': 'Valide'},
                },
              ],
            })),
      );
      final r = await svc.searchNearby(
        categoryKey: 'pharmacie',
        centerLat: 48.0,
        centerLng: 1.0,
      );
      // Seul l'element valide survit ; les 2 malformes sont ignores.
      expect(r, hasLength(1));
      expect(r.first.poiName, 'Valide');
    });

    test('UTF-8 : nom de POI accentue preserve (pas de mojibake)', () async {
      final jsonStr = jsonEncode({
        'elements': [
          {
            'type': 'node',
            'lat': 48.01,
            'lon': 1.01,
            'tags': {'name': 'Boulangerie Pâtisserie Léa'},
          },
        ],
      });
      final svc = OverpassPoiService(
        // Vrais octets UTF-8 sans charset -> l'ancien code (latin1)
        // produisait du mojibake ; utf8.decode(bodyBytes) preserve.
        client: MockClient(
          (_) async => http.Response.bytes(utf8.encode(jsonStr), 200),
        ),
      );
      final r = await svc.searchNearby(
        categoryKey: 'boulangerie',
        centerLat: 48.0,
        centerLng: 1.0,
      );
      expect(r, hasLength(1));
      expect(r.first.poiName, 'Boulangerie Pâtisserie Léa');
    });
  });
}
