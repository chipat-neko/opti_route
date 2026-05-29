import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';

// Complete bordereau_extraction_test : strings vides vs null, defauts
// format/source, et rechercheParNom avec ville vide.
void main() {
  group('BordereauExtraction — null vs empty string', () {
    test('hasUsefulData : champ vide ("") est consideree "presente"', () {
      // Bug-shield : hasUsefulData fait `!= null`, pas `.isNotEmpty`.
      // Donc une rue = "" compte comme "useful" (pourrait surprendre).
      const e = BordereauExtraction(rue: '');
      expect(e.hasUsefulData, isTrue);
    });

    test('adressePostale : rue vide n\'est PAS incluse dans la sortie', () {
      const e = BordereauExtraction(
        rue: '',
        codePostal: '28100',
        ville: 'Dreux',
      );
      expect(e.adressePostale, '28100 Dreux',
          reason: 'rue="" doit etre ignoree, pas "  , 28100 Dreux"');
    });

    test('adressePostale : codePostal vide est ignore', () {
      const e = BordereauExtraction(rue: '12 rue X', codePostal: '');
      expect(e.adressePostale, '12 rue X');
    });

    test('adressePostale : ville vide -> "cp" seul si cp present', () {
      const e = BordereauExtraction(codePostal: '28100', ville: '');
      expect(e.adressePostale, '28100');
    });

    test('rechercheParNom : nom vide -> null (pas la string vide)', () {
      const e = BordereauExtraction(nomDestinataire: '', ville: 'Dreux');
      expect(e.rechercheParNom, isNull);
    });

    test('rechercheParNom : ville vide -> nom seul (pas "nom ")', () {
      const e = BordereauExtraction(
        nomDestinataire: 'Carrefour',
        ville: '',
      );
      expect(e.rechercheParNom, 'Carrefour');
    });
  });

  group('BordereauExtraction — defauts format/source', () {
    test('format defaut : livraison', () {
      const e = BordereauExtraction();
      expect(e.format, BordereauFormat.livraison);
    });

    test('source defaut : parserLocal', () {
      const e = BordereauExtraction();
      expect(e.source, ExtractionSource.parserLocal);
    });

    test('format ENLEVEMENT explicite', () {
      const e = BordereauExtraction(format: BordereauFormat.enlevement);
      expect(e.format, BordereauFormat.enlevement);
    });

    test('source llmGemini explicite', () {
      const e = BordereauExtraction(source: ExtractionSource.llmGemini);
      expect(e.source, ExtractionSource.llmGemini);
    });

    test('source clientMemory explicite', () {
      const e = BordereauExtraction(source: ExtractionSource.clientMemory);
      expect(e.source, ExtractionSource.clientMemory);
    });
  });

  group('Enums : completude', () {
    test('BordereauFormat : 2 valeurs (livraison, enlevement)', () {
      expect(BordereauFormat.values, hasLength(2));
      expect(BordereauFormat.values,
          containsAll(const [BordereauFormat.livraison, BordereauFormat.enlevement]));
    });

    test('ExtractionSource : 3 valeurs', () {
      expect(ExtractionSource.values, hasLength(3));
      expect(ExtractionSource.values, containsAll(const [
        ExtractionSource.parserLocal,
        ExtractionSource.clientMemory,
        ExtractionSource.llmGemini,
      ]));
    });
  });
}
