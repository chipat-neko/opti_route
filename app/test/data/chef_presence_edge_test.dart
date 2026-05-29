import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/chef_presence_service.dart';

// Complete chef_presence_test :
// - constantes kFreshThreshold / kRecentThreshold
// - LiveFreshness enum 3 valeurs
// - duree 0 / negative
// - boundaries 59999 ms / 60000 ms / 299999 / 300000
void main() {
  group('LiveFreshness enum', () {
    test('3 valeurs : fresh, recent, stale', () {
      expect(LiveFreshness.values, hasLength(3));
      expect(
        LiveFreshness.values,
        containsAll(const [
          LiveFreshness.fresh,
          LiveFreshness.recent,
          LiveFreshness.stale,
        ]),
      );
    });
  });

  group('Constantes — verrou des seuils', () {
    test('kFreshThreshold = 60 secondes', () {
      expect(kFreshThreshold, const Duration(seconds: 60));
    });

    test('kRecentThreshold = 300 secondes', () {
      expect(kRecentThreshold, const Duration(seconds: 300));
    });

    test('fresh < recent (invariant ordre)', () {
      expect(kFreshThreshold, lessThan(kRecentThreshold));
    });
  });

  group('freshnessOf — boundaries milliseconde', () {
    test('age = 0 ms : fresh', () {
      expect(freshnessOf(Duration.zero), LiveFreshness.fresh);
    });

    test('age negatif (defensif) : fresh (< seuil)', () {
      // Duree negative possible avec une horloge desynchronisee
      // entre serveur et client. On reste fresh plutot que crasher.
      expect(
        freshnessOf(const Duration(seconds: -5)),
        LiveFreshness.fresh,
      );
    });

    test('59999 ms (juste avant 60s) : fresh', () {
      expect(
        freshnessOf(const Duration(milliseconds: 59999)),
        LiveFreshness.fresh,
      );
    });

    test('60000 ms (60s pile) : recent (seuil strict)', () {
      expect(
        freshnessOf(const Duration(milliseconds: 60000)),
        LiveFreshness.recent,
      );
    });

    test('60001 ms : recent', () {
      expect(
        freshnessOf(const Duration(milliseconds: 60001)),
        LiveFreshness.recent,
      );
    });

    test('299999 ms (juste avant 300s) : recent', () {
      expect(
        freshnessOf(const Duration(milliseconds: 299999)),
        LiveFreshness.recent,
      );
    });

    test('300000 ms (300s pile) : stale', () {
      expect(
        freshnessOf(const Duration(milliseconds: 300000)),
        LiveFreshness.stale,
      );
    });

    test('1 heure : stale', () {
      expect(
        freshnessOf(const Duration(hours: 1)),
        LiveFreshness.stale,
      );
    });
  });
}
