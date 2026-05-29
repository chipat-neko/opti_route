import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/battery_monitor_service.dart';

// Premier test pour evaluateLowBattery (logique pure carte #258).
// Couvre les 4 branches de la machine d'etat + invariant de debounce.
void main() {
  group('evaluateLowBattery — re-armement', () {
    test('level > resetAbove en decharge -> re-arme (notify=false, alerted=false)',
        () {
      final d = evaluateLowBattery(
        level: 25,
        discharging: true,
        alreadyAlerted: true,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isFalse);
    });

    test('en charge a niveau bas -> re-arme (pas d\'alerte sur secteur)', () {
      final d = evaluateLowBattery(
        level: 5,
        discharging: false,
        alreadyAlerted: true,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isFalse,
          reason: 'rebranche -> on reset alerted pour la prochaine decharge');
    });
  });

  group('evaluateLowBattery — alerte', () {
    test('seuil franchi en decharge, jamais alerte -> notify une fois', () {
      final d = evaluateLowBattery(
        level: 15,
        discharging: true,
        alreadyAlerted: false,
      );
      expect(d.notify, isTrue);
      expect(d.alerted, isTrue);
    });

    test('seuil franchi en decharge mais deja alerte -> pas de spam', () {
      final d = evaluateLowBattery(
        level: 10,
        discharging: true,
        alreadyAlerted: true,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isTrue, reason: 'on reste en etat alerte');
    });

    test('niveau 0 % en decharge premiere alerte', () {
      final d = evaluateLowBattery(
        level: 0,
        discharging: true,
        alreadyAlerted: false,
      );
      expect(d.notify, isTrue);
    });
  });

  group('evaluateLowBattery — zone tampon (threshold < level <= resetAbove)',
      () {
    test('zone tampon, jamais alerte : notify=false, alerted=false', () {
      // threshold=15, resetAbove=20, level=18 (entre les deux)
      final d = evaluateLowBattery(
        level: 18,
        discharging: true,
        alreadyAlerted: false,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isFalse);
    });

    test('zone tampon, deja alerte : notify=false, alerted=true (debounce)',
        () {
      final d = evaluateLowBattery(
        level: 18,
        discharging: true,
        alreadyAlerted: true,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isTrue, reason: 'on attend de remonter au-dessus de 20');
    });

    test('exactement a resetAbove (20) : zone tampon, pas re-arme', () {
      // level == resetAbove (20) : level > resetAbove est faux, donc on
      // ne re-arme pas. Tombe dans la zone tampon (threshold=15 < 20).
      final d = evaluateLowBattery(
        level: 20,
        discharging: true,
        alreadyAlerted: true,
      );
      expect(d.alerted, isTrue);
      expect(d.notify, isFalse);
    });

    test('exactement a threshold (15) : alerte declenchee (<=)', () {
      final d = evaluateLowBattery(
        level: 15,
        discharging: true,
        alreadyAlerted: false,
      );
      expect(d.notify, isTrue);
    });
  });

  group('evaluateLowBattery — seuils custom', () {
    test('threshold 5 / resetAbove 10', () {
      // Plus permissif : alerte seulement a 5 %, reset a 11 %.
      final d = evaluateLowBattery(
        level: 4,
        discharging: true,
        alreadyAlerted: false,
        threshold: 5,
        resetAbove: 10,
      );
      expect(d.notify, isTrue);
    });

    test('threshold 5 : 6 % en decharge -> zone tampon, pas d\'alerte', () {
      final d = evaluateLowBattery(
        level: 6,
        discharging: true,
        alreadyAlerted: false,
        threshold: 5,
        resetAbove: 10,
      );
      expect(d.notify, isFalse);
    });
  });

  group('evaluateLowBattery — scenarios end-to-end (sequences)', () {
    test('cycle complet : decharge -> alerte -> oscillation -> reset', () {
      // 1. Au demarrage : 50 % decharge, jamais alerte
      var d = evaluateLowBattery(
        level: 50,
        discharging: true,
        alreadyAlerted: false,
      );
      expect(d.alerted, isFalse);

      // 2. Tombe a 14 % en decharge
      d = evaluateLowBattery(
        level: 14,
        discharging: true,
        alreadyAlerted: d.alerted,
      );
      expect(d.notify, isTrue, reason: '1ere alerte');
      expect(d.alerted, isTrue);

      // 3. Tombe a 10 %, deja alerte -> pas re-notif (debounce)
      d = evaluateLowBattery(
        level: 10,
        discharging: true,
        alreadyAlerted: d.alerted,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isTrue);

      // 4. Remonte a 18 % (zone tampon), reste alerted
      d = evaluateLowBattery(
        level: 18,
        discharging: true,
        alreadyAlerted: d.alerted,
      );
      expect(d.notify, isFalse);
      expect(d.alerted, isTrue);

      // 5. Remonte a 25 % -> re-arme
      d = evaluateLowBattery(
        level: 25,
        discharging: true,
        alreadyAlerted: d.alerted,
      );
      expect(d.alerted, isFalse, reason: 'au-dessus de resetAbove -> re-armed');

      // 6. Re-tombe a 14 % : nouvelle alerte autorisee
      d = evaluateLowBattery(
        level: 14,
        discharging: true,
        alreadyAlerted: d.alerted,
      );
      expect(d.notify, isTrue, reason: '2e cycle, peut re-alerter');
    });
  });

  group('LowBatteryDecision', () {
    test('expose notify et alerted', () {
      const d = LowBatteryDecision(notify: true, alerted: true);
      expect(d.notify, isTrue);
      expect(d.alerted, isTrue);
    });
  });
}
