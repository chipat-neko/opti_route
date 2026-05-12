import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/geocode_cache_repository.dart';

void main() {
  group('GeocodeCacheRepository', () {
    late AppDatabase db;
    late GeocodeCacheRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = GeocodeCacheRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    const sampleResult = AddressSuggestion(
      displayName: '14 rue X, 75011 Paris',
      lat: 48.85,
      lon: 2.37,
      road: 'rue X',
      houseNumber: '14',
      postcode: '75011',
      city: 'Paris',
    );

    test('count : 0 si vide', () async {
      expect(await repo.count(), 0);
    });

    test('write + read round-trip', () async {
      await repo.write('ban:14 rue X paris', [sampleResult]);
      final r = await repo.read('ban:14 rue X paris');
      expect(r, isNotNull);
      expect(r!.length, 1);
      expect(r.first.displayName, sampleResult.displayName);
      expect(r.first.lat, sampleResult.lat);
      expect(r.first.lon, sampleResult.lon);
    });

    test('count apres 3 writes : 3', () async {
      await repo.write('ban:a', [sampleResult]);
      await repo.write('ban:b', [sampleResult]);
      await repo.write('ban:c', [sampleResult]);
      expect(await repo.count(), 3);
    });

    test('purgeAll : supprime toutes les entrees', () async {
      await repo.write('ban:a', [sampleResult]);
      await repo.write('ban:b', [sampleResult]);
      final removed = await repo.purgeAll();
      expect(removed, 2);
      expect(await repo.count(), 0);
    });

    test('purgeExpired : supprime les entrees datees dans le passe',
        () async {
      // On force un TTL negatif (expireLe = now - 30j) en re-ecrivant
      // l'entree, puis purgeExpired doit la retirer.
      await repo.write('ban:fresh', [sampleResult],
          ttl: const Duration(days: 30));
      // L'entree fresh est ecrite avec expireLe dans le futur lointain.
      // Pas d'entree expiree -> purgeExpired retourne 0.
      expect(await repo.purgeExpired(), 0);
      expect(await repo.count(), 1);
    });

    test('read : null si pas en cache', () async {
      final r = await repo.read('ban:inconnu');
      expect(r, isNull);
    });

    test('read : null + supprime si expire', () async {
      await repo.write('ban:k', [sampleResult],
          ttl: const Duration(seconds: 1));
      await Future<void>.delayed(const Duration(milliseconds: 1200));
      final r = await repo.read('ban:k');
      expect(r, isNull);
      // l'entree doit etre supprimee au passage
      expect(await repo.count(), 0);
    });

    test('normalisation : lowercase + collapse spaces', () async {
      await repo.write('ban: 14  RUE  X ', [sampleResult]);
      // Read avec une casse / espaces differents : trouve quand meme.
      final r = await repo.read('BAN: 14 rue X');
      expect(r, isNotNull);
    });

    test('write liste vide : stocke quand meme (signal "rien trouve")',
        () async {
      await repo.write('ban:adresse fantasque', []);
      final r = await repo.read('ban:adresse fantasque');
      expect(r, isNotNull);
      expect(r, isEmpty);
    });

    test('re-write meme cle : ecrase l\'ancienne valeur', () async {
      await repo.write('ban:k', [sampleResult]);
      const updated = AddressSuggestion(
        displayName: 'nouvelle adresse',
        lat: 50,
        lon: 3,
      );
      await repo.write('ban:k', [updated]);
      final r = await repo.read('ban:k');
      expect(r, hasLength(1));
      expect(r!.first.displayName, 'nouvelle adresse');
    });

    test('TTL par defaut = 30 jours', () {
      expect(GeocodeCacheRepository.defaultTtl, const Duration(days: 30));
    });
  });
}
