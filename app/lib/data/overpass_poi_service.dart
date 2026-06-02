import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_suggestion.dart';
import 'geo_utils.dart';

/// ════════════════════════════════════════════════════════════════
/// Recherche de commerces / POI proches via OSM Overpass API.
/// ════════════════════════════════════════════════════════════════
///
/// Inspire de Spoke route planner : "Find addresses fast". Permet a
/// Noah de chercher des **categories** ("pharmacie", "boulangerie",
/// "supermarche") plutot que des noms precis, et de voir tout ce qui
/// est autour de sa position GPS.
///
/// Use cases livreur :
/// - 'Mon client veut un drive en passant -> supermarches autour'
/// - 'J'ai oublie mon medicament -> pharmacies sur la route'
/// - 'Pause cafe -> brasseries dans 500 m'
///
/// API : Overpass (https://overpass-api.de) public, gratuit, sans cle.
/// Quota theorique : 10000 req/jour mais en pratique abuse ne plait
/// pas. Pour notre usage (1-5 req par tournee), on est tres en dessous.
///
/// Retourne des [AddressSuggestion] reutilisables avec le carnet et
/// le geocoder existant. Le `poiName` contient le nom du commerce.
class OverpassPoiService {
  OverpassPoiService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const _endpoint = 'https://overpass-api.de/api/interpreter';

  /// Catalogue des categories proposees a Noah. Chaque entree map un
  /// label FR vers un selecteur Overpass (`amenity=pharmacy`,
  /// `shop=bakery`, etc.). Visible publiquement pour que l'UI puisse
  /// afficher les chips.
  static const Map<String, PoiCategory> categories = {
    'pharmacie': PoiCategory(
      label: 'Pharmacie',
      iconName: 'local_pharmacy',
      tagFilter: '"amenity"="pharmacy"',
    ),
    'boulangerie': PoiCategory(
      label: 'Boulangerie',
      iconName: 'bakery_dining',
      tagFilter: '"shop"="bakery"',
    ),
    'supermarche': PoiCategory(
      label: 'Supermarche',
      iconName: 'shopping_cart',
      tagFilter: '"shop"="supermarket"',
    ),
    'restaurant': PoiCategory(
      label: 'Restaurant',
      iconName: 'restaurant',
      tagFilter: '"amenity"="restaurant"',
    ),
    'cafe': PoiCategory(
      label: 'Cafe / Bar',
      iconName: 'local_cafe',
      tagFilter: '"amenity"~"cafe|bar"',
    ),
    'station_service': PoiCategory(
      label: 'Station-service',
      iconName: 'local_gas_station',
      tagFilter: '"amenity"="fuel"',
    ),
    'atm': PoiCategory(
      label: 'Distributeur',
      iconName: 'atm',
      tagFilter: '"amenity"~"atm|bank"',
    ),
    'poste': PoiCategory(
      label: 'La Poste',
      iconName: 'local_post_office',
      tagFilter: '"amenity"="post_office"',
    ),
    'parking': PoiCategory(
      label: 'Parking',
      iconName: 'local_parking',
      tagFilter: '"amenity"="parking"',
    ),
    'toilettes': PoiCategory(
      label: 'Toilettes',
      iconName: 'wc',
      tagFilter: '"amenity"="toilets"',
    ),
  };

