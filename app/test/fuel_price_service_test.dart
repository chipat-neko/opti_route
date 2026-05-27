// Tests pour FuelPriceService : appels API data.gouv.fr pour prix
// Diesel moyen + stations proches (carte Trello #39 V1 + V4).
//
// Mocke `http.Client` pour ne pas dependre du reseau / API publique
// (qui peut etre lente ou en panne). Couvre les cas heureux + erreurs
// reseau + stations sans gazole + filtres aberrants.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/fuel_price_service.dart';

void main() {
  group('FuelPriceService.getAverageDieselPrice', () {
    test('moyenne sur 3 stations valides', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'results': [
              {'gazole_prix': 1.700, 'gazole_maj': '2026-05-27T08:00:00Z'},
              {'gazole_prix': 1.800, 'gazole_maj': '2026-05-27T09:00:00Z'},
              {'gazole_prix': 1.750, 'gazole_maj': '2026-05-27T07:00:00Z'},
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final svc = FuelPriceService(client: client);

      final result = await svc.getAverageDieselPrice(departement: '28');
      expect(result, isNotNull);
      expect(result!.averageEurPerLiter, closeTo(1.750, 0.001));
      expect(result.sampleSize, 3);
      expect(result.departement, '28');
      // Plus recente des 3 maj : 09:00 UTC.
      expect(result.lastUpdate.toUtc(),
          DateTime.utc(2026, 5, 27, 9, 0, 0));

      svc.dispose();
    });

    test('stations sans gazole_prix : ignorees', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'results': [
              {'gazole_prix': 1.700},
              {'gazole_prix': null}, // station electrique pure
              {'gazole_prix': 1.800},
            ],
          }),
          200,
        );
      });
      final svc = FuelPriceService(client: client);

      final result = await svc.getAverageDieselPrice();
      expect(result!.sampleSize, 2);
      expect(result.averageEurPerLiter, closeTo(1.750, 0.001));

      svc.dispose();
    });

    test('filtre defensif : prix < 0.5 ou > 5 EUR exclus', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'results': [
              {'gazole_prix': 1.750},
              {'gazole_prix': 0.10}, // erreur saisie
              {'gazole_prix': 99.0}, // erreur saisie
              {'gazole_prix': 1.800},
            ],
          }),
          200,
        );
      });
      final svc = FuelPriceService(client: client);

      final result = await svc.getAverageDieselPrice();
      expect(result!.sampleSize, 2);
      expect(result.averageEurPerLiter, closeTo(1.775, 0.001));

      svc.dispose();
    });

    test('aucun resultat : retourne null', () async {
      final client = MockClient((req) async {
        return http.Response(jsonEncode({'results': []}), 200);
      });
      final svc = FuelPriceService(client: client);
      expect(await svc.getAverageDieselPrice(), isNull);
      svc.dispose();
    });

    test('status code != 200 : retourne null', () async {
      final client = MockClient((req) async {
        return http.Response('Internal Server Error', 500);
      });
      final svc = FuelPriceService(client: client);
      expect(await svc.getAverageDieselPrice(), isNull);
      svc.dispose();
    });

    test('exception reseau : retourne null (best-effort)', () async {
      final client = MockClient((req) async {
        throw Exception('reseau down');
      });
      final svc = FuelPriceService(client: client);
      expect(await svc.getAverageDieselPrice(), isNull);
      svc.dispose();
    });
  });

  group('FuelPriceService.findNearbyDieselStations', () {
    test('round-trip station + distance haversine calculee', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 'st1',
                'gazole_prix': 1.752,
                'gazole_maj': '2026-05-27T08:00:00Z',
                'cp': '28000',
                'ville': 'Chartres',
                'adresse': '12 rue X',
                // geom = geo_point_2d : objet {lat, lon}.
                'geom': {'lat': 48.4471, 'lon': 1.4885},
              },
            ],
          }),
          200,
        );
      });
      final svc = FuelPriceService(client: client);

      // Position de test = meme point que la station -> distance ~0.
      final stations = await svc.findNearbyDieselStations(
        lat: 48.4471,
        lng: 1.4885,
        maxKm: 10,
      );
      expect(stations, hasLength(1));
      expect(stations.first.id, 'st1');
      expect(stations.first.dieselPriceEur, closeTo(1.752, 0.001));
      expect(stations.first.distanceKm, closeTo(0.0, 0.01));
      expect(stations.first.ville, 'Chartres');
      expect(stations.first.address, '12 rue X');

      svc.dispose();
    });

    test('tri par distance croissante + limit applique', () async {
      // 3 stations : tres proche, moyennement proche, plus loin.
      // L'API renvoie dans le desordre, on attend tri.
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 'loin',
                'gazole_prix': 1.700,
                'cp': '28',
                'ville': 'X',
                'adresse': 'X',
                // 0.1 deg latitude ~= 11 km.
                'geom': {'lat': 48.55, 'lon': 1.4885},
              },
              {
                'id': 'proche',
                'gazole_prix': 1.800,
                'cp': '28',
                'ville': 'X',
                'adresse': 'X',
                'geom': {'lat': 48.4471, 'lon': 1.4885},
              },
              {
                'id': 'moyenne',
                'gazole_prix': 1.750,
                'cp': '28',
                'ville': 'X',
                'adresse': 'X',
                // 0.05 deg latitude ~= 5.5 km.
                'geom': {'lat': 48.50, 'lon': 1.4885},
              },
            ],
          }),
          200,
        );
      });
      final svc = FuelPriceService(client: client);

      final stations = await svc.findNearbyDieselStations(
        lat: 48.4471,
        lng: 1.4885,
        maxKm: 50,
        limit: 2,
      );
      expect(stations, hasLength(2));
      expect(stations.map((s) => s.id).toList(), ['proche', 'moyenne']);
      expect(stations.first.distanceKm,
          lessThan(stations.last.distanceKm));

      svc.dispose();
    });

    test('exception reseau : retourne liste vide (pas de throw)',
        () async {
      final client = MockClient((req) async {
        throw Exception('reseau down');
      });
      final svc = FuelPriceService(client: client);
      final stations = await svc.findNearbyDieselStations(
        lat: 48.0,
        lng: 1.0,
      );
      expect(stations, isEmpty);
      svc.dispose();
    });

    test('station sans geom : ignoree', () async {
      final client = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'id': 'good',
                'gazole_prix': 1.75,
                'cp': '28',
                'ville': 'X',
                'adresse': 'X',
                'geom': {'lat': 48.0, 'lon': 1.0},
              },
              {
                'id': 'no-geom',
                'gazole_prix': 1.80,
                'cp': '28',
                'ville': 'X',
                'adresse': 'X',
                'geom': null,
              },
            ],
          }),
          200,
        );
      });
      final svc = FuelPriceService(client: client);
      final stations = await svc.findNearbyDieselStations(
        lat: 48.0,
        lng: 1.0,
        maxKm: 10,
      );
      expect(stations, hasLength(1));
      expect(stations.first.id, 'good');
      svc.dispose();
    });
  });

  group('FuelStation.displayLabel', () {
    FuelStation makeStation({String name = '', String address = ''}) {
      return FuelStation(
        id: '',
        name: name,
        address: address,
        codePostal: '28000',
        ville: 'Chartres',
        lat: 48.0,
        lng: 1.0,
        dieselPriceEur: 1.75,
        distanceKm: 1.2,
        lastUpdate: DateTime(2026, 1, 1),
      );
    }

    test('name vide -> retourne adresse', () {
      expect(makeStation(address: '12 rue X').displayLabel, '12 rue X');
    });

    test('name + adresse -> "name · adresse"', () {
      expect(
        makeStation(name: 'TOTAL', address: '12 rue X').displayLabel,
        'TOTAL · 12 rue X',
      );
    });

    test('name vide + adresse vide -> ville', () {
      expect(makeStation().displayLabel, 'Chartres');
    });
  });
}
