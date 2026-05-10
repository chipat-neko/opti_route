import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_parser.dart';

void main() {
  group('BordereauParser - format MESEXP', () {
    /// Lignes telles qu'elles seraient probablement extraites par
    /// Google ML Kit Text Recognition sur le bordereau MESEXP partage
    /// par Noah. Ordre top-to-bottom, ligne par ligne.
    final mlkitLines = [
      'N° récépissé',
      '45109476',
      'Date expédition',
      '06/05/2026',
      'Client',
      'FA45',
      'U.M.',
      '1',
      'Poids',
      '2',
      'Vol/Lg',
      'Port',
      'payé',
      'Régime',
      'MESEXP',
      'Messagerie Express',
      'Expéditeur',
      'TRANSMANUCENTRE',
      '20 RUE EMILE LECONTE',
      'FR 45140 SAINT JEAN DE LA RUELLE',
      'Ref. exped.',
      '147863 / 19',
      'Ref. dest.',
      'Contact destinataire',
      'Tel : 0621250794',
      'HYDRO ALUMINIUM EXTRUSION SERVICES',
      'Instruction de livraison - Document de suivi',
      'Destinataire',
      'HYDRO ALUMINIUM EXTRUSION SERVICES',
      '42 RUE DE LA BEAUCE',
      'BP 10077',
      'Lieu de livraison',
      '28110 LUCE',
      'Nature de la marchandise',
      'GALET',
      'total colis : 1',
      'Lettre de voiture',
      'T01.2',
      'Facture',
      'Port HT',
      'T.V.A.',
      'Port TTC',
      'Débour',
      'Marchandise reçue en bon état',
      'Commissionnaire ou transporteur principal',
      'FA45 TRANSPORTS',
      '16 RUE DE LA MOUCHETIERE',
      '45140 INGRE',
      'Siret : 44760810000015 Tel : 02 38 88 26 15',
      'Transporteur livreur',
      'Eure et Loir Acheminement',
      '24 AVENUE LOUIS PASTEUR',
      '28630 GELLAINVILLE',
      'Siret : 97880271800012 Tel : 02 37 84 44 41',
    ];

    test('extrait nom destinataire', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.nomDestinataire, 'HYDRO ALUMINIUM EXTRUSION SERVICES');
    });

    test('extrait la rue (avec BP)', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.rue, contains('42 RUE DE LA BEAUCE'));
      expect(result.rue, contains('BP 10077'));
    });

    test('extrait le code postal du destinataire (28110)', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.codePostal, '28110');
    });

    test('extrait la ville LUCE', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.ville, 'LUCE');
    });

    test('NE prend PAS le CP de l\'expediteur (45140) ni du transporteur',
        () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.codePostal, isNot('45140'));
      expect(result.codePostal, isNot('28630'));
    });

    test('extrait le total colis = 1', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.nbColis, 1);
    });

    test('extrait le telephone du contact destinataire', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.telephone, '0621250794');
    });

    test('hasUsefulData = true', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.hasUsefulData, isTrue);
    });

    test('adressePostale composee correctement', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.adressePostale, isNotNull);
      expect(result.adressePostale, contains('42 RUE DE LA BEAUCE'));
      expect(result.adressePostale, contains('28110 LUCE'));
    });

    test('rechercheParNom = nom + ville pour SIRENE', () {
      final result = BordereauParser().parse(mlkitLines);
      expect(result.rechercheParNom,
          'HYDRO ALUMINIUM EXTRUSION SERVICES LUCE');
    });
  });

  group('BordereauParser - vraies lignes ML Kit (Noah, 2026-05-10)', () {
    /// 70 lignes telles que retournees par ML Kit sur le vrai bordereau
    /// MESEXP de Noah, capturees via `adb logcat -s flutter:V | grep
    /// OCRDUMP`. L'ordre est chaotique parce que la photo etait prise
    /// tete-beche : c'est exactement ce que le parser doit gerer en
    /// production.
    final realLines = [
      'décret avril',
      '1999 sont applicables. du 6',
      'Transports :A',
      'défaut',
      'de',
      'contrat',
      'spécifique : entre les puzies, Tes dispositions issues du',
      'les 3 jours sulvant la réception seront recevables (art lL33-3 ou code de commerce).',
      'Sur demande). seules les réserves précisées et confirmées par lettre recommandée dans',
      "La remise des colis entraine l'acceptatios de nos conditions générales (exte intégral remis",
      'Nom, Signature et Cachet obligatoire',
      'Siret: 44760810000015 Tel: 02 38 88 26 15Siret: 97880271800012 Tel : 02 37 84 44 41',
      '45140 |NGRE',
      '16 RUE DE LA MOUCHETIERE',
      'FA45 TRANSPORTS',
      '28630 GELLAINVILLE',
      '24 AVENUE LOUIS PASTEUR',
      'Eure et Loir Acheminement',
      'COmmissionnaire Ou transporteur principalTransporteur livreur',
      'Le:',
      'total colis: 1',
      'Marchandise reçue en bon état',
      'heures',
      'Instruction de livraison - Document de suivi',
      'FA450000395356',
      'Tel : 0681250 794 HYDRO ALUMINIUM EXTRUSION SERVICES',
      'Contact destinataire',
      'Lieu de livraison',
      'Ref. dest.',
      '28110 LUCE',
      'Ref. exped. 147863/ 19',
      'FR 45140 SAINT JEAN DE LA RUELLE',
      '20 RUE EMILE LECONTE',
      'BP 10077',
      'RE',
      'Débour',
      'Port TTC',
      'T.V.A',
      'Port HT',
      'TRANSMANUCENTRE',
      '42 RUE DE LA BEAUCE',
      'HYDRO ALUMINIUM EXTRUSION SERVICES',
      'Facture',
      'Expéditeur',
      'Dest',
      'Desinataire', // Faute OCR : il manque le 't'
      'LETTRE DE VOITURE',
      'Messagerie Express',
      'GALET',
      'MESEXP',
      'TO1. 2',
      'Régime',
      'Nature de la marchandise',
      'Ligne',
      'MatiercS dangereuses ADR',
      '06/05/2026',
      'FA45',
      '1',
      '45109476',
      '2',
      'payé',
      'N° récépissé',
      'Date expedition',
      'Client',
      'U.M.',
      'Poids',
      'Vol / Lg',
      'Port',
      'Contre-remboursement',
      'sOuhaitée',
    ];

    test('extrait nom destinataire HYDRO ALUMINIUM EXTRUSION SERVICES',
        () {
      final result = BordereauParser().parse(realLines);
      expect(result.nomDestinataire, contains('HYDRO ALUMINIUM EXTRUSION'));
    });

    test('extrait CP destinataire 28110', () {
      final result = BordereauParser().parse(realLines);
      expect(result.codePostal, '28110');
    });

    test('extrait ville LUCE', () {
      final result = BordereauParser().parse(realLines);
      expect(result.ville, 'LUCE');
    });

    test('extrait total colis 1', () {
      final result = BordereauParser().parse(realLines);
      expect(result.nbColis, 1);
    });

    test('NE prend PAS TRANSMANUCENTRE comme nom (c\'est l\'expediteur)',
        () {
      final result = BordereauParser().parse(realLines);
      expect(result.nomDestinataire, isNot(contains('TRANSMANUCENTRE')));
    });
  });

  group('BordereauParser - cas limites', () {
    test('liste vide -> tout null', () {
      final result = BordereauParser().parse([]);
      expect(result.hasUsefulData, isFalse);
      expect(result.nomDestinataire, isNull);
      expect(result.codePostal, isNull);
    });

    test('lignes random sans marqueurs -> trouve quand meme un CP en fallback',
        () {
      final result = BordereauParser().parse([
        'JEAN DUPONT',
        '5 rue Foo',
        '75011 Paris',
      ]);
      expect(result.codePostal, '75011');
      expect(result.ville, 'Paris');
    });
  });
}
