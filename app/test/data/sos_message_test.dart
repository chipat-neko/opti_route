import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/sos_message.dart';

void main() {
  final t = DateTime(2026, 5, 30, 14, 7);
  group('SosMessage.compose (#286)', () {
    test('avec GPS', () {
      final s = SosMessage.compose(
          name: 'Noah', lat: 48.12345, lng: 1.6789, now: t);
      expect(s, contains('SOS - Noah - 14:07'));
      expect(s, contains('48.12345,1.67890'));
      expect(s, contains('maps.google.com'));
    });
    test('sans GPS', () {
      final s = SosMessage.compose(name: 'Noah', now: t);
      expect(s, contains('GPS indisponible'));
      expect(s, isNot(contains('maps.google.com')));
    });
    test('name vide -> defaut', () {
      final s = SosMessage.compose(now: t);
      expect(s, startsWith('SOS - opti_route - 14:07'));
    });
  });
  group('SosMessage.smsUri', () {
    test('scheme sms + recipient + body encode', () {
      final uri = SosMessage.smsUri(recipient: '0612345678', body: 'a b');
      expect(uri.scheme, 'sms');
      expect(uri.path, '0612345678');
      expect(uri.queryParameters['body'], 'a b');
    });
  });
}
