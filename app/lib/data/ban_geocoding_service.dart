import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_suggestion.dart';
import 'geocode_cache_repository.dart';
import 'geocoding_service.dart';

/// Client pour la **Base Adresse Nationale (BAN)**, source officielle
/// francaise des adresses postales.
///
/// API : https://api-adresse.data.gouv.fr/search/
/// - Maintenue par IGN + La Poste + DGFiP + contributeurs OSM
/// - ~25 millions d'adresses, mise a jour quotidienne
/// - Pas de cle API, pas de quota strict (usage raisonnable)
/// - Couverture quasi exhaustive France metropolitaine + DOM-TOM
///
/// Reponse : GeoJSON FeatureCollection.
class BanGeocodingService implements GeocodingService {
  BanGeocodingService({http.Client? client, GeocodeCacheRepository? cache})
      : _client = client ?? http.Client(),
        _cache = cache;

  static const _userAgent =
      'opti_route/0.1 (https://github.com/chipat-neko/opti_route)';

  final http.Client _client;
  final GeocodeCacheRepository? _cache;

  @override
  String get providerKey => 'ban';

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

    final uri = Uri.https('api-adresse.data.gouv.fr', '/search/', {
      'q': q,
      'limit': '$limit',
      'autocomplete': '1',
    });

    final response =
        await _client.get(uri, headers: {'User-Agent': _userAgent});

    if (response.statusCode != 200) {
      throw GeocodingException('Reponse BAN ${response.statusCode}');
    }

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw const GeocodingException('Reponse JSON inattendue (BAN)');
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

    final lon = (coords[0] as num).toDouble();
    final lat = (coords[1] as num).toDouble();

    final props =
        (feature['properties'] as Map?)?.cast<String, dynamic>() ?? {};

    final type = props['type'] as String?;
    final label = props['label'] as String?;
    final houseNumber =
        type == 'housenumber' ? props['housenumber'] as String? : null;
    final street = props['street'] as String?;
    final postcode = props['postcode'] as String?;
    final city = props['city'] as String?;

    if (label == null || label.isEmpty) return null;

    return AddressSuggestion(
      displayName: label,
      lat: lat,
      lon: lon,
      road: street,
      houseNumber: houseNumber,
      postcode: postcode,
      city: city,
      country: 'France',
    );
  }

  @override
  void close() => _client.close();
}
