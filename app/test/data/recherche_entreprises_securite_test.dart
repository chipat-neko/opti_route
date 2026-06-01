import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/geocoding_service.dart';
import 'package:opti_route/data/recherche_entreprises_service.dart';

/// Tests SECURITE / ROBUSTESSE du parseur SIRENE (Recherche d'Entreprises).
///
/// recherche_entreprises_service.dart desserialise du JSON venu d'une API
/// gov.fr tierce. recherche_entreprises_service_test.dart couvre la logique
/// metier (etat_administratif C/F/A, choix siege vs etablissement). Ce
/// fichier-ci se concentre sur l'HOSTILE : types incoherents, poison lists,
/// JSON tronque, unicode, debordements, et les memes classes de bugs de
/// cast/encodage reperees sur BAN/Photon.
void main() {
  // Bytes UTF-8 (comme le vrai reseau). Voir note encodage plus bas.
  MockClient ok(String body) => MockClient(
        (req) async => http.Response.bytes(utf8.encode(body), 200),
      );

  RechercheEntreprisesService svc(String body) =>
      RechercheEntreprisesService(client: ok(body));

  String oneResult(Map<String, dynamic> result) =>
      jsonEncode({'results': [result]});

  group('Top-level JSON hostile', () {
    test('body = "null" -> JSON inattendu -> GeocodingException', () {
      expect(svc('null').search('garage test'),
          throwsA(isA<GeocodingException>()));
    });

    test('body = tableau JSON -> GeocodingException', () {
      expect(svc('[1,2,3]').search('garage test'),
          throwsA(isA<GeocodingException>()));
    });

    test('body JSON tronque -> FormatException (jsonDecode, non encapsule)',
        () {
      expect(svc('{"results": [').search('garage test'),
          throwsA(isA<FormatException>()));
    });

    test('results = objet (pas liste) -> liste vide', () async {
      expect(await svc('{"results": {"a": 1}}').search('garage test'),
          isEmpty);
    });

    test('results = string -> liste vide', () async {
      expect(await svc('{"results": "boom"}').search('garage test'), isEmpty);
    });

    test('results = null explicite -> liste vide', () async {
      expect(await svc('{"results": null}').search('garage test'), isEmpty);
    });
  });

  group('Poison list dans results', () {
    test('elements non-Map (string/null/int) ignores, 1 valide survit',
        () async {
      final body = jsonEncode({
        'results': [
          'parasite',
          null,
          42,
          {
            'nom_complet': 'GARAGE OK',
            'etat_administratif': 'A',
            'siege': {
              'etat_administratif': 'A',
              'latitude': '48.0',
              'longitude': '1.0',
              'adresse': '1 RUE X 28000 CHARTRES',
              'libelle_commune': 'CHARTRES',
              'code_postal': '28000',
            },
          },
        ],
      });
      final r = await svc(body).search('garage');
      expect(r, hasLength(1));
      expect(r.first.poiName, 'GARAGE OK');
    });

    test('100% parasites -> liste vide', () async {
      final r = await svc(jsonEncode({
        'results': ['a', 1, null, true, [], 'x'],
      })).search('garage');
      expect(r, isEmpty);
    });
  });

  group('siege / etablissement malformes', () {
    test('siege = liste (non-Map) -> CAST ERROR (BUG documente)', () {
      // recherche_entreprises_service.dart:116 :
      //   (result['siege'] as Map?)?.cast<String, dynamic>()
      // Le `as Map?` jette si siege est une List. Meme classe de bug que
      // BAN (properties non-Map). Documente le comportement REEL.
      final body = oneResult({
        'nom_complet': 'X',
        'etat_administratif': 'A',
        'siege': ['not', 'a', 'map'],
      });
      expect(svc(body).search('x sas'), throwsA(isA<TypeError>()));
    });

    test('siege absent + matching_etablissements actif -> utilise l\'etab',
        () async {
      final body = oneResult({
        'nom_complet': 'SANS SIEGE',
        'etat_administratif': 'A',
        // pas de siege du tout
        'matching_etablissements': [
          {
            'etat_administratif': 'A',
            'latitude': '48.5',
            'longitude': '1.5',
            'adresse': '2 RUE Y 28100 DREUX',
            'libelle_commune': 'DREUX',
            'code_postal': '28100',
          }
        ],
      });
      final r = await svc(body).search('sans siege');
      expect(r, hasLength(1));
      expect(r.first.lat, 48.5);
      expect(r.first.city, 'DREUX');
    });

    test('matching_etablissements contient des non-Map -> ignores (m is Map)',
        () async {
      final body = oneResult({
        'nom_complet': 'AVEC PARASITES',
        'etat_administratif': 'A',
        'siege': {'etat_administratif': 'F'}, // ferme -> on cherche un etab
        'matching_etablissements': [
          'parasite',
          null,
          123,
          {
            'etat_administratif': 'A',
            'latitude': '48.6',
            'longitude': '1.6',
            'adresse': '3 RUE Z',
          },
        ],
      });
      final r = await svc(body).search('avec parasites');
      expect(r, hasLength(1));
      expect(r.first.lat, 48.6);
    });

    test('matching_etablissements = objet (pas liste) -> skip propre',
        () async {
      // matching n'est pas une List -> le if (matching is List) est faux,
      // etab reste null/ferme -> return null -> liste vide, pas de crash.
      final body = oneResult({
        'nom_complet': 'X',
        'etat_administratif': 'A',
        'siege': {'etat_administratif': 'F'},
        'matching_etablissements': {'k': 'v'},
      });
      final r = await svc(body).search('x sas');
      expect(r, isEmpty);
    });
  });

  group('Coordonnees - parseDouble robuste (pas de cast crash)', () {
    String coordBody(String lat, String lon) => oneResult({
          'nom_complet': 'COORD TEST',
          'etat_administratif': 'A',
          'siege': {
            'etat_administratif': 'A',
            'latitude': lat,
            'longitude': lon,
            'adresse': '1 RUE X',
          },
        });

    test('latitude/longitude string non numerique -> _parseDouble null '
        '-> skip (pas de crash)', () async {
      final body = oneResult({
        'nom_complet': 'X',
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'latitude': 'pas un nombre',
          'longitude': 'NaN aussi',
          'adresse': '1 RUE X',
        },
      });
      final r = await svc(body).search('x sas');
      expect(r, isEmpty);
    });

    test('latitude num (pas string) -> toleree par _parseDouble', () async {
      final body = oneResult({
        'nom_complet': 'NUM COORDS',
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'latitude': 48.42,
          'longitude': 1.49,
          'adresse': '1 RUE X 28000 CHARTRES',
          'libelle_commune': 'CHARTRES',
        },
      });
      final r = await svc(body).search('num coords');
      expect(r, hasLength(1));
      expect(r.first.lat, 48.42);
      expect(r.first.lon, 1.49);
    });

    test('latitude = bool -> _parseDouble retourne null -> skip', () async {
      final body = oneResult({
        'nom_complet': 'X',
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'latitude': true,
          'longitude': false,
          'adresse': '1 RUE X',
        },
      });
      final r = await svc(body).search('x sas');
      expect(r, isEmpty);
    });

    test('latitude manquante -> skip', () async {
      final body = oneResult({
        'nom_complet': 'X',
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'longitude': '1.0',
          'adresse': '1 RUE X',
        },
      });
      expect(await svc(body).search('x sas'), isEmpty);
    });

    test('coords aberrantes hors bornes -> ACCEPTEES (pas de validation) '
        '- documente', () async {
      final r = await svc(coordBody('999', '-999')).search('coord test');
      expect(r, hasLength(1));
      expect(r.first.lat, 999.0);
      expect(r.first.lon, -999.0);
    });

    test('coords "Infinity" / scientifique -> double.tryParse', () async {
      // double.tryParse("1e3") = 1000.0 ; "Infinity" = Infinity.
      final r = await svc(coordBody('1e3', 'Infinity')).search('coord test');
      expect(r, hasLength(1));
      expect(r.first.lat, 1000.0);
      expect(r.first.lon.isInfinite, isTrue);
    });
  });

  group('Champs texte de type incoherent', () {
    test('nom_complet = int -> CAST ERROR (BUG documente)', () {
      // result['nom_complet'] as String? jette si la valeur est un int.
      final body = oneResult({
        'nom_complet': 12345,
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'latitude': '48.0',
          'longitude': '1.0',
          'adresse': '1 RUE X',
        },
      });
      expect(svc(body).search('x sas'), throwsA(isA<TypeError>()));
    });

    test('nom_complet absent -> fallback nom_raison_sociale', () async {
      final body = oneResult({
        'nom_raison_sociale': 'RAISON SOCIALE SARL',
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'latitude': '48.0',
          'longitude': '1.0',
          'adresse': '1 RUE X 28000 CHARTRES',
          'libelle_commune': 'CHARTRES',
        },
      });
      final r = await svc(body).search('raison');
      expect(r, hasLength(1));
      expect(r.first.poiName, 'RAISON SOCIALE SARL');
    });

    test('ni nom ni adresse exploitable -> displayName vide -> skip',
        () async {
      final body = oneResult({
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'latitude': '48.0',
          'longitude': '1.0',
          // pas d'adresse, pas de code_postal, pas de commune, pas de nom
        },
      });
      expect(await svc(body).search('vide sas'), isEmpty);
    });
  });

  group('Encodage UTF-8 / mojibake (bug commun aux 3 geocodeurs)', () {
    test('nom_complet avec accent -> UTF-8 PRESERVE (fix nuit 2026-06-01)',
        () async {
      // Le service décode désormais utf8.decode(response.bodyBytes) au lieu
      // de response.body (Latin-1 par défaut faute de charset). On envoie de
      // l'UTF-8 (réseau réel via http.Response.bytes) et on vérifie que les
      // accents ressortent INTACTS (plus de mojibake « SociÃ©tÃ© »).
      const nom = 'Soci\u{00E9}t\u{00E9} G\u{00E9}n\u{00E9}rale';
      final body = oneResult({
        'nom_complet': nom,
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'latitude': '48.0',
          'longitude': '1.0',
          'adresse': '1 RUE X 28000 CHARTRES',
          'libelle_commune': 'CHARTRES',
        },
      });
      final r = await svc(body).search('societe');
      expect(r, hasLength(1));
      expect(r.first.poiName, equals(nom),
          reason: 'les accents UTF-8 doivent être préservés après le fix');
    });

    test('nom 100% ASCII -> intact (non affecte par le bug d\'encodage)',
        () async {
      const nom = 'GARAGE DUPONT ET FILS';
      final body = oneResult({
        'nom_complet': nom,
        'etat_administratif': 'A',
        'siege': {
          'etat_administratif': 'A',
          'latitude': '48.0',
          'longitude': '1.0',
          'adresse': '1 RUE X 28000 CHARTRES',
          'libelle_commune': 'CHARTRES',
        },
      });
      final r = await svc(body).search('garage dupont');
      expect(r.first.poiName, nom);
    });
  });

  group('Volumetrie', () {
    test('2000 entreprises actives -> toutes parsees', () async {
      final results = List.generate(
        2000,
        (i) => {
          'nom_complet': 'ENTREPRISE $i',
          'etat_administratif': 'A',
          'siege': {
            'etat_administratif': 'A',
            'latitude': '${48.0 + i * 0.0001}',
            'longitude': '1.0',
            'adresse': 'RUE $i',
            'libelle_commune': 'VILLE',
            'code_postal': '28000',
          },
        },
      );
      final r = await svc(jsonEncode({'results': results})).search('entreprise');
      expect(r, hasLength(2000));
    });
  });
}
