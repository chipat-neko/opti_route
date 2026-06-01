import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/pii_mask.dart';

// Tests "mentalite hacker" du masquage email : la garantie de
// confidentialite (jamais la partie locale complete) doit tenir pour
// TOUS les cas, y compris hostiles. Un ecran Diagnostic peut etre capture
// et partage -> aucune fuite tolere.
void main() {
  group('maskEmailForDisplay — cas nominaux', () {
    test('email standard -> 1re lettre + *** + domaine', () {
      expect(maskEmailForDisplay('lucas@gmail.com'), 'l***@gmail.com');
      expect(maskEmailForDisplay('noah.trillon28@gmail.com'),
          'n***@gmail.com');
    });

    test('partie locale de 2 caracteres -> 1re lettre seulement', () {
      expect(maskEmailForDisplay('ab@x.com'), 'a***@x.com');
    });
  });

  group('maskEmailForDisplay — null / vide', () {
    test('null -> tiret', () => expect(maskEmailForDisplay(null), '—'));
    test('vide -> tiret', () => expect(maskEmailForDisplay(''), '—'));
  });

  group('maskEmailForDisplay — aucune fuite de la partie locale', () {
    test('partie locale d\'1 caractere -> rien revele', () {
      // "a@x.com" : on ne doit PAS voir le "a".
      final r = maskEmailForDisplay('a@x.com');
      expect(r, '***@x.com');
      expect(r.startsWith('a'), isFalse);
    });

    test('email commencant par @ -> rien revele avant @', () {
      expect(maskEmailForDisplay('@x.com'), '***@x.com');
    });

    test('chaine sans @ : ne revele AUCUN caractere (pas de fuite)', () {
      // Cas hostile : pas d'arobase -> on ne doit rien laisser passer.
      final r = maskEmailForDisplay('motdepassesecret');
      expect(r, '***');
      expect(r.contains('motdepasse'), isFalse);
    });

    test('la partie locale complete n\'apparait jamais (>=2 chars)', () {
      const locale = 'jeandupont';
      final r = maskEmailForDisplay('$locale@société.fr');
      // Seule la 1re lettre + *** ; le reste de la locale est masque.
      expect(r, 'j***@société.fr');
      expect(r.contains(locale), isFalse);
      expect(r.contains('eandupont'), isFalse);
    });

    test('plusieurs @ : coupe au 1er, ne fuit pas la locale', () {
      // indexOf('@')=2 -> "a***" + "@b@c.com".
      expect(maskEmailForDisplay('ab@b@c.com'), 'a***@b@c.com');
      // locale d'1 char avant @ -> rien revele.
      expect(maskEmailForDisplay('a@b@c.com'), '***@b@c.com');
    });

    test('espaces / casse preserves dans le domaine (pas de crash)', () {
      expect(maskEmailForDisplay('Marie@MAIL.fr'), 'M***@MAIL.fr');
    });
  });
}
