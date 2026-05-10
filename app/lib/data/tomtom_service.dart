import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_suggestion.dart';
import 'geocode_cache_repository.dart';
import 'geocoding_service.dart';

/// Client pour TomTom Search API (Geocoding endpoint).
///
/// https://developer.tomtom.com/search-api/documentation/geocoding-service/
///
/// Plan free TomTom : 2 500 requetes/jour, sans carte de credit. La cle
/// API est passee en query string (`?key=...`). Pour la securite, elle
/// n'est jamais en dur dans le code : elle est saisie par l'utilisateur
/// dans l'ecran Parametres et stockee dans la table `parametres` locale.
///
/// Qualite : reference pour la livraison/logistique. Connait les
/// numeros de rue precis, les commerces, et tolere les fautes.
class TomTomService implements GeocodingService {
  TomTomService({
    required this.apiKey,
    http.Client? client,
    GeocodeCacheRepository? cache,
    this.countrySet = 'FR',
    this.language = 'fr-FR',
  })  : _client = client ?? http.Client(),
        _cache = cache;

  final String apiKey;
  final String countrySet;
  final String language;

  final http.Client _client;
  final GeocodeCacheRepository? _cache;

  @override
  String get providerKey => 'tomtom';

  @override
  Future<List<AddressSuggestion>> search(
    String query, {
    int limit = 10,
    String acceptLanguage = 'fr-FR',
  }) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    if (_cache != null) {
      final cached = await _cache.read('$providerKey:$q');
      if (cached != null) return cached;
    }

    // Endpoint /search/2/search/{q}.json (Fuzzy Search) : retourne
    // adresses ET POIs (commerces, entreprises, sites). Plus large que
    // /search/2/geocode qui ne fait que des adresses.
    // Uri.https encode chaque segment proprement.
    final uri = Uri.https('api.tomtom.com', '/search/2/search/$q.json', {
      'key': apiKey,
      'limit': '$limit',
      'countrySet': countrySet,
      'language': language,
      'typeahead': 'true',
    });

    final response = await _client.get(uri);

    if (response.statusCode == 401) {
      throw GeocodingException(
        'Cle TomTom non autorisee pour Search API (401). '
        'Va sur developer.tomtom.com/user/me/apps, ouvre ton app, '
        'et verifie que le produit "Search" est bien dans la liste. '
        'URL essayee : ${_safeUrl(uri)}',
      );
    }
    if (response.statusCode == 403) {
      throw const GeocodingException(
        'Cle TomTom valide mais quota du jour atteint (2500 requetes). '
        'Reessaie demain ou bascule sur Photon dans les Parametres.',
      );
    }
    if (response.statusCode == 429) {
      throw const GeocodingException(
        'Trop de requetes TomTom en peu de temps. Patiente quelques '
        'secondes avant de retaper.',
      );
    }
    if (response.statusCode != 200) {
      throw GeocodingException(
        'Reponse TomTom ${response.statusCode}. URL : ${_safeUrl(uri)}',
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw const GeocodingException('Reponse JSON inattendue (TomTom)');
    }
    final results = raw['results'];
    if (results is! List) return const [];

    final suggestions = results
        .whereType<Map<String, dynamic>>()
        .map(_toSuggestion)
        .whereType<AddressSuggestion>()
        .toList(growable: false);

    if (_cache != null) {
      try {
        await _cache.write('$providerKey:$q', suggestions);
      } catch (_) {
        // best-effort
      }
    }

    return suggestions;
  }

  AddressSuggestion? _toSuggestion(Map<String, dynamic> result) {
    final position = result['position'];
    if (position is! Map) return null;
    final lat = (position['lat'] as num?)?.toDouble();
    final lon = (position['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) return null;

    final address = (result['address'] as Map?)?.cast<String, dynamic>() ?? {};

    final freeform = address['freeformAddress'] as String?;
    final street = address['streetName'] as String?;
    final houseNumber = address['streetNumber'] as String?;
    final postcode = address['postalCode'] as String?;
    final city = address['municipality'] as String?;
    final country = address['country'] as String?;

    // POI : si le resultat est de type "POI", on extrait le nom de
    // l'entreprise / commerce.
    String? poiName;
    final type = result['type'] as String?;
    if (type == 'POI') {
      final poi = (result['poi'] as Map?)?.cast<String, dynamic>();
      poiName = poi?['name'] as String?;
    }

    final displayName = freeform ??
        _build(
          houseNumber: houseNumber,
          street: street,
          postcode: postcode,
          city: city,
          country: country,
        );
    if (displayName.isEmpty && poiName == null) return null;

    return AddressSuggestion(
      displayName: displayName,
      lat: lat,
      lon: lon,
      road: street,
      houseNumber: houseNumber,
      postcode: postcode,
      city: city,
      country: country,
      poiName: poiName,
    );
  }

  String _build({
    String? houseNumber,
    String? street,
    String? postcode,
    String? city,
    String? country,
  }) {
    final parts = <String>[];
    if (street != null && street.isNotEmpty) {
      parts.add(houseNumber != null && houseNumber.isNotEmpty
          ? '$houseNumber $street'
          : street);
    }
    final localityBits = <String>[
      if (postcode != null && postcode.isNotEmpty) postcode,
      if (city != null && city.isNotEmpty) city,
    ];
    if (localityBits.isNotEmpty) parts.add(localityBits.join(' '));
    if (country != null && country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  /// Retourne l'URL avec la cle masquee, sans risque d'apparaitre
  /// telle quelle dans un message d'erreur visible a l'utilisateur.
  String _safeUrl(Uri uri) {
    final params = Map<String, String>.from(uri.queryParameters);
    if (params.containsKey('key')) {
      params['key'] = '***';
    }
    return uri.replace(queryParameters: params).toString();
  }

  @override
  void close() => _client.close();
}
