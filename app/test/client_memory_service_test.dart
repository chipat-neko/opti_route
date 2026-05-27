// Tests pour ClientMemoryService : fuzzy match Levenshtein du nom OCR
// contre le carnet d'adresses + enrichissement de l'extraction.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/client_memory_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';

void main() {
  late AppDatabase db;
  late SavedDestinationsRepository carnet;
  late ClientMemoryService svc;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    carnet = SavedDestinationsRepository(db);
    svc = ClientMemoryService(carnet);
  });

  tearDown(() async {
    await db.close();
  });

  group('ClientMemoryService.findSimilarClient', () {
    test('carnet vide : retourne null', () async {
      expect(await svc.findSimilarClient('GARAGE X'), isNull);
    });

    test('nom < 3 chars : retourne null (trop court)', () async {
      await carnet.upsertFromValidatedStop(
        nomClient: 'GARAGE LANCTIN',
        adresseDisplay: 'X',
        lat: 48.0,
        lng: 1.0,
      );
      expect(await svc.findSimilarClient('GA'), isNull);
    });

    test('match exact : trouve le client', () async {
      await carnet.upsertFromValidatedStop(
        nomClient: 'GARAGE LANCTIN',
        adresseDisplay: '12 rue X, 28000 Chartres',
        lat: 48.0,
        lng: 1.0,
        ville: 'Chartres',
      );
      final match = await svc.findSimilarClient('GARAGE LANCTIN');
      expect(match, isNotNull);
      expect(match!.nomClient, 'GARAGE LANCTIN');
    });

    test('faute OCR (distance 2) : match accepte par defaultMaxDistance=3',
        () async {
      await carnet.upsertFromValidatedStop(
        nomClient: 'GARAGE LANCTIN',
        adresseDisplay: 'X',
        lat: 48.0,
        lng: 1.0,
      );
      // "LANTCIN" vs "LANCTIN" = swap 2 chars = distance 2.
      final match = await svc.findSimilarClient('GARAGE LANTCIN');
      expect(match, isNotNull);
      expect(match!.nomClient, 'GARAGE LANCTIN');
    });

    test('nom different : ne match pas (distance > 3 + ratio < 0.85)',
        () async {
      await carnet.upsertFromValidatedStop(
        nomClient: 'GARAGE LANCTIN',
        adresseDisplay: 'X',
        lat: 48.0,
        lng: 1.0,
      );
      expect(await svc.findSimilarClient('PHARMACIE DUVAL'), isNull);
    });

    test('homonymes : prefere celui de la bonne ville si specifiee',
        () async {
      await carnet.upsertFromValidatedStop(
        nomClient: 'GARAGE MARTIN',
        adresseDisplay: 'X',
        lat: 48.0,
        lng: 1.0,
        ville: 'Chartres',
      );
      await carnet.upsertFromValidatedStop(
        nomClient: 'GARAGE MARTIN',
        adresseDisplay: 'Y',
        lat: 49.0,
        lng: 2.0,
        ville: 'Dreux',
      );
      // Sans ville : un des 2 (ambigu).
      final ambigu = await svc.findSimilarClient('GARAGE MARTIN');
      expect(ambigu, isNotNull);

      // Avec ville Dreux : doit prendre celui de Dreux.
      final cible = await svc.findSimilarClient(
        'GARAGE MARTIN',
        ville: 'Dreux',
      );
      expect(cible!.ville, 'Dreux');
    });

    test('insensible aux accents et casse', () async {
      await carnet.upsertFromValidatedStop(
        nomClient: 'CRÉPERIE BRETONNE',
        adresseDisplay: 'X',
        lat: 48.0,
        lng: 1.0,
      );
      final match = await svc.findSimilarClient('creperie bretonne');
      expect(match, isNotNull);
    });

    test('clients sans nom (entree adresse seule) : ignores', () async {
      await carnet.upsertFromValidatedStop(
        nomClient: null,
        adresseDisplay: '12 rue X',
        lat: 48.0,
        lng: 1.0,
      );
      expect(await svc.findSimilarClient('quelconque'), isNull);
    });
  });

  group('ClientMemoryService.enrichWithMemory', () {
    test('extraction sans nom : retournee inchangee', () async {
      const extraction = BordereauExtraction(
        confidence: ExtractionConfidence.none,
      );
      final out = await svc.enrichWithMemory(extraction);
      expect(out, same(extraction));
    });

    test('match trouve : enrichi avec nom carnet + adresse', () async {
      await carnet.upsertFromValidatedStop(
        nomClient: 'NOVA',
        adresseDisplay: 'Z rue, 28190 Courville',
        lat: 48.0,
        lng: 1.0,
        rue: 'rue de la Vallee',
        codePostal: '28190',
        ville: 'COURVILLE SUR EURE',
      );

      const ocr = BordereauExtraction(
        nomDestinataire: 'NOVA',
        confidence: ExtractionConfidence.low,
        format: BordereauFormat.livraison,
        source: ExtractionSource.parserLocal,
        nbColis: 2,
      );
      final out = await svc.enrichWithMemory(ocr);

      expect(out.nomDestinataire, 'NOVA');
      expect(out.rue, 'rue de la Vallee');
      expect(out.codePostal, '28190');
      expect(out.ville, 'COURVILLE SUR EURE');
      expect(out.nbColis, 2,
          reason: 'nbColis garde de l\'extraction OCR (specifique scan)');
      expect(out.confidence, ExtractionConfidence.high);
      expect(out.source, ExtractionSource.clientMemory);
    });

    test('aucun match : extraction retournee inchangee', () async {
      await carnet.upsertFromValidatedStop(
        nomClient: 'NOVA',
        adresseDisplay: 'X',
        lat: 48.0,
        lng: 1.0,
      );
      const ocr = BordereauExtraction(
        nomDestinataire: 'CLIENT INCONNU LOIN',
        confidence: ExtractionConfidence.low,
        format: BordereauFormat.livraison,
        source: ExtractionSource.parserLocal,
      );
      final out = await svc.enrichWithMemory(ocr);
      expect(out, same(ocr));
    });
  });
}
