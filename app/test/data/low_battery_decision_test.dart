import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/battery_monitor_service.dart';

// Tests directs du data class LowBatteryDecision (1 test deja dans
// battery_monitor_evaluate_test). Complete avec const, fields, etc.
void main() {
  group('LowBatteryDecision', () {
    test('expose les 2 booleens', () {
      const d = LowBatteryDecision(notify: true, alerted: false);
      expect(d.notify, isTrue);
      expect(d.alerted, isFalse);
    });

    test('4 combinaisons possibles : tt vrai / tt faux / mix', () {
      const tt = LowBatteryDecision(notify: true, alerted: true);
      const ff = LowBatteryDecision(notify: false, alerted: false);
      const tf = LowBatteryDecision(notify: true, alerted: false);
      const ft = LowBatteryDecision(notify: false, alerted: true);
      expect(tt.notify && tt.alerted, isTrue);
      expect(ff.notify || ff.alerted, isFalse);
      expect(tf.notify, isTrue);
      expect(tf.alerted, isFalse);
      expect(ft.notify, isFalse);
      expect(ft.alerted, isTrue);
    });

    test('const canonicalisation : identical pour memes valeurs', () {
      const a = LowBatteryDecision(notify: true, alerted: true);
      const b = LowBatteryDecision(notify: true, alerted: true);
      expect(identical(a, b), isTrue);
    });

    test('valeurs differentes : non identical', () {
      const a = LowBatteryDecision(notify: true, alerted: true);
      const b = LowBatteryDecision(notify: false, alerted: true);
      expect(identical(a, b), isFalse);
    });
  });
}
