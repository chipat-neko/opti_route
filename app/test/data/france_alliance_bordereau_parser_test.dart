import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/france_alliance_bordereau_parser.dart';

/// Tests du parser France Alliance, basés sur la vérité terrain du lot v2
/// (cf docs/ocr-france-alliance.md). L'OCR est simulé en ordre « blocs »
/// (ce que ML Kit produit : chaque colonne = un bloc, de haut en bas).
void main() {
  final parser = FranceAllianceBordereauParser();

  group('looksLikeFranceAlliance', () {
    test('reconnaît les émetteurs du réseau', () {
      expect(
        FranceAllianceBordereauParser.looksLikeFranceAlliance(
            ['EXPEDITEUR', 'ALLIANCE PR']),
        isTrue,
      );
      expect(
        FranceAllianceBordereauParser.looksLikeFranceAlliance(
            ['Transporteur : ORN ALLIANCE (FA28)']),
        isTrue,
      );
      expect(
        FranceAllianceBordereauParser.looksLikeFranceAlliance(
            ['FA28 TRANSPORTS']),
        isTrue,
      );
      expect(
        FranceAllianceBordereauParser.looksLikeFranceAlliance(
            ['Colissimo', 'La Poste']),
        isFalse,
      );
    });
  });

  group('Format A — ALLIANCE PR', () {
    test('GGE CAILLON (nom simple, lieu-dit)', () {
      final r = parser.parse([
        'EXPEDITEUR',
        'ALLIANCE PR',
        'Le Champ du Chataignier',
        'RD23',
        'VOIVRES LES LE MANS',
        'FR 72210',
        'DESTINATAIRE',
        'Code Client 4746-0',
        'GGE CAILLON',
        'LA HURIE',
        '28240 ST VICTOR DE BUTHON',
        'FRANCE',
        'No DMS/OL 5446198 / 0015291979',
        'Code article 98208816ZD',
      ]);
      expect(r.nomDestinataire, 'GGE CAILLON');
      expect(r.rue, 'LA HURIE');
      expect(r.codePostal, '28240');
      expect(r.ville, 'ST VICTOR DE BUTHON');
      expect(r.confidence, ExtractionConfidence.high);
      // L'expéditeur (VOIVRES / 72210) ne doit PAS fuiter.
      expect(r.ville, isNot(contains('VOIVRES')));
      expect(r.codePostal, isNot('72210'));
    });

    test('CARROSSERIE DE LA COLLINE (nom coupé sur 2 lignes)', () {
      final r = parser.parse([
        'DESTINATAIRE',
        'Code Client 5359-0',
        'CARROSSERIE DE LA CO',
        'LLINE',
        '10 RUE DE BEAUCE ZAC DE L EOLIE',
        '28190 COURVILLE SUR EURE',
        'FRANCE',
      ]);
      expect(r.nomDestinataire, 'CARROSSERIE DE LA COLLINE');
      expect(r.rue, '10 RUE DE BEAUCE ZAC DE L EOLIE');
      expect(r.codePostal, '28190');
      expect(r.ville, 'COURVILLE SUR EURE');
    });
  });

  group('Format B — CSG / Seigneurie Gauthier', () {
    test('LEDUC SARL (COLIS x/y + téléphone après le CP)', () {
      final r = parser.parse([
        'COLIS 1/11   FR28400',
        'EXPEDITEUR',
        'CSG CHARTRES',
        'CPTOIR SEIGNEURIE GAUTHIER',
        '58 RUE DU CHATEAU D EAU',
        '28300 MAINVILLIERS',
        'DESTINATAIRE',
        'LEDUC SARL',
        'RUE DE SULLY',
        '28400 NOGENT-LE-ROTROU',
        'Tel : 06 61 78 67 71',
        'Transporteur : ORN ALLIANCE (FA28) MOINS DE 200KG',
        'N° de COMMANDE : 28B27268001',
      ]);
      expect(r.nomDestinataire, 'LEDUC SARL');
      expect(r.rue, 'RUE DE SULLY');
      expect(r.codePostal, '28400');
      expect(r.ville, 'NOGENT-LE-ROTROU');
      expect(r.telephone, '0661786771');
      expect(r.nbColis, 11);
      // L'expéditeur CSG / MAINVILLIERS ne doit pas être pris.
      expect(r.nomDestinataire, isNot(contains('CSG')));
      expect(r.codePostal, isNot('28300'));
    });
  });

  group('Format C — GETTYGO (sans ancre DESTINATAIRE)', () {
    test('GARAGE DU CENTRE (destinataire en haut, tél collé au nom)', () {
      final r = parser.parse([
        'GETTYGO    GETTY',
        'GARAGE DU CENTRE 0237267502',
        '12 RUE RAYMOND BATAILLE',
        'FR 28190 ST GEORGES SUR EURE',
        'Date exp 22/05/26',
        'COLIS 1/N',
        'BL : 120260521257357',
        'FRANCE ALLIANCE RESEAU',
      ]);
      expect(r.nomDestinataire, 'GARAGE DU CENTRE');
      expect(r.rue, '12 RUE RAYMOND BATAILLE');
      expect(r.codePostal, '28190');
      expect(r.ville, 'ST GEORGES SUR EURE');
      expect(r.telephone, '0237267502');
      expect(r.nbColis, isNull); // "1/N" : total inconnu
    });
  });

  group('Format D — FA28 Transports / Beauceronne', () {
    test('COOK INOV (tél transporteur AVANT, ne doit pas être pris)', () {
      final r = parser.parse([
        'FA28 TRANSPORTS',
        '28 LUISANT',
        'Tel : 02.37.91.12.02',
        'Fax : 02.37.90.72.20',
        'No Colis : QBEAUCERON28000010206C002',
        'EXPEDITEUR',
        'BEAUCERONNE',
        '1 RUE CHARLES COULOMB',
        '28000 CHARTRES',
        'DESTINATAIRE 0545803-0',
        'COOK INOV',
        'PARC D ACTIVITES L AULNAY',
        '02 37 52 72 59',
        '28400 NOGENT LE ROTROU',
      ]);
      expect(r.nomDestinataire, 'COOK INOV');
      expect(r.rue, 'PARC D ACTIVITES L AULNAY');
      expect(r.codePostal, '28400');
      expect(r.ville, 'NOGENT LE ROTROU');
      // Tél du destinataire, PAS celui du transporteur FA28.
      expect(r.telephone, '0237527259');
      expect(r.codePostal, isNot('28000')); // pas l'expéditeur Chartres
    });
  });

  group('Robustesse', () {
    test('texte vide -> confidence none', () {
      final r = parser.parse([]);
      expect(r.confidence, ExtractionConfidence.none);
      expect(r.hasUsefulData, isFalse);
    });

    test('rechercheParNom combine nom + ville', () {
      final r = parser.parse([
        'DESTINATAIRE',
        'Code Client 4746-0',
        'GGE CAILLON',
        'LA HURIE',
        '28240 ST VICTOR DE BUTHON',
      ]);
      expect(r.rechercheParNom, 'GGE CAILLON ST VICTOR DE BUTHON');
      expect(r.adressePostale, 'LA HURIE, 28240 ST VICTOR DE BUTHON');
    });
  });
}
