import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/tournee_realtime_service.dart';

// Tests des data classes PURES PresenceDelta + LivePosition (jalons
// 3.C/3.E). Pas de sync touche : juste structure / constructeurs.
void main() {
  group('PresenceDelta', () {
    test('expose userCloudId + isJoin (join=true)', () {
      const d = PresenceDelta(
        userCloudId: 'u-1234',
        isJoin: true,
      );
      expect(d.userCloudId, 'u-1234');
      expect(d.isJoin, isTrue);
    });

    test('isJoin=false (leave)', () {
      const d = PresenceDelta(
        userCloudId: 'u-5678',
        isJoin: false,
      );
      expect(d.isJoin, isFalse);
    });

    test('const constructor : identical pour memes valeurs', () {
      const a = PresenceDelta(userCloudId: 'x', isJoin: true);
      const b = PresenceDelta(userCloudId: 'x', isJoin: true);
      // Const canonicalisation : meme reference
      expect(identical(a, b), isTrue);
    });
  });

  group('LivePosition', () {
    test('expose les 5 champs', () {
      final pos = LivePosition(
        userCloudId: 'u-1',
        lat: 48.5,
        lng: 1.5,
        accuracyMeters: 10.0,
        timestamp: DateTime(2026, 5, 29, 14),
      );
      expect(pos.userCloudId, 'u-1');
      expect(pos.lat, 48.5);
      expect(pos.lng, 1.5);
      expect(pos.accuracyMeters, 10.0);
      expect(pos.timestamp, DateTime(2026, 5, 29, 14));
    });

    test('coords negatives (hemisphere sud, longitude ouest)', () {
      final pos = LivePosition(
        userCloudId: 'u-1',
        lat: -33.86,
        lng: -74.006,
        accuracyMeters: 20.0,
        timestamp: DateTime(2026),
      );
      expect(pos.lat, -33.86);
      expect(pos.lng, -74.006);
    });

    test('accuracyMeters = 0 (GPS exact theorique)', () {
      final pos = LivePosition(
        userCloudId: 'u',
        lat: 0,
        lng: 0,
        accuracyMeters: 0,
        timestamp: DateTime(2026),
      );
      expect(pos.accuracyMeters, 0);
    });

    test('coords (0,0) preservees (golfe de Guinee)', () {
      final pos = LivePosition(
        userCloudId: 'u',
        lat: 0,
        lng: 0,
        accuracyMeters: 5,
        timestamp: DateTime(2026, 5, 29),
      );
      expect(pos.lat, 0);
      expect(pos.lng, 0);
    });
  });
}
