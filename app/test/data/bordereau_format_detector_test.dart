import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart' show BordereauFormat;
import 'package:opti_route/data/bordereau_format_detector.dart';

// Tests purs : détection ENLEVEMENT vs LIVRAISON à partir des lignes OCR.
void main() {
  group('BordereauFormatDetector.detect', () {
    test('label "ENLEVEMENT" en majuscules -> enlevement', () {
      expect(
        BordereauFormatDetector.detect(['MODE : ENLEVEMENT obligatoire']),
        BordereauFormat.enlevement,
      );
    });

    test('"enlever chez" -> enlevement', () {
      expect(
        BordereauFormatDetector.detect(['à enlever chez M. Dupont']),
        BordereauFormat.enlevement,
      );
    });

    test('"d\'enlèvement" (avec accent) -> enlevement', () {
      expect(
        BordereauFormatDetector.detect(["Date d'enlèvement : 12/05"]),
        BordereauFormat.enlevement,
      );
    });

    test('"d\'enlevement" (sans accent) -> enlevement', () {
      expect(
        BordereauFormatDetector.detect(["Periode d'enlevement : matin"]),
        BordereauFormat.enlevement,
      );
    });

    test('aucune clé -> livraison (défaut)', () {
      expect(
        BordereauFormatDetector.detect([
          'DESTINATAIRE',
          'NOVA',
          '12 RUE DES LILAS',
          '28000 CHARTRES',
        ]),
        BordereauFormat.livraison,
      );
    });

    test('liste vide -> livraison (défaut)', () {
      expect(
        BordereauFormatDetector.detect(const []),
        BordereauFormat.livraison,
      );
    });

    test('1ère occurrence suffit (court-circuit)', () {
      expect(
        BordereauFormatDetector.detect([
          'à enlever chez',
          'DESTINATAIRE',
        ]),
        BordereauFormat.enlevement,
      );
    });
  });
}
