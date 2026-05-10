import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_suggestion.dart';

/// Client minimal pour l'API publique de Nominatim (OpenStreetMap).
///
/// Conditions d'usage Nominatim public (free) :
/// - User-Agent identifiable obligatoire (sinon banni).
/// - 1 requete/seconde maximum par IP. Le rate-limiting cote client est
///   gere via le debounce dans le widget d'autocomplete (400 ms entre
///   chaque frappe), pas ici.
/// - Pas de scraping massif — on utilise pour de l'autocomplete et
///   du geocodage individuel uniquement.
class NominatimService {
  NominatimService({http.Client? client}) : _client = client ?? http.Client();

  static const _base = 'https://nominatim.openstreetmap.org';
  static const _userAgent =
      'opti_route/0.1 (https://github.com/chipat-neko/opti_route)';

  final http.Client _client;

  /// Recherche d'adresses libres (autocomplete).
  /// Retourne une liste vide si la requete fait moins de 3 caracteres.
  Future<List<AddressSuggestion>> search(
    String query, {
    int limit = 5,
    String acceptLanguage = 'fr',
  }) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': q,
      'format': 'json',
      'addressdetails': '1',
      'limit': '$limit',
      'accept-language': acceptLanguage,
    });

    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );

    if (response.statusCode != 200) {
      throw NominatimException(
        'Reponse Nominatim ${response.statusCode}',
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is! List) {
      throw const NominatimException('Reponse JSON inattendue');
    }
    return raw
        .whereType<Map<String, dynamic>>()
        .map(AddressSuggestion.fromJson)
        .toList(growable: false);
  }

  void close() => _client.close();
}

class NominatimException implements Exception {
  const NominatimException(this.message);
  final String message;

  @override
  String toString() => 'NominatimException: $message';
}
