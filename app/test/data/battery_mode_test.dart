import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/battery_mode.dart';

void main() {
  group('BatteryMode (#325)', () {
    test('decide : normal > 30, low 16-30, critical <=15', () {
      expect(BatteryMode.decide(100), BatteryProfile.normal);
      expect(BatteryMode.decide(31), BatteryProfile.normal);
      expect(BatteryMode.decide(30), BatteryProfile.low);
      expect(BatteryMode.decide(16), BatteryProfile.low);
      expect(BatteryMode.decide(15), BatteryProfile.critical);
      expect(BatteryMode.decide(0), BatteryProfile.critical);
    });

    test('disable rules', () {
      expect(BatteryMode.shouldDisableWeather(BatteryProfile.normal), isFalse);
      expect(BatteryMode.shouldDisableWeather(BatteryProfile.low), isTrue);
      expect(
        BatteryMode.shouldSuspendOsrm(BatteryProfile.low),
        isFalse,
        reason: 'OSRM coupé seulement en critical',
      );
      expect(
        BatteryMode.shouldSuspendOsrm(BatteryProfile.critical),
        isTrue,
      );
      expect(BatteryMode.shouldSlowGpsTracking(BatteryProfile.low), isTrue);
    });
  });
}
