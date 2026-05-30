import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/night_mode_decision.dart';

void main() {
  group('NightModeDecision.isNight (#307)', () {
    test('seuil sans etat precedent', () {
      expect(NightModeDecision.isNight(currentLux: 3), isTrue);
      expect(NightModeDecision.isNight(currentLux: 10), isFalse);
    });

    test('hysteresis depuis night', () {
      // night actif : reste night jusqu'a 5+3 = 8 lux strict
      expect(
        NightModeDecision.isNight(currentLux: 7, previousIsNight: true),
        isTrue,
      );
      expect(
        NightModeDecision.isNight(currentLux: 9, previousIsNight: true),
        isFalse,
      );
    });

    test('seuil custom', () {
      expect(
        NightModeDecision.isNight(currentLux: 8, thresholdLux: 10),
        isTrue,
      );
    });
  });
}
