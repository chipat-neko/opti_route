import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/driving_time_compliance.dart';

void main() {
  group('DrivingTimeCompliance (#327)', () {
    test('ok < 4h15', () {
      expect(
        DrivingTimeCompliance.evaluate(
            elapsedSinceLastPause: const Duration(hours: 3)),
        DrivingComplianceState.ok,
      );
    });

    test('warning 4h15-4h29', () {
      expect(
        DrivingTimeCompliance.evaluate(
            elapsedSinceLastPause: const Duration(hours: 4, minutes: 16)),
        DrivingComplianceState.warning,
      );
    });

    test('overdue >= 4h30', () {
      expect(
        DrivingTimeCompliance.evaluate(
            elapsedSinceLastPause: const Duration(hours: 4, minutes: 30)),
        DrivingComplianceState.overdue,
      );
      expect(
        DrivingTimeCompliance.evaluate(
            elapsedSinceLastPause: const Duration(hours: 5)),
        DrivingComplianceState.overdue,
      );
    });

    test('isPauseSufficient >= 45min', () {
      expect(
        DrivingTimeCompliance.isPauseSufficient(const Duration(minutes: 30)),
        isFalse,
      );
      expect(
        DrivingTimeCompliance.isPauseSufficient(const Duration(minutes: 45)),
        isTrue,
      );
    });

    test('ttsForState : null pour ok, texte sinon', () {
      expect(
        DrivingTimeCompliance.ttsForState(DrivingComplianceState.ok),
        isNull,
      );
      expect(
        DrivingTimeCompliance.ttsForState(DrivingComplianceState.warning),
        contains('15 minutes'),
      );
      expect(
        DrivingTimeCompliance.ttsForState(DrivingComplianceState.overdue),
        contains('45 minutes'),
      );
    });
  });
}
