import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/ban_geocoding_service.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/bordereau_validator.dart';

void main() {
  /// Fabrique un faux body BAN avec [features] = liste de tuples
  /// (label, street, postcode, city, lat, lon).
  String fakeBanBody(
    List<({String label, String? street, String postcode, String city,
        double lat, double lon})> features,
  ) {
    return jsonEncode({
      'features': features
          .map((f) => {
                'geometry': {
                  'type': 'Point',
                  'coordinates': [f.lon, f.lat],
                },
                'properties': {
                  'label': f.label,
                  'street': f.street,
                  'postcode': f.postcode,
                  'city': f.city,
                  'type': f.street == null ? 'municipality' : 'street',
                },
              })
          .toList(),
    });
  }

  http.Client clientWith(List<dynamic> features) {
    return MockClient((req) async {
      // Cast pour passer dans fakeBanBody
      final typed = features.cast<
          ({
            String label,
            String? street,
            String postcode,
            String city,
            double lat,
            double lon,
          })>();
      return http.Response(fakeBanBody(typed), 200);
    });
  }

  group('BordereauValidator.validate', () {
    test('extraction sans adresse : validated=false, pas d\'appel BAN',
        () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{"features": []}', 200);
      });
      final ban = BanGeocodingService(client: mock);
      final v = BordereauValidator(ban);

      final r = await v.validate(const BordereauExtraction(
        nomDestinataire: 'BOULANGERIE MARTIN',
      ));

      expect(r.validated, false);
      expect(r.banSuggestion, isNull);
      expect(called, false, reason: 'pas besoin d\'appeler BAN');
    });

    test('adresse exacte trouvee : validated=true sans correction', () async {
      final mock = clientWith([
        (
          label: '12 Rue Sainte-Catherine 33000 Bordeaux',
          street: 'Rue Sainte-Catherine',
          postcode: '33000',
          city: 'Bordeaux',
          lat: 44.84,
          lon: -0.575,
        ),
      ]);
      final ban = BanGeocodingService(client: mock);
      final v = BordereauValidator(ban);

      final r = await v.validate(const BordereauExtraction(
        nomDestinataire: 'BOULANGERIE MARTIN',
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUX',
      ));

      expect(r.validated, true);
      expect(r.banSuggestion, isNotNull);
      expect(r.banSuggestion!.city, 'Bordeaux');
      // Ville deja correcte (apres upper) -> pas de correction
      expect(r.correctionsApplied, isEmpty);
    });

    test('ville mal orthographiee (BORDEAUS) : corrigee en BORDEAUX',
        () async {
      final mock = clientWith([
        (
          label: '12 Rue Sainte-Catherine 33000 Bordeaux',
          street: 'Rue Sainte-Catherine',
          postcode: '33000',
          city: 'Bordeaux',
          lat: 44.84,
          lon: -0.575,
        ),
      ]);
      final ban = BanGeocodingService(client: mock);
      final v = BordereauValidator(ban);

      final r = await v.validate(const BordereauExtraction(
        nomDestinataire: 'BOULANGERIE MARTIN',
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUS', // OCR a confondu X et S
      ));

      expect(r.validated, true);
      expect(r.extraction.ville, 'BORDEAUX',
          reason: 'la ville doit etre corrigee a partir de la BAN');
      expect(r.correctionsApplied, hasLength(1));
      expect(r.correctionsApplied.first, contains('Ville'));
      expect(r.correctionsApplied.first, contains('BORDEAUS'));
      expect(r.correctionsApplied.first, contains('BORDEAUX'));
    });

    test('BAN retourne vide : validated=false', () async {
      final mock = MockClient((req) async {
        return http.Response('{"features": []}', 200);
      });
      final ban = BanGeocodingService(client: mock);
      final v = BordereauValidator(ban);

      final r = await v.validate(const BordereauExtraction(
        rue: 'XYZ INEXISTANTE',
        codePostal: '99999',
        ville: 'NULLEPART',
      ));

      expect(r.validated, false);
      expect(r.banSuggestion, isNull);
    });

    test('BAN retourne une adresse trop differente : validated=false',
        () async {
      // Note : ici BAN repond avec une adresse a Paris alors qu'on
      // cherchait a Bordeaux. La similarite sera bien au-dessus du
      // seuil 0.3 -> validation refusee.
      final mock = clientWith([
        (
          label: '1 Avenue des Champs-Elysees 75008 Paris',
          street: 'Avenue des Champs-Elysees',
          postcode: '75008',
          city: 'Paris',
          lat: 48.87,
          lon: 2.30,
        ),
      ]);
      final ban = BanGeocodingService(client: mock);
      final v = BordereauValidator(ban);

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUX',
      ));

      expect(r.validated, false);
      expect(r.validationScore, isNotNull);
      expect(r.validationScore!, greaterThan(0.3));
    });

    test('erreur reseau : validated=false (best-effort, pas de throw)',
        () async {
      final mock = MockClient((req) async {
        throw Exception('reseau down');
      });
      final ban = BanGeocodingService(client: mock);
      final v = BordereauValidator(ban);

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUX',
      ));

      expect(r.validated, false);
    });
  });
}
