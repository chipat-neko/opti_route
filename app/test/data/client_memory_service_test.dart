// Tests du fuzzy matching client. Utilise une DB in-memory pour
// peupler le carnet sans toucher au filesystem reel.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/client_memory_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/saved_destinations_repository.dart';
import 'package:drift/drift.dart' show Value;

void main() {
  late AppDatabase db;
  late SavedDestinationsRepository repo;
  late ClientMemoryService service;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = SavedDestinationsRepository(db);
    service = ClientMemoryService(repo);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> insert({
    required String nom,
    String rue = '',
    String? cp,
    String? ville,
    double lat = 48.0,
    double lng = 1.0,
  }) {
    return db.into(db.savedDestinations).insert(
          SavedDestinationsCompanion.insert(
            nomClient: Value(nom),
            adresseDisplay: '$rue, ${cp ?? ''} ${ville ?? ''}'.trim(),
            lat: lat,
            lng: lng,
            rue: Value(rue.isEmpty ? null : rue),
            codePostal: Value(cp),
            ville: Value(ville),
          ),
        );
  }

  group('ClientMemoryService.findSimilarClient', () {
    test('carnet vide -> null', () async {
      final match = await service.findSimilarClient('GARAGE LANCTIN');
      expect(match, isNull);
    });

    test('match exact', () async {
      await insert(nom: 'GARAGE LANCTIN DAMIEN', ville: 'COURVILLE');
      final match = await service.findSimilarClient('GARAGE LANCTIN DAMIEN');
      expect(match, isNotNull);
      expect(match!.nomClient, 'GARAGE LANCTIN DAMIEN');
    });

    test('match fuzzy distance 2 (faute OCR)', () async {
      await insert(nom: 'GARAGE LANCTIN DAMIEN', ville: 'COURVILLE');
      // 1 substitution + 1 suppression = distance 2.
      final match = await service.findSimilarClient('GARAGE LANTCN DAMIEN');
      expect(match, isNotNull);
      expect(match!.nomClient, 'GARAGE LANCTIN DAMIEN');
    });

    test('match fuzzy avec ratio (nom long, distance plus grande tolere)',
        () async {
      await insert(nom: 'CARROSSERIE COCULO PEINTURE', ville: 'CHARTRES');
      // Distance 4 mais ratio > 0.85 sur nom long.
      final match = await service.findSimilarClient('CARROSERIE COCULO PEINTUR');
      expect(match, isNotNull);
      expect(match!.nomClient, 'CARROSSERIE COCULO PEINTURE');
    });

    test('rejet si distance trop grande ET ratio trop faible', () async {
      await insert(nom: 'GARAGE LANCTIN', ville: 'COURVILLE');
      final match = await service.findSimilarClient('NOM COMPLETEMENT DIFFERENT');
      expect(match, isNull);
    });

    test('rejet si nom trop court (< 3 chars)', () async {
      await insert(nom: 'NOVA', ville: 'COURVILLE');
      final match = await service.findSimilarClient('AB');
      expect(match, isNull);
    });

    test('bonus ville : prefere le match avec ville correspondante',
        () async {
      await insert(
          nom: 'GARAGE LANCTIN', cp: '28190', ville: 'COURVILLE SUR EURE');
      await insert(
          nom: 'GARAGE LANCTIN', cp: '28400', ville: 'NOGENT LE ROTROU');
      final match = await service.findSimilarClient('GARAGE LANCTIN',
          ville: 'NOGENT LE ROTROU');
      expect(match, isNotNull);
      expect(match!.ville, 'NOGENT LE ROTROU');
    });

    test('normalisation accents : Lucé == LUCE', () async {
      await insert(nom: 'CARROSSERIE LUCÉ', ville: 'LUCE');
      final match = await service.findSimilarClient('CARROSSERIE LUCE');
      expect(match, isNotNull);
    });

    test('case insensitive', () async {
      await insert(nom: 'Garage Lanctin Damien', ville: 'COURVILLE');
      final match = await service.findSimilarClient('GARAGE LANCTIN DAMIEN');
      expect(match, isNotNull);
    });
  });

  group('ClientMemoryService.enrichWithMemory', () {
    test('match trouve -> nom + adresse remplaces, source = clientMemory',
        () async {
      await insert(
        nom: 'GARAGE LANCTIN DAMIEN',
        rue: '31 RUE ARISTIDE BRIAND',
        cp: '28190',
        ville: 'COURVILLE SUR EURE',
      );
      final ocr = BordereauExtraction(
        nomDestinataire: 'GARAGE LANTCN DAMIEN', // faute OCR
        rue: '31 RUE BRIAND', // approximatif OCR
        codePostal: null,
        ville: 'COURVILLE',
        nbColis: 2,
        telephone: '0237911586',
        confidence: ExtractionConfidence.low,
        format: BordereauFormat.enlevement,
      );
      final enriched = await service.enrichWithMemory(ocr);
      expect(enriched.nomDestinataire, 'GARAGE LANCTIN DAMIEN');
      expect(enriched.rue, '31 RUE ARISTIDE BRIAND'); // carnet
      expect(enriched.codePostal, '28190'); // carnet
      expect(enriched.ville, 'COURVILLE SUR EURE'); // carnet
      expect(enriched.nbColis, 2); // preserve OCR
      expect(enriched.telephone, '0237911586'); // preserve OCR
      expect(enriched.confidence, ExtractionConfidence.high); // boost
      expect(enriched.format, BordereauFormat.enlevement); // preserve
      expect(enriched.source, ExtractionSource.clientMemory);
    });

    test('pas de match -> extraction inchangee', () async {
      await insert(nom: 'AUTRE CLIENT', ville: 'AUTRE VILLE');
      final ocr = BordereauExtraction(
        nomDestinataire: 'NOM JAMAIS VU',
        confidence: ExtractionConfidence.low,
      );
      final result = await service.enrichWithMemory(ocr);
      expect(result, same(ocr));
    });

    test('extraction sans nom -> inchangee', () async {
      const ocr = BordereauExtraction(
        nomDestinataire: null,
        confidence: ExtractionConfidence.none,
      );
      final result = await service.enrichWithMemory(ocr);
      expect(result, same(ocr));
    });
  });
}
