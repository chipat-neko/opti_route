import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/evening_debrief.dart';

void main() {
  group('EveningDebrief.questions (#318)', () {
    test('base : 3 questions (rues, codes, meteo)', () {
      final qs = EveningDebrief.questions(
          echecsCount: 0, sansContactCount: 0);
      expect(qs, hasLength(3));
      expect(qs.map((q) => q.id),
          containsAll(['rues_difficiles', 'codes_changes', 'meteo_ressenti']));
    });
    test('+ echec -> +1 question', () {
      final qs = EveningDebrief.questions(
          echecsCount: 2, sansContactCount: 0);
      expect(qs, hasLength(4));
      expect(qs.any((q) => q.id == 'echec_recidive'), isTrue);
    });
    test('+ sans contact -> +1 question', () {
      final qs = EveningDebrief.questions(
          echecsCount: 0, sansContactCount: 3);
      expect(qs.any((q) => q.id == 'depot_safe'), isTrue);
    });
  });

  group('EveningDebrief.isNothingToReport (#318)', () {
    test('"non" / "rien" / vide -> true', () {
      expect(EveningDebrief.isNothingToReport(''), isTrue);
      expect(EveningDebrief.isNothingToReport('non'), isTrue);
      expect(EveningDebrief.isNothingToReport('Rien à signaler'), isTrue);
      expect(EveningDebrief.isNothingToReport('Tout va bien'), isTrue);
    });
    test('vraie info -> false', () {
      expect(
        EveningDebrief.isNothingToReport(
            'Le code de Mme Dupont est passé à 1234B'),
        isFalse,
      );
    });
  });
}
