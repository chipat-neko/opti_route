import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/recherche_entreprises_service.dart';

void main() {
  group('RechercheEntreprisesService - filtres etat_administratif', () {
    test('entreprise cessee (etat C) : skippee', () async {
      // Cas reel : SAS Alain Javault. L'entreprise est cessee depuis
      // 2006-03-31 mais SIRENE la retourne quand meme avec une adresse
      // de siege ferme a CAEN. Si on l'utilisait, on enverrait le
      // livreur a 2h de route de l'entreprise actuelle (Chartres).
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'siren': '313153629',
                'nom_complet': 'ALAIN JAVAULT',
                'etat_administratif': 'C',
                'siege': {
                  'etat_administratif': 'F',
                  'adresse': '57 COURS CAFFARELLI 14000 CAEN',
                  'latitude': '49.180780672428',
                  'longitude': '-0.342789166661757',
                  'libelle_commune': 'CAEN',
                  'code_postal': '14000',
                },
                'matching_etablissements': [
                  {
                    'etat_administratif': 'F',
                    'adresse': '3 RUE DES TOURNEBALLETS 28110 LUCE',
                    'latitude': '48.424924535',
                    'longitude': '1.4518710443',
                  }
                ],
              }
            ],
          }),
          200,
        );
      });
      final svc = RechercheEntreprisesService(client: mock);
      final results = await svc.search('Alain Javault');
      svc.close();
      expect(results, isEmpty);
    });

    test('entreprise active, siege actif : retourne le siege', () async {
      final mock = MockClient((req) async {
        return http.Response(
          jsonEncode({
            'results': [
              {
                'siren': '111111111',
                'nom_complet': 'CARROSSERIE COCULO',
                'etat_administratif': 'A',
                'siege': {
                  'etat_administratif': 'A',
                  'adresse': '1 RUE DES TOURNESOLS 28110 LUCE',
                  'latitude': '48.4307',
                  'longitude': '1.4892',
                  'libelle_commune': 'LUCE',
                  'code_postal': '28110',
                  'numero_voie': '1',
                  'libelle_voie': 'DES TOURNESOLS',
                  'type_voie': 'RUE',
                },
              }
            ],
          }),
          200,
        );
      });
      final svc = RechercheEntreprisesService(client: mock);
      final results = await svc.search('Carrosserie Coculo');
      svc.close();
      expect(results, hasLength(1));
      expect(results.first.lat, 48.4307);
      expect(results.first.poiName, 'CARROSSERIE COCULO');
    });

    test(
      'siege ferme mais etablissement actif : retourne l\'etablissement',
      () async {
        final mock = MockClient((req) async {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'siren': '222222222',
                  'nom_complet': 'CHAINE EXEMPLE',
                  'etat_administratif': 'A',
                  'siege': {
                    'etat_administratif': 'F',
                    'adresse': '1 RUE FERMEE 75001 PARIS',
                    'latitude': '48.85',
                    'longitude': '2.35',
                  },
                  'matching_etablissements': [
                    {
                      'etat_administratif': 'F',
                      'adresse': '2 RUE FERMEE BIS 75002 PARIS',
                      'latitude': '48.86',
                      'longitude': '2.36',
                    },
                    {
                      'etat_administratif': 'A',
                      'adresse': '10 RUE OUVERTE 28000 CHARTRES',
                      'latitude': '48.4444',
                      'longitude': '1.5555',
                      'libelle_commune': 'CHARTRES',
                      'code_postal': '28000',
                    }
                  ],
                }
              ],
            }),
            200,
          );
        });
        final svc = RechercheEntreprisesService(client: mock);
        final results = await svc.search('Chaine Exemple');
        svc.close();
        // L'etablissement actif a Chartres doit etre choisi, pas le
        // siege ferme a Paris.
        expect(results, hasLength(1));
        expect(results.first.lat, 48.4444);
        expect(results.first.city, 'CHARTRES');
      },
    );

    test(
      'siege ferme + aucun etablissement actif : skippe',
      () async {
        final mock = MockClient((req) async {
          return http.Response(
            jsonEncode({
              'results': [
                {
                  'siren': '333333333',
                  'nom_complet': 'TOTALEMENT MORTE',
                  'etat_administratif': 'A',
                  'siege': {
                    'etat_administratif': 'F',
                    'latitude': '48',
                    'longitude': '2',
                  },
                  'matching_etablissements': [
                    {'etat_administratif': 'F'},
                    {'etat_administratif': 'F'},
                  ],
                }
              ],
            }),
            200,
          );
        });
        final svc = RechercheEntreprisesService(client: mock);
        final results = await svc.search('Totalement morte');
        svc.close();
        expect(results, isEmpty);
      },
    );
  });
}
