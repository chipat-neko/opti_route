import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/address_suggestion.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/geocode_cache_repository.dart';

/// Tests sur GeocodeCacheRepository.readByPrefix (V7.5).
///
/// On utilise une DB Drift en memoire pour valider les garde-fous
/// anti-faux-positifs : prefixe >= 4 chars, filtre par contenu
/// textuel, minimum 2 resultats apres filtrage.
void main() {
  group('GeocodeCacheRepository.readByPrefix (V7.5)', () {
    late AppDatabase db;
    late GeocodeCacheRepository cache;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      cache = GeocodeCacheRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('cache vide -> null', () async {
      expect(await cache.readByPrefix('ban:chart'), isNull);
    });

    test('prefixe < 4 chars -> null (garde-fou)', () async {
      // On rempli un cache qui matcherait, mais le prefix trop court
      // -> on refuse pour eviter les faux positifs.
      await cache.write('ban:char', [
        _suggestion(displayName: 'Chartres', city: 'Chartres'),
        _suggestion(displayName: 'Charles de Gaulle', city: 'Paris'),
      ]);
      expect(await cache.readByPrefix('ban'), isNull);
      expect(await cache.readByPrefix('ban:c'), isNull);
    });

    test('hit cache plus large, prefix matche textuellement -> retourne',
        () async {
      // On a mis en cache "chartres" (8 chars). On cherche "chart" qui
      // est un prefix valide. Les 2 entrees ont des coords differentes
      // (sinon dedup ramene a 1).
      await cache.write('ban:chartres', [
        _suggestion(
            displayName: '1 Rue Test, 28000 Chartres',
            city: 'Chartres',
            lat: 48.45,
            lon: 1.48),
        _suggestion(
            displayName: '2 Rue Test, 28000 Chartres',
            city: 'Chartres',
            lat: 48.46,
            lon: 1.49),
      ]);
      final results = await cache.readByPrefix('ban:chart');
      expect(results, isNotNull);
      expect(results!.length, 2);
      expect(results.every((s) => s.city == 'Chartres'), isTrue);
    });

    test('resultats non-pertinents filtres', () async {
      // On a en cache "ban:c" qui contient 1 resultat Chartres et 5
      // resultats Charles de Gaulle.
      // En cherchant "ban:chart" (5 chars), apres filtrage, seul
      // Chartres reste -> < 2 resultats -> null (anti-faux-positif).
      await cache.write('ban:chartres', [
        _suggestion(displayName: '1 Rue, 28000 Chartres', city: 'Chartres'),
        _suggestion(displayName: 'Aeroport Charles de Gaulle', city: 'Paris'),
        _suggestion(displayName: 'Pont Charles', city: 'Reims'),
      ]);
      final results = await cache.readByPrefix('ban:chart');
      // 1 seul matche le prefix "chart" dans le contenu (Chartres) -> null.
      expect(results, isNull);
    });

    test('entree expiree ignoree', () async {
      await cache.write(
        'ban:chartres',
        [
          _suggestion(
              displayName: '1 Rue, 28000 Chartres', city: 'Chartres'),
          _suggestion(
              displayName: '2 Rue, 28000 Chartres', city: 'Chartres'),
        ],
        ttl: const Duration(milliseconds: 1),
      );
      // Attendre que l'entree expire.
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(await cache.readByPrefix('ban:chart'), isNull);
    });

    test('plusieurs entrees avec prefixe commun fusionnees + dedupees',
        () async {
      await cache.write('ban:chartres centre', [
        _suggestion(
            displayName: '1 Rue Test', city: 'Chartres', lat: 48.45, lon: 1.48),
        _suggestion(
            displayName: '2 Rue Test', city: 'Chartres', lat: 48.46, lon: 1.49),
      ]);
      await cache.write('ban:chartres mairie', [
        // Meme coord que ci-dessus -> deduplique.
        _suggestion(
            displayName: '1 Rue Test', city: 'Chartres', lat: 48.45, lon: 1.48),
        _suggestion(
            displayName: 'Mairie', city: 'Chartres', lat: 48.447, lon: 1.489),
      ]);
      final results = await cache.readByPrefix('ban:chartres');
      expect(results, isNotNull);
      // 3 coords distinctes apres dedup (la 1 et la 1' partagent les
      // memes coords).
      expect(results!.length, 3);
    });
  });
}

AddressSuggestion _suggestion({
  required String displayName,
  String? city,
  double lat = 48.0,
  double lon = 1.0,
  String? road,
  String? poiName,
}) {
  return AddressSuggestion(
    displayName: displayName,
    lat: lat,
    lon: lon,
    city: city,
    road: road,
    poiName: poiName,
  );
}
