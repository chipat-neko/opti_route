import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';

// Tests des helpers ParametresRepository pas couverts ailleurs :
// capacite/duree_arret defauts, navAppDefault, onboardingDone +
// resetOnboarding, clearOrsApiKey.
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

  group('Capacite defaut vehicule', () {
    test('defaut : null (pas saisi)', () async {
      expect(await repo.getCapaciteDefault(), isNull);
    });

    test('set/get round-trip 50 colis', () async {
      await repo.setCapaciteDefault(50);
      expect(await repo.getCapaciteDefault(), 50);
    });

    test('clear remet null', () async {
      await repo.setCapaciteDefault(80);
      await repo.clearCapaciteDefault();
      expect(await repo.getCapaciteDefault(), isNull);
    });
  });

  group('DureeArret defaut', () {
    test('defaut : null', () async {
      expect(await repo.getDureeArretDefault(), isNull);
    });

    test('set/get round-trip 5 min', () async {
      await repo.setDureeArretDefault(5);
      expect(await repo.getDureeArretDefault(), 5);
    });

    test('clear remet null', () async {
      await repo.setDureeArretDefault(10);
      await repo.clearDureeArretDefault();
      expect(await repo.getDureeArretDefault(), isNull);
    });
  });

  group('NavAppDefault', () {
    test('defaut : null (demande a chaque fois)', () async {
      expect(await repo.getNavAppDefault(), isNull);
    });

    test('set "maps" puis "waze" round-trip', () async {
      await repo.setNavAppDefault('maps');
      expect(await repo.getNavAppDefault(), 'maps');
      await repo.setNavAppDefault('waze');
      expect(await repo.getNavAppDefault(), 'waze');
    });

    test('clear remet null', () async {
      await repo.setNavAppDefault('maps');
      await repo.clearNavAppDefault();
      expect(await repo.getNavAppDefault(), isNull);
    });

    test('watchNavAppDefault emet null par defaut puis valeur', () async {
      final values = <String?>[];
      final sub = repo.watchNavAppDefault().listen(values.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.setNavAppDefault('waze');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(values, contains(null));
      expect(values, contains('waze'));
    });
  });

  group('OnboardingDone', () {
    test('defaut : false (1er lancement)', () async {
      expect(await repo.isOnboardingDone(), isFalse);
    });

    test('setOnboardingDone : passe a true', () async {
      await repo.setOnboardingDone();
      expect(await repo.isOnboardingDone(), isTrue);
    });

    test('resetOnboarding : retour a false (re-affiche walkthrough)',
        () async {
      await repo.setOnboardingDone();
      await repo.resetOnboarding();
      expect(await repo.isOnboardingDone(), isFalse);
    });
  });

  group('ORS API key', () {
    test('setOrsApiKey : trim applique', () async {
      await repo.setOrsApiKey('  abc123  ');
      expect(await repo.getOrsApiKey(), 'abc123');
    });

    test('clearOrsApiKey retire la cle', () async {
      await repo.setOrsApiKey('xyz');
      await repo.clearOrsApiKey();
      expect(await repo.getOrsApiKey(), isNull);
    });
  });
}
