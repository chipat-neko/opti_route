import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/external_search_service.dart';

/// Tests sur la construction des URLs Google. On ne teste pas le
/// lancement effectif (`launchUrl`) -- c'est un side effect Android
/// qui demande un device, on se contente de verifier que les URLs
/// sont bien formees et que l'encoding marche.
void main() {
  group('ExternalSearchService.googleMapsUrl', () {
    test('query simple -> URL valide', () {
      final url = ExternalSearchService.googleMapsUrl('Mairie Chartres');
      expect(url.host, 'www.google.com');
      expect(url.path, '/maps/search/');
      expect(url.queryParameters['api'], '1');
      expect(url.queryParameters['query'], 'Mairie Chartres');
    });

    test('query avec accents -> encodage correct', () {
      final url = ExternalSearchService.googleMapsUrl('Cathédrale d\'Évreux');
      expect(url.queryParameters['query'], 'Cathédrale d\'Évreux');
      // Le `toString()` doit encoder pour HTTP.
      expect(url.toString(), contains('Cath%C3%A9drale'));
    });

    test('query avec espaces multiples -> encoded en + (form-encoded)', () {
      // Uri.encodeQueryComponent utilise le style form-encoded
      // (espaces -> +), accepte par Google et par tous les serveurs HTTP.
      final url = ExternalSearchService.googleMapsUrl('14 Rue de la Paix');
      expect(url.toString(), contains('14+Rue+de+la+Paix'));
      expect(url.queryParameters['query'], '14 Rue de la Paix');
    });

    test('query avec caracteres speciaux URL -> encoded', () {
      // & et = peuvent perturber la query string si pas encodes.
      final url = ExternalSearchService.googleMapsUrl('Cafe & Co');
      expect(url.toString(), contains('Cafe+%26+Co'));
      expect(url.queryParameters['query'], 'Cafe & Co');
    });

    test('query vide -> URL valide mais query vide', () {
      final url = ExternalSearchService.googleMapsUrl('');
      expect(url.queryParameters['query'], '');
    });

    test('query avec espaces en bordure -> trim auto', () {
      final url = ExternalSearchService.googleMapsUrl('  Paris  ');
      expect(url.queryParameters['query'], 'Paris');
    });
  });

  group('ExternalSearchService.googleSearchUrl', () {
    test('query simple -> URL valide', () {
      final url = ExternalSearchService.googleSearchUrl('Auchan Chartres');
      expect(url.host, 'www.google.com');
      expect(url.path, '/search');
      expect(url.queryParameters['q'], 'Auchan Chartres');
    });

    test('query trim + encode', () {
      final url = ExternalSearchService.googleSearchUrl(' Décathlon  ');
      expect(url.queryParameters['q'], 'Décathlon');
      expect(url.toString(), contains('D%C3%A9cathlon'));
    });
  });
}
