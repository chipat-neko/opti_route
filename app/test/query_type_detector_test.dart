import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/query_type_detector.dart';

void main() {
  group('QueryTypeDetector.detect (V7.4)', () {
    test('vide / trop court -> unknown', () {
      expect(QueryTypeDetector.detect(''), QueryType.unknown);
      expect(QueryTypeDetector.detect('a'), QueryType.unknown);
    });

    group('Identifiants numeriques', () {
      test('14 chiffres -> siret', () {
        expect(
          QueryTypeDetector.detect('12345678901234'),
          QueryType.siret,
        );
      });

      test('SIRET avec espaces -> siret', () {
        expect(
          QueryTypeDetector.detect('832 023 558 00018'),
          QueryType.siret,
        );
      });

      test('9 chiffres -> siren', () {
        expect(QueryTypeDetector.detect('832023558'), QueryType.siren);
      });

      test('10 chiffres commencant par 0 -> phone', () {
        expect(QueryTypeDetector.detect('0612345678'), QueryType.phone);
        expect(
          QueryTypeDetector.detect('06 12 34 56 78'),
          QueryType.phone,
        );
      });

      test('+33 + 9 chiffres -> phone', () {
        expect(
          QueryTypeDetector.detect('+33 6 12 34 56 78'),
          QueryType.phone,
        );
      });

      test('10 chiffres avec lettres autour -> NOT phone', () {
        // "14 Rue 75002 Paris" -> on a 10 chiffres au total mais c'est
        // une adresse, pas un telephone.
        expect(
          QueryTypeDetector.detect('14 Rue 75002 Paris'),
          isNot(QueryType.phone),
        );
      });
    });

    group('Adresse postale', () {
      test('chiffre + rue -> address', () {
        expect(
          QueryTypeDetector.detect('14 Rue de la Paix'),
          QueryType.address,
        );
        expect(
          QueryTypeDetector.detect('3 bis Boulevard Voltaire'),
          QueryType.address,
        );
      });

      test('chiffre + ter -> address', () {
        expect(
          QueryTypeDetector.detect('5ter Avenue de Wagram'),
          QueryType.address,
        );
      });

      test('chiffre seul -> unknown (pas une adresse complete)', () {
        // "14" tout seul est ambigu, on ne tranche pas.
        expect(QueryTypeDetector.detect('14'), QueryType.unknown);
      });
    });

    group('Locality (ville)', () {
      test('nom de ville court -> locality', () {
        expect(QueryTypeDetector.detect('Chartres'), QueryType.locality);
        expect(QueryTypeDetector.detect('Paris'), QueryType.locality);
      });

      test('ville avec tiret -> locality', () {
        expect(
          QueryTypeDetector.detect('Saint-Etienne'),
          QueryType.locality,
        );
      });

      test('ville en 2-3 mots courts -> locality', () {
        expect(
          QueryTypeDetector.detect('Le Mans'),
          QueryType.locality,
        );
      });
    });

    group('Business (entreprise)', () {
      test('forme juridique SAS -> business', () {
        expect(
          QueryTypeDetector.detect('GARAGE DUPONT SAS'),
          QueryType.business,
        );
      });

      test('forme juridique SARL en debut -> business', () {
        expect(
          QueryTypeDetector.detect('SARL Plomberie Martin'),
          QueryType.business,
        );
      });

      test('2 mots en MAJUSCULES consecutives -> business', () {
        expect(
          QueryTypeDetector.detect('ATELIER MENUISERIE DU CENTRE'),
          QueryType.business,
        );
      });

      test('texte long avec plusieurs mots -> business', () {
        expect(
          QueryTypeDetector.detect(
              'Boulangerie patisserie chocolatier centre ville'),
          QueryType.business,
        );
      });
    });
  });
}
