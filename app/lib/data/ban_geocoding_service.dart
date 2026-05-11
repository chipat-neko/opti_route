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
      // 1. Cache exact (cle = providerKey:query).
      final cached = await _cache.read('$providerKey:$q');
      if (cached != null) return cached;

      // 2. V7.5 : cache par prefixe. Si une recherche plus large
      //    contient des resultats qui matchent notre query courante,
      //    on les reutilise sans taper le reseau. Garde-fous dans
      //    `readByPrefix` : prefixe >= 4 chars + filtrage des
      //    resultats par pertinence textuelle.
      final byPrefix = await _cache.readByPrefix('$providerKey:$q');
      if (byPrefix != null) return byPrefix;
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

  /// Recherche de communes uniquement (BAN type=municipality). Sert a
  /// l'auto-correct quand la cascade standard a rien trouve : BAN fait
  /// du fuzzy matching sur les noms de communes francaises, ce qui
  /// rattrape les fautes de frappe ("Charters" -> "Chartres",
  /// "Marseile" -> "Marseille").
  ///
  /// Le score BAN tient compte de l'edit distance, on n'a pas besoin
  /// de notre propre Levenshtein.
  Future<List<AddressSuggestion>> searchMunicipalities(
    String query, {
    int limit = 3,
  }) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    final uri = Uri.https('api-adresse.data.gouv.fr', '/search/', {
      'q': q,
      'limit': '$limit',
      'type': 'municipality',
      'autocomplete': '0', // on veut le best-match, pas le prefix
    });
    final response =
        await _client.get(uri, headers: {'User-Agent': _userAgent});
    if (response.statusCode != 200) return const [];
    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) return const [];
    final features = raw['features'];
    if (features is! List) return const [];
    return features
        .whereType<Map<String, dynamic>>()
        .map(_toSuggestion)
        .whereType<AddressSuggestion>()
        .toList(growable: false);
  }

  /// Reverse geocoding : a partir d'un point GPS, retourne l'adresse
  /// la plus proche selon BAN. Utilise par le mode "tap sur la carte"
  /// qui permet a Noah de pointer un emplacement quand l'autocomplete
  /// n'a rien trouve. Retourne null si aucune adresse trouvee.
  Future<AddressSuggestion?> reverseGeocode({
    required double lat,
    required double lng,
  }) async {
    final uri = Uri.https('api-adresse.data.gouv.fr', '/reverse/', {
      'lon': lng.toString(),
      'lat': lat.toString(),
      'limit': '1',
    });
    final response =
        await _client.get(uri, headers: {'User-Agent': _userAgent});
    if (response.statusCode != 200) {
      throw GeocodingException('Reponse BAN reverse ${response.statusCode}');
    }
    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) return null;
    final features = raw['features'];
    if (features is! List || features.isEmpty) return null;
    final first = features.first as Map<String, dynamic>;
    return _toSuggestion(first);
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
      source: AddressSource.ban,
    );
  }

  @override
  void close() => _client.close();
}
