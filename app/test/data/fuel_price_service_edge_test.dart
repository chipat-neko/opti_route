import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/fuel_price_service.dart';

// Complete fuel_price_service_test : URL params, FuelPriceResult /
// FuelStation structure, lastUpdate fallback, trim, take(limit).
void main() {
  group('FuelPriceService.getAverageDieselPrice — URL', () {
    test('URL contient where, select, limit=100', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"results": []}', 200);
      });
      await FuelPriceService(client: mock).getAverageDieselPrice();
      expect(captured!.host, 'data.economie.gouv.fr');
      expect(captured!.queryParameters['where'],
          'code_departement="28"',
          reason: '28 = defaut Noah (Eure-et-Loir)');
      expect(captured!.queryParameters['select'],
          contains('gazole_prix'));
      expect(captured!.queryParameters['limit'], '100');
    });

    test('departement custom : "75" Paris', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"results": []}', 200);
      });
      await FuelPriceService(client: mock)
          .getAverageDieselPrice(departement: '75');
      expect(
        captured!.queryParameters['where'],
        'code_departement="75"',
      );
    });
  });

  group('FuelPriceService.getAverageDieselPrice — lastUpdate', () {
    test('prend la date la plus recente', () async {
      final body = jsonEncode({
        'results': [
          {'gazole_prix': 1.8, 'gazole_maj': '2026-05-01T10:00:00Z'},
          {'gazole_prix': 1.85, 'gazole_maj': '2026-05-29T10:00:00Z'},
          {'gazole_prix': 1.75, 'gazole_maj': '2026-05-15T10:00:00Z'},
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await FuelPriceService(client: mock).getAverageDieselPrice();
      expect(r, isNotNull);
      expect(r!.lastUpdate.year, 2026);
      expect(r.lastUpdate.month, 5);
      expect(r.lastUpdate.day, 29);
    });

    test('gazole_maj absent : fallback sur DateTime.now()', () async {
      final body = jsonEncode({
        'results': [
          {'gazole_prix': 1.8}, // pas de gazole_maj
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final beforeCall = DateTime.now().subtract(const Duration(seconds: 5));
      final r = await FuelPriceService(client: mock).getAverageDieselPrice();
      expect(r, isNotNull);
      expect(r!.lastUpdate.isAfter(beforeCall), isTrue);
    });
  });

  group('FuelPriceService.getAverageDieselPrice — FuelPriceResult', () {
    test('expose sampleSize + departement', () async {
      final body = jsonEncode({
        'results': [
          {'gazole_prix': 1.8},
          {'gazole_prix': 1.9},
          {'gazole_prix': 2.0},
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await FuelPriceService(client: mock)
          .getAverageDieselPrice(departement: '28');
      expect(r!.sampleSize, 3);
      expect(r.departement, '28');
      expect(r.averageEurPerLiter, closeTo(1.9, 0.001));
    });
  });

  group('FuelPriceService.findNearbyDieselStations — URL', () {
    test('URL utilise POINT(lng lat) dans cet ordre (WKT)', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"results": []}', 200);
      });
      await FuelPriceService(client: mock).findNearbyDieselStations(
        lat: 48.5,
        lng: 1.5,
        maxKm: 10,
      );
      // WKT POINT(lng lat) -> "POINT(1.5 48.5)"
      expect(captured!.queryParameters['where'],
          contains('POINT(1.5 48.5)'));
      expect(captured!.queryParameters['where'],
          contains('10km'));
      expect(captured!.queryParameters['where'],
          contains('gazole_prix is not null'));
    });
  });

  group('FuelPriceService.findNearbyDieselStations — FuelStation', () {
    test('parse station valide : id, address, cp, ville, lat, lng, prix, dist',
        () async {
      final body = jsonEncode({
        'results': [
          {
            'id': 'STAT001',
            'gazole_prix': 1.85,
            'gazole_maj': '2026-05-29T10:00:00Z',
            'cp': '28100',
            'ville': '  Dreux  ',
            'adresse': '  1 rue X  ',
            'geom': {'lat': 48.5, 'lon': 1.5},
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final stations = await FuelPriceService(client: mock)
          .findNearbyDieselStations(lat: 48.5, lng: 1.5);
      expect(stations, hasLength(1));
      final s = stations.first;
      expect(s.id, 'STAT001');
      expect(s.address, '1 rue X', reason: 'trim');
      expect(s.ville, 'Dreux', reason: 'trim');
      expect(s.codePostal, '28100');
      expect(s.dieselPriceEur, 1.85);
      expect(s.distanceKm, closeTo(0.0, 0.5),
          reason: 'meme point = 0 km');
    });

    test('limit applique apres tri par distance', () async {
      // 5 stations a distances differentes
      final body = jsonEncode({
        'results': [
          for (var i = 0; i < 5; i++)
            {
              'id': 'S$i',
              'gazole_prix': 1.8,
              'geom': {'lat': 48.5 + i * 0.01, 'lon': 1.5},
              'cp': '28100',
              'ville': 'V',
              'adresse': 'A',
            },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final stations = await FuelPriceService(client: mock)
          .findNearbyDieselStations(lat: 48.5, lng: 1.5, limit: 2, maxKm: 100);
      expect(stations, hasLength(2),
          reason: 'on limite a 2');
      // tri ascendant : la plus proche en premier
      expect(stations[0].id, 'S0');
      expect(stations[1].id, 'S1');
    });

    test('station hors maxKm defensif : exclue', () async {
      final body = jsonEncode({
        'results': [
          {
            'id': 'S0',
            'gazole_prix': 1.8,
            'geom': {'lat': 48.5, 'lon': 1.5},
            'cp': '28100', 'ville': 'V', 'adresse': 'A',
          },
          {
            'id': 'S1',
            'gazole_prix': 1.8,
            // 50km au nord -> hors maxKm=10
            'geom': {'lat': 48.95, 'lon': 1.5},
            'cp': '28100', 'ville': 'V', 'adresse': 'A',
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final stations = await FuelPriceService(client: mock)
          .findNearbyDieselStations(lat: 48.5, lng: 1.5, maxKm: 10);
      expect(stations, hasLength(1));
      expect(stations.first.id, 'S0');
    });

    test('prix > 5 EUR (saisie aberrante) : exclu', () async {
      final body = jsonEncode({
        'results': [
          {
            'id': 'S0',
            'gazole_prix': 9.99, // aberrant
            'geom': {'lat': 48.5, 'lon': 1.5},
            'cp': '28100', 'ville': 'V', 'adresse': 'A',
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final stations = await FuelPriceService(client: mock)
          .findNearbyDieselStations(lat: 48.5, lng: 1.5);
      expect(stations, isEmpty);
    });

    test('geom avec lat null : station ignoree', () async {
      final body = jsonEncode({
        'results': [
          {
            'id': 'S0',
            'gazole_prix': 1.8,
            'geom': {'lat': null, 'lon': 1.5},
            'cp': '28100', 'ville': 'V', 'adresse': 'A',
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final stations = await FuelPriceService(client: mock)
          .findNearbyDieselStations(lat: 48.5, lng: 1.5);
      expect(stations, isEmpty);
    });
  });
}
