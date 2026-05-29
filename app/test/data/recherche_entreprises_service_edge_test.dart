import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/recherche_entreprises_service.dart';

// Complete recherche_entreprises_service_test : URL params, headers,
// fallback siege/matching, formats lat/lng, displayName vide, trim query.
void main() {
  Map<String, dynamic> mkResult({
    String etat = 'A',
    String etatSiege = 'A',
    String? lat = '48.4220',
    String? lon = '1.4889',
    String? nomComplet = 'GARAGE X',
    String? numeroVoie,
    String? libelleVoie = 'rue X',
    String? typeVoie,
    String? codePostal = '28100',
    String? libelleCommune = 'Dreux',
    String? adresse = '1 rue X 28100 DREUX',
    List<Map<String, dynamic>>? matching,
  }) {
    final out = <String, dynamic>{
      'etat_administratif': etat,
      'nom_complet': nomComplet,
      'siege': {
        'etat_administratif': etatSiege,
        'latitude': lat,
        'longitude': lon,
        'numero_voie': numeroVoie,
        'libelle_voie': libelleVoie,
        'type_voie': typeVoie,
        'code_postal': codePostal,
        'libelle_commune': libelleCommune,
        'adresse': adresse,
      },
    };
    if (matching != null) {
      out['matching_etablissements'] = matching;
    }
    return out;
  }

  group('RechercheEntreprisesService — URL/headers', () {
    test('URL contient q + per_page + page=1', () async {
      Uri? captured;
      final mock = MockClient((req) async {
        captured = req.url;
        return http.Response('{"results": []}', 200);
      });
      await RechercheEntreprisesService(client: mock)
          .search('Garage Cabaret', limit: 5);
      expect(captured!.host, 'recherche-entreprises.api.gouv.fr');
      expect(captured!.path, '/search');
      expect(captured!.queryParameters['q'], 'Garage Cabaret');
      expect(captured!.queryParameters['per_page'], '5');
      expect(captured!.queryParameters['page'], '1');
    });

    test('User-Agent contient "opti_route"', () async {
      String? ua;
      final mock = MockClient((req) async {
        ua = req.headers['User-Agent'];
        return http.Response('{"results": []}', 200);
      });
      await RechercheEntreprisesService(client: mock).search('test rue');
      expect(ua, contains('opti_route'));
    });
  });

  group('RechercheEntreprisesService — trim query', () {
    test('whitespace 4 chars trim -> "ab" (2 chars) -> rejette', () async {
      var called = false;
      final mock = MockClient((req) async {
        called = true;
        return http.Response('{"results": []}', 200);
      });
      final r = await RechercheEntreprisesService(client: mock)
          .search('  ab  ');
      expect(r, isEmpty);
      expect(called, isFalse);
    });
  });

  group('RechercheEntreprisesService — fallback siege/matching', () {
    test('siege ferme + matching actif : utilise le matching', () async {
      final body = jsonEncode({
        'results': [
          mkResult(
            etatSiege: 'F',
            matching: [
              {
                'etat_administratif': 'A',
                'latitude': '48.5',
                'longitude': '1.5',
                'libelle_voie': 'rue Active',
                'libelle_commune': 'ActiveVille',
                'code_postal': '28200',
                'adresse': '5 rue Active',
              },
            ],
          ),
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r, hasLength(1));
      expect(r.first.city, 'ActiveVille');
      expect(r.first.lat, 48.5);
    });

    test('siege ferme + matching tous fermes : skip', () async {
      final body = jsonEncode({
        'results': [
          mkResult(
            etatSiege: 'F',
            matching: [
              {'etat_administratif': 'F', 'latitude': '48.5', 'longitude': '1.5'},
            ],
          ),
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r, isEmpty);
    });

    test('entreprise cessee (etat_administratif=C) : skip', () async {
      final body = jsonEncode({
        'results': [mkResult(etat: 'C')],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r, isEmpty);
    });
  });

  group('RechercheEntreprisesService — formats coordonnees', () {
    test('lat/lng en num (pas string) : accepte', () async {
      final body = jsonEncode({
        'results': [
          mkResult(lat: null, lon: null)..['siege'] = {
            'etat_administratif': 'A',
            'latitude': 48.5, // num au lieu de string
            'longitude': 1.5,
            'libelle_voie': 'rue X',
            'libelle_commune': 'Dreux',
            'code_postal': '28100',
            'adresse': '1 rue X',
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r.first.lat, 48.5);
    });

    test('lat null : skip le resultat', () async {
      final body = jsonEncode({
        'results': [mkResult(lat: null)],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r, isEmpty);
    });

    test('lat string non-parseable : skip', () async {
      final body = jsonEncode({
        'results': [mkResult(lat: 'pas-un-nombre')],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r, isEmpty);
    });
  });

  group('RechercheEntreprisesService — composition road', () {
    test('road = typeVoie + libelleVoie quand les 2 presents', () async {
      final body = jsonEncode({
        'results': [
          mkResult(
            typeVoie: 'RUE',
            libelleVoie: 'DE LA PAIX',
          ),
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r.first.road, 'RUE DE LA PAIX');
    });

    test('road = libelleVoie quand typeVoie null', () async {
      final body = jsonEncode({
        'results': [mkResult(libelleVoie: 'Rue X', typeVoie: null)],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r.first.road, 'Rue X');
    });
  });

  group('RechercheEntreprisesService — divers', () {
    test('nom_complet absent : fallback nom_raison_sociale', () async {
      final body = jsonEncode({
        'results': [
          {
            'etat_administratif': 'A',
            'nom_raison_sociale': 'FALLBACK NAME',
            'siege': {
              'etat_administratif': 'A',
              'latitude': '48.0',
              'longitude': '1.0',
              'libelle_voie': 'rue X',
              'libelle_commune': 'Dreux',
              'code_postal': '28100',
              'adresse': '1 rue X',
            },
          },
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r.first.poiName, 'FALLBACK NAME');
    });

    test('plusieurs resultats valides : tous conserves', () async {
      final body = jsonEncode({
        'results': [
          mkResult(nomComplet: 'A', lat: '48.1', lon: '1.1'),
          mkResult(nomComplet: 'B', lat: '48.2', lon: '1.2'),
          mkResult(nomComplet: 'C', lat: '48.3', lon: '1.3'),
        ],
      });
      final mock = MockClient((req) async => http.Response(body, 200));
      final r = await RechercheEntreprisesService(client: mock).search('XYZ');
      expect(r, hasLength(3));
    });
  });
}
