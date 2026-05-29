import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/photon_service.dart';

// Complete photon_service_test : URL params, headers, trim query,
// coords degradees, POI categories non encore couvertes (tourism,
// leisure, craft, healthcare, building, industrial), et displayName
// fallback.
void main() {
  String fakeBody(List<Map<String, dynamic>> features) {
    return jsonEncode({'features': features});
  }

  Map<String, dynamic> feature({
    List<num?>? coords,
    String? osmKey,
    String? name,
    String? street,
    String? postcode = '28100',
    String? city = 'Dreux',
    String? country = 'France',
    String? housenumber,
  }) {
    final props = <String, dynamic>{};
    if (osmKey != null) props['osm_key'] = osmKey;
    if (name != null) props['name'] = name;
    if (street != null) props['street'] = street;
    if (postcode != null) props['postcode'] = postcode;
    if (city != null) props['city'] = city;
    if (country != null) props['country'] = country;
    if (housenumber != null) props['housenumber'] = housenumber;
    return {
      'geometry': {'type': 'Point', 'coordinates': coords ?? [1.0, 48.0]},
      'properties': props,
    };
  }

  group('PhotonService — URL/headers', () {
    test('URL contient q + limit + lang', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"features": []}', 200);
      });
      await PhotonService(client: mock).search(
        'Garage X',
        limit: 7,
        acceptLanguage: 'fr',
      );
      expect(captured!.host, 'photon.komoot.io');
      expect(captured!.path, '/api');
      expect(captured!.queryParameters['q'], 'Garage X');
      expect(captured!.queryParameters['limit'], '7');
      expect(captured!.queryParameters['lang'], 'fr');
    });

    test('User-Agent contient "opti_route"', () async {
      String? ua;
      final mock = MockClient((req) async {
        ua = req.headers['User-Agent'];
        return http.Response('{"features": []}', 200);
      });
      await PhotonService(client: mock).search('test rue');
      expect(ua, contains('opti_route'));
    });
  });

  group('PhotonService — trim query', () {
    test('whitespace "  ab  " trim -> 2 chars -> rejette', () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{"features": []}', 200);
      });
      final r = await PhotonService(client: mock).search('  ab  ');
      expect(r, isEmpty);
      expect(called, isFalse);
    });
  });

  group('PhotonService — coords degradees', () {
    test('coordinates [null, null] : feature filtre', () async {
      final body = fakeBody([feature(coords: [null, null])]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await PhotonService(client: mock).search('rue X');
      expect(r, isEmpty);
    });

    test('coordinates < 2 elements : feature filtre', () async {
      final body = fakeBody([feature(coords: [1.0])]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await PhotonService(client: mock).search('rue X');
      expect(r, isEmpty);
    });

    test('geometry absent : feature filtre', () async {
      final body = jsonEncode({
        'features': [
          {'properties': {'name': 'X', 'osm_key': 'shop'}},
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await PhotonService(client: mock).search('rue X');
      expect(r, isEmpty);
    });
  });

  group('PhotonService — POI categories', () {
    final pois = ['tourism', 'leisure', 'craft', 'healthcare', 'building',
        'industrial'];
    for (final key in pois) {
      test('osm_key=$key : isPoi = true', () async {
        final body = fakeBody([
          feature(osmKey: key, name: 'POI $key', street: 'rue X'),
        ]);
        final mock = MockClient((req) async => http.Response(body, 200));
        final r = await PhotonService(client: mock).search('test');
        expect(r, hasLength(1));
        expect(r.first.isPoi, isTrue,
            reason: '$key doit etre dans _poiOsmKeys');
        expect(r.first.poiName, 'POI $key');
      });
    }

    test('osm_key=highway (non POI) : poiName null', () async {
      final body = fakeBody([
        feature(osmKey: 'highway', name: 'Boulevard X', street: 'Boulevard X'),
      ]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await PhotonService(client: mock).search('test');
      expect(r, hasLength(1));
      expect(r.first.isPoi, isFalse);
      expect(r.first.poiName, isNull);
    });
  });

  group('PhotonService — displayName fallback', () {
    test('POI sans street : displayName contient name + locality', () async {
      final body = fakeBody([
        feature(
          osmKey: 'shop',
          name: 'Carrefour Dreux',
          street: null,
        ),
      ]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await PhotonService(client: mock).search('Carrefour');
      expect(r.first.displayName, contains('Carrefour Dreux'));
      expect(r.first.displayName, contains('28100 Dreux'));
    });

    test('displayName contient le pays quand fourni', () async {
      final body = fakeBody([feature(street: 'rue X', country: 'France')]);
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await PhotonService(client: mock).search('rue');
      expect(r.first.displayName, contains('France'));
    });
  });
}
