import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/clipboard_address_helper.dart';

void main() {
  group('ClipboardAddressHelper.looksLikeAddress', () {
    test('texte vide -> false', () {
      expect(ClipboardAddressHelper.looksLikeAddress(''), isFalse);
      expect(ClipboardAddressHelper.looksLikeAddress('   '), isFalse);
    });

    test('CP francais -> true', () {
      expect(ClipboardAddressHelper.looksLikeAddress('28000 Chartres'), isTrue);
      expect(ClipboardAddressHelper.looksLikeAddress('Texte 75002 paris'),
          isTrue);
    });

    test('mot-cle rue -> true', () {
      expect(
        ClipboardAddressHelper.looksLikeAddress('Rue de la Paix'),
        isTrue,
      );
      expect(
        ClipboardAddressHelper.looksLikeAddress('Avenue des Champs'),
        isTrue,
      );
    });

    test('mention "France" -> true', () {
      expect(ClipboardAddressHelper.looksLikeAddress('Hello, France'),
          isTrue);
    });

    test('texte random sans aucun indice -> false', () {
      expect(
        ClipboardAddressHelper.looksLikeAddress('Bonjour comment vas-tu'),
        isFalse,
      );
    });

    test('mot-cle rue inclus dans un mot (faux positif) -> false', () {
      // "Boutique" contient "tique" mais pas le mot-cle "rue" isole.
      // On ne doit pas matcher.
      expect(
        ClipboardAddressHelper.looksLikeAddress('Boutique Bordeaux'),
        isFalse,
      );
    });
  });

  group('ClipboardAddressHelper.extractAddress', () {
    test('null -> null', () {
      expect(ClipboardAddressHelper.extractAddress(null), isNull);
    });

    test('vide -> null', () {
      expect(ClipboardAddressHelper.extractAddress(''), isNull);
      expect(ClipboardAddressHelper.extractAddress('   '), isNull);
    });

    test('partage Google Maps standard -> isole l\'adresse', () {
      // Format typique partage depuis l'app Maps Android.
      const raw = '''Mairie de Chartres
1 Place des Halles, 28000 Chartres, France
https://maps.app.goo.gl/abc123''';
      final addr = ClipboardAddressHelper.extractAddress(raw);
      expect(addr, '1 Place des Halles, 28000 Chartres');
    });

    test('partage avec ", France" supprime', () {
      const raw = '14 Rue de la Paix, 75002 Paris, France';
      expect(
        ClipboardAddressHelper.extractAddress(raw),
        '14 Rue de la Paix, 75002 Paris',
      );
    });

    test('partage avec URL longue google.com/maps', () {
      const raw = '''Cathedrale Notre-Dame
1 Cloitre Notre Dame, 28000 Chartres
https://www.google.com/maps/place/Cath%C3%A9drale+Notre-Dame/@48.4474,1.4877,17z''';
      final addr = ClipboardAddressHelper.extractAddress(raw);
      expect(addr, '1 Cloitre Notre Dame, 28000 Chartres');
    });

    test('texte sans CP ni mot-cle -> null', () {
      expect(
        ClipboardAddressHelper.extractAddress('Hello world'),
        isNull,
      );
    });

    test('1 ligne avec mot-cle rue mais pas de CP -> retourne quand meme',
        () {
      // Cas particulier : adresse partielle "Rue des Lilas" sans CP.
      // On accepte car ca permet de pre-remplir et BAN/SIRENE pourra
      // peut-etre completer.
      expect(
        ClipboardAddressHelper.extractAddress('Rue des Lilas'),
        'Rue des Lilas',
      );
    });

    test('multi-ligne avec CP sur la 2e ligne', () {
      const raw = 'POI name\n42 Avenue Hugo, 28000 Chartres';
      expect(
        ClipboardAddressHelper.extractAddress(raw),
        '42 Avenue Hugo, 28000 Chartres',
      );
    });

    test('CP avec ville sur ligne separee -> prend la 1ere ligne avec CP',
        () {
      const raw = 'Auchan Chartres\n28000 Chartres';
      expect(
        ClipboardAddressHelper.extractAddress(raw),
        '28000 Chartres',
      );
    });

    test('CRLF (Windows) supporte', () {
      const raw = 'POI\r\n14 Rue X, 75002 Paris\r\nhttps://maps.app.goo.gl/x';
      expect(
        ClipboardAddressHelper.extractAddress(raw),
        '14 Rue X, 75002 Paris',
      );
    });

    test('texte trop long sans CP -> null (evite copies fortuites)', () {
      final raw = 'Lorem ipsum ' * 50; // ~600 caracteres
      expect(ClipboardAddressHelper.extractAddress(raw), isNull);
    });
  });
}
