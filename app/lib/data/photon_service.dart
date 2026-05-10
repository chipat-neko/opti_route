import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_suggestion.dart';
import 'geocode_cache_repository.dart';
import 'geocoding_service.dart';

/// Client pour l'API Photon (https://photon.komoot.io/).
///
/// Photon est un geocoder open-source maintenu par Komoot, base sur
/// OpenStreetMap mais avec un index et un ranker dedies (Elasticsearch)
/// qui retourne souvent l'adresse exacte la ou Nominatim renvoie la rue
/// seule. Pas de cle API requise pour usage modere.
///
/// Reponse au format GeoJSON FeatureCollection.
class PhotonService implements GeocodingService {
  PhotonService({http.Client? client, GeocodeCacheRepository? cache})
      : _client = client ?? http.Client(),
        _cache = cache;

  static const _base = 'https://photon.komoot.io';
  static const _userAgent =
      'opti_route/0.1 (https://github.com/chipat-neko/opti_route)';

  final http.Client _client;
  final GeocodeCacheRepository? _cache;

  @override
  String get providerKey => 'photon';

  @override
  Future<List<AddressSuggestion>> search(
    String query, {
    int limit = 10,
    String acceptLanguage = 'fr',
  }) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    if (_cache != null) {
      final cached = await _cache.read('$providerKey:$q');
      if (cached != null) return cached;
    }

    final uri = Uri.parse('$_base/api').replace(queryParameters: {
      'q': q,
      'limit': '$limit',
      'lang': acceptLanguage,
    });

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) {
      throw GeocodingException('Reponse Photon ${response.statusCode}');
    }

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw const GeocodingException('Reponse JSON inattendue (Photon)');
    }
    final features = raw['features'];
    if (features is! List) return const [];

    final results = features
        .whereType<Map<String, dynamic>>()
        .map(_toSuggestion)
        .whereType<AddressSuggestion>()
        .toList(growable: false);

    final ranked = _rankByPrecision(results);

    if (_cache != null) {
      try {
        await _cache.write('$providerKey:$q', ranked);
      } catch (_) {
        // best-effort
      }
    }

    return ranked;
  }

  /// Categories OSM qui correspondent a des POIs (commerces,
  /// entreprises, services). Quand `osm_key` tombe la-dedans, on
  /// considere `name` comme le nom du POI.
  static const _poiOsmKeys = {
    'amenity',
    'shop',
    'office',
    'tourism',
    'leisure',
    'craft',
    'healthcare',
    'building',
    'industrial',
  };

  AddressSuggestion? _toSuggestion(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    if (geometry is! Map) return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    final props = (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

    final houseNumber = props['housenumber'] as String?;
    final street = props['street'] as String?;
    final postcode = props['postcode'] as String?;
    final city = props['city'] as String? ??
        props['town'] as String? ??
        props['village'] as String? ??
        props['locality'] as String?;
    final country = props['country'] as String?;

    final osmKey = props['osm_key'] as String?;
    final name = props['name'] as String?;
    final isPoi =
        osmKey != null && _poiOsmKeys.contains(osmKey) && name != null;

    final displayName = _buildDisplayName(
      houseNumber: houseNumber,
      street: street ?? (isPoi ? null : name),
      postcode: postcode,
      city: city,
      country: country,
      fallbackName: name,
    );
    if (displayName.isEmpty && !isPoi) return null;

    return AddressSuggestion(
      displayName: displayName,
      lat: lat,
      lon: lon,
      road: street,
      houseNumber: houseNumber,
      postcode: postcode,
      city: city,
      country: country,
      poiName: isPoi ? name : null,
    );
  }

  String _buildDisplayName({
    String? houseNumber,
    String? street,
    String? postcode,
    String? city,
    String? country,
    String? fallbackName,
  }) {
    final parts = <String>[];
    if (street != null && street.isNotEmpty) {
      parts.add(houseNumber != null && houseNumber.isNotEmpty
          ? '$houseNumber $street'
          : street);
    } else if (fallbackName != null && fallbackName.isNotEmpty) {
      parts.add(fallbackName);
    }
    final localityBits = <String>[
      if (postcode != null && postcode.isNotEmpty) postcode,
      if (city != null && city.isNotEmpty) city,
    ];
    if (localityBits.isNotEmpty) parts.add(localityBits.join(' '));
    if (country != null && country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  /// Photon trie deja correctement, mais on s'assure que les adresses
  /// avec house_number passent devant les rues sans numero.
  List<AddressSuggestion> _rankByPrecision(List<AddressSuggestion> all) {
    int score(AddressSuggestion s) =>
        (s.houseNumber != null && s.houseNumber!.isNotEmpty) ? 0 : 1;
    return all.toList()..sort((a, b) => score(a).compareTo(score(b)));
  }

  @override
  void close() => _client.close();
}
