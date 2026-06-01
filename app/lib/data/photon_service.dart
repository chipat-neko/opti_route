import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_suggestion.dart';
import 'geocode_cache_repository.dart';
import 'geocoding_service.dart';

/// Client pour l'API Photon (https://photon.komoot.io/).
///
/// Photon est un geocoder open-source maintenu par Komoot, base sur
/// OpenStreetMap. **On l'utilise specifiquement pour les enseignes /
/// marques commerciales** (Citroen, Carrefour, McDonald's, etc.) : OSM
/// les indexe via les tags `brand=...` et `name=...` ce que SIRENE ne
/// fait pas (SIRENE n'a que le nom legal des entreprises, pas les
/// enseignes).
///
/// Pas de cle API requise pour usage modere. Reponse au format
/// GeoJSON FeatureCollection.
class PhotonService implements GeocodingService {
  PhotonService({http.Client? client, GeocodeCacheRepository? cache})
      : _client = client ?? http.Client(),
        _cache = cache;

  static const _userAgent =
      'opti_route/0.1 (https://github.com/chipat-neko/opti_route)';

  final http.Client _client;
  final GeocodeCacheRepository? _cache;

  @override
  String get providerKey => 'photon';

  /// Categories OSM qui correspondent a des POIs (commerces,
  /// entreprises, services). Quand `osm_key` tombe la-dedans, on
  /// considere `name` comme le nom du POI / de l'enseigne.
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

    final uri = Uri.parse('https://photon.komoot.io/api').replace(
      queryParameters: {
        'q': q,
        'limit': '$limit',
        'lang': acceptLanguage,
      },
    );

    final response = await _client
        .get(uri, headers: {'User-Agent': _userAgent})
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw const GeocodingException('Photon timeout'),
        );

    if (response.statusCode != 200) {
      throw GeocodingException('Reponse Photon ${response.statusCode}');
    }

    // UTF-8 explicite (cf ban_geocoding_service) : évite le mojibake des
    // accents si le header charset manque.
    final raw = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
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

    if (_cache != null && results.isNotEmpty) {
      try {
        await _cache.write('$providerKey:$q', results);
      } catch (_) {
        // best-effort
      }
    }

    return results;
  }

  AddressSuggestion? _toSuggestion(Map<String, dynamic> feature) {
    final geometry = feature['geometry'];
    if (geometry is! Map) return null;
    final coords = geometry['coordinates'];
    if (coords is! List || coords.length < 2) return null;

    // Photon retourne parfois des coords null/strings pour des POIs mal
    // indexes : conversion TOLERANTE (num ou String) plutot que `as num?`
    // qui crashe sur une String. Cf audit secu nuit 2026-06-01.
    final lon = _coordToDouble(coords[0]);
    final lat = _coordToDouble(coords[1]);
    if (lon == null || lat == null) return null;

    // `as Map?` crashe si properties est une List : on teste avec `is`.
    final rawProps = feature['properties'];
    final props = rawProps is Map
        ? rawProps.cast<String, dynamic>()
        : <String, dynamic>{};

    final houseNumber = _asString(props['housenumber']);
    final street = _asString(props['street']);
    final postcode = _asString(props['postcode']);
    final city = _asString(props['city']) ??
        _asString(props['town']) ??
        _asString(props['village']) ??
        _asString(props['locality']);
    final country = _asString(props['country']);

    final osmKey = _asString(props['osm_key']);
    final name = _asString(props['name']);
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

  /// Conversion coordonnée tolérante (num ou String) -> double, sinon null.
  /// Évite le crash `as num?` sur une String. Cf audit sécu nuit 2026-06-01.
  static double? _coordToDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  /// Lecture tolérante d'un champ texte : renvoie la String si c'en est
  /// une, sinon null (au lieu de `as String?` qui crashe sur un nombre).
  static String? _asString(Object? v) => v is String ? v : null;

  @override
  void close() => _client.close();
}
