import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/colissimo_bordereau_parser.dart';

void main() {
  group('ColissimoBordereauParser.looksLikeColissimo', () {
    test('contient "Colissimo" : true', () {
      expect(
        ColissimoBordereauParser.looksLikeColissimo([
          'Colissimo',
          'N° 6A12345678901',
        ]),
        isTrue,
      );
    });

    test('contient "La Poste" : true', () {
      expect(
        ColissimoBordereauParser.looksLikeColissimo([
          'La Poste',
          'Destinataire :',
          'M. DUPONT',
        ]),
        isTrue,
      );
    });

    test('numero tracking format 6A... : true', () {
      expect(
        ColissimoBordereauParser.looksLikeColissimo([
          'Bordereau',
          '6L98765432109',
        ]),
        isTrue,
      );
    });

    test('aucun marqueur : false', () {
      expect(
        ColissimoBordereauParser.looksLikeColissimo([
          'Destinataire',
          'M. DUPONT',
          '28100 DREUX',
        ]),
        isFalse,
      );
    });
  });

  group('ColissimoBordereauParser.parse - bordereau type', () {
    test('format standard : nom + rue + CP + ville + tel extraits', () {
      final result = ColissimoBordereauParser().parse([
        'Colissimo',
        'N° 6A12345678901',
        'Destinataire :',
        'MR DUPONT JEAN',
        '12 RUE DES LILAS',
        '28100 DREUX',
        'Tel : 0612345678',
      ]);
      expect(result.nomDestinataire, 'MR DUPONT JEAN');
      expect(result.rue, '12 RUE DES LILAS');
      expect(result.codePostal, '28100');
      expect(result.ville, 'DREUX');
      expect(result.telephone, '0612345678');
      expect(result.confidence, ExtractionConfidence.high);
    });

    test('marqueur "Destinataire" sans ":" : OK', () {
      final result = ColissimoBordereauParser().parse([
        'Destinataire',
        'MME MARTIN SOPHIE',
        '5 AVENUE DU GENERAL DE GAULLE',
        '75011 PARIS',
      ]);
      expect(result.nomDestinataire, 'MME MARTIN SOPHIE');
      expect(result.codePostal, '75011');
      expect(result.ville, 'PARIS');
    });

    test('bloc destinataire termine par "Expediteur"', () {
      final result = ColissimoBordereauParser().parse([
        'Destinataire :',
        'MR DUPONT',
        '12 RUE X',
        '28000 CHARTRES',
        'Expediteur :', // ← stop ici
        'AMAZON',
        '14 RUE DE LA LOGISTIQUE',
        '93200 SAINT-DENIS',
      ]);
      // Ne doit PAS prendre "AMAZON" ni les coords de l'expediteur
      expect(result.nomDestinataire, 'MR DUPONT');
      expect(result.codePostal, '28000');
      expect(result.ville, 'CHARTRES');
    });

    test('telephone format avec points : extrait', () {
      final result = ColissimoBordereauParser().parse([
        'Destinataire :',
        'M. PIERRE',
        '1 RUE A',
        '75000 PARIS',
        '06.12.34.56.78',
      ]);
      expect(result.telephone, isNotNull);
      final digits = result.telephone!.replaceAll(RegExp(r'\D'), '');
      expect(digits, '0612345678');
    });

    test('pas de marqueur destinataire : fallback CP/ville seulement',
        () {
      final result = ColissimoBordereauParser().parse([
        'Colissimo',
        '12 rue X',
        '28100 DREUX',
        '06 11 22 33 44',
      ]);
      expect(result.nomDestinataire, isNull);
      expect(result.codePostal, '28100');
      expect(result.ville, 'DREUX');
      expect(result.telephone, isNotNull);
      expect(result.confidence, ExtractionConfidence.low);
    });

    test('lignes vides : tout null + confidence none', () {
      final result = ColissimoBordereauParser().parse([]);
      expect(result.hasUsefulData, isFalse);
      expect(result.confidence, ExtractionConfidence.none);
    });

    test('bloc destinataire limite a 5 lignes max', () {
      // Si on a 10 lignes apres "Destinataire :" sans stop marker,
      // on s'arrete a la 5e pour eviter d'eparpiller dans le reste.
      final result = ColissimoBordereauParser().parse([
        'Destinataire :',
        'MR DUPONT',
        '12 RUE X',
        '28100 DREUX',
        '0612345678',
        // ligne 5 ok
        'AUTRE LIGNE 6',
        'AUTRE LIGNE 7',
        'AUTRE LIGNE 8',
      ]);
      expect(result.nomDestinataire, 'MR DUPONT');
      // Le bloc s'est arrete : pas de pollution avec les lignes 6-8
      expect(result.rue, '12 RUE X');
    });

    test('nom destinataire avec accents preserve', () {
      final result = ColissimoBordereauParser().parse([
        'Destinataire :',
        'MME LEFEVRE GENEVIEVE',
        '3 RUE DU MARECHAL FOCH',
        '69001 LYON',
      ]);
      expect(result.nomDestinataire, 'MME LEFEVRE GENEVIEVE');
      expect(result.ville, 'LYON');
    });
  });
}
