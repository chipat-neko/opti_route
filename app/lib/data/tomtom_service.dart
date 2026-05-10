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

  static const _base = 'https://api.tomtom.com';

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

    // Le path utilise la query encodee. On laisse Dart faire l'encoding via Uri().
    final uri = Uri.parse(
      '$_base/search/2/geocode/${Uri.encodeComponent(q)}.json',
    ).replace(queryParameters: {
      'key': apiKey,
      'limit': '$limit',
      'countrySet': countrySet,
      'language': language,
      'typeahead': 'true',
    });

    final response = await _client.get(uri);

    if (response.statusCode == 403) {
      throw const GeocodingException(
        'Cle API TomTom invalide ou quota atteint',
      );
    }
    if (response.statusCode != 200) {
      throw GeocodingException('Reponse TomTom ${response.statusCode}');
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

    final displayName = freeform ??
        _build(
          houseNumber: houseNumber,
          street: street,
          postcode: postcode,
          city: city,
          country: country,
        );
    if (displayName.isEmpty) return null;

    return AddressSuggestion(
      displayName: displayName,
      lat: lat,
      lon: lon,
      road: street,
      houseNumber: houseNumber,
      postcode: postcode,
      city: city,
      country: country,
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

  @override
  void close() => _client.close();
}
