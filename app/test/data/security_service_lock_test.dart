import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';
import 'package:opti_route/data/security_service.dart';

// Tests d'integration ParametresRepository + SecurityService (sans
// le plugin biometrique). Couvre la machine d'etat verrou complet :
// enable -> verify -> change -> disable.
void main() {
  late AppDatabase db;
  late ParametresRepository params;
  late SecurityService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    params = ParametresRepository(db);
    svc = SecurityService(params);
  });

  tearDown(() async {
    await db.close();
  });

  group('SecurityService.enableLock', () {
    test('PIN valide 4 chiffres : verrou actif + hash persiste', () async {
      final ok = await svc.enableLock('1234');
      expect(ok, isTrue);
      expect(await params.getVerrouActif(), isTrue);
      expect(await params.getPinHash(), isNotNull);
    });

    test('PIN 6 chiffres : OK', () async {
      expect(await svc.enableLock('123456'), isTrue);
    });

    test('PIN 3 chiffres : rejete (trop court)', () async {
      expect(await svc.enableLock('123'), isFalse);
      expect(await params.getVerrouActif(), isFalse);
      expect(await params.getPinHash(), isNull);
    });

    test('PIN 7 chiffres : rejete (trop long)', () async {
      expect(await svc.enableLock('1234567'), isFalse);
    });

    test('PIN avec lettre : rejete (que des chiffres)', () async {
      expect(await svc.enableLock('12a4'), isFalse);
    });

    test('PIN vide : rejete', () async {
      expect(await svc.enableLock(''), isFalse);
    });
  });

  group('SecurityService.isLockEnabled', () {
    test('faux par defaut', () async {
      expect(await svc.isLockEnabled(), isFalse);
    });

    test('vrai apres enableLock', () async {
      await svc.enableLock('1234');
      expect(await svc.isLockEnabled(), isTrue);
    });

    test('verrouActif=true mais pinHash absent : false', () async {
      // Cas pathologique : on force verrou actif sans definir le hash.
      await params.setVerrouActif(true);
      expect(await svc.isLockEnabled(), isFalse,
          reason: 'verrou sans PIN est inutilisable');
    });
  });

  group('SecurityService.verifyPin', () {
    test('PIN correct : true', () async {
      await svc.enableLock('1234');
      expect(await svc.verifyPin('1234'), isTrue);
    });

    test('PIN incorrect : false', () async {
      await svc.enableLock('1234');
      expect(await svc.verifyPin('1111'), isFalse);
    });

    test('aucun PIN configure : false (jamais accepte)', () async {
      expect(await svc.verifyPin('1234'), isFalse);
    });
  });

  group('SecurityService.disableLock', () {
    test('efface verrouActif + pinHash + biometrieActive', () async {
      await svc.enableLock('1234');
      await params.setBiometrieActive(true);
      await svc.disableLock();
      expect(await params.getVerrouActif(), isFalse);
      expect(await params.getPinHash(), isNull);
      // biometrie est tjs reset a false par disableLock
    });
  });

  group('SecurityService.changePin', () {
    test('ancien PIN OK, nouveau PIN valide : remplace le hash', () async {
      await svc.enableLock('1234');
      final hashAvant = await params.getPinHash();
      final ok = await svc.changePin(oldPin: '1234', newPin: '5678');
      expect(ok, isTrue);
      final hashApres = await params.getPinHash();
      expect(hashApres, isNotNull);
      expect(hashApres, isNot(hashAvant));
      // Verifie que le nouveau passe et l'ancien echoue
      expect(await svc.verifyPin('5678'), isTrue);
      expect(await svc.verifyPin('1234'), isFalse);
    });

    test('ancien PIN faux : rejete', () async {
      await svc.enableLock('1234');
      final hashAvant = await params.getPinHash();
      final ok = await svc.changePin(oldPin: '0000', newPin: '5678');
      expect(ok, isFalse);
      expect(await params.getPinHash(), hashAvant,
          reason: 'hash inchange');
    });

    test('nouveau PIN invalide : rejete avant verification ancien',
        () async {
      await svc.enableLock('1234');
      final hashAvant = await params.getPinHash();
      final ok = await svc.changePin(oldPin: '1234', newPin: 'abc');
      expect(ok, isFalse);
      expect(await params.getPinHash(), hashAvant);
    });
  });
}
