import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/share_intent_service.dart';

// Tests purs de parseSharedText (sans expansion des short-links
// maps.app.goo.gl qui necessitent un HTTP HEAD reseau).
void main() {
  group('ShareIntentService.parseSharedText', () {
    test('texte vide -> null', () async {
      expect(await ShareIntentService.parseSharedText(''), isNull);
    });

    test('whitespace seul -> null', () async {
      expect(
        await ShareIntentService.parseSharedText('   \n   \n  '),
        isNull,
      );
    });

    test('texte simple -> SharedAddress avec name = texte, pas de coords',
        () async {
      final r = await ShareIntentService.parseSharedText('Garage Cabaret');
      expect(r, isNotNull);
      expect(r!.name, 'Garage Cabaret');
      expect(r.lat, isNull);
      expect(r.lng, isNull);
      expect(r.sourceUrl, isNull);
    });

    test('URL Google Maps avec @lat,lng,zoom -> extrait les coords', () async {
      final r = await ShareIntentService.parseSharedText(
        'https://www.google.com/maps/@48.4467,1.4889,17z',
      );
      expect(r, isNotNull);
      expect(r!.lat, closeTo(48.4467, 0.0001));
      expect(r.lng, closeTo(1.4889, 0.0001));
      expect(r.sourceUrl, contains('google.com/maps'));
    });

    test('URL Google Maps /place/X/@lat,lng -> extrait nom + coords', () async {
      final r = await ShareIntentService.parseSharedText(
        'https://www.google.com/maps/place/Garage+Cabaret/@48.44,1.48,17z',
      );
      expect(r, isNotNull);
      expect(r!.name, contains('Garage Cabaret'));
      expect(r.lat, closeTo(48.44, 0.0001));
    });

    test('URL Google Maps ?q=lat,lng -> extrait les coords', () async {
      final r = await ShareIntentService.parseSharedText(
        'https://www.google.com/maps?q=48.5,1.5',
      );
      expect(r, isNotNull);
      expect(r!.lat, closeTo(48.5, 0.0001));
      expect(r.lng, closeTo(1.5, 0.0001));
    });

    test('texte + URL maps : name = texte, coords = URL', () async {
      final r = await ShareIntentService.parseSharedText(
        'Mon garage\nhttps://www.google.com/maps/@48.4,1.4,17z',
      );
      expect(r, isNotNull);
      expect(r!.name, 'Mon garage');
      expect(r.lat, closeTo(48.4, 0.0001));
      expect(r.sourceUrl, contains('google.com/maps'));
    });

    test('URL non-Google : traitee comme texte name (sourceUrl null)', () async {
      final r = await ShareIntentService.parseSharedText(
        'https://example.com/page',
      );
      expect(r, isNotNull);
      expect(r!.name, 'https://example.com/page');
      expect(r.sourceUrl, isNull);
      expect(r.lat, isNull);
    });
  });
}
