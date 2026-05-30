import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/ocr_stats_log.dart';

// Tests directs de la data class OcrBaselineStats : empty factory,
// total, greenRate/orangeRate/redRate avec divers ratios. Couvre les
// getters sans dependre de l'I/O CSV (qui est dans ocr_stats_log_test).
void main() {
  group('OcrBaselineStats.empty()', () {
    test('all 0 + tous les rates a 0', () {
      const s = OcrBaselineStats.empty();
      expect(s.highCount, 0);
      expect(s.lowCount, 0);
      expect(s.noneCount, 0);
      expect(s.total, 0);
      expect(s.greenRate, 0);
      expect(s.orangeRate, 0);
      expect(s.redRate, 0);
    });
  });

  group('OcrBaselineStats — total', () {
    test('somme des 3 compteurs', () {
      const s = OcrBaselineStats(
        highCount: 5,
        lowCount: 3,
        noneCount: 2,
      );
      expect(s.total, 10);
    });

    test('total avec un seul groupe', () {
      const s = OcrBaselineStats(highCount: 7, lowCount: 0, noneCount: 0);
      expect(s.total, 7);
    });
  });

  group('OcrBaselineStats — rates', () {
    test('100% high : greenRate=1, autres=0', () {
      const s = OcrBaselineStats(highCount: 10, lowCount: 0, noneCount: 0);
      expect(s.greenRate, 1.0);
      expect(s.orangeRate, 0.0);
      expect(s.redRate, 0.0);
    });

    test('100% low : orangeRate=1', () {
      const s = OcrBaselineStats(highCount: 0, lowCount: 5, noneCount: 0);
      expect(s.orangeRate, 1.0);
      expect(s.greenRate, 0);
    });

    test('100% none : redRate=1', () {
      const s = OcrBaselineStats(highCount: 0, lowCount: 0, noneCount: 8);
      expect(s.redRate, 1.0);
      expect(s.greenRate, 0);
      expect(s.orangeRate, 0);
    });

    test('mix 1/2/1 (target Sprint 3.A) : 25%/50%/25%', () {
      const s = OcrBaselineStats(highCount: 1, lowCount: 2, noneCount: 1);
      expect(s.greenRate, 0.25);
      expect(s.orangeRate, 0.5);
      expect(s.redRate, 0.25);
    });

    test('somme des rates = 1.0 (invariant)', () {
      const s = OcrBaselineStats(highCount: 3, lowCount: 4, noneCount: 5);
      expect(s.greenRate + s.orangeRate + s.redRate, closeTo(1.0, 0.0001));
    });

    test('grands nombres : pas d\'overflow ni de precision perdue', () {
      const s = OcrBaselineStats(
        highCount: 850, lowCount: 100, noneCount: 50,
      );
      // 85% target carte verte
      expect(s.greenRate, closeTo(0.85, 0.0001));
      expect(s.total, 1000);
    });

    test('un seul scan high : 100% green sans crash', () {
      const s = OcrBaselineStats(highCount: 1, lowCount: 0, noneCount: 0);
      expect(s.greenRate, 1.0);
    });
  });
}
