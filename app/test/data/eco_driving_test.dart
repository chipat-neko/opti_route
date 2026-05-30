import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/eco_driving.dart';

void main() {
  group('EcoDriving.classify (#313)', () {
    test('repos -> normal', () {
      expect(
        EcoDriving.classify(accelX: 0, accelY: 0, accelZ: 9.81),
        DrivingEvent.normal,
      );
    });

    test('freinage sec (Y positif > 4) -> hardBrake', () {
      expect(
        EcoDriving.classify(accelX: 0, accelY: 5, accelZ: 0),
        DrivingEvent.hardBrake,
      );
    });

    test('acceleration brute (Y negatif > 3) -> hardAccel', () {
      expect(
        EcoDriving.classify(accelX: 0, accelY: -4, accelZ: 0),
        DrivingEvent.hardAccel,
      );
    });

    test('pic > 4g -> crash', () {
      expect(
        EcoDriving.classify(accelX: 0, accelY: 0, accelZ: 50),
        DrivingEvent.crash,
      );
      expect(
        EcoDriving.classify(accelX: 40, accelY: 0, accelZ: 0),
        DrivingEvent.crash,
      );
    });
  });

  group('EcoDriving.computeScore (#313)', () {
    test('0 evenements -> 100', () {
      expect(
        EcoDriving.computeScore(
            hardBrakes: 0, hardAccels: 0, durationMin: 60),
        100,
      );
    });
    test('1 evenement/min -> 90', () {
      expect(
        EcoDriving.computeScore(
            hardBrakes: 30, hardAccels: 30, durationMin: 60),
        90,
        reason: '60/60 = 1 evt/min => -10pts => 90',
      );
    });
    test('beaucoup d\'evts -> 0 (borne)', () {
      expect(
        EcoDriving.computeScore(
            hardBrakes: 200, hardAccels: 200, durationMin: 30),
        0,
      );
    });
    test('duree 0 -> 100 (pas de division par 0)', () {
      expect(
        EcoDriving.computeScore(
            hardBrakes: 10, hardAccels: 5, durationMin: 0),
        100,
      );
    });
  });
}
