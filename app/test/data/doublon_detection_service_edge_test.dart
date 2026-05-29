import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/doublon_detection_service.dart';

// Complete doublon_detection_service_test : cas-limites (gardes, tri,
// fiches anonymes, combinatoires).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<SavedDestination> insert({
    String? nom,
    required String adresse,
    required double lat,
    required double lng,
    String? rue,
    String? cp,
    String? ville,
  }) async {
    final id = await db.into(db.savedDestinations).insert(
          SavedDestinationsCompanion.insert(
            nomClient: Value(nom),
            adresseDisplay: adresse,
            lat: lat,
            lng: lng,
            rue: Value(rue),
            codePostal: Value(cp),
            ville: Value(ville),
          ),
        );
    return (db.select(db.savedDestinations)
          ..where((s) => s.id.equals(id)))
        .getSingle();
  }

  group('DoublonDetectionService — gardes negatives', () {
    test('1 fiche seule : aucune paire', () async {
      final a = await insert(nom: 'X', adresse: '1 rue X', lat: 48, lng: 1);
      expect(DoublonDetectionService.detect([a]), isEmpty);
    });

    test('nom similaire mais GPS loin (>100 m) : pas de doublon (heuristique 1)',
        () async {
      // 1 deg lat = ~111 km > 100m
      final a =
          await insert(nom: 'GARAGE X', adresse: 'A', lat: 48, lng: 1);
      final b =
          await insert(nom: 'GARAGE X', adresse: 'B', lat: 49, lng: 1);
      final paires = DoublonDetectionService.detect([a, b]);
      // Pas heuristique 1 (GPS loin) ni 2 (adresses differentes) ni 3
      // (nom identique mais ville absente -> bothNamed=true mais villeA
      // vide donc heuristique 3 skip).
      expect(paires, isEmpty);
    });

    test('GPS proche mais noms tres differents : pas de doublon', () async {
      final a = await insert(
          nom: 'GARAGE LANCTIN', adresse: 'A', lat: 48, lng: 1);
      final b = await insert(
          nom: 'BOULANGERIE MARTIN', adresse: 'B', lat: 48.0001, lng: 1);
      final paires = DoublonDetectionService.detect([a, b]);
      // Heuristique 1 : levenshtein >> 2. Heuristique 2 : adresses
      // differentes. Heuristique 3 : noms differents.
      expect(paires, isEmpty);
    });

    test('une fiche sans nom : heuristique 1 et 3 ne s\'appliquent pas',
        () async {
      final a = await insert(adresse: '1 rue X', lat: 48, lng: 1);
      final b = await insert(
          nom: 'X', adresse: '2 rue Y', lat: 48.0001, lng: 1);
      final paires = DoublonDetectionService.detect([a, b]);
      // bothNamed=false (a sans nom) -> heuristique 1 et 3 skip.
      // Adresses differentes -> heuristique 2 skip aussi.
      expect(paires, isEmpty);
    });
  });

  group('DoublonDetectionService — heuristique 2 (meme adresse)', () {
    test('meme rue+CP+ville (noms differents) : meme adresse', () async {
      // Noms tres differents pour bypasser heuristique 1 (Levenshtein).
      final a = await insert(
        nom: 'BOULANGERIE MARTIN',
        adresse: 'A',
        rue: '12 rue de la Paix',
        cp: '28100',
        ville: 'Dreux',
        lat: 48.0,
        lng: 1.0,
      );
      final b = await insert(
        nom: 'GARAGE LANCTIN',
        adresse: 'B',
        rue: '12 rue de la Paix',
        cp: '28100',
        ville: 'Dreux',
        lat: 48.0001,
        lng: 1.0001,
      );
      final paires = DoublonDetectionService.detect([a, b]);
      expect(paires, hasLength(1));
      expect(paires.first.raison, contains('adresse'));
    });

    test('meme rue mais CP different : pas un doublon', () async {
      final a = await insert(
        adresse: 'A',
        rue: '12 rue X',
        cp: '28100',
        ville: 'Dreux',
        lat: 48,
        lng: 1,
      );
      final b = await insert(
        adresse: 'B',
        rue: '12 rue X',
        cp: '28200',
        ville: 'Dreux',
        lat: 48.5,
        lng: 1,
      );
      expect(DoublonDetectionService.detect([a, b]), isEmpty);
    });
  });

  group('DoublonDetectionService — tri par distance croissante', () {
    test('3 paires : sorties par distance ascendante', () async {
      // a-b proches (5m), c-d moyens (50m), e-f proches (~10m).
      final a = await insert(adresse: 'X', rue: '1 r X', cp: '28000', ville: 'V', lat: 48, lng: 1);
      final b = await insert(adresse: 'X', rue: '1 r X', cp: '28000', ville: 'V', lat: 48.00004, lng: 1);
      final c = await insert(adresse: 'Y', rue: '1 r Y', cp: '28000', ville: 'V', lat: 48.5, lng: 1);
      final d = await insert(adresse: 'Y', rue: '1 r Y', cp: '28000', ville: 'V', lat: 48.50045, lng: 1); // ~50m
      final e = await insert(adresse: 'Z', rue: '1 r Z', cp: '28000', ville: 'V', lat: 48.6, lng: 1);
      final f = await insert(adresse: 'Z', rue: '1 r Z', cp: '28000', ville: 'V', lat: 48.60009, lng: 1); // ~10m
      final paires = DoublonDetectionService.detect([a, b, c, d, e, f]);
      expect(paires, hasLength(3));
      // Verifie l'ordre croissant
      for (var i = 1; i < paires.length; i++) {
        expect(
          paires[i].distanceMeters,
          greaterThanOrEqualTo(paires[i - 1].distanceMeters),
        );
      }
    });
  });

  group('DoublonDetectionService — meme nom + meme ville (heuristique 3)',
      () {
    test('meme nom + meme ville mais GPS LOIN ET adresses differentes -> doublon',
        () async {
      // 50 km de distance, mais meme nom + meme ville.
      final a = await insert(
        nom: 'GARAGE X',
        adresse: 'A',
        ville: 'Dreux',
        lat: 48,
        lng: 1,
      );
      final b = await insert(
        nom: 'GARAGE X',
        adresse: 'B',
        ville: 'Dreux',
        lat: 48.5,
        lng: 1,
      );
      final paires = DoublonDetectionService.detect([a, b]);
      expect(paires, hasLength(1));
      expect(paires.first.raison, contains('nom'));
    });

    test('meme nom + ville differente : pas un doublon', () async {
      final a = await insert(
        nom: 'GARAGE X',
        adresse: 'A',
        ville: 'Dreux',
        lat: 48,
        lng: 1,
      );
      final b = await insert(
        nom: 'GARAGE X',
        adresse: 'B',
        ville: 'Chartres',
        lat: 48.5,
        lng: 1,
      );
      // Heuristique 1 : GPS loin -> skip. Heuristique 2 : adresses
      // differentes. Heuristique 3 : meme nom mais villes differentes.
      expect(DoublonDetectionService.detect([a, b]), isEmpty);
    });
  });
}
