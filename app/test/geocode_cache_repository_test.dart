// Tests pour GeocodeCacheRepository : cache persistant des reponses
// Nominatim / BAN avec TTL 30 jours par defaut. Couvre le round-trip
// read/write, le hit expire (purge auto), le decode tolerant aux JSON
// corrompus, et les purges manuelles.

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

    test('read : null si jamais ecrit', () async {
      expect(await repo.read('jamais vu'), isNull);
    });

    test('write puis read : round-trip preserve les champs', () async {
      final s = AddressSuggestion(
        displayName: '12 rue X, 28000 Chartres',
        lat: 48.4471,
        lon: 1.4885,
        road: 'rue X',
        houseNumber: '12',
        postcode: '28000',
        city: 'Chartres',
        country: 'France',
      );
      await repo.write('rue X chartres', [s]);

      final out = await repo.read('rue X chartres');
      expect(out, isNotNull);
      expect(out, hasLength(1));
      expect(out!.first.displayName, s.displayName);
      expect(out.first.lat, closeTo(s.lat, 1e-6));
      expect(out.first.lon, closeTo(s.lon, 1e-6));
      expect(out.first.postcode, '28000');
      expect(out.first.city, 'Chartres');
    });

    test('read : normalise la query (case + espaces)', () async {
      final s = AddressSuggestion(
        displayName: 'X',
        lat: 1.0,
        lon: 2.0,
      );
      await repo.write('  RUE des LILAS ', [s]);
      // Query avec casse / espaces differents = meme hit cache.
      final out = await repo.read('rue des lilas');
      expect(out, isNotNull);
      expect(out!.first.displayName, 'X');
    });

    test('read : hit expire renvoie null + purge la row', () async {
      final s = AddressSuggestion(displayName: 'X', lat: 1.0, lon: 2.0);
      // Insert direct avec TTL deja depasse.
      final key = 'expire';
      await db.into(db.geocodeCache).insert(
            GeocodeCacheCompanion.insert(
              query: key,
              responseJson: '[]',
              expireLe: DateTime.now().subtract(const Duration(days: 1)),
            ),
          );
      expect(await repo.count(), 1);

      final out = await repo.read(key);
      expect(out, isNull, reason: 'TTL depasse');
      expect(await repo.count(), 0,
          reason: 'la row expiree a ete supprimee au passage');
      // Sanity : ecrire frais marche apres ce GC.
      await repo.write(key, [s]);
      expect((await repo.read(key))!.first.displayName, 'X');
    });

    test('read : JSON corrompu = cache miss + purge', () async {
      await db.into(db.geocodeCache).insert(
            GeocodeCacheCompanion.insert(
              query: 'broken',
              responseJson: 'not json at all',
              expireLe: DateTime.now().add(const Duration(days: 30)),
            ),
          );
      final out = await repo.read('broken');
      expect(out, isNull);
      expect(await repo.count(), 0);
    });

    test('write liste vide : stocke quand meme (signal "rien trouve")',
        () async {
      await repo.write('vide', const []);
      final out = await repo.read('vide');
      expect(out, isNotNull);
      expect(out, isEmpty);
    });

    test('purgeExpired : retire UNIQUEMENT les entrees expirees', () async {
      await db.into(db.geocodeCache).insert(GeocodeCacheCompanion.insert(
            query: 'vieux',
            responseJson: '[]',
            expireLe: DateTime.now().subtract(const Duration(days: 1)),
          ));
      await db.into(db.geocodeCache).insert(GeocodeCacheCompanion.insert(
            query: 'frais',
            responseJson: '[]',
            expireLe: DateTime.now().add(const Duration(days: 7)),
          ));
      expect(await repo.count(), 2);

      final removed = await repo.purgeExpired();
      expect(removed, 1);
      expect(await repo.count(), 1);
      // Le frais est encore lisible.
      expect(await repo.read('frais'), isNotNull);
    });

    test('purgeAll : retire tout y compris les non-expirees', () async {
      final s = AddressSuggestion(displayName: 'X', lat: 1.0, lon: 2.0);
      await repo.write('a', [s]);
      await repo.write('b', [s]);
      await repo.write('c', [s]);
      expect(await repo.count(), 3);

      final removed = await repo.purgeAll();
      expect(removed, 3);
      expect(await repo.count(), 0);
    });

    test('write : re-write ecrase l\'entree precedente (insertOnConflictUpdate)',
        () async {
      final s1 = AddressSuggestion(displayName: 'V1', lat: 1.0, lon: 2.0);
      final s2 = AddressSuggestion(displayName: 'V2', lat: 3.0, lon: 4.0);
      await repo.write('clef', [s1]);
      await repo.write('clef', [s2]);
      expect(await repo.count(), 1, reason: 'pas de doublon');
      final out = await repo.read('clef');
      expect(out!.first.displayName, 'V2');
    });
  });
}
