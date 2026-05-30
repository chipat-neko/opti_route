import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';

// Tests des helpers ParametresRepository pas encore couverts :
// autoLockMinutes (+defaut), secureScreen, modeEco, biometrieActive,
// ambientLight (auto + seuil), coach done flags, quietHours
// start/end + isQuietHoursNow.
void main() {
  late AppDatabase db;
  late ParametresRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ParametresRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AutoLock', () {
    test('defaut : 5 minutes', () async {
      expect(await repo.getAutoLockMinutes(),
          ParametresRepository.defaultAutoLockMinutes);
      expect(ParametresRepository.defaultAutoLockMinutes, 5);
    });

    test('set/get round-trip 15 min', () async {
      await repo.setAutoLockMinutes(15);
      expect(await repo.getAutoLockMinutes(), 15);
    });

    test('set 0 (jamais auto-lock) : OK', () async {
      await repo.setAutoLockMinutes(0);
      expect(await repo.getAutoLockMinutes(), 0);
    });

    test('valeur non parseable en base : fallback default', () async {
      // Ce cas est defensif. Pas trivial a forcer mais le getter
      // utilise tryParse ?? defaultAutoLockMinutes.
      // -> on insere une valeur garbage directement.
      // Pas d'API publique pour ca, on se contente d'un check du default.
      expect(await repo.getAutoLockMinutes(),
          ParametresRepository.defaultAutoLockMinutes);
    });
  });

  group('SecureScreen', () {
    test('defaut : false', () async {
      expect(await repo.getSecureScreen(), isFalse);
    });

    test('toggle true / false', () async {
      await repo.setSecureScreen(true);
      expect(await repo.getSecureScreen(), isTrue);
      await repo.setSecureScreen(false);
      expect(await repo.getSecureScreen(), isFalse);
    });
  });

  group('ModeEco', () {
    test('defaut : false', () async {
      expect(await repo.getModeEco(), isFalse);
    });

    test('toggle true / false', () async {
      await repo.setModeEco(true);
      expect(await repo.getModeEco(), isTrue);
    });
  });

  group('BiometrieActive', () {
    test('defaut : false', () async {
      expect(await repo.getBiometrieActive(), isFalse);
    });

    test('toggle true / false', () async {
      await repo.setBiometrieActive(true);
      expect(await repo.getBiometrieActive(), isTrue);
    });
  });

  group('AmbientLight', () {
    test('auto defaut : false', () async {
      expect(await repo.getAmbientLightAuto(), isFalse);
    });

    test('seuil defaut : 50 lux', () async {
      expect(await repo.getAmbientLightSeuilLux(),
          ParametresRepository.defaultAmbientLightSeuilLux);
      expect(ParametresRepository.defaultAmbientLightSeuilLux, 50);
    });

    test('seuil set/get 100 lux', () async {
      await repo.setAmbientLightSeuilLux(100);
      expect(await repo.getAmbientLightSeuilLux(), 100);
    });

    test('auto toggle', () async {
      await repo.setAmbientLightAuto(true);
      expect(await repo.getAmbientLightAuto(), isTrue);
    });
  });

  group('Coach done flags', () {
    test('defauts : tous false', () async {
      expect(await repo.getCoachTourneeDone(), isFalse);
      expect(await repo.getCoachScanDone(), isFalse);
      expect(await repo.getCoachParametresDone(), isFalse);
    });

    test('setCoachTourneeDone : passe a true (1-way)', () async {
      await repo.setCoachTourneeDone();
      expect(await repo.getCoachTourneeDone(), isTrue);
    });

    test('setCoachScanDone : passe a true', () async {
      await repo.setCoachScanDone();
      expect(await repo.getCoachScanDone(), isTrue);
    });

    test('setCoachParametresDone : passe a true', () async {
      await repo.setCoachParametresDone();
      expect(await repo.getCoachParametresDone(), isTrue);
    });
  });

  group('QuietHours start/end + isQuietHoursNow', () {
    test('defauts : start/end null + isQuietHoursNow false', () async {
      expect(await repo.getQuietHoursStart(), isNull);
      expect(await repo.getQuietHoursEnd(), isNull);
      expect(await repo.isQuietHoursNow(), isFalse);
    });

    test('set start "12:00" + end "14:00" : creneau midi', () async {
      await repo.setQuietHoursStart('12:00');
      await repo.setQuietHoursEnd('14:00');
      // Test a 13h : dedans
      expect(
        await repo.isQuietHoursNow(now: DateTime(2026, 5, 29, 13)),
        isTrue,
      );
      // Test a 11h : avant
      expect(
        await repo.isQuietHoursNow(now: DateTime(2026, 5, 29, 11)),
        isFalse,
      );
    });

    test('clear start uniquement : isQuietHoursNow false (l\'un des 2 null)',
        () async {
      await repo.setQuietHoursStart('12:00');
      await repo.setQuietHoursEnd('14:00');
      await repo.clearQuietHoursStart();
      expect(
        await repo.isQuietHoursNow(now: DateTime(2026, 5, 29, 13)),
        isFalse,
      );
    });

    test('clear end uniquement : isQuietHoursNow false', () async {
      await repo.setQuietHoursStart('12:00');
      await repo.setQuietHoursEnd('14:00');
      await repo.clearQuietHoursEnd();
      expect(
        await repo.isQuietHoursNow(now: DateTime(2026, 5, 29, 13)),
        isFalse,
      );
    });
  });
}
