import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/ban_geocoding_service.dart';
import 'package:opti_route/data/geocoding_service.dart';

void main() {
  group('BanGeocodingService.search', () {
    test('query < 3 chars : retourne liste vide sans appeler le reseau',
        () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      });
      final svc = BanGeocodingService(client: mock);
      final r = await svc.search('14');
      expect(r, isEmpty);
      expect(called, isFalse);
    });

    test('parse une FeatureCollection BAN valide', () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.366, 48.737],
            },
            'properties': {
              'type': 'housenumber',
              'label': '12 rue des Lilas 28100 Dreux',
              'housenumber': '12',
              'street': 'rue des Lilas',
              'postcode': '28100',
              'city': 'Dreux',
            },
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = BanGeocodingService(client: mock);
      final r = await svc.search('12 rue des Lilas');
      expect(r, hasLength(1));
      expect(r.first.lat, 48.737);
      expect(r.first.lon, 1.366);
      expect(r.first.houseNumber, '12');
      expect(r.first.road, 'rue des Lilas');
      expect(r.first.postcode, '28100');
      expect(r.first.city, 'Dreux');
      expect(r.first.country, 'France');
    });

    test('features sans label : filtre', () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.0, 48.0],
            },
            'properties': {
              'type': 'street',
              // pas de label
              'street': 'rue X',
            },
          },
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.5, 48.5],
            },
            'properties': {
              'label': 'rue valide',
              'street': 'rue valide',
            },
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = BanGeocodingService(client: mock);
      final r = await svc.search('rue');
      expect(r, hasLength(1));
      expect(r.first.displayName, 'rue valide');
    });

    test('status non 200 : throw GeocodingException', () async {
      final mock =
          MockClient((req) async => http.Response('err', 503));
      final svc = BanGeocodingService(client: mock);
      expect(svc.search('test rue'),
          throwsA(isA<GeocodingException>()));
    });

    test('housenumber null sur type != housenumber', () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.0, 48.0],
            },
            'properties': {
              'type': 'street',
              'label': 'rue X',
              'street': 'rue X',
              'housenumber': '12',
            },
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = BanGeocodingService(client: mock);
      final r = await svc.search('rue X');
      // Pour le type "street", on n'expose pas le numero (puisqu'il est
      // approximatif). Donc r.first.houseNumber doit etre null.
      expect(r.first.houseNumber, isNull);
    });

    test('providerKey vaut "ban"', () {
      final svc = BanGeocodingService(client: MockClient((_) async {
        return http.Response('{}', 200);
      }));
      expect(svc.providerKey, 'ban');
    });

    test('reverseGeocode : retourne le 1er feature decode', () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.366, 48.737],
            },
            'properties': {
              'type': 'housenumber',
              'label': '12 rue X 28100 Dreux',
              'housenumber': '12',
              'street': 'rue X',
              'postcode': '28100',
              'city': 'Dreux',
            },
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = BanGeocodingService(client: mock);
      final r = await svc.reverseGeocode(lat: 48.737, lng: 1.366);
      expect(r, isNotNull);
      expect(r!.displayName, '12 rue X 28100 Dreux');
      expect(r.houseNumber, '12');
    });

    test('reverseGeocode : null si features vide', () async {
      final body = jsonEncode({'features': []});
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = BanGeocodingService(client: mock);
      final r = await svc.reverseGeocode(lat: 48.0, lng: 1.0);
      expect(r, isNull);
    });

    test('reverseGeocode : throw GeocodingException sur 500', () async {
      final mock = MockClient((req) async => http.Response('err', 500));
      final svc = BanGeocodingService(client: mock);
      expect(
        svc.reverseGeocode(lat: 48.0, lng: 1.0),
        throwsA(isA<GeocodingException>()),
      );
    });

    test('features absent du JSON : retourne liste vide', () async {
      final body = jsonEncode({'type': 'FeatureCollection'});
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = BanGeocodingService(client: mock);
      final r = await svc.search('test rue');
      expect(r, isEmpty);
    });

    test('coordonnees inversees : lat=Y lon=X dans le GeoJSON', () async {
      // BAN renvoie coordinates = [lon, lat] dans le GeoJSON (norme).
      // Le service doit bien rebrandir : [0]=lon, [1]=lat.
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              // Paris : lon 2.3522, lat 48.8566
              'coordinates': [2.3522, 48.8566],
            },
            'properties': {
              'label': 'Paris',
              'street': 'P',
            },
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final svc = BanGeocodingService(client: mock);
      final r = await svc.search('paris');
      expect(r.first.lat, 48.8566);
      expect(r.first.lon, 2.3522);
    });
  });
}
