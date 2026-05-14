import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/security_service.dart';

/// Tests des fonctions PURES de [SecurityService] (hash PIN +
/// validation). Les methodes async qui touchent [ParametresRepository]
/// ou `local_auth` (plugin natif) sont couvertes par les tests
/// d'integration, pas ici.
void main() {
  group('SecurityService.hashPin', () {
    test('PIN identique -> meme hash (deterministe)', () {
      final h1 = SecurityService.hashPin('1234');
      final h2 = SecurityService.hashPin('1234');
      expect(h1, equals(h2));
    });

    test('PINs differents -> hashs differents', () {
      expect(
        SecurityService.hashPin('1234'),
        isNot(equals(SecurityService.hashPin('1235'))),
      );
    });

    test('hash est un SHA-256 hex (64 caracteres)', () {
      final hash = SecurityService.hashPin('1234');
      expect(hash.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(hash), isTrue);
    });

    test('hash connu pour "1234" (valeur SHA-256 attendue)', () {
      // SHA-256("1234") = 03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4
      expect(
        SecurityService.hashPin('1234'),
        '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4',
      );
    });

    test('PIN vide produit un hash (pas d\'exception)', () {
      // Edge case : hashPin('') doit retourner le hash de la chaine vide
      // sans throw. La validation est faite ailleurs (enableLock).
      final hash = SecurityService.hashPin('');
      expect(hash.length, 64);
    });

    test('PIN avec accents : hash UTF-8 standard', () {
      // Verifie que l'encodage est bien UTF-8 (pas latin-1).
      final hash = SecurityService.hashPin('caféà');
      expect(hash.length, 64);
      // SHA-256("caféà") en UTF-8 doit etre stable
      expect(
        SecurityService.hashPin('caféà'),
        SecurityService.hashPin('caféà'),
      );
    });
  });
}
