import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/levenshtein.dart';

// Verifie les proprietes mathematiques classiques de la distance de
// Levenshtein + cas-limites de closestMatch / similarity (non couverts
// dans levenshtein_test.dart).
void main() {
  group('Levenshtein.distance — proprietes mathematiques', () {
    test('symetrie : d(a,b) == d(b,a)', () {
      for (final pair in const [
        ('BORDEAUX', 'BORDEAUS'),
        ('PARIS', 'LYON'),
        ('', 'NOVA'),
        ('AAA', 'BBB'),
        ('CHARTRES', 'ARTRES'),
      ]) {
        final ab = Levenshtein.distance(pair.$1, pair.$2);
        final ba = Levenshtein.distance(pair.$2, pair.$1);
        expect(ab, ba, reason: '${pair.$1} <-> ${pair.$2}');
      }
    });

    test('identite : d(a,a) == 0', () {
      for (final s in ['', 'a', 'NOVA', 'opti_route', 'A' * 100]) {
        expect(Levenshtein.distance(s, s), 0, reason: 's = "$s"');
      }
    });

    test('inegalite triangulaire : d(a,c) <= d(a,b) + d(b,c)', () {
      for (final triple in const [
        ('PARIS', 'LYON', 'LILLE'),
        ('BORDEAUX', 'BORDEAUS', 'BORDEAUY'),
        ('CHARTRES', 'CHATEAU', 'CHARLY'),
        ('a', 'b', 'c'),
      ]) {
        final ac = Levenshtein.distance(triple.$1, triple.$3);
        final ab = Levenshtein.distance(triple.$1, triple.$2);
        final bc = Levenshtein.distance(triple.$2, triple.$3);
        expect(ac, lessThanOrEqualTo(ab + bc),
            reason: '${triple.$1} -> ${triple.$2} -> ${triple.$3}');
      }
    });

    test('non-negativite : d(a,b) >= 0', () {
      for (final pair in [
        ('', ''),
        ('PARIS', 'LYON'),
        ('a' * 50, 'b' * 50),
      ]) {
        expect(
          Levenshtein.distance(pair.$1, pair.$2),
          greaterThanOrEqualTo(0),
        );
      }
    });

    test('bornes : 0 <= d(a,b) <= max(len(a), len(b))', () {
      const samples = [
        ('NOVA', 'PARIS'),
        ('', 'BORDEAUX'),
        ('LILLE', ''),
      ];
      for (final pair in samples) {
        final d = Levenshtein.distance(pair.$1, pair.$2);
        final maxLen = pair.$1.length > pair.$2.length
            ? pair.$1.length
            : pair.$2.length;
        expect(d, greaterThanOrEqualTo(0));
        expect(d, lessThanOrEqualTo(maxLen));
      }
    });
  });

  group('Levenshtein.similarity — proprietes', () {
    test('symetrie : similarity(a,b) == similarity(b,a)', () {
      expect(
        Levenshtein.similarity('PARIS', 'LYON'),
        Levenshtein.similarity('LYON', 'PARIS'),
      );
    });

    test('similarity in [0, 1]', () {
      for (final pair in const [
        ('NOVA', 'NOVA'),
        ('NOVA', 'NOVB'),
        ('AAA', 'BBB'),
        ('PARIS', 'BORDEAUX'),
      ]) {
        final s = Levenshtein.similarity(pair.$1, pair.$2);
        expect(s, inInclusiveRange(0.0, 1.0));
      }
    });
  });

  group('Levenshtein.closestMatch — cas-limites', () {
    test('candidats vides -> null', () {
      expect(Levenshtein.closestMatch('PARIS', const []), isNull);
    });

    test('maxDistance = 0 -> exact match only', () {
      expect(
        Levenshtein.closestMatch('PARIS', const ['PARIS'], maxDistance: 0),
        'PARIS',
      );
      expect(
        Levenshtein.closestMatch('PARIS', const ['PARI'], maxDistance: 0),
        isNull,
      );
    });

    test('iterable lazy (Iterable, pas List)', () {
      final candidates = ['PARIS', 'LYON', 'BORDEAUX'].map((s) => s);
      expect(Levenshtein.closestMatch('BORDEAUS', candidates), 'BORDEAUX');
    });
  });
}
