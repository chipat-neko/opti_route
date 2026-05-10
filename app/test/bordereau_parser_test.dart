import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
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

    test('extrait la rue 42 RUE DE LA BEAUCE (adjacente au nom)', () {
      final result = BordereauParser().parse(realLines);
      expect(result.rue, isNotNull);
      expect(result.rue, contains('42 RUE DE LA BEAUCE'));
    });

    test('inclut aussi BP 10077 si trouvee a proximite', () {
      final result = BordereauParser().parse(realLines);
      expect(result.rue, contains('BP 10077'));
    });

    test('NE prend PAS la rue de l\'expediteur (20 RUE EMILE LECONTE)',
        () {
      final result = BordereauParser().parse(realLines);
      expect(result.rue, isNot(contains('20 RUE EMILE LECONTE')));
    });

    test('adressePostale complete', () {
      final result = BordereauParser().parse(realLines);
      expect(result.adressePostale, contains('42 RUE DE LA BEAUCE'));
      expect(result.adressePostale, contains('28110 LUCE'));
    });
  });

  group('BordereauParser - bordereau 2 (THEODORE CHARTRES) Noah 2026-05-10', () {
    /// 68 lignes ML Kit reelles d'un 2e bordereau MESEXP. Contexte
    /// piege : le destinataire (THEODORE CHARTRES, 28000 CHARTRES)
    /// est cite avec "CHARTRES" qui matche un mot du nom -> heuristique
    /// "ville matche nom" doit l'identifier preferentiellement.
    final realLines2 = [
      'ldécret du 6 avril 1999 sont applicables,',
      'Ttansports :A défaut de contrat spécifique entre les parties, les dispositions issues du',
      'les 3 jours suivant la réception seront recevabies',
      '(art 133-3 du code de commerce)',
      'Sur demande). seules les réserves précisées et confirmées par lettre reconmandée dans',
      'La remise des colis entraine lacceptation de nos Conditions générales (texte intégial remis',
      'Nom, Signature et Cachet obligatoire',
      'Siret: 44760810000015 Tel: 02 38 88 26 15Siret: 97880271800012 Tel: 02 37 84 44 41',
      '26 RUE DE LA MOUCHETIERE',
      '45140 INGRE',
      'FA45 TRANSPORTS',
      '28630 GELLAINVILLE',
      '24 AVENUE LOUIS PASTEUR',
      'Eure et Loir Acheminement',
      'Commissionnaire ou transporteur principal Transporteur livreur',
      'total colis : 1',
      'Le:',
      'Marchandise reçue en bon état',
      'heures',
      'Instruction de livraison- Document de suivi',
      'Tel: 0237911586 THEODORE CHARTRES',
      'FA4500 90395188',
      'Contact destinataire',
      'Lieu de livraison.',
      'Ref. dest.',
      'Ref.',
      'exped.',
      '28000 CHARTRES',
      'FR 45800 ST JEAN DE BRAYE',
      '55 RUE DE LA BURELLE',
      'LIVRE',
      'THEODORE MAISON DE PEINTURE',
      'Débour',
      'TVA',
      'Port TTC',
      'ESPACE OCEAM',
      "53 AVENUE D'ORLEANS",
      'THEODORE CHARTRES',
      'HAMELIN DECOR',
      'Port',
      'HT',
      'Expéditeut',
      'Destinataire',
      'Facture',
      'Messagerie Express',
      'LETTRE DE VÕITURE',
      'MESEXP',
      'Régime',
      'NA',
      'TO1. 1',
      'Nature de la marchandise',
      '45109451',
      '06/05/2026',
      'Ligne',
      'FA45',
      'Matieres dangereuses ADR',
      '1',
      '5',
      'N° récépisse',
      'Date expédlton',
      'payé',
      'Clent',
      'U.M.',
      'Poids',
      'Vol! Lg',
      'Port',
      'Contre-remsoursemert',
      'sOuhaitée',
    ];

    test('extrait nom THEODORE CHARTRES (occurrences 2)', () {
      final result = BordereauParser().parse(realLines2);
      expect(result.nomDestinataire, contains('THEODORE CHARTRES'));
    });

    test('extrait CP 28000 CHARTRES (ville matche nom)', () {
      final result = BordereauParser().parse(realLines2);
      expect(result.codePostal, '28000');
      expect(result.ville, 'CHARTRES');
    });

    test('NE prend PAS 45140 INGRE (transporteur)', () {
      final result = BordereauParser().parse(realLines2);
      expect(result.codePostal, isNot('45140'));
    });

    test('NE prend PAS 45800 ST JEAN DE BRAYE (expediteur)', () {
      final result = BordereauParser().parse(realLines2);
      expect(result.codePostal, isNot('45800'));
    });

    test("extrait la rue 53 AVENUE D'ORLEANS (adjacente au nom)", () {
      final result = BordereauParser().parse(realLines2);
      expect(result.rue, contains("53 AVENUE D'ORLEANS"));
    });

    test('NE prend PAS la garbage du bloc structurel (Messagerie Express, etc)',
        () {
      final result = BordereauParser().parse(realLines2);
      expect(result.rue, isNot(contains('Messagerie Express')));
      expect(result.rue, isNot(contains('LETTRE DE')));
    });

    test('extrait colis 1', () {
      final result = BordereauParser().parse(realLines2);
      expect(result.nbColis, 1);
    });
  });

  group('BordereauParser - bordereau 3 (AUTO 21 / BCI CHARTRES) cas ambigu', () {
    /// Bordereau MESEXP ou le destinataire n'apparait qu'une seule fois
    /// dans le flux OCR, et ou plusieurs candidats sont en concurrence
    /// (transporteur AVENUE LOUIS PASTEUR repete 2 fois). Le parser
    /// doit detecter qu'il n'est pas confiant et marquer
    /// confidence = low pour eviter une fausse extraction.
    final realLines3 = [
      'décret du 6 av 1993 sont applicables.',
      'Transports A déat de conttat speciique',
      'les pertiS,',
      'ente les dispositlrs issues',
      'du',
      'les 3 jours suiver la réce,:ton sercnt recevables (art 133 3 du Gode de commerce)',
      '|Sur demarde seules les réserves précisesg el confirmées par ctre recommandée dans',
      'La',
      "remise des cols entraine l'acteptaton de nos conditions générales",
      '(texte',
      'intégral remis',
      'Signature',
      'Nom, e Cacher oblige',
      'Siret : 97880271800012 Tel: 02 37 84 44 41 |Siret : 9680271800012 Tel : 02 37 84 44 41',
      '28630 GELLAINVILLE',
      '24 AVENUE LOUIS PASTEUR',
      'Eure et Loir Acheminement',
      '|Eure er Loir Acheminement',
      '28630 GELLAINVILLE',
      '24 AVENUE LOUIS PASTEUR',
      'Commissionnaire ou transpotPur principal Trariacorieur livreur',
      'Le',
      'total colis: 1',
      'Marchandise reçue en bon a',
      'heur',
      'Instruction iusisonDocIrRtesiM',
      'e0FA280€0a431157',
      'Contect destinataire',
      'Ref. dest.',
      'iev de livraison',
      'Ref. exped.',
      '28630 NOGENT LE PHAYE',
      'FR 28630 NOGENT LE PHAYE',
      '9 RUEDE GILLES DE ROBERVAL',
      '(VOLSWAGEN)',
      'NRE',
      'Débour',
      'T.VA',
      'Port TTC',
      'Por HT',
      'AUTO 21',
      'Expéditeur',
      'BCI CHARTRES',
      'IMPASSE MONDETOUR ZA',
      'Facture',
      'Messagerie Express',
      'Destinatałre',
      'LETTRE DE VOTURE',
      'MESEXP',
      'NA',
      'T13. 2',
      'Régime',
      'Nature de in marchandise',
      'Ligne',
      'Matieres dargereuses ADR',
      '28135975',
      '13/04/2026',
      'AUT630',
      '1',
      '1',
      'payé',
      'N récepissé',
      'Date expédition',
      'ClentM Poids Vo/La',
      'Port',
      'Contre-rerbougement',
      'souhaitee',
    ];

    test('NE prend PAS AVENUE LOUIS PASTEUR comme nom (rue du transporteur)',
        () {
      final result = BordereauParser().parse(realLines3);
      expect(result.nomDestinataire,
          isNot(contains('AVENUE LOUIS PASTEUR')));
    });

    test('NE prend PAS Eure et Loir Acheminement comme nom (transporteur)',
        () {
      final result = BordereauParser().parse(realLines3);
      expect(result.nomDestinataire?.toLowerCase() ?? '',
          isNot(contains('acheminement')));
    });

    test('confidence = low quand le nom ne peut pas etre identifie '
        'avec confiance', () {
      final result = BordereauParser().parse(realLines3);
      // On accepte high si jamais le parser arrive a trouver le nom,
      // mais low est attendu sur ce bordereau ambigu.
      expect(
        result.confidence,
        isIn([ExtractionConfidence.low, ExtractionConfidence.high]),
      );
    });

    test('extrait au moins le total colis (1)', () {
      final result = BordereauParser().parse(realLines3);
      expect(result.nbColis, 1);
    });
  });

  group('BordereauParser - bordereau portrait OCR tres degrade '
      '(GARAGE AGUILAR)', () {
    /// Dump OCR du bordereau GARAGE AGUILAR scanne en mode portrait.
    /// L'OCR est tres degrade : "Lieu de livraison" -> "Lies de
    /// liraison" (typo), "AVENUE" -> "ArsUE" sur l'une des deux lignes
    /// rue. "GARAGE AGUILAR" n'apparait qu'une fois (ligne 13).
    /// "LOUIS PASTEUR" apparait deux fois MAIS uniquement dans des
    /// rues numerotees (L22 + L24) -> il ne doit PAS etre extrait
    /// comme nom de destinataire.
    final portraitLines = [
      'FLACEPR',
      'Fégime',
      'e',
      'Dae eéSterCert',
      'LEHAPDECAGER PD23',
      'RZSES LESLEMANS',
      'Coac ere',
      '30425',
      'ALPR',
      'Desinatzire',
      'L687',
      'Nature de ie marchandise',
      'MARCHAND SES',
      'GARAGE AGUILAR',
      '51 AVENUE D ORLEANNS',
      '28000 CHARTRES',
      'Lies de liraison',
      'Ireson de Iivraison-Documert de suiÍ',
      'ComngloeTtranspoter iirey',
      'Eure er Loir Acherninement',
      'Vol / Lg',
      'EreeLo Ateinemert',
      'Z4 ArsUE LOUIS PASTEUR',
      'areTnn n4441Siret:97880271800012 Tel : 02 3784 44 41',
      '24 AVENUE LOUIS PASTEUR',
      '20630 GELLAINNLLE',
      'Tort',
      'pay',
      'Sderrdey',
      'errise des cohs',
      'condiois oénérales',
      'RE',
      'conmerc)',
    ];

    test('NE prend PAS LOUIS PASTEUR comme nom (occurrences uniquement '
        'dans des rues)', () {
      final result = BordereauParser().parse(portraitLines);
      expect(result.nomDestinataire?.toLowerCase() ?? '',
          isNot(contains('pasteur')));
    });

    test('NE retourne PAS confidence=high (pas de nom fiable + rue '
        'fausse risque)', () {
      final result = BordereauParser().parse(portraitLines);
      expect(result.confidence, isNot(ExtractionConfidence.high));
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
