import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cheapest_fuel.dart';

void main() {
  group('CheapestFuel.findCheapestNearby (#309)', () {
    test('aucune station -> null', () {
      expect(
        CheapestFuel.findCheapestNearby(
          around: (lat: 48, lng: 1),
          stations: const [],
        ),
        isNull,
      );
    });

    test('toutes hors rayon -> null', () {
      final out = CheapestFuel.findCheapestNearby(
        around: (lat: 48, lng: 1),
        stations: const [
          FuelStation(
              id: 'a',
              name: 'Total',
              lat: 49,
              lng: 1,
              pricePerLiter: 1.80),
        ],
        radiusMeters: 1000,
      );
      expect(out, isNull);
    });

    test('retourne la moins chere parmi les candidats du rayon', () {
      final out = CheapestFuel.findCheapestNearby(
        around: (lat: 48.0, lng: 1.0),
        stations: const [
          FuelStation(
              id: 'a',
              name: 'A',
              lat: 48.001,
              lng: 1.0,
              pricePerLiter: 1.90),
          FuelStation(
              id: 'b',
              name: 'B',
              lat: 48.002,
              lng: 1.0,
              pricePerLiter: 1.75),
          FuelStation(
              id: 'c',
              name: 'C loin',
              lat: 50,
              lng: 1.0,
              pricePerLiter: 1.50),
        ],
      );
      expect(out!.id, 'b');
    });
  });

  group('CheapestFuel.deltaPerLiter', () {
    test('negatif si moins cher', () {
      expect(
        CheapestFuel.deltaPerLiter(
          stationPrice: 1.75,
          referencePrice: 1.87,
        ),
        closeTo(-0.12, 0.001),
      );
    });
  });
}
