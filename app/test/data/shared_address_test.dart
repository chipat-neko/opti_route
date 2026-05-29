import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/share_intent_service.dart';

// Tests des getters de SharedAddress (hasCoords, queryHint), pas
// couverts par share_intent_parse_test.dart.
void main() {
  group('SharedAddress.hasCoords', () {
    test('lat ET lng requis : true', () {
      const a = SharedAddress(
        rawText: 'X',
        lat: 48.5,
        lng: 1.5,
      );
      expect(a.hasCoords, isTrue);
    });

    test('lat seul : false', () {
      const a = SharedAddress(rawText: 'X', lat: 48.5);
      expect(a.hasCoords, isFalse);
    });

    test('lng seul : false', () {
      const a = SharedAddress(rawText: 'X', lng: 1.5);
      expect(a.hasCoords, isFalse);
    });

    test('aucun : false', () {
      const a = SharedAddress(rawText: 'X');
      expect(a.hasCoords, isFalse);
    });
  });

  group('SharedAddress.queryHint — priorite name > sourceUrl > rawText', () {
    test('name + sourceUrl + rawText : name gagne', () {
      const a = SharedAddress(
        rawText: 'raw',
        name: 'NomLieu',
        sourceUrl: 'https://example.com',
      );
      expect(a.queryHint, 'NomLieu');
    });

    test('sourceUrl + rawText (pas de name) : sourceUrl gagne', () {
      const a = SharedAddress(
        rawText: 'raw',
        sourceUrl: 'https://example.com',
      );
      expect(a.queryHint, 'https://example.com');
    });

    test('rawText seul : rawText retourne', () {
      const a = SharedAddress(rawText: 'fallback brut');
      expect(a.queryHint, 'fallback brut');
    });

    test('name vide : name vide encore prioritaire (truthy par non-null)',
        () {
      // queryHint utilise ?? qui ne distingue pas null vs "". On
      // verrouille le comportement actuel.
      const a = SharedAddress(
        rawText: 'raw',
        name: '',
      );
      expect(a.queryHint, '');
    });
  });

  group('SharedAddress — defauts', () {
    test('tous les optionnels null par defaut', () {
      const a = SharedAddress(rawText: 'X');
      expect(a.name, isNull);
      expect(a.lat, isNull);
      expect(a.lng, isNull);
      expect(a.sourceUrl, isNull);
    });
  });
}
