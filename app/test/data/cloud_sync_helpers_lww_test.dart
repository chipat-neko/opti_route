import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cloud/cloud_sync_helpers.dart';

// Complete cloud_sync_helpers_test : parseCloudUpdatedAt (string ISO
// 8601 + fallback) et cloudIsNewer (last-write-wins avec tolerance 1s).
// Aucun touche de sync : juste de la logique pure.
void main() {
  group('parseCloudUpdatedAt', () {
    test('string ISO 8601 valide -> DateTime local', () {
      final d = parseCloudUpdatedAt('2026-05-29T14:23:45.123Z');
      expect(d.year, 2026);
      expect(d.month, 5);
      expect(d.day, isIn([29, 30]),
          reason: 'jour selon TZ locale du test');
    });

    test('null -> fallback epoch (1970-01-01)', () {
      final d = parseCloudUpdatedAt(null);
      expect(d.millisecondsSinceEpoch, 0);
    });

    test('valeur non-string (int) -> fallback epoch', () {
      final d = parseCloudUpdatedAt(123456789);
      expect(d.millisecondsSinceEpoch, 0);
    });

    test('valeur non-string (Map) -> fallback epoch', () {
      final d = parseCloudUpdatedAt({'foo': 'bar'});
      expect(d.millisecondsSinceEpoch, 0);
    });
  });

  group('cloudIsNewer — tolerance 1 seconde', () {
    test('cloud 2s apres local : true (strictement plus recent)', () {
      final local = DateTime(2026, 5, 29, 10, 0, 0);
      final cloud = DateTime(2026, 5, 29, 10, 0, 2);
      expect(cloudIsNewer(cloud, local), isTrue);
    });

    test('cloud 1s apres local : false (dans la tolerance)', () {
      final local = DateTime(2026, 5, 29, 10, 0, 0);
      final cloud = DateTime(2026, 5, 29, 10, 0, 1);
      expect(cloudIsNewer(cloud, local), isFalse,
          reason: '1s exactement -> isAfter(local+1s) = false');
    });

    test('cloud 1s 1ms apres local : true (au-dela de la tolerance)', () {
      final local = DateTime(2026, 5, 29, 10, 0, 0);
      final cloud = DateTime(2026, 5, 29, 10, 0, 1, 1);
      expect(cloudIsNewer(cloud, local), isTrue);
    });

    test('cloud egal a local : false (egalite -> skip)', () {
      final local = DateTime(2026, 5, 29, 10, 0, 0);
      final cloud = DateTime(2026, 5, 29, 10, 0, 0);
      expect(cloudIsNewer(cloud, local), isFalse);
    });

    test('cloud avant local : false (local plus recent)', () {
      final local = DateTime(2026, 5, 29, 10, 0, 0);
      final cloud = DateTime(2026, 5, 29, 9, 0, 0);
      expect(cloudIsNewer(cloud, local), isFalse);
    });

    test('cloud 1 heure apres local : true', () {
      final local = DateTime(2026, 5, 29, 10, 0, 0);
      final cloud = DateTime(2026, 5, 29, 11, 0, 0);
      expect(cloudIsNewer(cloud, local), isTrue);
    });

    test('cloud epoch (parseCloudUpdatedAt null) vs local recent : false',
        () {
      final local = DateTime(2026, 5, 29, 10, 0, 0);
      final cloud = DateTime.fromMillisecondsSinceEpoch(0);
      expect(cloudIsNewer(cloud, local), isFalse,
          reason:
              'cloud sans updated_at est "infiniment ancien", local gagne');
    });
  });
}
