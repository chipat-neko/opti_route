import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/vcard_parser.dart';

/// Tests du parser vCard pur (carte #102) : extraction nom/adresse/
/// tel/coords, priorite des noms, repliement de lignes, echappement,
/// GEO 3.0 et 4.0.
void main() {
  test('carte simple : FN + ADR + TEL + GEO', () {
    const vcf = '''
BEGIN:VCARD
VERSION:3.0
FN:Garage Dupont
ADR;TYPE=WORK:;;12 rue de la Paix;Chartres;;28000;France
TEL;TYPE=CELL:0612345678
GEO:48.4500;1.4900
END:VCARD
''';
    final list = VcardParser.parse(vcf);
    expect(list, hasLength(1));
    final c = list.single;
    expect(c.nom, 'Garage Dupont');
    expect(c.rue, '12 rue de la Paix');
    expect(c.ville, 'Chartres');
    expect(c.codePostal, '28000');
    expect(c.telephone, '0612345678');
    expect(c.lat, 48.45);
    expect(c.lng, 1.49);
    expect(c.adresseComposee, '12 rue de la Paix, 28000 Chartres');
    expect(c.hasCoords, isTrue);
  });

  test('plusieurs cartes', () {
    const vcf = '''
BEGIN:VCARD
VERSION:3.0
FN:Client A
END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:Client B
TEL:0700000000
END:VCARD
''';
    final list = VcardParser.parse(vcf);
    expect(list.map((c) => c.nom).toList(), ['Client A', 'Client B']);
    expect(list[1].telephone, '0700000000');
  });

  test('priorite nom : FN > N > ORG', () {
    const withFn = 'BEGIN:VCARD\nFN:Nom FN\nN:Famille;Prenom;;;\nORG:Boite\nEND:VCARD';
    expect(VcardParser.parse(withFn).single.nom, 'Nom FN');

    const withN = 'BEGIN:VCARD\nN:Martin;Paul;;;\nORG:Boite\nEND:VCARD';
    expect(VcardParser.parse(withN).single.nom, 'Paul Martin');

    const withOrg = 'BEGIN:VCARD\nORG:Ma Boite\nTEL:06\nEND:VCARD';
    expect(VcardParser.parse(withOrg).single.nom, 'Ma Boite');
  });

  test('GEO format 4.0 (geo:lat,lng)', () {
    const vcf = 'BEGIN:VCARD\nFN:X\nGEO:geo:43.300,5.370\nEND:VCARD';
    final c = VcardParser.parse(vcf).single;
    expect(c.lat, 43.3);
    expect(c.lng, 5.37);
  });

  test('repliement de lignes (continuation)', () {
    // La 2e ligne commence par un espace -> continuation de FN.
    const vcf = 'BEGIN:VCARD\nFN:Nom tres\n  long client\nEND:VCARD';
    expect(VcardParser.parse(vcf).single.nom, 'Nom tres long client');
  });

  test('echappement \\, et \\; dans les valeurs', () {
    const vcf = r'BEGIN:VCARD' '\n'
        r'FN:Dupont\, Paul' '\n'
        r'ADR:;;Rue du 8\; mai;Lille;;59000;France' '\n'
        'END:VCARD';
    final c = VcardParser.parse(vcf).single;
    expect(c.nom, 'Dupont, Paul');
    expect(c.rue, 'Rue du 8; mai');
  });

  test('carte sans rien d\'exploitable -> ignoree', () {
    const vcf = 'BEGIN:VCARD\nVERSION:3.0\nEND:VCARD';
    expect(VcardParser.parse(vcf), isEmpty);
  });

  test('contenu vide -> liste vide', () {
    expect(VcardParser.parse(''), isEmpty);
    expect(VcardParser.parse('n\'importe quoi'), isEmpty);
  });

  test('adresseComposee : rue seule / ville seule', () {
    const vcf = 'BEGIN:VCARD\nFN:X\nADR:;;Rue seule;;;;\nEND:VCARD';
    expect(VcardParser.parse(vcf).single.adresseComposee, 'Rue seule');
  });
}
