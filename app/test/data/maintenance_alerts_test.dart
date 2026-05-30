import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/maintenance_alerts.dart';

void main() {
  group('MaintenanceAlerts.compute (#316)', () {
    test('aucune donnee -> aucune alerte (sauf hiver)', () {
      final out = MaintenanceAlerts.compute(
        currentOdometerKm: 50000,
        now: DateTime(2026, 5, 30),
      );
      expect(out, isEmpty);
    });

    test('vidange dans 500 km (proche seuil)', () {
      final out = MaintenanceAlerts.compute(
        currentOdometerKm: 49500,
        now: DateTime(2026, 5, 30),
        lastVidangeOdometerKm: 40000,
      );
      expect(out.first.kind, MaintenanceKind.vidange);
      expect(out.first.dueInKm, 500);
    });

    test('vidange overdue', () {
      final out = MaintenanceAlerts.compute(
        currentOdometerKm: 51000,
        now: DateTime(2026, 5, 30),
        lastVidangeOdometerKm: 40000,
      );
      expect(out.first.kind, MaintenanceKind.vidange);
      expect(out.first.isOverdue, isTrue);
    });

    test('CT < 30 jours', () {
      final out = MaintenanceAlerts.compute(
        currentOdometerKm: 100000,
        now: DateTime(2026, 5, 30),
        firstRegistrationDate: DateTime(2022, 6, 5),
      );
      expect(
        out.any((a) => a.kind == MaintenanceKind.controlTechnique),
        isTrue,
      );
    });

    test('pneus hiver en novembre', () {
      final out = MaintenanceAlerts.compute(
        currentOdometerKm: 50000,
        now: DateTime(2026, 11, 5),
      );
      expect(
        out.any((a) => a.kind == MaintenanceKind.pneusHiver),
        isTrue,
      );
    });
  });
}
