import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/photon_service.dart';

void main() {
  group('PhotonService.search', () {
    test('query < 3 chars : retourne liste vide sans appel', () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      });
      final svc = PhotonService(client: mock);
      final r = await svc.search('ca');
      expect(r, isEmpty);
      expect(called, isFalse);
    });

    test('parse une enseigne (osm_key = shop) -> poiName rempli',
        () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.366, 48.737],
            },
            'properties': {
              'osm_key': 'shop',
              'osm_value': 'supermarket',
              'name': 'Carrefour Dreux',
              'street': 'avenue de la Gare',
              'housenumber': '4',
              'postcode': '28100',
              'city': 'Dreux',
              'country': 'France',
            },
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = PhotonService(client: mock);
      final r = await svc.search('carrefour dreux');
      expect(r, hasLength(1));
      expect(r.first.poiName, 'Carrefour Dreux');
      expect(r.first.lat, 48.737);
      expect(r.first.lon, 1.366);
      expect(r.first.isPoi, isTrue);
    });

    test('adresse pure (osm_key = place) -> poiName null', () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.5, 48.5],
            },
            'properties': {
              'osm_key': 'place',
              'name': 'Dreux',
              'city': 'Dreux',
              'country': 'France',
            },
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = PhotonService(client: mock);
      final r = await svc.search('Dreux');
      expect(r, hasLength(1));
      expect(r.first.isPoi, isFalse);
    });

    test('providerKey vaut "photon"', () {
      final svc = PhotonService(client: MockClient((_) async {
        return http.Response('{}', 200);
      }));
      expect(svc.providerKey, 'photon');
    });
  });
}
