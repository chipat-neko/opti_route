import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/ban_geocoding_service.dart';
import 'package:opti_route/data/geocoding_service.dart';

// Complete ban_geocoding_service_test : defenses contre les payloads
// degradees (coords nulles, geometry manquante, top-level pas Map),
// trim de query, headers et params dans l'URL.
void main() {
  group('BanGeocodingService.search — defenses', () {
    test('coordinates [null, null] : feature filtre', () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [null, null],
            },
            'properties': {'label': 'rue X', 'street': 'rue X'},
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await BanGeocodingService(client: mock).search('rue X');
      expect(r, isEmpty);
    });

    test('coordinates < 2 elements : feature filtre', () async {
      final body = jsonEncode({
        'features': [
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.0], // pas de lat
            },
            'properties': {'label': 'rue X', 'street': 'rue X'},
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await BanGeocodingService(client: mock).search('rue X');
      expect(r, isEmpty);
    });

    test('geometry manquant : feature filtre', () async {
      final body = jsonEncode({
        'features': [
          {
            'properties': {'label': 'rue X', 'street': 'rue X'},
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await BanGeocodingService(client: mock).search('rue X');
      expect(r, isEmpty);
    });

    test('top-level JSON pas un Map : throw GeocodingException', () async {
      final mock = MockClient(
          (req) async => http.Response(jsonEncode('hello world'), 200));
      expect(
        BanGeocodingService(client: mock).search('rue X'),
        throwsA(isA<GeocodingException>()),
      );
    });

    test('query whitespace seulement : empty sans appel reseau', () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      });
      final r = await BanGeocodingService(client: mock).search('   ');
      expect(r, isEmpty);
      expect(called, isFalse);
    });

    test('query trimmee avant la limite de 3 chars', () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{"features": []}', 200);
      });
      // "  ab  " trim -> "ab" (2 chars) -> rejete sans appel
      final r = await BanGeocodingService(client: mock).search('  ab  ');
      expect(r, isEmpty);
      expect(called, isFalse);
    });

    test('headers User-Agent envoye', () async {
      String? uaCapture;
      final mock = MockClient((req) async {
        uaCapture = req.headers['User-Agent'];
        return http.Response('{"features": []}', 200);
      });
      await BanGeocodingService(client: mock).search('test rue');
      expect(uaCapture, isNotNull);
      expect(uaCapture, contains('opti_route'));
    });

    test('URL contient bien les params q + limit + autocomplete', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"features": []}', 200);
      });
      await BanGeocodingService(client: mock).search('12 rue X', limit: 5);
      expect(captured!.host, 'api-adresse.data.gouv.fr');
      expect(captured!.path, '/search/');
      expect(captured!.queryParameters['q'], '12 rue X');
      expect(captured!.queryParameters['limit'], '5');
      expect(captured!.queryParameters['autocomplete'], '1');
    });

    test('multiples features valides : conservees', () async {
      final body = jsonEncode({
        'features': List.generate(
          3,
          (i) => {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.0 + i * 0.1, 48.0 + i * 0.1],
            },
            'properties': {
              'label': 'rue ${String.fromCharCode(65 + i)}',
              'street': 'rue ${String.fromCharCode(65 + i)}',
            },
          },
        ),
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await BanGeocodingService(client: mock).search('rue');
      expect(r, hasLength(3));
    });
  });

  group('BanGeocodingService.reverseGeocode — defenses', () {
    test('raw pas un Map : null', () async {
      final mock = MockClient(
          (req) async => http.Response(jsonEncode([]), 200));
      final r = await BanGeocodingService(client: mock)
          .reverseGeocode(lat: 48.0, lng: 1.0);
      expect(r, isNull);
    });

    test('features pas une List : null', () async {
      final body = jsonEncode({'features': 'pas une liste'});
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await BanGeocodingService(client: mock)
          .reverseGeocode(lat: 48.0, lng: 1.0);
      expect(r, isNull);
    });

    test('URL params lat/lon dans l\'URL reverseGeocode', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"features": []}', 200);
      });
      await BanGeocodingService(client: mock)
          .reverseGeocode(lat: 48.5, lng: 1.5);
      expect(captured!.path, '/reverse/');
      expect(captured!.queryParameters['lat'], '48.5');
      expect(captured!.queryParameters['lon'], '1.5');
      expect(captured!.queryParameters['limit'], '1');
    });
  });
}
