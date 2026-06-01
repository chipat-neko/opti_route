import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:opti_route/data/ban_geocoding_service.dart';
import 'package:opti_route/data/geocoding_service.dart';
import 'package:opti_route/data/photon_service.dart';

/// Tests SECURITE / ROBUSTESSE des parseurs de reponses geocodage.
///
/// [BanGeocodingService] et [PhotonService] desserialisent du JSON venu
/// d'APIs TIERCES sur le reseau (api-adresse.data.gouv.fr, photon.komoot.io).
/// C'est une frontiere de confiance : un serveur compromis, un MITM, ou
/// simplement une API qui change de schema peut renvoyer n'importe quoi.
/// Le parseur ne DOIT JAMAIS planter l'app : soit il filtre l'entree
/// malformee, soit il leve une [GeocodingException] propre.
///
/// Ces tests complementent ban_geocoding_service_test.dart et
/// photon_service_test.dart (qui couvrent le happy-path) en se concentrant
/// sur l'hostile : types incoherents, JSON tronque, NaN/Infinity, unicode,
/// injections, debordements, profondeur, valeurs negatives.
void main() {
  // ---- Helpers ----------------------------------------------------------

  // http.Response(String,...) encode le body en Latin-1 par defaut, ce
  // qui plante sur les emojis/unicode hors Latin-1. Le vrai client http
  // recoit des BYTES et le service les decode via jsonDecode(response.body)
  // qui suppose de l'UTF-8. On reproduit fidelement en passant des bytes.
  MockClient ok(String body) => MockClient(
        (req) async => http.Response.bytes(utf8.encode(body), 200),
      );

  BanGeocodingService ban(String body) => BanGeocodingService(client: ok(body));
  PhotonService photon(String body) => PhotonService(client: ok(body));

  /// Body Photon minimal autour d'un unique feature.
  String photonFeature(Map<String, dynamic> feature) =>
      jsonEncode({'features': [feature]});

  String banFeature(Map<String, dynamic> feature) =>
      jsonEncode({'features': [feature]});

  group('JSON top-level hostile', () {
    test('BAN: body = "null" -> JSON inattendu -> GeocodingException', () {
      // jsonDecode("null") == null ; raw is! Map -> throw propre attendu.
      expect(
        ban('null').search('rue test'),
        throwsA(isA<GeocodingException>()),
      );
    });

    test('BAN: body = tableau JSON au lieu d\'objet -> GeocodingException', () {
      expect(
        ban('[1,2,3]').search('rue test'),
        throwsA(isA<GeocodingException>()),
      );
    });

    test('Photon: body = nombre brut -> GeocodingException', () {
      expect(
        photon('42').search('rue test'),
        throwsA(isA<GeocodingException>()),
      );
    });

    test('BAN: body = JSON tronque/invalide -> leve une erreur (jsonDecode)',
        () {
      // {"features": [   -> FormatException de jsonDecode. Documente le
      // comportement actuel : l'erreur N'EST PAS encapsulee en
      // GeocodingException (jsonDecode jette avant les checks de type).
      expect(
        ban('{"features": [').search('rue test'),
        throwsA(isA<FormatException>()),
      );
    });

    test('BAN: body vide "" -> erreur jsonDecode', () {
      expect(
        ban('').search('rue test'),
        throwsA(anything),
      );
    });

    test('Photon: features = objet (pas une liste) -> liste vide', () async {
      final r = await photon('{"features": {"k": "v"}}').search('rue test');
      expect(r, isEmpty);
    });

    test('BAN: features = string -> liste vide (pas de crash)', () async {
      final r = await ban('{"features": "boom"}').search('rue test');
      expect(r, isEmpty);
    });

    test('Photon: features = null explicite -> liste vide', () async {
      final r = await photon('{"features": null}').search('rue test');
      expect(r, isEmpty);
    });
  });

  group('Features avec elements non-Map (poison list)', () {
    test('BAN: liste melangeant string/null/nombre + 1 feature valide '
        '-> seul le valide survit', () async {
      final body = jsonEncode({
        'features': [
          'string parasite',
          null,
          12345,
          ['nested', 'list'],
          {
            'geometry': {
              'type': 'Point',
              'coordinates': [1.0, 48.0],
            },
            'properties': {'label': 'rue valide', 'street': 'rue valide'},
          },
        ],
      });
      final r = await ban(body).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.displayName, 'rue valide');
    });

    test('Photon: 100% d\'elements parasites -> liste vide', () async {
      final body = jsonEncode({
        'features': ['a', 1, null, true, [], {}],
      });
      final r = await photon(body).search('rue test');
      expect(r, isEmpty);
    });
  });

  group('Geometry / coordinates malformees', () {
    test('Photon: geometry absente -> feature filtre', () async {
      final r = await photon(photonFeature({
        'properties': {'name': 'X', 'street': 'rue X'},
      })).search('rue test');
      expect(r, isEmpty);
    });

    test('Photon: geometry = liste au lieu de Map -> filtre', () async {
      final r = await photon(photonFeature({
        'geometry': [1, 2],
        'properties': {'name': 'X'},
      })).search('rue test');
      expect(r, isEmpty);
    });

    test('BAN: coordinates = 1 seul element -> filtre', () async {
      final r = await ban(banFeature({
        'geometry': {'coordinates': [1.0]},
        'properties': {'label': 'X', 'street': 'X'},
      })).search('rue test');
      expect(r, isEmpty);
    });

    test('BAN: coordinates = [] vide -> filtre', () async {
      final r = await ban(banFeature({
        'geometry': {'coordinates': []},
        'properties': {'label': 'X', 'street': 'X'},
      })).search('rue test');
      expect(r, isEmpty);
    });

    test('Photon: coordinates = [null, null] -> filtre (lon/lat null)',
        () async {
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [null, null]
        },
        'properties': {'name': 'X', 'street': 'rue X'},
      })).search('rue test');
      expect(r, isEmpty);
    });

    test('Photon: coordinates avec elements en trop [lon,lat,alt] '
        '-> garde lon/lat, ignore le reste', () async {
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [1.5, 48.5, 120.0]
        },
        'properties': {'name': 'X', 'street': 'rue X'},
      })).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.lon, 1.5);
      expect(r.first.lat, 48.5);
    });

    test('BAN: coordinates string "1.0" -> parsees (fix defensif nuit)',
        () async {
      // Fix nuit 2026-06-01 : _coordToDouble accepte desormais une String
      // parsable ("1.0") au lieu de crasher (`as num?` jetait un TypeError).
      // Le commentaire du code promettait du defensif : c'est maintenant vrai.
      final body = banFeature({
        'geometry': {
          'coordinates': ['1.0', '48.0']
        },
        'properties': {'label': 'X', 'street': 'X'},
      });
      final r = await ban(body).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.lon, 1.0);
      expect(r.first.lat, 48.0);
    });

    test('Photon: coordinates int (pas double) -> converti via toDouble',
        () async {
      // jsonDecode rend des int pour "1" ; (x as num?).toDouble() OK.
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [1, 48]
        },
        'properties': {'name': 'X', 'street': 'rue X'},
      })).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.lat, 48.0);
      expect(r.first.lon, 1.0);
    });
  });

  group('Valeurs numeriques extremes / aberrantes', () {
    test('Photon: coords hors plage [lon=999, lat=-999] -> ACCEPTEES '
        '(pas de validation de bornes) - documente', () async {
      // Le parseur ne valide PAS que lat in [-90,90] / lon in [-180,180].
      // Une coord aberrante est donc stockee telle quelle. Limitation
      // connue (cf rapport) : un point a (-999, 999) pourrait corrompre
      // l'optimisation de tournee. Test documente le comportement actuel.
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [999.0, -999.0]
        },
        'properties': {'name': 'X', 'street': 'rue X'},
      })).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.lon, 999.0);
      expect(r.first.lat, -999.0);
    });

    test('BAN: coords negatives plausibles (Atlantique) -> acceptees',
        () async {
      final r = await ban(banFeature({
        'geometry': {
          'coordinates': [-4.5, 48.39]
        },
        'properties': {'label': 'Brest', 'street': 'rue de Brest'},
      })).search('brest');
      expect(r.first.lon, -4.5);
      expect(r.first.lat, 48.39);
    });

    test('Photon: coords entieres tres grandes -> toDouble sans overflow',
        () async {
      final big = 9007199254740992; // 2^53
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [big, big]
        },
        'properties': {'name': 'X', 'street': 'rue X'},
      })).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.lon, big.toDouble());
    });
  });

  group('Proprietes hostiles', () {
    test('Photon: properties absente -> {} par defaut, feature peut survivre '
        'si coords ok mais displayName vide + pas POI -> filtre', () async {
      // props ?? {} ; name/street null ; displayName vide ; isPoi false
      // -> _toSuggestion retourne null.
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
      })).search('rue test');
      expect(r, isEmpty);
    });

    test('BAN: properties = liste -> traite comme vide (fix defensif nuit)',
        () async {
      // Fix nuit 2026-06-01 : on teste `is Map` avant de caster -> un
      // properties non-Map est traite comme vide (props = {}), donc label
      // absent -> resultat filtre (pas de crash). AVANT, `as Map?` jetait.
      final body2 = banFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
        'properties': ['not', 'a', 'map'],
      });
      // label absent (props vide) -> _toSuggestion renvoie null -> liste vide.
      expect(await ban(body2).search('rue test'), isEmpty);
    });

    test('Photon: champ name de type int -> ignore proprement (fix nuit)',
        () async {
      // Fix nuit 2026-06-01 : _asString filtre par type -> un name numerique
      // est traite comme absent (name=null) au lieu de crasher (`as String?`).
      // Le POI n'est pas reconnu (name requis) mais aucun TypeError.
      final body = photonFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
        'properties': {'osm_key': 'shop', 'name': 12345},
      });
      expect(
        photon(body).search('rue test'),
        completes,
      );
    });

    test('BAN: label = chaine vide -> filtre (label.isEmpty)', () async {
      final r = await ban(banFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
        'properties': {'label': '', 'street': 'rue X'},
      })).search('rue test');
      expect(r, isEmpty);
    });
  });

  group('Injection / unicode / chaines pathologiques (pass-through)', () {
    test('BAN: label avec script HTML/JS conserve tel quel (pas de strip) '
        '- responsabilite de l\'UI d\'echapper', () async {
      const evil = '<script>alert(1)</script> 28000 Dreux';
      final r = await ban(banFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
        'properties': {'label': evil, 'street': 'rue X'},
      })).search('rue test');
      expect(r, hasLength(1));
      // Le parseur ne sanitize pas : la chaine ressort intacte.
      expect(r.first.displayName, evil);
    });

    test('Photon: name non-ASCII (accent + emoji) -> UTF-8 PRESERVE '
        '(fix nuit 2026-06-01)', () async {
      // Le service décode désormais `utf8.decode(response.bodyBytes)` au
      // lieu de `response.body` (Latin-1 par défaut faute de charset). Les
      // APIs gov.fr / Komoot renvoient de l'UTF-8 : accents + emoji doivent
      // ressortir INTACTS (plus de mojibake « CafÃ© »).
      const tricky = 'Caf\u{00E9} \u{1F600} Pharmacie';
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
        'properties': {'osm_key': 'amenity', 'name': tricky},
      })).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.isPoi, isTrue);
      expect(r.first.poiName, equals(tricky),
          reason: 'accents + emoji UTF-8 préservés après le fix');
    });

    test('Photon: name 100% ASCII (injection HTML) -> preserve intact '
        '(pas affecte par le bug d\'encodage)', () async {
      const evil = '<img src=x onerror=alert(1)> Garage';
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
        'properties': {'osm_key': 'shop', 'name': evil},
      })).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.poiName, evil);
    });

    test('BAN: street tres longue (100k chars) -> ne plante pas, ressort',
        () async {
      final huge = 'A' * 100000;
      final r = await ban(banFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
        'properties': {'label': huge, 'street': huge},
      })).search('rue test');
      expect(r, hasLength(1));
      expect(r.first.road!.length, 100000);
    });

    test('Photon: city via fallback locality quand town/village absents',
        () async {
      final r = await photon(photonFeature({
        'geometry': {
          'coordinates': [1.0, 48.0]
        },
        'properties': {
          'osm_key': 'place',
          'name': 'X',
          'street': 'rue X',
          'locality': 'Hameau Perdu',
        },
      })).search('rue test');
      expect(r.first.city, 'Hameau Perdu');
    });
  });

  group('Volumetrie (limit + grosses listes)', () {
    test('Photon: 5000 features valides -> toutes parsees sans timeout '
        'cote parsing', () async {
      final features = List.generate(
        5000,
        (i) => {
          'geometry': {
            'coordinates': [1.0 + i * 0.0001, 48.0]
          },
          'properties': {'name': 'lieu $i', 'street': 'rue $i'},
        },
      );
      final r = await photon(jsonEncode({'features': features}))
          .search('rue test');
      expect(r, hasLength(5000));
    });

    test('BAN: limit passe dans l\'URL mais le parseur ne tronque PAS '
        'cote client (documente)', () async {
      // Le service ne re-applique pas `limit` apres parsing : si l\'API
      // renvoie plus que demande, tout est conserve. Documente.
      final features = List.generate(
        20,
        (i) => {
          'geometry': {
            'coordinates': [1.0 + i, 48.0]
          },
          'properties': {'label': 'rue $i', 'street': 'rue $i'},
        },
      );
      final r =
          await ban(jsonEncode({'features': features})).search('rue', );
      expect(r.length, 20); // > limit par defaut (10) mais non tronque
    });
  });

  group('reverseGeocode (BAN) - robustesse', () {
    test('reverse: raw non-Map -> retourne null (pas de throw)', () async {
      final svc = BanGeocodingService(client: ok('[1,2]'));
      final r = await svc.reverseGeocode(lat: 48.0, lng: 1.0);
      expect(r, isNull);
    });

    test('reverse: features[0] non-Map -> null', () async {
      final body = jsonEncode({
        'features': ['parasite']
      });
      final svc = BanGeocodingService(client: ok(body));
      final r = await svc.reverseGeocode(lat: 48.0, lng: 1.0);
      expect(r, isNull);
    });

    test('reverse: lat/lng extremes acceptes dans l\'URL sans crash', () async {
      final body = jsonEncode({'features': []});
      final svc = BanGeocodingService(client: ok(body));
      final r = await svc.reverseGeocode(lat: -90.0, lng: 180.0);
      expect(r, isNull);
    });
  });

  group('Query d\'entree hostile (avant reseau)', () {
    test('Photon: query whitespace seul -> trim < 3 -> pas d\'appel reseau',
        () async {
      var called = false;
      final svc = PhotonService(client: MockClient((req) async {
        called = true;
        return http.Response('{}', 200);
      }));
      final r = await svc.search('   ');
      expect(r, isEmpty);
      expect(called, isFalse);
    });

    test('BAN: query unicode 2 graphemes (emoji) -> length>=3 en code units '
        '-> appelle le reseau (documente)', () async {
      // Un seul emoji = 2 code units UTF-16. "ab" + emoji peut depasser 3.
      // Ici on verifie qu\'un emoji unique (surrogate pair = length 2)
      // NE declenche PAS l\'appel (length 2 < 3).
      var called = false;
      final svc = BanGeocodingService(client: MockClient((req) async {
        called = true;
        return http.Response(jsonEncode({'features': []}), 200);
      }));
      final r = await svc.search('😀'); // 1 emoji = length 2
      expect(r, isEmpty);
      expect(called, isFalse);
    });
  });
}
