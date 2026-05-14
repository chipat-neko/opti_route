import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/levenshtein.dart';

void main() {
  group('Levenshtein.distance', () {
    test('chaines identiques : 0', () {
      expect(Levenshtein.distance('BORDEAUX', 'BORDEAUX'), 0);
      expect(Levenshtein.distance('', ''), 0);
    });

    test('chaine vide vs non vide : longueur de l\'autre', () {
      expect(Levenshtein.distance('', 'PARIS'), 5);
      expect(Levenshtein.distance('LYON', ''), 4);
    });

    test('substitution simple : 1', () {
      // OCR typique : X -> S sur fin de "BORDEAUX"
      expect(Levenshtein.distance('BORDEAUX', 'BORDEAUS'), 1);
      // T -> 7 (OCR confond chiffre/lettre)
      expect(Levenshtein.distance('BORDEAUX', 'BORDEAU7'), 1);
    });

    test('insertion / suppression : 1', () {
      // OCR a saute le T : "DESTINATAIRE" -> "DESINATAIRE"
      expect(Levenshtein.distance('DESTINATAIRE', 'DESINATAIRE'), 1);
      // OCR a ajoute un E : "RUE" -> "RUEE"
      expect(Levenshtein.distance('RUE', 'RUEE'), 1);
    });

    test('plusieurs operations cumulees', () {
      // CHARTRES -> ARTRES : 2 suppressions (C, H)
      expect(Levenshtein.distance('CHARTRES', 'ARTRES'), 2);
      // Cas extreme : aucun caractere en commun
      expect(Levenshtein.distance('AAA', 'BBB'), 3);
    });

    test('case-sensitive : "abc" != "ABC"', () {
      expect(Levenshtein.distance('abc', 'ABC'), 3);
    });
  });

  group('Levenshtein.similarity', () {
    test('chaines identiques : 0.0', () {
      expect(Levenshtein.similarity('PARIS', 'PARIS'), 0.0);
    });

    test('similaires : valeur faible', () {
      // 1 char different sur 8 -> ~0.125
      expect(Levenshtein.similarity('BORDEAUX', 'BORDEAUS'), closeTo(0.125, 0.01));
    });

    test('totalement differentes : 1.0', () {
      expect(Levenshtein.similarity('AAA', 'BBB'), 1.0);
    });

    test('chaines vides : 0.0 (pas de division par zero)', () {
      expect(Levenshtein.similarity('', ''), 0.0);
    });
  });

  group('Levenshtein.closestMatch', () {
    const villes = ['BORDEAUX', 'PARIS', 'LYON', 'LILLE', 'CHARTRES'];

    test('match exact retourne le candidat', () {
      expect(Levenshtein.closestMatch('PARIS', villes), 'PARIS');
    });

    test('case-insensitive', () {
      expect(Levenshtein.closestMatch('bordeaux', villes), 'BORDEAUX');
      expect(Levenshtein.closestMatch('Lyon', villes), 'LYON');
    });

    test('corrige une faute typique OCR', () {
      // S -> X en fin
      expect(Levenshtein.closestMatch('BORDEAUS', villes), 'BORDEAUX');
      // Saute le 1er caractere
      expect(Levenshtein.closestMatch('ARTRES', villes, maxDistance: 2),
          'CHARTRES');
    });

    test('retourne null si au-dela du seuil', () {
      // MARSEILLE n\'est pas dans la liste, et tous les candidats sont
      // tres differents
      expect(Levenshtein.closestMatch('MARSEILLE', villes), null);
    });

    test('respecte maxDistance', () {
      // CHARTRES vs ARTRES : distance 2
      expect(
        Levenshtein.closestMatch('ARTRES', villes, maxDistance: 1),
        null,
      );
      expect(
        Levenshtein.closestMatch('ARTRES', villes, maxDistance: 2),
        'CHARTRES',
      );
    });

    test('prefere le plus proche en cas d\'ambigu', () {
      // Entre "LYON" (dist 1 sur "LION") et "LILLE" (dist 3)
      expect(Levenshtein.closestMatch('LION', villes, maxDistance: 2), 'LYON');
    });
  });
}
