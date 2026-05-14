import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/location_service.dart';

void main() {
  group('LocationPermissionDenied', () {
    test('toString prefix + message', () {
      const e = LocationPermissionDenied('GPS off');
      expect(e.toString(), 'LocationPermissionDenied: GPS off');
      expect(e.message, 'GPS off');
    });

    test('implements Exception', () {
      const e = LocationPermissionDenied('test');
      expect(e, isA<Exception>());
    });
  });
}
