import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/incident_report.dart';

void main() {
  group('IncidentReport.compose (#334)', () {
    test('minimal accrochage', () {
      final s = IncidentReport.compose(
        kind: IncidentKind.accrochage,
        when: DateTime(2026, 5, 30, 14, 7),
      );
      expect(s, contains('ACCROCHAGE'));
      expect(s, contains('30/05/2026 14:07'));
      expect(s, contains('compléter'));
    });

    test('avec GPS + meteo + tiers', () {
      final s = IncidentReport.compose(
        kind: IncidentKind.accrochage,
        when: DateTime(2026, 5, 30, 14),
        lat: 48.123,
        lng: 1.456,
        weatherSummary: 'pluie',
        freeText: 'Choc latéral arrière',
      );
      expect(s, contains('48.12300,1.45600'));
      expect(s, contains('maps.google.com'));
      expect(s, contains('pluie'));
      expect(s, contains('Choc latéral'));
      expect(s, contains('Plaque immatriculation'));
    });

    test('vol/agression -> mention plainte', () {
      final s = IncidentReport.compose(
        kind: IncidentKind.theft,
        when: DateTime(2026, 5, 30),
      );
      expect(s, contains('dépôt de plainte'));
    });

    test('panne -> pas de plainte', () {
      final s = IncidentReport.compose(
        kind: IncidentKind.panne,
        when: DateTime(2026, 5, 30),
      );
      expect(s, isNot(contains('dépôt de plainte')));
    });
  });
}
