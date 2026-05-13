import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/chronopost_bordereau_parser.dart';

void main() {
  group('ChronopostBordereauParser.looksLikeChronopost', () {
    test('contient "Chronopost" : true', () {
      expect(
        ChronopostBordereauParser.looksLikeChronopost([
          'CHRONOPOST',
          'LIVRAISON 13H',
        ]),
        isTrue,
      );
    });

    test('tracking XR.....FR : true', () {
      expect(
        ChronopostBordereauParser.looksLikeChronopost([
          'Bordereau',
          'XR123456789FR',
        ]),
        isTrue,
      );
    });

    test('aucun marqueur : false', () {
      expect(
        ChronopostBordereauParser.looksLikeChronopost([
          'Destinataire',
          'M. DUPONT',
          '28100 DREUX',
        ]),
        isFalse,
      );
    });
  });

  group('ChronopostBordereauParser.parse', () {
    test('format standard avec expediteur AVANT destinataire', () {
      final result = ChronopostBordereauParser().parse([
        'CHRONOPOST',
        'LIVRAISON 13H',
        'XR123456789FR',
        'EXPEDITEUR :',
        'AMAZON FRANCE',
        '78290 CROISSY S/SEINE',
        'DESTINATAIRE :',
        'CALOTE NOAH',
        '12 RUE DES LILAS',
        '28100 DREUX',
        'FRANCE',
        '06 12 34 56 78',
      ]);
      expect(result.nomDestinataire, 'CALOTE NOAH');
      expect(result.rue, '12 RUE DES LILAS');
      expect(result.codePostal, '28100');
      expect(result.ville, 'DREUX');
      expect(result.telephone, isNotNull);
      expect(result.confidence, ExtractionConfidence.high);
    });

    test('FRANCE seul ignore (pas dans la rue)', () {
      final result = ChronopostBordereauParser().parse([
        'DESTINATAIRE :',
        'M. MARTIN',
        '5 AVENUE DE LA REPUBLIQUE',
        '69001 LYON',
        'FRANCE',
      ]);
      expect(result.rue, '5 AVENUE DE LA REPUBLIQUE');
      // FRANCE n'est PAS dans la rue
      expect(result.rue, isNot(contains('FRANCE')));
    });

    test('bloc destinataire stop sur "EXPEDITEUR" suivant', () {
      // Cas inverse : expediteur APRES le destinataire (rare mais
      // Chronopost le fait parfois sur les retours).
      final result = ChronopostBordereauParser().parse([
        'DESTINATAIRE :',
        'MR DUPONT',
        '12 RUE X',
        '28000 CHARTRES',
        'EXPEDITEUR :',
        'AMAZON',
        '93200 ST-DENIS',
      ]);
      expect(result.nomDestinataire, 'MR DUPONT');
      expect(result.codePostal, '28000');
      // Ne doit PAS prendre les coords de l'expediteur
      expect(result.ville, isNot('ST-DENIS'));
    });

    test('telephone format 06.12.34.56.78', () {
      final result = ChronopostBordereauParser().parse([
        'DESTINATAIRE :',
        'M. PIERRE',
        '1 RUE A',
        '75000 PARIS',
        '06.12.34.56.78',
      ]);
      expect(result.telephone, isNotNull);
      final digits = result.telephone!.replaceAll(RegExp(r'\D'), '');
      expect(digits, '0612345678');
    });

    test('pas de marqueur destinataire : fallback CP/ville/tel', () {
      final result = ChronopostBordereauParser().parse([
        'CHRONOPOST',
        'XR987654321FR',
        '14 RUE Z',
        '75011 PARIS',
        '06 11 22 33 44',
      ]);
      expect(result.nomDestinataire, isNull);
      expect(result.codePostal, '75011');
      expect(result.confidence, ExtractionConfidence.low);
    });

    test('liste vide -> tout null + none', () {
      final result = ChronopostBordereauParser().parse([]);
      expect(result.hasUsefulData, isFalse);
      expect(result.confidence, ExtractionConfidence.none);
    });

    test('bloc destinataire limite a 6 lignes', () {
      // Chronopost a un peu plus de lignes (FRANCE + tel typique).
      final result = ChronopostBordereauParser().parse([
        'DESTINATAIRE :',
        'M. DUPONT',
        '12 RUE X',
        '28100 DREUX',
        'FRANCE',
        '0612345678',
        // ligne 6 fin du bloc
        'POLLUTION LIGNE 7',
        'POLLUTION LIGNE 8',
      ]);
      expect(result.nomDestinataire, 'M. DUPONT');
      expect(result.rue, '12 RUE X');
      expect(result.codePostal, '28100');
    });
  });
}
