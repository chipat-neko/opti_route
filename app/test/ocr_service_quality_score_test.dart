import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/ocr_service.dart';

OcrResult mk(List<String> lines) => OcrResult(
      fullText: lines.join('\n'),
      lines: lines,
    );

void main() {
  group('OcrService.qualityScore', () {
    test('liste vide -> 0', () {
      expect(OcrService.qualityScore(mk(const [])), 0);
    });

    test('1 ligne avec >=3 alphanum contigus -> 1', () {
      expect(OcrService.qualityScore(mk(['MESEXP'])), 1);
      expect(OcrService.qualityScore(mk(['28000'])), 1);
      expect(OcrService.qualityScore(mk(['Rue de Paris'])), 1);
    });

    test('ligne avec < 3 alphanum contigus -> 0', () {
      expect(OcrService.qualityScore(mk(['ab'])), 0);
      expect(OcrService.qualityScore(mk(['12'])), 0);
      expect(OcrService.qualityScore(mk(['a.b.c'])), 0);
      // 'a-b-c' : 'a', 'b', 'c' separes par tirets, max contigu = 1
      expect(OcrService.qualityScore(mk(['a-b-c'])), 0);
    });

    test('ligne ponctuation seule -> 0', () {
      expect(OcrService.qualityScore(mk(['---'])), 0);
      expect(OcrService.qualityScore(mk(['... !!!'])), 0);
      expect(OcrService.qualityScore(mk(['*** | ***'])), 0);
    });

    test('chiffres seuls comptent quand contigus >= 3', () {
      expect(OcrService.qualityScore(mk(['12345'])), 1);
      expect(OcrService.qualityScore(mk(['1 2 3'])), 0);
    });

    test('compte les lignes valides, pas les caracteres', () {
      final r = mk(['Premiere ligne', 'Deuxieme', 'Troisieme']);
      expect(OcrService.qualityScore(r), 3);
    });

    test('mix de lignes valides et invalides : compte que les valides',
        () {
      final r = mk([
        'MESEXP',
        '---',
        'Destinataire',
        '12',
        '28000',
        '.',
      ]);
      expect(OcrService.qualityScore(r), 3);
    });

    test('threshold 3 inclusif (3 chars suffit)', () {
      expect(OcrService.qualityScore(mk(['abc'])), 1);
      expect(OcrService.qualityScore(mk(['a23'])), 1);
    });

    test('threshold strict : 2 chars insuffisant', () {
      expect(OcrService.qualityScore(mk(['ab'])), 0);
    });

    test('caracteres accentues : ne comptent PAS comme alphanumeriques',
        () {
      // Les regex `[A-Za-z]` ne matchent pas les accents. Donc "etre"
      // valide mais "Aere" valide aussi (la regex matche "ere", 3 chars).
      // Verifier qu'on a le bon comportement (regex strict ASCII).
      expect(OcrService.qualityScore(mk(['etre'])), 1); // 'etre' = 4 chars ASCII
      // Mais 'eee' (juste 3 e accentues) ne compte pas
      expect(OcrService.qualityScore(mk(['éèê'])), 0);
    });

    test('vraie ligne bordereau livraison -> score >= 1', () {
      final r = mk([
        '14 Impasse du Bois',
        '28000 CHARTRES',
        'Tel: 06.12.34.56.78',
      ]);
      expect(OcrService.qualityScore(r), 3);
    });

    test('threshold 8 utilise dans extractFromFileWithRotations', () {
      // Ce test documente que 8 = score "suffisant" pour skip les
      // rotations. Si on change le default qualityThreshold, ce test
      // ne casse PAS (il valide juste qu'un bordereau "typique"
      // depasse facilement 8 lignes valides).
      final r = mk([
        'MESEXP',
        '14 Impasse du Bois',
        '28000 CHARTRES',
        'Destinataire',
        'Jean Dupont',
        'Tel 06123',
        'BON N 12345',
        'Total colis 1',
        'Reception',
      ]);
      expect(OcrService.qualityScore(r), greaterThanOrEqualTo(8));
    });
  });
}
