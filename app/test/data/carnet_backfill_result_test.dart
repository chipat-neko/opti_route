import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/carnet_backfill_service.dart';

// Tests directs du data class CarnetBackfillResult (sans I/O).
// Verrouille les champs + getter hasActivity.
void main() {
  group('CarnetBackfillResult', () {
    test('expose les 4 champs', () {
      const r = CarnetBackfillResult(
        totalStops: 100,
        created: 25,
        merged: 50,
        skipped: 25,
      );
      expect(r.totalStops, 100);
      expect(r.created, 25);
      expect(r.merged, 50);
      expect(r.skipped, 25);
    });

    test('hasActivity : false si created+merged+skipped = 0', () {
      const r = CarnetBackfillResult(
        totalStops: 0, created: 0, merged: 0, skipped: 0,
      );
      expect(r.hasActivity, isFalse);
    });

    test('hasActivity : true si au moins 1 created', () {
      const r = CarnetBackfillResult(
        totalStops: 1, created: 1, merged: 0, skipped: 0,
      );
      expect(r.hasActivity, isTrue);
    });

    test('hasActivity : true si au moins 1 merged', () {
      const r = CarnetBackfillResult(
        totalStops: 1, created: 0, merged: 1, skipped: 0,
      );
      expect(r.hasActivity, isTrue);
    });

    test('hasActivity : true si au moins 1 skipped', () {
      const r = CarnetBackfillResult(
        totalStops: 1, created: 0, merged: 0, skipped: 1,
      );
      expect(r.hasActivity, isTrue);
    });

    test('hasActivity : true si combination > 0', () {
      const r = CarnetBackfillResult(
        totalStops: 10, created: 3, merged: 4, skipped: 3,
      );
      expect(r.hasActivity, isTrue);
    });

    test('totalStops = 0 mais activity != 0 (incoherent mais defensif) '
        '-> hasActivity true', () {
      // Cas pathologique : totalStops=0 mais created/merged/skipped > 0
      // (ne devrait jamais arriver mais hasActivity ne regarde que
      // les 3 derniers).
      const r = CarnetBackfillResult(
        totalStops: 0, created: 5, merged: 0, skipped: 0,
      );
      expect(r.hasActivity, isTrue);
    });
  });
}
