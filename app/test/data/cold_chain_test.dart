import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/cold_chain.dart';

void main() {
  group('ColdChain.evaluate (#328)', () {
    final loaded = DateTime(2026, 5, 30, 8);
    test('elapsed faible -> ok', () {
      expect(
        ColdChain.evaluate(
          loadedAt: loaded,
          now: loaded.add(const Duration(minutes: 10)),
          maxHours: 1,
        ),
        ColdChainState.ok,
      );
    });
    test('50% -> warning', () {
      expect(
        ColdChain.evaluate(
          loadedAt: loaded,
          now: loaded.add(const Duration(minutes: 30)),
          maxHours: 1,
        ),
        ColdChainState.warning,
      );
    });
    test('75% -> critical', () {
      expect(
        ColdChain.evaluate(
          loadedAt: loaded,
          now: loaded.add(const Duration(minutes: 46)),
          maxHours: 1,
        ),
        ColdChainState.critical,
      );
    });
    test('depasse -> lost', () {
      expect(
        ColdChain.evaluate(
          loadedAt: loaded,
          now: loaded.add(const Duration(hours: 2)),
          maxHours: 1,
        ),
        ColdChainState.lost,
      );
    });
  });

  group('ColdChain.remainingMinutes (#328)', () {
    final loaded = DateTime(2026, 5, 30, 8);
    test('apres 20 min sur 60 -> 40', () {
      expect(
        ColdChain.remainingMinutes(
          loadedAt: loaded,
          now: loaded.add(const Duration(minutes: 20)),
          maxHours: 1,
        ),
        40,
      );
    });
    test('depasse -> negatif', () {
      expect(
        ColdChain.remainingMinutes(
          loadedAt: loaded,
          now: loaded.add(const Duration(minutes: 90)),
          maxHours: 1,
        ),
        -30,
      );
    });
  });
}
