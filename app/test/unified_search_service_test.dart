import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/unified_search_service.dart';

void main() {
  late AppDatabase db;
  late UnifiedSearchService svc;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    svc = UnifiedSearchService(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTournee({required String nom}) async {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: nom,
            date: DateTime(2026, 5, 14),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'Depot',
          ),
        );
  }

  Future<int> seedStop({
    required int tourneeId,
    String? nomClient,
    String adresseBrute = 'A',
    String? notes,
  }) async {
    return db.into(db.stops).insert(
          StopsCompanion.insert(
            tourneeId: tourneeId,
            adresseBrute: adresseBrute,
            nomClient: Value(nomClient),
            notes: Value(notes),
          ),
        );
  }

  Future<int> seedCarnet({
    String? nomClient,
    required String adresseDisplay,
    String? ville,
  }) async {
    return db.into(db.savedDestinations).insert(
          SavedDestinationsCompanion.insert(
            adresseDisplay: adresseDisplay,
            lat: 48.0,
            lng: 1.0,
            nomClient: Value(nomClient),
            ville: Value(ville),
          ),
        );
  }

  group('UnifiedSearchService.search', () {
    test('query < 2 caracteres : retourne vide', () async {
      await seedTournee(nom: 'Bordeaux centre');
      expect(await svc.search(''), isEmpty);
      expect(await svc.search('a'), isEmpty);
    });

    test('base vide : retourne vide', () async {
      expect(await svc.search('boulangerie'), isEmpty);
    });

    test('match exact sur le nom d\'une tournee', () async {
      await seedTournee(nom: 'Bordeaux centre mardi');
      final hits = await svc.search('bordeaux');
      expect(hits, hasLength(1));
      expect(hits.first, isA<SearchHitTournee>());
      final t = hits.first as SearchHitTournee;
      expect(t.tournee.nom, 'Bordeaux centre mardi');
    });

    test('fuzzy match avec faute de frappe', () async {
      await seedTournee(nom: 'Bordeaux centre');
      // L'utilisateur tape "bordo" -> doit quand meme matcher
      final hits = await svc.search('bordeau');
      expect(hits.isNotEmpty, true);
      expect(hits.first, isA<SearchHitTournee>());
    });

    test('match sur le nom client d\'un stop, retourne aussi la tournee parente',
        () async {
      final tId = await seedTournee(nom: 'Tournee Mardi');
      await seedStop(
        tourneeId: tId,
        nomClient: 'Boulangerie Martin',
        adresseBrute: '12 rue Sainte-Catherine',
      );
      final hits = await svc.search('boulangerie');
      expect(hits, hasLength(1));
      final h = hits.first as SearchHitStop;
      expect(h.stop.nomClient, 'Boulangerie Martin');
      expect(h.tournee.nom, 'Tournee Mardi');
    });

    test('match sur l\'adresse brute d\'un stop', () async {
      final tId = await seedTournee(nom: 'T');
      await seedStop(
        tourneeId: tId,
        adresseBrute: '12 rue Sainte-Catherine Bordeaux',
      );
      final hits = await svc.search('catherine');
      expect(hits, hasLength(1));
      expect(hits.first, isA<SearchHitStop>());
    });

    test('match sur les notes d\'un stop (codes interphones)', () async {
      final tId = await seedTournee(nom: 'T');
      await seedStop(
        tourneeId: tId,
        adresseBrute: 'A',
        notes: 'Code 1234B - sonner Martin',
      );
      final hits = await svc.search('1234B');
      expect(hits, hasLength(1));
      expect(hits.first, isA<SearchHitStop>());
    });

    test('match sur le carnet d\'adresses', () async {
      await seedCarnet(
        nomClient: 'Pharmacie Lafayette',
        adresseDisplay: '8 cours Pasteur 33000 Bordeaux',
        ville: 'Bordeaux',
      );
      final hits = await svc.search('pharmacie');
      expect(hits, hasLength(1));
      expect(hits.first, isA<SearchHitClient>());
      final c = hits.first as SearchHitClient;
      expect(c.client.nomClient, 'Pharmacie Lafayette');
    });

    test('match cross-sources : tournee + stop + client', () async {
      final tId = await seedTournee(nom: 'Bordeaux centre');
      await seedStop(
        tourneeId: tId,
        nomClient: 'Bordeaux Vins',
        adresseBrute: 'Bordeaux',
      );
      await seedCarnet(
        nomClient: 'Bordeaux Express',
        adresseDisplay: 'X',
        ville: 'Bordeaux',
      );
      final hits = await svc.search('bordeaux');
      // 1 tournee + 1 stop + 1 client
      expect(hits, hasLength(3));
      expect(hits.whereType<SearchHitTournee>(), hasLength(1));
      expect(hits.whereType<SearchHitStop>(), hasLength(1));
      expect(hits.whereType<SearchHitClient>(), hasLength(1));
    });

    test('limite a 10 hits par categorie', () async {
      // 12 tournees toutes nommees pareil
      for (var i = 0; i < 12; i++) {
        await seedTournee(nom: 'Bordeaux #$i');
      }
      final hits = await svc.search('bordeaux');
      // Devrait etre limite a 10
      expect(hits.whereType<SearchHitTournee>().length, 10);
    });

    test('tri par score ascendant : matches exacts en premier', () async {
      await seedTournee(nom: 'Bordeaux'); // exact
      await seedTournee(nom: 'Bordeaux centre lundi'); // moins exact
      final hits = await svc.search('bordeaux');
      expect(hits.length, 2);
      expect(hits[0].score, lessThanOrEqualTo(hits[1].score));
    });

    test('ne retourne rien si tous les hits sont au-dessus du seuil',
        () async {
      await seedTournee(nom: 'Paris nord');
      final hits = await svc.search('xyzwabc');
      expect(hits, isEmpty);
    });
  });
}
