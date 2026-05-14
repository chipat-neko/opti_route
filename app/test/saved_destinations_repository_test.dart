import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

void main() {
  group('SavedDestinationsRepository', () {
    late AppDatabase db;
    late SavedDestinationsRepository repo;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      repo = SavedDestinationsRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('upsert nouveau client : insert avec useCount = 1', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'Garage Aguilar',
        adresseDisplay: '51 Avenue d\'Orleans, 28000 Chartres',
        lat: 48.4307,
        lng: 1.4892,
        rue: '51 Avenue d\'Orleans',
        codePostal: '28000',
        ville: 'Chartres',
      );

      expect(await repo.count(), 1);
      final found = await repo.search('aguilar');
      expect(found, hasLength(1));
      expect(found.first.useCount, 1);
      expect(found.first.nomClient, 'Garage Aguilar');
    });

    test('upsert meme nomClient (case insensitive) : refresh + useCount++',
        () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'Garage Aguilar',
        adresseDisplay: '51 Avenue d\'Orleans, 28000 Chartres',
        lat: 48.4307,
        lng: 1.4892,
      );
      await repo.upsertFromValidatedStop(
        nomClient: 'GARAGE AGUILAR',
        adresseDisplay: '51 Avenue d\'Orleans, 28000 Chartres',
        lat: 48.4307,
        lng: 1.4892,
      );

      expect(await repo.count(), 1);
      final found = await repo.search('aguilar');
      expect(found.first.useCount, 2);
    });

    test('upsert sans nom mais coords proches : merge sur les coords',
        () async {
      await repo.upsertFromValidatedStop(
        nomClient: null,
        adresseDisplay: '51 Avenue d\'Orleans, 28000 Chartres',
        lat: 48.4307,
        lng: 1.4892,
      );
      await repo.upsertFromValidatedStop(
        nomClient: null,
        adresseDisplay: '51 av d Orleans, 28000 Chartres',
        // ~5m d'ecart
        lat: 48.43075,
        lng: 1.48925,
      );

      expect(await repo.count(), 1);
    });

    test('search : matche nomClient OR ville', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'Pharmacie Centrale',
        adresseDisplay: '12 Place du Marche, 28000 Chartres',
        lat: 48.45,
        lng: 1.49,
        ville: 'Chartres',
      );
      await repo.upsertFromValidatedStop(
        nomClient: 'Carrefour Lucé',
        adresseDisplay: 'ZAC, 28110 Lucé',
        lat: 48.44,
        lng: 1.46,
        ville: 'Lucé',
      );

      expect((await repo.search('pharma')).map((d) => d.nomClient),
          contains('Pharmacie Centrale'));
      expect((await repo.search('chartres')).map((d) => d.nomClient),
          contains('Pharmacie Centrale'));
      expect((await repo.search('luce')).map((d) => d.nomClient),
          contains('Carrefour Lucé'));
    });

    test('search : ordre par useCount desc puis lastUsedAt desc', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'Client A',
        adresseDisplay: 'A',
        lat: 1,
        lng: 1,
      );
      await repo.upsertFromValidatedStop(
        nomClient: 'Client B',
        adresseDisplay: 'B',
        lat: 2,
        lng: 2,
      );
      // B utilise 2 fois -> doit ressortir en premier
      await repo.upsertFromValidatedStop(
        nomClient: 'Client B',
        adresseDisplay: 'B',
        lat: 2,
        lng: 2,
      );

      final results = await repo.search('client');
      expect(results.first.nomClient, 'Client B');
    });

    test('search : retourne vide si query < 2 caracteres', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'Aaaa',
        adresseDisplay: 'foo',
        lat: 1,
        lng: 1,
      );
      expect(await repo.search('a'), isEmpty);
      expect(await repo.search(''), isEmpty);
    });

    test('toggleFavori : false -> true -> false', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'A',
        lat: 0,
        lng: 0,
      );
      final entries = await repo.watchAll().first;
      final id = entries.first.id;

      await repo.toggleFavori(id);
      var fresh = await repo.getById(id);
      expect(fresh!.isFavori, isTrue);

      await repo.toggleFavori(id);
      fresh = await repo.getById(id);
      expect(fresh!.isFavori, isFalse);
    });

    test('setColorTag : update + null pour reset', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'A',
        lat: 0,
        lng: 0,
      );
      final entries = await repo.watchAll().first;
      final id = entries.first.id;

      await repo.setColorTag(id, 'lime');
      var fresh = await repo.getById(id);
      expect(fresh!.colorTag, 'lime');

      await repo.setColorTag(id, null);
      fresh = await repo.getById(id);
      expect(fresh!.colorTag, isNull);
    });

    test('count : nb d\'entrees', () async {
      expect(await repo.count(), 0);
      await repo.upsertFromValidatedStop(
        nomClient: 'A',
        adresseDisplay: 'A',
        lat: 0,
        lng: 0,
      );
      await repo.upsertFromValidatedStop(
        nomClient: 'B',
        adresseDisplay: 'B',
        lat: 1,
        lng: 1,
      );
      expect(await repo.count(), 2);
    });

    test('upsert sans nomClient : detection doublon par coords (~11m)',
        () async {
      // 2 upserts avec coords quasi-identiques (delta < 0.0001), sans nom.
      // -> doit etre detecte comme doublon et refresher useCount.
      await repo.upsertFromValidatedStop(
        nomClient: null,
        adresseDisplay: '14 rue X, 28000 Chartres',
        lat: 48.4307,
        lng: 1.4892,
      );
      await repo.upsertFromValidatedStop(
        nomClient: null,
        adresseDisplay: '14 rue X, 28000 Chartres',
        lat: 48.43071, // < 0.0001 delta
        lng: 1.48921,
      );
      expect(await repo.count(), 1);
    });

    test('upsert : coords > 11m -> nouvelle entree', () async {
      await repo.upsertFromValidatedStop(
        nomClient: null,
        adresseDisplay: 'A',
        lat: 48.4307,
        lng: 1.4892,
      );
      await repo.upsertFromValidatedStop(
        nomClient: null,
        adresseDisplay: 'B',
        lat: 48.4400, // ~1 km plus loin
        lng: 1.4892,
      );
      expect(await repo.count(), 2);
    });

    test('delete : retire une entree', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'A',
        lat: 1,
        lng: 1,
      );
      final id = (await repo.watchAll().first).first.id;
      await repo.delete(id);
      expect(await repo.count(), 0);
    });

    test('watchAll : favori en haut peu importe useCount', () async {
      // A : tres utilise mais pas favori. B : 1x use mais favori.
      await repo.upsertFromValidatedStop(
        nomClient: 'A',
        adresseDisplay: 'A',
        lat: 1,
        lng: 1,
      );
      await repo.upsertFromValidatedStop(
        nomClient: 'A',
        adresseDisplay: 'A',
        lat: 1,
        lng: 1,
      );
      await repo.upsertFromValidatedStop(
        nomClient: 'A',
        adresseDisplay: 'A',
        lat: 1,
        lng: 1,
      );
      await repo.upsertFromValidatedStop(
        nomClient: 'B',
        adresseDisplay: 'B',
        lat: 2,
        lng: 2,
      );
      final entries = await repo.watchAll().first;
      final bId = entries.firstWhere((d) => d.nomClient == 'B').id;
      await repo.toggleFavori(bId);

      final ordered = await repo.watchAll().first;
      expect(ordered.first.nomClient, 'B'); // favori en haut
    });

    test('search : accents (Luce == Lucé), insensible diacritiques',
        () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'Carrefour Lucé',
        adresseDisplay: 'ZAC, 28110 Lucé',
        lat: 48.44,
        lng: 1.46,
        ville: 'Lucé',
      );
      // Sans accent
      expect((await repo.search('luce')).map((d) => d.nomClient),
          contains('Carrefour Lucé'));
      // Avec accent
      expect((await repo.search('Lucé')).map((d) => d.nomClient),
          contains('Carrefour Lucé'));
    });

    test('setTags : encode/decode round-trip', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'addr',
        lat: 0,
        lng: 0,
      );
      final id = (await repo.watchAll().first).first.id;

      await repo.setTags(id, ['pro', 'fragile', 'codé']);
      final entry = await repo.getById(id);
      final tags = SavedDestinationsRepository.parseTags(entry!.tagsJson);
      expect(tags, ['pro', 'fragile', 'codé']);
    });

    test('setTags null : retire les tags', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'addr',
        lat: 0,
        lng: 0,
      );
      final id = (await repo.watchAll().first).first.id;
      await repo.setTags(id, ['pro']);
      await repo.setTags(id, null);
      final entry = await repo.getById(id);
      expect(entry!.tagsJson, isNull);
    });

    test('setTags liste vide : stocke null', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'addr',
        lat: 0,
        lng: 0,
      );
      final id = (await repo.watchAll().first).first.id;
      await repo.setTags(id, []);
      final entry = await repo.getById(id);
      expect(entry!.tagsJson, isNull);
    });

    test('parseTags : null / vide / malforme -> []', () {
      expect(SavedDestinationsRepository.parseTags(null), isEmpty);
      expect(SavedDestinationsRepository.parseTags(''), isEmpty);
      expect(SavedDestinationsRepository.parseTags('garbage'), isEmpty);
      expect(SavedDestinationsRepository.parseTags('[]'), isEmpty);
    });

    test('setPhotoPath + getById : round-trip', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'addr',
        lat: 0,
        lng: 0,
      );
      final id = (await repo.watchAll().first).first.id;
      await repo.setPhotoPath(id, '/data/photos/12.jpg');
      final entry = await repo.getById(id);
      expect(entry!.photoPath, '/data/photos/12.jpg');
    });

    test('update : codeAcces + etageBatiment', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'addr',
        lat: 0,
        lng: 0,
      );
      final id = (await repo.watchAll().first).first.id;
      await repo.update(
        id,
        codeAcces: '1234B',
        etageBatiment: 'Bat C, 3e etage',
      );
      final entry = await repo.getById(id);
      expect(entry!.codeAcces, '1234B');
      expect(entry.etageBatiment, 'Bat C, 3e etage');
    });

    test('update : modifie notesCarnet', () async {
      await repo.upsertFromValidatedStop(
        nomClient: 'X',
        adresseDisplay: 'addr',
        lat: 0,
        lng: 0,
      );
      final entries = await repo.watchAll().first;
      final id = entries.first.id;

      await repo.update(id, notesCarnet: 'Code 1234B');
      final fresh = await repo.getById(id);
      expect(fresh!.notesCarnet, 'Code 1234B');
    });
  });
}
