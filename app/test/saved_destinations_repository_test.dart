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
