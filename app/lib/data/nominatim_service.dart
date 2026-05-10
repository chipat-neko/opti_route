import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_suggestion.dart';
import 'geocode_cache_repository.dart';

/// Client minimal pour l'API publique de Nominatim (OpenStreetMap).
///
/// Conditions d'usage Nominatim public (free) :
/// - User-Agent identifiable obligatoire (sinon banni).
/// - 1 requete/seconde maximum par IP. Le rate-limiting cote client est
///   gere via le debounce dans le widget d'autocomplete (400 ms entre
///   chaque frappe), pas ici.
/// - Pas de scraping massif — on utilise pour de l'autocomplete et
///   du geocodage individuel uniquement.
///
/// Cache : si un [GeocodeCacheRepository] est injecte, chaque recherche
/// passe d'abord par le cache local (TTL 30 jours). Les requetes deja
/// resolues ne tapent plus Nominatim.
///
/// Precision : si la requete contient un numero (ex: "14 rue X"),
/// on lance en parallele une recherche free et une recherche
/// `structured` (street/city), on merge, on dedupe, et on rerangee
/// pour mettre les adresses avec house_number en tete.
class NominatimService {
  NominatimService({http.Client? client, GeocodeCacheRepository? cache})
      : _client = client ?? http.Client(),
        _cache = cache;

  static const _base = 'https://nominatim.openstreetmap.org';
  static const _userAgent =
      'opti_route/0.1 (https://github.com/chipat-neko/opti_route)';

  final http.Client _client;
  final GeocodeCacheRepository? _cache;

  Future<List<AddressSuggestion>> search(
    String query, {
    int limit = 8,
    String acceptLanguage = 'fr',
  }) async {
    final q = query.trim();
    if (q.length < 3) return const [];

    if (_cache != null) {
      final cached = await _cache.read(q);
      if (cached != null) return cached;
    }

    final parsed = _parseQuery(q);

    final results = <AddressSuggestion>[];
    final futures = <Future<List<AddressSuggestion>>>[
      _searchFree(q, limit: limit, lang: acceptLanguage),
      if (parsed.houseNumber != null)
        _searchStructured(parsed, limit: limit, lang: acceptLanguage),
    ];

    for (final r in await Future.wait(futures)) {
      results.addAll(r);
    }

    final deduped = _dedupe(results);
    final ranked = _rank(deduped, parsed.houseNumber);

    if (_cache != null) {
      try {
        await _cache.write(q, ranked);
      } catch (_) {
        // best-effort
      }
    }

    return ranked;
  }

  Future<List<AddressSuggestion>> _searchFree(
    String query, {
    required int limit,
    required String lang,
  }) async {
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'addressdetails': '1',
      'limit': '$limit',
      'accept-language': lang,
    });
    return _doRequest(uri);
  }

  Future<List<AddressSuggestion>> _searchStructured(
    _ParsedAddress parsed, {
    required int limit,
    required String lang,
  }) async {
    final uri = Uri.parse('$_base/search').replace(queryParameters: {
      'street': parsed.street,
      if (parsed.city != null) 'city': parsed.city!,
      'format': 'json',
      'addressdetails': '1',
      'limit': '$limit',
      'accept-language': lang,
    });
    return _doRequest(uri);
  }

  Future<List<AddressSuggestion>> _doRequest(Uri uri) async {
    final response = await _client.get(
      uri,
      headers: {'User-Agent': _userAgent},
    );
    if (response.statusCode != 200) {
      throw NominatimException('Reponse Nominatim ${response.statusCode}');
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

  static List<AddressSuggestion> _dedupe(List<AddressSuggestion> all) {
    final seen = <String>{};
    final out = <AddressSuggestion>[];
    for (final s in all) {
      final key = '${s.lat.toStringAsFixed(5)}_${s.lon.toStringAsFixed(5)}';
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  /// Re-rangee :
  /// 1) house_number == numero exact -> tout en haut
  /// 2) house_number != null -> milieu
  /// 3) reste -> bas
  static List<AddressSuggestion> _rank(
    List<AddressSuggestion> all,
    String? targetNumber,
  ) {
    int score(AddressSuggestion s) {
      if (targetNumber != null && s.houseNumber == targetNumber) return 0;
      if (s.houseNumber != null && s.houseNumber!.isNotEmpty) return 1;
      return 2;
    }

    return all.toList()..sort((a, b) => score(a).compareTo(score(b)));
  }

  static _ParsedAddress _parseQuery(String query) {
    final trimmed = query.trim();
    final numMatch = RegExp(
      r'^(\d+(?:\s?(?:bis|ter|quater|b|t))?)\s+(.+)',
      caseSensitive: false,
    ).firstMatch(trimmed);

    String? number;
    String rest;
    if (numMatch != null) {
      number = numMatch.group(1)!.replaceAll(RegExp(r'\s+'), '');
      rest = numMatch.group(2)!;
    } else {
      rest = trimmed;
    }

    final parts = rest
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    final street = parts.isEmpty ? rest : parts.first;
    final city = parts.length > 1 ? parts.sublist(1).join(', ') : null;
    final fullStreet = number != null ? '$number $street' : street;
    return _ParsedAddress(
      houseNumber: number,
      street: fullStreet,
      city: city,
    );
  }

  void close() => _client.close();
}

class _ParsedAddress {
  const _ParsedAddress({
    required this.street,
    this.houseNumber,
    this.city,
  });

  final String? houseNumber;
  final String street;
  final String? city;
}

class NominatimException implements Exception {
  const NominatimException(this.message);
  final String message;

  @override
  String toString() => 'NominatimException: $message';
}
