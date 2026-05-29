import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/ban_geocoding_service.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/bordereau_validator.dart';

// Complete bordereau_validator_test : cas-limites pas couverts par les
// 6 tests existants (preservation format/source, correction CP isolee,
// multiple candidats BAN, rue avec separateur " . ", etc).
void main() {
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

  http.Client mockOk(
    List<({String label, String? street, String postcode, String city,
        double lat, double lon})> features,
  ) {
    return MockClient((req) async {
      return http.Response(fakeBanBody(features), 200);
    });
  }

  group('BordereauValidator — preservation des metadata', () {
    test('format ENLEVEMENT preserve apres correction de ville', () async {
      final mock = mockOk([
        (
          label: '12 Rue Sainte-Catherine 33000 Bordeaux',
          street: 'Rue Sainte-Catherine',
          postcode: '33000',
          city: 'Bordeaux',
          lat: 44.84,
          lon: -0.575,
        ),
      ]);
      final v = BordereauValidator(BanGeocodingService(client: mock));

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUS',
        format: BordereauFormat.enlevement,
      ));

      expect(r.validated, true);
      expect(r.extraction.format, BordereauFormat.enlevement,
          reason: 'le format detecte en amont doit survivre a la correction');
    });

    test('source llmGemini preservee apres correction', () async {
      final mock = mockOk([
        (
          label: '12 Rue Sainte-Catherine 33000 Bordeaux',
          street: 'Rue Sainte-Catherine',
          postcode: '33000',
          city: 'Bordeaux',
          lat: 44.84,
          lon: -0.575,
        ),
      ]);
      final v = BordereauValidator(BanGeocodingService(client: mock));

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUS',
        source: ExtractionSource.llmGemini,
      ));

      expect(r.extraction.source, ExtractionSource.llmGemini);
    });

    test('confiance HIGH appliquee meme si extraction etait low', () async {
      final mock = mockOk([
        (
          label: '12 Rue Sainte-Catherine 33000 Bordeaux',
          street: 'Rue Sainte-Catherine',
          postcode: '33000',
          city: 'Bordeaux',
          lat: 44.84,
          lon: -0.575,
        ),
      ]);
      final v = BordereauValidator(BanGeocodingService(client: mock));

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUX',
        confidence: ExtractionConfidence.low,
      ));

      expect(r.validated, true);
      expect(r.extraction.confidence, ExtractionConfidence.high,
          reason: 'validation BAN reussie -> upgrade confiance a high');
    });
  });

  group('BordereauValidator — corrections', () {
    test('CP corrige independamment quand ville deja correcte', () async {
      final mock = mockOk([
        (
          label: '12 Rue Sainte-Catherine 33000 Bordeaux',
          street: 'Rue Sainte-Catherine',
          postcode: '33000',
          city: 'Bordeaux',
          lat: 44.84,
          lon: -0.575,
        ),
      ]);
      final v = BordereauValidator(BanGeocodingService(client: mock));

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33333', // CP mal lu par OCR
        ville: 'BORDEAUX',
      ));

      expect(r.validated, true);
      expect(r.extraction.codePostal, '33000');
      expect(r.correctionsApplied, hasLength(1));
      expect(r.correctionsApplied.first, contains('CP'));
    });

    test('CP + ville corriges en meme temps (2 corrections)', () async {
      final mock = mockOk([
        (
          label: '12 Rue Sainte-Catherine 33000 Bordeaux',
          street: 'Rue Sainte-Catherine',
          postcode: '33000',
          city: 'Bordeaux',
          lat: 44.84,
          lon: -0.575,
        ),
      ]);
      final v = BordereauValidator(BanGeocodingService(client: mock));

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33333',
        ville: 'BORDEAUS',
      ));

      expect(r.validated, true);
      expect(r.correctionsApplied, hasLength(2));
    });
  });

  group('BordereauValidator — queries fallback', () {
    test('extraction avec seulement CP : appelle bien la BAN', () async {
      var calls = 0;
      final mock = MockClient((req) async {
        calls++;
        return http.Response('{"features": []}', 200);
      });
      final v = BordereauValidator(BanGeocodingService(client: mock));

      await v.validate(const BordereauExtraction(codePostal: '33000'));

      expect(calls, greaterThanOrEqualTo(1),
          reason: 'CP seul -> 1 query "33000"');
    });

    test('extraction avec seulement ville : non eligible (ne tente pas)',
        () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{"features": []}', 200);
      });
      final v = BordereauValidator(BanGeocodingService(client: mock));

      final r = await v.validate(const BordereauExtraction(ville: 'BORDEAUX'));

      // Sans rue ni CP, _buildQueries ne genere rien.
      expect(called, isFalse);
      expect(r.validated, isFalse);
    });
  });

  group('BordereauValidator — score', () {
    test('validationScore renvoye meme quand validated=false', () async {
      final mock = mockOk([
        (
          label: '1 Avenue des Champs-Elysees 75008 Paris',
          street: 'Avenue des Champs-Elysees',
          postcode: '75008',
          city: 'Paris',
          lat: 48.87,
          lon: 2.30,
        ),
      ]);
      final v = BordereauValidator(BanGeocodingService(client: mock));

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUX',
      ));

      expect(r.validated, isFalse);
      expect(r.validationScore, isNotNull,
          reason: 'on a calcule un score meme s\'il etait > seuil');
    });

    test('plusieurs candidats BAN : le meilleur (score le plus bas) gagne',
        () async {
      final mock = mockOk([
        (
          label: '1 Avenue des Champs-Elysees 75008 Paris',
          street: 'Avenue des Champs-Elysees',
          postcode: '75008',
          city: 'Paris',
          lat: 48.87,
          lon: 2.30,
        ),
        (
          label: '12 Rue Sainte-Catherine 33000 Bordeaux',
          street: 'Rue Sainte-Catherine',
          postcode: '33000',
          city: 'Bordeaux',
          lat: 44.84,
          lon: -0.575,
        ),
      ]);
      final v = BordereauValidator(BanGeocodingService(client: mock));

      final r = await v.validate(const BordereauExtraction(
        rue: '12 RUE SAINTE-CATHERINE',
        codePostal: '33000',
        ville: 'BORDEAUX',
      ));

      expect(r.validated, isTrue);
      expect(r.banSuggestion!.city, 'Bordeaux',
          reason: 'Bordeaux est plus proche du texte OCR que Paris');
    });
  });
}
