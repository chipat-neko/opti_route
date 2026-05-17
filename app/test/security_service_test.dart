import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';
import 'package:opti_route/data/security_service.dart';

void main() {
  group('SecurityService.hashPin (pure)', () {
    test('hash deterministe : meme PIN -> meme hash', () {
      final h1 = SecurityService.hashPin('1234');
      final h2 = SecurityService.hashPin('1234');
      expect(h1, equals(h2));
    });

    test('PINs differents -> hashes differents', () {
      final h1 = SecurityService.hashPin('1234');
      final h2 = SecurityService.hashPin('1235');
      expect(h1, isNot(equals(h2)));
    });

    test('hash SHA-256 connu pour "1234"', () {
      // Valeur de reference : sha256("1234")
      const expected =
          '03ac674216f3e15c761ee1a5e255f067953623c8b388b4459e13f978d7c846f4';
      expect(SecurityService.hashPin('1234'), equals(expected));
    });

    test('PIN vide -> hash quand meme calcule (hash("")) non vide', () {
      // hashPin ne valide PAS le format (c'est enableLock qui le fait)
      final h = SecurityService.hashPin('');
      expect(h, isNotEmpty);
      expect(h.length, 64); // SHA-256 hex = 64 chars
    });
  });

  group('SecurityService - lifecycle complet', () {
    late AppDatabase db;
    late ParametresRepository params;
    late SecurityService security;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      params = ParametresRepository(db);
      security = SecurityService(params);
    });

    tearDown(() async {
      await db.close();
    });

    test('isLockEnabled : false par defaut (pas de PIN + verrou inactif)',
        () async {
      expect(await security.isLockEnabled(), isFalse);
    });

    test('enableLock + isLockEnabled : true apres activation', () async {
      final ok = await security.enableLock('123456');
      expect(ok, isTrue);
      expect(await security.isLockEnabled(), isTrue);
    });

    test('enableLock rejette PIN trop court (3 chiffres)', () async {
      final ok = await security.enableLock('123');
      expect(ok, isFalse);
      expect(await security.isLockEnabled(), isFalse);
    });

    test('enableLock rejette PIN trop long (7 chiffres)', () async {
      final ok = await security.enableLock('1234567');
      expect(ok, isFalse);
    });

    test('enableLock rejette PIN non numerique', () async {
      expect(await security.enableLock('12a4'), isFalse);
      expect(await security.enableLock('abcd'), isFalse);
      expect(await security.enableLock('12.4'), isFalse);
    });

    test('enableLock accepte 4 chiffres (borne basse)', () async {
      expect(await security.enableLock('1234'), isTrue);
    });

    test('enableLock accepte 6 chiffres (borne haute)', () async {
      expect(await security.enableLock('123456'), isTrue);
    });

    test('verifyPin : true si PIN correct, false sinon', () async {
      await security.enableLock('4242');
      expect(await security.verifyPin('4242'), isTrue);
      expect(await security.verifyPin('4243'), isFalse);
      expect(await security.verifyPin(''), isFalse);
    });

    test('verifyPin : false si aucun PIN n\'est defini', () async {
      // Pas de enableLock prealable -> pas de hash stocke
      expect(await security.verifyPin('1234'), isFalse);
    });

    test('disableLock : isLockEnabled redevient false + verifyPin echoue',
        () async {
      await security.enableLock('1234');
      expect(await security.isLockEnabled(), isTrue);

      await security.disableLock();
      expect(await security.isLockEnabled(), isFalse);
      expect(await security.verifyPin('1234'), isFalse);
    });

    test('changePin : succes si oldPin correct + newPin valide', () async {
      await security.enableLock('1234');
      final ok =
          await security.changePin(oldPin: '1234', newPin: '5678');
      expect(ok, isTrue);
      expect(await security.verifyPin('5678'), isTrue);
      expect(await security.verifyPin('1234'), isFalse);
    });

    test('changePin : echec si oldPin incorrect', () async {
      await security.enableLock('1234');
      final ok =
          await security.changePin(oldPin: '9999', newPin: '5678');
      expect(ok, isFalse);
      // PIN initial inchange
      expect(await security.verifyPin('1234'), isTrue);
      expect(await security.verifyPin('5678'), isFalse);
    });

    test('changePin : echec si newPin invalide (rejette avant verifier oldPin)',
        () async {
      await security.enableLock('1234');
      final ok =
          await security.changePin(oldPin: '1234', newPin: '12');
      expect(ok, isFalse);
      expect(await security.verifyPin('1234'), isTrue);
    });
  });
}
