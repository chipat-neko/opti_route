import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/geocoding_service.dart';

void main() {
  group('GeocodingException', () {
    test('toString : prefix + message', () {
      const e = GeocodingException('BAN 500');
      expect(e.toString(), 'GeocodingException: BAN 500');
      expect(e.message, 'BAN 500');
    });

    test('implements Exception', () {
      const e = GeocodingException('test');
      expect(e, isA<Exception>());
    });
  });
}
