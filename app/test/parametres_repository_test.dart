import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';

void main() {
  group('ParametresRepository - cout carburant', () {
    late AppDatabase db;
    late ParametresRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ParametresRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('defauts retournes quand rien en base', () async {
      final c = await repo.getCoutCarburantLitre();
      final k = await repo.getConsoLitresPar100Km();
      expect(c, ParametresRepository.defaultCoutCarburantLitre);
      expect(k, ParametresRepository.defaultConsoLitresPar100Km);
    });

    test('set + get round-trip', () async {
      await repo.setCoutCarburantLitre(1.95);
      await repo.setConsoLitresPar100Km(8.5);
      expect(await repo.getCoutCarburantLitre(), 1.95);
      expect(await repo.getConsoLitresPar100Km(), 8.5);
    });

    test('estimerCoutCarburant : 50km a 7L/100 a 1.85EUR = 6.475EUR',
        () async {
      await repo.setCoutCarburantLitre(1.85);
      await repo.setConsoLitresPar100Km(7);
      final cout = await repo.estimerCoutCarburant(distanceMeters: 50000);
      // 50 km * 7L/100km = 3.5 L ; 3.5 * 1.85 = 6.475 EUR
      expect(cout, closeTo(6.475, 0.001));
    });

    test('estimerCoutCarburant : 0 metres -> 0 EUR', () async {
      final cout = await repo.estimerCoutCarburant(distanceMeters: 0);
      expect(cout, 0);
    });

    test('estimerCoutCarburant : 100km a 8.5L/100 a 1.95EUR = 16.575EUR',
        () async {
      await repo.setCoutCarburantLitre(1.95);
      await repo.setConsoLitresPar100Km(8.5);
      final cout =
          await repo.estimerCoutCarburant(distanceMeters: 100000);
      // 100 km * 8.5L/100 = 8.5 L ; 8.5 * 1.95 = 16.575 EUR
      expect(cout, closeTo(16.575, 0.001));
    });
  });

  group('ParametresRepository - themeMode', () {
    late AppDatabase db;
    late ParametresRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ParametresRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('defaut : system', () async {
      final m = await repo.getThemeMode();
      expect(m, 'system');
    });

    test('set + get round-trip dark', () async {
      await repo.setThemeMode('dark');
      expect(await repo.getThemeMode(), 'dark');
    });

    test('set + get round-trip light', () async {
      await repo.setThemeMode('light');
      expect(await repo.getThemeMode(), 'light');
    });
  });

  group('ParametresRepository - orsUsedToday', () {
    late AppDatabase db;
    late ParametresRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ParametresRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('compteur a zero par defaut', () async {
      expect(await repo.getOrsUsedToday(), 0);
    });

    test('incrementOrsUsed incremente le compteur du jour', () async {
      await repo.incrementOrsUsed();
      await repo.incrementOrsUsed();
      await repo.incrementOrsUsed();
      expect(await repo.getOrsUsedToday(), 3);
    });
  });

  group('ParametresRepository - capacite + duree defaults', () {
    late AppDatabase db;
    late ParametresRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = ParametresRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('capaciteDefault null par defaut', () async {
      expect(await repo.getCapaciteDefault(), isNull);
    });

    test('set + clear capaciteDefault', () async {
      await repo.setCapaciteDefault(50);
      expect(await repo.getCapaciteDefault(), 50);
      await repo.clearCapaciteDefault();
      expect(await repo.getCapaciteDefault(), isNull);
    });

    test('dureeArretDefault round-trip', () async {
      expect(await repo.getDureeArretDefault(), isNull);
      await repo.setDureeArretDefault(5);
      expect(await repo.getDureeArretDefault(), 5);
    });
  });
}
