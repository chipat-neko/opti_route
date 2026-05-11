import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/geo_utils.dart';

void main() {
  group('GeoUtils.haversineMeters', () {
    test('meme point : 0', () {
      final d = GeoUtils.haversineMeters(
        lat1: 48.8566,
        lon1: 2.3522,
        lat2: 48.8566,
        lon2: 2.3522,
      );
      expect(d, 0);
    });

    test('Paris -> Lyon : ~393 km (a +/- 5 km pres)', () {
      final d = GeoUtils.haversineMeters(
        lat1: 48.8566, // Paris
        lon1: 2.3522,
        lat2: 45.7640, // Lyon
        lon2: 4.8357,
      );
      expect(d, closeTo(393000, 5000));
    });

    test('Dreux -> Chartres : ~35 km (a +/- 2 km pres)', () {
      final d = GeoUtils.haversineMeters(
        lat1: 48.737, // Dreux
        lon1: 1.366,
        lat2: 48.4467, // Chartres
        lon2: 1.4889,
      );
      expect(d, closeTo(35000, 2000));
    });

    test('symetrique : (A->B) == (B->A)', () {
      final ab = GeoUtils.haversineMeters(
        lat1: 48.0,
        lon1: 1.0,
        lat2: 48.5,
        lon2: 1.5,
      );
      final ba = GeoUtils.haversineMeters(
        lat1: 48.5,
        lon1: 1.5,
        lat2: 48.0,
        lon2: 1.0,
      );
      expect(ab, closeTo(ba, 0.001));
    });
  });

  group('GeoUtils.areClose', () {
    test('30 metres a une latitude donnee', () {
      // 30 metres = ~0.00027 degres a 48 N
      expect(
        GeoUtils.areClose(
          lat1: 48.0,
          lon1: 1.0,
          lat2: 48.0002, // ~22 m au nord
          lon2: 1.0,
        ),
        isTrue,
      );
      expect(
        GeoUtils.areClose(
          lat1: 48.0,
          lon1: 1.0,
          lat2: 48.001, // ~111 m au nord
          lon2: 1.0,
        ),
        isFalse,
      );
    });

    test('threshold custom', () {
      expect(
        GeoUtils.areClose(
          lat1: 48.0,
          lon1: 1.0,
          lat2: 48.001,
          lon2: 1.0,
          thresholdMeters: 200,
        ),
        isTrue,
      );
    });
  });
}
