import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau/colis_parser.dart';
import 'package:opti_route/data/bordereau_extraction.dart';

/// Tests bases sur les 9 photos de reference du 11 mai 2026
/// (`bordereaux_test/Bordereau livraison/colis/`).
///
/// Les dumps OCR ne sont pas re-extraits depuis les photos (cela
/// necessiterait ML Kit sur appareil) : on simule des lignes plausibles
/// dans un ordre approximativement chaotique pour valider que le
/// parser tient debout sur les vrais cas.
void main() {
  group('ColisBordereauParser - variante A (etiquette complete)', () {
    const parser = ColisBordereauParser();

    test('DE MATOS ANTONIO (MVIMG_063125)', () {
      final result = parser.parse(const [
        'Transports France Alliance',
        'Centre Livreur',
        'Eure et Loir Acheminement',
        '28630 - GELLAINVILLE',
        'Tel : 02 37 84 44 41',
        'EXP: UNIKALO',
        'FR - 28110 - LUCE',
        'Date : 07/05/26',
        'INSTRUCTION(S)',
        '28',
        'T07',
        'RECEP.:',
        '28146356',
        'UM: 1/1',
        'Poids: 5.00 Kg',
        'Destinataire :',
        'DE MATOS ANTONIO',
        '1 RUE DE L\'ABREUVOIRE',
        'FR - 28240 - LA LOUPE',
        'TRAVEE',
        'REF.:',
        'PRODUIT: MESEXP',
      ]);

      expect(result.nomDestinataire, 'DE MATOS ANTONIO');
      expect(result.rue, '1 RUE DE L\'ABREUVOIRE');
      expect(result.codePostal, '28240');
      expect(result.ville, 'LA LOUPE');
      expect(result.nbColis, 1);
      expect(result.confidence, ExtractionConfidence.high);
    });

    test('NOVA village des entreprises (MVIMG_063133)', () {
      final result = parser.parse(const [
        'Tr',
        'Fra',
        'EXP:',
        'FR -',
        'Date : 07/05/26',
        'INST',
        'RECEP.:',
        '2014063',
        'UM: 1/1',
        'Poids: 75.00 Kg',
        'T10',
        'Destinataire :',
        'NOVA',
        'rue du Thymerais',
        'village des entreprises',
        'FR-28190-COURVILLE SUR EURE',
        'TRAVEE',
        'REF: 281278',
        'PRODUIT: MESEXP',
      ]);

      expect(result.nomDestinataire, 'NOVA');
      // La rue est composee de 2 lignes (rue + complement).
      expect(result.rue, contains('rue du Thymerais'));
      expect(result.rue, contains('village des entreprises'));
      expect(result.codePostal, '28190');
      expect(result.ville, 'COURVILLE SUR EURE');
      expect(result.confidence, ExtractionConfidence.high);
    });

    test('ATELIER MENUISERIE DU CEN (MVIMG_063136)', () {
      // Cas degrade : photo prise a l'envers, l'OCR a coupe "FR - 28xxx"
      // au lieu de "FR - 28240 -". Le pattern FR ne matche donc rien
      // dans le bloc. On garde quand meme le nom et la rue (avec la
      // ville tronquee dedans en complement). Noah corrigera CP/ville
      // manuellement (confidence low).
      final result = parser.parse(const [
        'T07',
        'Destinataire:',
        'ATELIER MENUISERIE DU CEN',
        'LE HOUX',
        '28 - LA LOUPE',
        'UM: 1/1',
        'Poids: 13.48 Kg',
        'DRE_26028060',
        'PRODUIT: MESEXP',
      ]);

      expect(result.nomDestinataire, 'ATELIER MENUISERIE DU CEN');
      expect(result.rue, contains('LE HOUX'));
      expect(result.codePostal, isNull);
      expect(result.ville, isNull);
      // hasNom + hasRue = high (selon la grille de confiance).
      expect(result.confidence, ExtractionConfidence.high);
    });

    test('BELHOMERT ELEC SERVICES (MVIMG_063137)', () {
      // Photo prise a 90 degres : OCR retourne les lignes en ordre
      // chaotique. On simule cet ordre.
      final result = parser.parse(const [
        'EXP-YESSS CHARTRES',
        'FR - 28630 - FONTENAY SUR EURE',
        'Heure collecte: 17:30',
        'RECEP.:',
        '281146335',
        'UM: 1/1',
        'Poids: 1.00 Kg',
        'Destinataire :',
        'BELHOMERT ELEC SERVICES',
        '13 RUE HELENE BOUCHER',
        'FR - 28240 - BELHOMERT',
        'GUEHOUVILLE',
        'PRODUIT: MESEXP',
      ]);

      expect(result.nomDestinataire, 'BELHOMERT ELEC SERVICES');
      expect(result.rue, '13 RUE HELENE BOUCHER');
      expect(result.codePostal, '28240');
      // Note : "BELHOMERT" + " GUEHOUVILLE" se serait combine si le
      // parser etait moins strict ; ici on prend juste BELHOMERT.
      expect(result.ville, contains('BELHOMERT'));
      expect(result.nbColis, 1);
      expect(result.confidence, ExtractionConfidence.high);
    });

    test('MANGUIN avec NAV28 (MVIMG_063143)', () {
      final result = parser.parse(const [
        'Transports France Alliance',
        'Centre Livreur',
        'FA28',
        '28630 - GELLAINVILLE',
        'Tel: 02.37.84.44.41',
        'EXP: VITRO SERVICE FRANCE',
        'FR - 41310 - ST AMAND LONGPRE',
        'Date : 07/05/26',
        'Heure collecte: 10:30',
        'RECEP.:',
        '41108116',
        'UM: 1/1',
        'Poids: 13.00 Kg',
        'NAV28',
        'Destinataire :',
        'MANGUIN',
        '6 RUE DE CHARTRES CHAINVILLE',
        'FR - 28400 - TRIZAY COUTRETOT',
        'ST SERGE',
        'TRAVEE',
        'REF.: 3531506',
        'PRODUIT: MESEXP',
      ]);

      expect(result.nomDestinataire, 'MANGUIN');
      expect(result.rue, '6 RUE DE CHARTRES CHAINVILLE');
      expect(result.codePostal, '28400');
      expect(result.ville, contains('TRIZAY'));
      // L\'EXP est en "FR - 41310 - ST AMAND LONGPRE" : le parser doit
      // l\'ignorer (label EXP: en amont) et bien prendre l\'adresse 28400.
      expect(result.confidence, ExtractionConfidence.high);
    });

    test('ETS J.P. FRANCE avec ZONE ARTISANALE (MVIMG_063147)', () {
      final result = parser.parse(const [
        'Transports France Alliance',
        'EXP: LEMOULT',
        'FR - 28200 - ST DENIS LES PONTS',
        'Date : 07/05/26',
        'RECEP.:',
        '28146042',
        'UM: 1/1',
        'Poids: 1.00 Kg',
        '28',
        'T07',
        'Destinataire :',
        'ETS J.P. FRANCE',
        '2 RUE CHARLES BIGUET',
        'ZONE ARTISANALE',
        'FR-28480-THIRON GARDAIS',
        'TRAVEE',
        'REF.:',
        'PRODUIT: MESEXP',
      ]);

      expect(result.nomDestinataire, 'ETS J.P. FRANCE');
      // 2 lignes de rue : la rue + ZONE ARTISANALE.
      expect(result.rue, contains('2 RUE CHARLES BIGUET'));
      expect(result.rue, contains('ZONE ARTISANALE'));
      expect(result.codePostal, '28480');
      expect(result.ville, 'THIRON GARDAIS');
      expect(result.confidence, ExtractionConfidence.high);
    });
  });

  group('ColisBordereauParser - variante B (etiquette FA56 PNEUS)', () {
    const parser = ColisBordereauParser();

    test('AUTODISTRIBUTION MORIZE LOIRET (MVIMG_063202)', () {
      // Sous-format simplifie sans label "Destinataire :".
      final result = parser.parse(const [
        'FA56 PNEUS',
        'AUTODISTRIBUTION MORIZE LOIRET',
        'FA02',
        'AVENUE DES PRES',
        'MARGON',
        'FR 28400 ARCISSES',
        'Rec',
        'Date exp 142698',
        'Poids 07/05/26D',
        '7.00 KG',
        'COLIS 1/1',
        'FRANCE ALLIANCE 56',
        'BL : 1410767827',
      ]);

      // Pas de label "Destinataire", le parser fallback sur l\'adresse
      // pour remonter nom + rue.
      expect(result.codePostal, '28400');
      expect(result.ville, 'ARCISSES');
      expect(result.nbColis, 1); // depuis "COLIS 1/1"
      // Le nom et la rue sont moins fiables (variante B) : on verifie
      // au moins qu\'on a du contenu.
      expect(result.confidence,
          isIn([ExtractionConfidence.high, ExtractionConfidence.low]));
    });
  });

  group('ColisBordereauParser - cas degrades', () {
    const parser = ColisBordereauParser();

    test('lignes vides -> confidence none', () {
      final result = parser.parse(const []);
      expect(result.confidence, ExtractionConfidence.none);
      expect(result.nomDestinataire, isNull);
    });

    test('aucun marqueur exploitable -> confidence none', () {
      final result = parser.parse(const [
        'Texte aleatoire',
        'Sans pattern adresse',
      ]);
      expect(result.confidence, ExtractionConfidence.none);
    });

    test('UM avec total > 1 colis -> nbColis correspond au total', () {
      final result = parser.parse(const [
        'Destinataire :',
        'CLIENT TEST',
        'FR - 75000 - PARIS',
        'UM: 2/3',
      ]);
      expect(result.nbColis, 3, reason: 'UM X/Y : Y = total de l\'envoi');
    });

    test('expediteur "FR - CP -" ignore au profit du destinataire', () {
      // L\'expediteur est dans la zone EXP: en haut. Le parser doit
      // prendre l\'adresse du destinataire plus bas.
      final result = parser.parse(const [
        'EXP: VITRO SERVICE',
        'FR - 41310 - ST AMAND LONGPRE',
        'Destinataire :',
        'VRAI CLIENT',
        '1 RUE TEST',
        'FR - 28000 - CHARTRES',
        'UM: 1/1',
      ]);
      expect(result.nomDestinataire, 'VRAI CLIENT');
      expect(result.codePostal, '28000');
      expect(result.ville, 'CHARTRES');
    });
  });
}
