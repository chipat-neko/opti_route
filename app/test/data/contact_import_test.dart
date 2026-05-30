import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/contact_import.dart';

void main() {
  group('ContactImport.mapToCompanions (#300)', () {
    test('skip contacts sans adresse', () {
      final out = ContactImport.mapToCompanions([
        const PhoneContact(displayName: 'Sans adresse', phone: '0612'),
      ]);
      expect(out, isEmpty);
    });

    test('map nom + adresse + tel', () {
      final out = ContactImport.mapToCompanions([
        const PhoneContact(
            displayName: 'M. A', address: '1 rue X', phone: '0612345678'),
        const PhoneContact(
            displayName: '', address: '2 rue Y'),
      ]);
      expect(out, hasLength(2));
      expect(out[0].nomClient.value, 'M. A');
      expect(out[0].adresseDisplay.value, '1 rue X');
      expect(out[0].telephone.value, '0612345678');
      expect(out[1].nomClient.value, isNull);
    });

    test('defaults lat/lng = 0 si non fournis', () {
      final out = ContactImport.mapToCompanions([
        const PhoneContact(displayName: 'A', address: 'x'),
      ]);
      expect(out.first.lat.value, 0);
      expect(out.first.lng.value, 0);
    });
  });
}
