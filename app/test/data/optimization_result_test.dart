import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/optimization_service.dart';

void main() {
  group('OptimizationResult', () {
    test('constructeur conserve les champs requis', () {
      const r = OptimizationResult(
        orderedStopIds: [3, 1, 2],
        totalDistanceMeters: 12345,
        totalDurationSeconds: 678,
      );
      expect(r.orderedStopIds, [3, 1, 2]);
      expect(r.totalDistanceMeters, 12345);
      expect(r.totalDurationSeconds, 678);
      expect(r.routeGeometry, isNull);
    });

    test('routeGeometry optionnelle', () {
      const r = OptimizationResult(
        orderedStopIds: [1],
        totalDistanceMeters: 0,
        totalDurationSeconds: 0,
        routeGeometry: [
          [1.0, 48.0],
          [1.5, 48.5],
        ],
      );
      expect(r.routeGeometry, hasLength(2));
      expect(r.routeGeometry!.first, [1.0, 48.0]);
    });
  });

  group('OptimizationException', () {
    test('toString : prefix + message', () {
      const e = OptimizationException('test msg');
      expect(e.toString(), 'OptimizationException: test msg');
      expect(e.message, 'test msg');
    });
  });
}
