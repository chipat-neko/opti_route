// Tests de la conversion JSON (Gemini Edge Function) -> BordereauExtraction.
//
// On ne mocke PAS Supabase ici : trop de coupling avec le client global.
// On teste juste [OcrLlmEnhanceService.parseResponse] qui est la partie
// risquee (mapping JSON -> model), pour se proteger d'un changement
// inattendu du format de reponse Gemini.
//
// La methode `enhance()` est testee implicitement par integration test
// (necessite Edge Function deployee + cle Gemini).

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/ocr_llm_enhance_service.dart';

void main() {
  group('OcrLlmEnhanceService.parseResponse', () {
    test('JSON complet ENLEVEMENT high confidence', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nom_destinataire': 'GARAGE LANCTIN DAMIEN',
        'rue': '31 RUE ARISTIDE BRIAND',
        'code_postal': '28190',
        'ville': 'COURVILLE SUR EURE',
        'nb_colis': 2,
        'telephone': '0237911586',
        'format': 'enlevement',
        'confidence': 'high',
      });
      expect(result.nomDestinataire, 'GARAGE LANCTIN DAMIEN');
      expect(result.rue, '31 RUE ARISTIDE BRIAND');
      expect(result.codePostal, '28190');
      expect(result.ville, 'COURVILLE SUR EURE');
      expect(result.nbColis, 2);
      expect(result.telephone, '0237911586');
      expect(result.format, BordereauFormat.enlevement);
      expect(result.confidence, ExtractionConfidence.high);
      expect(result.source, ExtractionSource.llmGemini);
    });

    test('JSON LIVRAISON low confidence', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nom_destinataire': 'NOVA',
        'code_postal': '28190',
        'ville': 'COURVILLE SUR EURE',
        'format': 'livraison',
        'confidence': 'low',
      });
      expect(result.nomDestinataire, 'NOVA');
      expect(result.format, BordereauFormat.livraison);
      expect(result.confidence, ExtractionConfidence.low);
    });

    test('JSON avec champs null -> extraction avec null', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nom_destinataire': null,
        'rue': null,
        'code_postal': null,
        'ville': null,
        'nb_colis': null,
        'telephone': null,
        'format': 'livraison',
        'confidence': 'none',
      });
      expect(result.nomDestinataire, isNull);
      expect(result.rue, isNull);
      expect(result.codePostal, isNull);
      expect(result.ville, isNull);
      expect(result.nbColis, isNull);
      expect(result.telephone, isNull);
      expect(result.confidence, ExtractionConfidence.none);
    });

    test('JSON avec strings vides -> normalisees a null', () {
      // Le service strip les whitespace puis convertit "" en null.
      final result = OcrLlmEnhanceService.parseResponse({
        'nom_destinataire': '',
        'rue': '   ',
        'code_postal': '',
        'format': 'livraison',
        'confidence': 'low',
      });
      expect(result.nomDestinataire, isNull);
      expect(result.rue, isNull);
      expect(result.codePostal, isNull);
    });

    test('nb_colis en string "3" -> parse a int', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nb_colis': '3',
        'format': 'livraison',
        'confidence': 'high',
      });
      expect(result.nbColis, 3);
    });

    test('nb_colis en double 2.0 -> parse a int 2', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nb_colis': 2.0,
        'format': 'livraison',
        'confidence': 'high',
      });
      expect(result.nbColis, 2);
    });

    test('nb_colis en string invalide "abc" -> null', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nb_colis': 'abc',
        'format': 'livraison',
        'confidence': 'high',
      });
      expect(result.nbColis, isNull);
    });

    test('format inconnu -> fallback livraison', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'format': 'unknown_format',
        'confidence': 'high',
      });
      expect(result.format, BordereauFormat.livraison);
    });

    test('confidence inconnue -> fallback low', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'confidence': 'super_high',
      });
      expect(result.confidence, ExtractionConfidence.low);
    });

    test('JSON sans format / confidence -> defaults', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nom_destinataire': 'TEST',
      });
      expect(result.format, BordereauFormat.livraison);
      expect(result.confidence, ExtractionConfidence.low);
    });

    test('source est TOUJOURS llmGemini (jamais parserLocal)', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nom_destinataire': 'TEST',
        'confidence': 'high',
      });
      expect(result.source, ExtractionSource.llmGemini);
    });

    test('JSON vide -> extraction vide avec defaults', () {
      final result = OcrLlmEnhanceService.parseResponse({});
      expect(result.nomDestinataire, isNull);
      expect(result.format, BordereauFormat.livraison);
      expect(result.confidence, ExtractionConfidence.low);
      expect(result.source, ExtractionSource.llmGemini);
    });

    test('strip whitespace sur les valeurs string', () {
      final result = OcrLlmEnhanceService.parseResponse({
        'nom_destinataire': '  GARAGE LANCTIN DAMIEN  ',
        'rue': '\t31 RUE ARISTIDE BRIAND\n',
        'confidence': 'high',
      });
      expect(result.nomDestinataire, 'GARAGE LANCTIN DAMIEN');
      expect(result.rue, '31 RUE ARISTIDE BRIAND');
    });
  });
}
