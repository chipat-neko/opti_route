import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/ocr_service.dart';

void main() {
  group('OcrResult', () {
    test('constructeur conserve fullText + lines', () {
      const r = OcrResult(
        fullText: 'Ligne 1\nLigne 2',
        lines: ['Ligne 1', 'Ligne 2'],
      );
      expect(r.fullText, 'Ligne 1\nLigne 2');
      expect(r.lines, hasLength(2));
      expect(r.lines.first, 'Ligne 1');
    });

    test('liste vide : pas de crash', () {
      const r = OcrResult(fullText: '', lines: []);
      expect(r.lines, isEmpty);
    });
  });
}
