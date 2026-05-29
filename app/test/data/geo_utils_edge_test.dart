import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/geo_utils.dart';

// Cas-limites de geo_utils non couverts par geo_utils_test.dart :
// equateur, pole, antipodes, seuils stricts < / 0 / negatif.
void main() {
  group('GeoUtils.haversineMeters (cas-limites)', () {
    test('Equateur : 1 deg de longitude = ~111,2 km (R=6371 km)', () {
      final d = GeoUtils.haversineMeters(
        lat1: 0,
        lon1: 0,
        lat2: 0,
        lon2: 1,
      );
      expect(d, closeTo(111195, 500));
    });

    test('1 deg de latitude n\'importe ou = ~111,2 km', () {
      final d = GeoUtils.haversineMeters(
        lat1: 48,
        lon1: 0,
        lat2: 49,
        lon2: 0,
      );
      expect(d, closeTo(111195, 500));
    });

    test('Antipodaux (0,0) vs (0,180) = demi-circonference ~20015 km', () {
      final d = GeoUtils.haversineMeters(
        lat1: 0,
        lon1: 0,
        lat2: 0,
        lon2: 180,
      );
      expect(d, closeTo(20015000, 5000));
    });

    test('Meme point au pole nord : 0', () {
      final d = GeoUtils.haversineMeters(
        lat1: 90,
        lon1: 0,
        lat2: 90,
        lon2: 0,
      );
      expect(d, 0);
    });

    test('Pole nord vs pole sud : ~20015 km (demi-circonference)', () {
      final d = GeoUtils.haversineMeters(
        lat1: 90,
        lon1: 0,
        lat2: -90,
        lon2: 0,
      );
      expect(d, closeTo(20015000, 5000));
    });
  });

  group('GeoUtils.areClose (cas-limites de seuil)', () {
    test('threshold = 0 : meme point n\'est PAS close (strict <)', () {
      expect(
        GeoUtils.areClose(
          lat1: 48,
          lon1: 1,
          lat2: 48,
          lon2: 1,
          thresholdMeters: 0,
        ),
        isFalse,
      );
    });

    test('threshold negatif : jamais close', () {
      expect(
        GeoUtils.areClose(
          lat1: 48,
          lon1: 1,
          lat2: 48,
          lon2: 1,
          thresholdMeters: -1,
        ),
        isFalse,
      );
    });

    test('distance < threshold -> true ; distance > threshold -> false', () {
      // ~111 m pour 0.001 deg de latitude.
      expect(
        GeoUtils.areClose(
          lat1: 48,
          lon1: 1,
          lat2: 48.001,
          lon2: 1,
          thresholdMeters: 200,
        ),
        isTrue,
      );
      expect(
        GeoUtils.areClose(
          lat1: 48,
          lon1: 1,
          lat2: 48.001,
          lon2: 1,
          thresholdMeters: 50,
        ),
        isFalse,
      );
    });
  });
}
