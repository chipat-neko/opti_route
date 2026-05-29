import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/battery_monitor_service.dart';

// Logique de l'alerte batterie faible (carte #258) testee en isolation
// (fonction pure, sans le plugin battery_plus).
void main() {
  group('evaluateLowBattery', () {
    test('sous le seuil, en decharge, pas encore alerte -> notifie', () {
      final d = evaluateLowBattery(
        level: 12,
        discharging: true,
        alreadyAlerted: false,
      );
      expect(d.notify, isTrue);
      expect(d.alerted, isTrue);
    });

    test('au seuil exact (15) en decharge -> notifie', () {
      final d = evaluateLowBattery(
        level: 15,
        discharging: true,
        alreadyAlerted: false,
      );
      expect(d.notify, isTrue);
    });

    test('sous le seuil mais deja alerte -> pas de re-notif (debounce)', () {
      final d = evaluateLowBattery(
        level: 10,
        discharging: true,
        alreadyAlerted: true,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isTrue);
    });

    test('niveau remonte au-dessus de 20 -> re-arme (alerted false)', () {
      final d = evaluateLowBattery(
        level: 55,
        discharging: true,
        alreadyAlerted: true,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isFalse);
    });

    test('branche en charge -> re-arme, pas de notif meme bas', () {
      final d = evaluateLowBattery(
        level: 5,
        discharging: false,
        alreadyAlerted: false,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isFalse);
    });

    test('zone tampon (16-20) en decharge -> garde l etat, pas de notif', () {
      final d = evaluateLowBattery(
        level: 18,
        discharging: true,
        alreadyAlerted: true,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isTrue);
    });
  });
}