  /// Cherche les POI d'une [categoryKey] (cle de [categories]) autour
  /// d'un point GPS. Trie par distance croissante. Limit raisonnable
  /// pour ne pas blast Overpass + UI sympa.
  ///
  /// Throws [OverpassException] si timeout / 5xx / parse fail.
  Future<List<AddressSuggestion>> searchNearby({
    required String categoryKey,
    required double centerLat,
    required double centerLng,
    int radiusMeters = 1500,
    int limit = 20,
  }) async {
    final cat = categories[categoryKey];
    if (cat == null) {
      throw OverpassException('Categorie inconnue : $categoryKey');
    }

    // Query Overpass QL : on cherche les nodes ET les ways
    // (certains POI comme les supermarches sont des polygones way).
    // `out center` retourne le centroid des ways, pratique pour
    // l'affichage / le routing.
    final query = '''
[out:json][timeout:15];
(
  node[${cat.tagFilter}](around:$radiusMeters,$centerLat,$centerLng);
  way[${cat.tagFilter}](around:$radiusMeters,$centerLat,$centerLng);
);
out tags center $limit;
''';

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Accept': 'application/json',
            },
            body: 'data=${Uri.encodeComponent(query)}',
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        throw OverpassException(
          'Overpass ${response.statusCode} : '
          '${_truncate(response.body, 150)}',
        );
      }

      // UTF-8 explicite (cf geocodeurs) : evite le mojibake des noms de
      // commerces accentues ("Boulangerie Patisserie...") si le header
      // charset venait a manquer. utf8.decode(bodyBytes) est toujours >=
      // response.body (latin1 par defaut).
      final raw = jsonDecode(utf8.decode(response.bodyBytes, allowMalformed: true));
      if (raw is! Map<String, dynamic>) {
        throw const OverpassException('Reponse Overpass invalide');
      }
      final elements = raw['elements'];
      if (elements is! List) {
        throw const OverpassException('Pas d\'elements dans la reponse');
      }

      final suggestions = <AddressSuggestion>[];
      for (final el in elements) {
        if (el is! Map<String, dynamic>) continue;
        final lat = _extractLat(el);
        final lng = _extractLng(el);
        if (lat == null || lng == null) continue;
        // Lecture tolerante : `as Map?` / `as String?` crashent si le
        // schema OSM est inattendu (tags=List, name numerique). On filtre
        // par type -> la valeur invalide est traitee comme absente.
        final rawTags = el['tags'];
        final tags = rawTags is Map ? rawTags : const {};
        final name = tags['name'] is String ? tags['name'] as String : null;
        if (name == null || name.isEmpty) continue;
        String? tag(String k) => tags[k] is String ? tags[k] as String : null;
        final houseNumber = tag('addr:housenumber');
        final street = tag('addr:street');
        final postcode = tag('addr:postcode');
        final city = tag('addr:city');
        // Concatene l'adresse postale si dispo
        final addrParts = <String>[
          ?houseNumber,
          ?street,
        ];
        final firstLine = addrParts.join(' ');
        final secondLine = [
          ?postcode,
          ?city,
        ].join(' ');
        final display = [
          name,
          if (firstLine.isNotEmpty) firstLine,
          if (secondLine.isNotEmpty) secondLine,
        ].join(', ');

        final dist = GeoUtils.haversineMeters(
          lat1: centerLat,
          lon1: centerLng,
          lat2: lat,
          lon2: lng,
        );

        suggestions.add(_OverpassSuggestion(
          displayName: display,
          lat: lat,
          lon: lng,
          poiName: name,
          road: street,
          houseNumber: houseNumber,
          postcode: postcode,
          city: city,
          distanceMeters: dist,
        ));
      }

      // Tri par distance croissante (le plus proche en haut).
      suggestions.sort((a, b) {
        final da = (a is _OverpassSuggestion) ? a.distanceMeters : 0;
        final db = (b is _OverpassSuggestion) ? b.distanceMeters : 0;
        return da.compareTo(db);
      });

      return suggestions.take(limit).toList();
    } on OverpassException {
      rethrow;
    } catch (e) {
      throw OverpassException('Erreur reseau Overpass : $e');
    }
  }

  double? _extractLat(Map<String, dynamic> el) {
    // Nodes : lat direct. Ways : center.lat (`out center` flag).
    final lat = el['lat'];
    if (lat is num) return lat.toDouble();
    final center = el['center'];
    if (center is Map<String, dynamic>) {
      final c = center['lat'];
      if (c is num) return c.toDouble();
    }
    return null;
  }

  double? _extractLng(Map<String, dynamic> el) {
    final lng = el['lon'];
    if (lng is num) return lng.toDouble();
    final center = el['center'];
    if (center is Map<String, dynamic>) {
      final c = center['lon'];
      if (c is num) return c.toDouble();
    }
    return null;
  }

  String _truncate(String s, int n) =>
      s.length <= n ? s : '${s.substring(0, n)}...';

  void close() => _client.close();
}

/// Categorie de POI (label FR + selecteur Overpass + nom d'icone
/// Material). Le nom d'icone est resolu cote UI car l'icone est un
/// concept Flutter Material qu'on ne veut pas importer ici.
class PoiCategory {
  const PoiCategory({
    required this.label,
    required this.iconName,
    required this.tagFilter,
  });

  final String label;
  final String iconName;
  final String tagFilter;
}

class OverpassException implements Exception {
  const OverpassException(this.message);
  final String message;

  @override
  String toString() => 'OverpassException: $message';
}

/// Extension d'AddressSuggestion qui porte la distance au centre de
/// recherche, utile pour l'affichage "350 m · Pharmacie X" dans l'UI.
class _OverpassSuggestion extends AddressSuggestion {
  _OverpassSuggestion({
    required super.displayName,
    required super.lat,
    required super.lon,
    super.poiName,
    super.road,
    super.houseNumber,
    super.postcode,
    super.city,
    required this.distanceMeters,
  });

  final double distanceMeters;
}
