import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/vcard_parser.dart';

// Complete vcard_parser_test : getters VcardContact, unescape "\\n",
// GEO format 3.0 "lat;lng", GEO degenere, BEGIN orphelin / END orphelin,
// TEL multiple (1ere prise), retours CRLF mixtes.
void main() {
  group('VcardContact — getters derives', () {
    test('contact totalement vide : hasAdresse=false, hasCoords=false', () {
      const c = VcardContact();
      expect(c.adresseComposee, isEmpty);
      expect(c.hasAdresse, isFalse);
      expect(c.hasCoords, isFalse);
    });

    test('hasCoords true seulement si lat ET lng', () {
      expect(const VcardContact(lat: 48).hasCoords, isFalse);
      expect(const VcardContact(lng: 1).hasCoords, isFalse);
      expect(const VcardContact(lat: 48, lng: 1).hasCoords, isTrue);
    });

    test('adresseComposee : rue + cp + ville', () {
      const c = VcardContact(rue: '1 rue X', codePostal: '28100', ville: 'Dreux');
      expect(c.adresseComposee, '1 rue X, 28100 Dreux');
    });

    test('adresseComposee : ville seule (sans CP)', () {
      const c = VcardContact(ville: 'Dreux');
      expect(c.adresseComposee, 'Dreux');
    });

    test('adresseComposee : rue seule', () {
      const c = VcardContact(rue: '1 rue X');
      expect(c.adresseComposee, '1 rue X');
    });

    test('adresseComposee : rue avec whitespace trim', () {
      const c = VcardContact(rue: '  1 rue X  ');
      expect(c.adresseComposee, '1 rue X');
    });
  });

  group('VcardParser.parse — formats GEO', () {
    test('GEO 3.0 format "lat;lng"', () {
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:X
GEO:48.5;1.5
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards, hasLength(1));
      expect(cards.first.lat, 48.5);
      expect(cards.first.lng, 1.5);
    });

    test('GEO 4.0 format "geo:lat,lng"', () {
      const vcard = '''BEGIN:VCARD
VERSION:4.0
FN:X
GEO:geo:48.5,1.5
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards.first.lat, 48.5);
      expect(cards.first.lng, 1.5);
    });

    test('GEO malforme : "abc" -> coords null', () {
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:X
GEO:abc
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards.first.lat, isNull);
      expect(cards.first.lng, isNull);
    });

    test('GEO incomplet (1 seul nombre) -> null', () {
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:X
GEO:48.5
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards.first.lat, isNull);
    });

    test('GEO hors bornes (999;999) -> coords rejetees (durcissement nuit)',
        () {
      // Un vCard malformé/hostile ne doit pas injecter une coord aberrante
      // qui corromprait l'optimisation. Le contact reste valide (nom),
      // mais sans coords (hasCoords=false).
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:Hacker
GEO:999;-999
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards, hasLength(1));
      expect(cards.first.nom, 'Hacker');
      expect(cards.first.lat, isNull);
      expect(cards.first.lng, isNull);
      expect(cards.first.hasCoords, isFalse);
    });

    test('GEO latitude hors plage seule (lat=91) -> rejetee', () {
      const vcard = '''BEGIN:VCARD
VERSION:4.0
FN:X
GEO:geo:91,2
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards.first.lat, isNull);
      expect(cards.first.lng, isNull);
    });
  });

  group('VcardParser.parse — structure', () {
    test('END:VCARD orphelin (sans BEGIN) : ignore proprement', () {
      const vcard = '''END:VCARD
BEGIN:VCARD
VERSION:3.0
FN:X
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      // 1 carte valide (la 2eme)
      expect(cards, hasLength(1));
      expect(cards.first.nom, 'X');
    });

    test('BEGIN:VCARD sans END : la carte courante est jetee', () {
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:Orpheline''';
      final cards = VcardParser.parse(vcard);
      // Pas de END -> _parseCard pas appele -> 0 cartes
      expect(cards, isEmpty);
    });

    test('CRLF (\\r\\n) au lieu de \\n : marche aussi', () {
      const vcard = 'BEGIN:VCARD\r\nVERSION:3.0\r\nFN:X\r\nEND:VCARD\r\n';
      final cards = VcardParser.parse(vcard);
      expect(cards, hasLength(1));
      expect(cards.first.nom, 'X');
    });

    test('CR seul (\\r) : marche aussi', () {
      const vcard = 'BEGIN:VCARD\rVERSION:3.0\rFN:X\rEND:VCARD\r';
      final cards = VcardParser.parse(vcard);
      expect(cards.first.nom, 'X');
    });
  });

  group('VcardParser.parse — TEL', () {
    test('plusieurs TEL : seul le 1er pris (tel ??=)', () {
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:X
TEL:0600000001
TEL:0600000002
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards.first.telephone, '0600000001');
    });

    test('TEL avec parametres TYPE=CELL : valeur extraite', () {
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:X
TEL;TYPE=CELL:0600000000
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards.first.telephone, '0600000000');
    });
  });

  group('VcardParser.parse — _unescape edge', () {
    test('\\\\ produit un backslash', () {
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:X
ORG:A\\\\B
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      // FN prime sur ORG, donc nom = "X". On verifie via ORG-only.
      // Recreons sans FN :
      const vcard2 = '''BEGIN:VCARD
VERSION:3.0
ORG:A\\\\B
END:VCARD''';
      final cards2 = VcardParser.parse(vcard2);
      expect(cards2.first.nom, r'A\B', reason: '\\\\ -> \\');
      expect(cards, hasLength(1));
    });

    test('\\n produit un retour ligne dans le nom', () {
      const vcard = '''BEGIN:VCARD
VERSION:3.0
FN:line1\\nline2
END:VCARD''';
      final cards = VcardParser.parse(vcard);
      expect(cards.first.nom, contains('\n'));
    });
  });

  group('VcardParser.parse — contenu vide / degenere', () {
    test('chaine vide -> aucune carte', () {
      expect(VcardParser.parse(''), isEmpty);
    });

    test('seulement des whitespaces -> aucune carte', () {
      expect(VcardParser.parse('   \n  \n'), isEmpty);
    });
  });
}
