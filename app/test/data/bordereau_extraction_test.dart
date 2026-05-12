import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';

void main() {
  group('BordereauExtraction.hasUsefulData', () {
    test('extraction vide : false', () {
      const e = BordereauExtraction();
      expect(e.hasUsefulData, isFalse);
    });

    test('nom destinataire seul : true', () {
      const e = BordereauExtraction(nomDestinataire: 'CALOTE Noah');
      expect(e.hasUsefulData, isTrue);
    });

    test('rue seule : true', () {
      const e = BordereauExtraction(rue: '12 rue X');
      expect(e.hasUsefulData, isTrue);
    });

    test('codePostal seul : true (rare, mais accepte)', () {
      const e = BordereauExtraction(codePostal: '28100');
      expect(e.hasUsefulData, isTrue);
    });

    test('seulement telephone : false (insuffisant pour adresse)', () {
      const e = BordereauExtraction(telephone: '0600000000');
      expect(e.hasUsefulData, isFalse);
    });
  });

  group('BordereauExtraction.adressePostale', () {
    test('rien : null', () {
      const e = BordereauExtraction();
      expect(e.adressePostale, isNull);
    });

    test('rue + cp + ville : "rue, cp ville"', () {
      const e = BordereauExtraction(
        rue: '12 rue des Lilas',
        codePostal: '28100',
        ville: 'Dreux',
      );
      expect(e.adressePostale, '12 rue des Lilas, 28100 Dreux');
    });

    test('rue seule : juste la rue', () {
      const e = BordereauExtraction(rue: '12 rue X');
      expect(e.adressePostale, '12 rue X');
    });

    test('cp + ville sans rue : "cp ville"', () {
      const e = BordereauExtraction(
        codePostal: '28100',
        ville: 'Dreux',
      );
      expect(e.adressePostale, '28100 Dreux');
    });

    test('cp seul sans ville : juste le cp', () {
      const e = BordereauExtraction(codePostal: '28100');
      expect(e.adressePostale, '28100');
    });
  });

  group('BordereauExtraction.rechercheParNom', () {
    test('rien : null', () {
      const e = BordereauExtraction();
      expect(e.rechercheParNom, isNull);
    });

    test('nom seul : nom', () {
      const e = BordereauExtraction(nomDestinataire: 'Carrefour');
      expect(e.rechercheParNom, 'Carrefour');
    });

    test('nom + ville : "nom ville"', () {
      const e = BordereauExtraction(
        nomDestinataire: 'Carrefour',
        ville: 'Dreux',
      );
      expect(e.rechercheParNom, 'Carrefour Dreux');
    });
  });

  group('BordereauExtraction.confidence', () {
    test('defaut : high', () {
      const e = BordereauExtraction();
      expect(e.confidence, ExtractionConfidence.high);
    });

    test('low : remplace high explicitement', () {
      const e = BordereauExtraction(
        confidence: ExtractionConfidence.low,
        rue: 'rue X',
      );
      expect(e.confidence, ExtractionConfidence.low);
    });

    test('none : aucun marqueur trouve', () {
      const e = BordereauExtraction(confidence: ExtractionConfidence.none);
      expect(e.confidence, ExtractionConfidence.none);
      expect(e.hasUsefulData, isFalse);
    });

    test('enum ExtractionConfidence : 3 valeurs', () {
      expect(ExtractionConfidence.values, hasLength(3));
      expect(ExtractionConfidence.values, containsAll([
        ExtractionConfidence.high,
        ExtractionConfidence.low,
        ExtractionConfidence.none,
      ]));
    });
  });
}
