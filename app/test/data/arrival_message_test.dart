import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/arrival_message.dart';

void main() {
  final now = DateTime(2026, 5, 30, 14, 0);
  group('ArrivalMessage.compose (#289)', () {
    test('avec nom + ETA dans le futur', () {
      final s = ArrivalMessage.compose(
        nomClient: 'M. Dupont',
        eta: now.add(const Duration(minutes: 10)),
        now: now,
      );
      expect(s, contains('Bonjour M. Dupont'));
      expect(s, contains('14:10'));
      expect(s, contains('(~10 min)'));
    });
    test('sans nom', () {
      final s = ArrivalMessage.compose(
        nomClient: '',
        eta: now.add(const Duration(minutes: 5)),
        now: now,
      );
      expect(s, contains('Bonjour votre livraison'));
    });
    test('ETA = maintenant -> pas de (~min)', () {
      final s = ArrivalMessage.compose(
        nomClient: 'A',
        eta: now,
        now: now,
      );
      expect(s, isNot(contains('(~')));
    });
  });

  group('ArrivalMessage.whatsAppUri', () {
    test('encode body', () {
      final uri = ArrivalMessage.whatsAppUri(
        phoneIntl: '33612345678',
        body: 'a b c',
      );
      expect(uri.scheme, 'https');
      expect(uri.host, 'wa.me');
      expect(uri.path, '/33612345678');
      expect(uri.query, contains('text=a+b+c'));
    });
  });
}
