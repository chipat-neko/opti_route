import 'dart:convert';

import 'package:http/http.dart' as http;

import 'address_suggestion.dart';
import 'geocode_cache_repository.dart';
import 'geocoding_service.dart';

/// Client pour l'API publique **Recherche d'Entreprises**, base
/// officielle francaise INSEE/SIRENE.
///
/// API : https://recherche-entreprises.api.gouv.fr/search
/// - Maintenue par data.gouv.fr / INSEE
/// - 30+ millions d'entreprises francaises (toute societe declaree)
/// - Adresse du siege social fournie + coordonnees + SIREN +
///   activite + dirigeants
/// - Pas de cle API, pas de quota strict
///
/// Sert a trouver une entreprise par son nom (ex "Carrosserie Coculo
/// Fontenay sur Eure" -> entreprise + adresse exacte).
class RechercheEntreprisesService implements GeocodingService {
  RechercheEntreprisesService({
    http.Client? client,
    GeocodeCacheRepository? cache,
  })  : _client = client ?? http.Client(),
        _cache = cache;

  static const _userAgent =
      'opti_route/0.1 (https://github.com/chipat-neko/opti_route)';

  final http.Client _client;
  final GeocodeCacheRepository? _cache;

  @override
  String get providerKey => 'recherche_entreprises';

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

    final uri = Uri.https(
      'recherche-entreprises.api.gouv.fr',
      '/search',
      {
        'q': q,
        'per_page': '$limit',
        'page': '1',
      },
    );

    final response =
        await _client.get(uri, headers: {'User-Agent': _userAgent});

    if (response.statusCode != 200) {
      throw GeocodingException(
        'Reponse Recherche-Entreprises ${response.statusCode}',
      );
    }

    final raw = jsonDecode(response.body);
    if (raw is! Map<String, dynamic>) {
      throw const GeocodingException(
        'Reponse JSON inattendue (Recherche-Entreprises)',
      );
    }
    final results = raw['results'];
    if (results is! List) return const [];

    final suggestions = results
        .whereType<Map<String, dynamic>>()
        .map(_toSuggestion)
        .whereType<AddressSuggestion>()
        .toList(growable: false);

    // On ne cache pas les resultats vides : si une recherche n'a rien
    // retourne, on prefere retaper l'API la prochaine fois (peut-etre
    // les donnees auront ete mises a jour, ou le bug etait cote client).
    if (_cache != null && suggestions.isNotEmpty) {
      try {
        await _cache.write('$providerKey:$q', suggestions);
      } catch (_) {
        // best-effort
      }
    }

    return suggestions;
  }

  AddressSuggestion? _toSuggestion(Map<String, dynamic> result) {
    final siege = (result['siege'] as Map?)?.cast<String, dynamic>();
    if (siege == null) return null;

    // L'API renvoie latitude/longitude comme **string** ("48.4220...").
    // Cast direct en `num` retourne null. On parse explicitement.
    final lat = _parseDouble(siege['latitude']);
    final lon = _parseDouble(siege['longitude']);
    if (lat == null || lon == null) return null;

    final nomComplet = result['nom_complet'] as String? ??
        result['nom_raison_sociale'] as String?;

    final houseNumber = siege['numero_voie'] as String?;
    final libelleVoie = siege['libelle_voie'] as String?;
    final typeVoie = siege['type_voie'] as String?;
    final road = libelleVoie != null && typeVoie != null
        ? '$typeVoie $libelleVoie'.trim()
        : libelleVoie ?? siege['adresse'] as String?;
    final postcode = siege['code_postal'] as String?;

    // ATTENTION : `commune` contient le **code INSEE** ("28158"), pas
    // le nom. Le nom est dans `libelle_commune`.
    final city = siege['libelle_commune'] as String?;
    final country = siege['pays'] as String? ?? 'France';

    final addressLine = siege['adresse'] as String? ?? '';
    final localityLine = [
      if (postcode != null && postcode.isNotEmpty) postcode,
      if (city != null && city.isNotEmpty) city,
    ].join(' ');
    final displayName = [
      if (nomComplet != null && nomComplet.isNotEmpty) nomComplet,
      if (addressLine.isNotEmpty) addressLine,
      if (localityLine.isNotEmpty) localityLine,
    ].join(', ');

    if (displayName.isEmpty) return null;

    return AddressSuggestion(
      displayName: displayName,
      lat: lat,
      lon: lon,
      road: road,
      houseNumber: houseNumber,
      postcode: postcode,
      city: city,
      country: country,
      poiName: nomComplet,
    );
  }

  /// L'API recherche-entreprises retourne latitude/longitude en
  /// string. On gere aussi le cas num au cas ou (robustesse).
  double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  @override
  void close() => _client.close();
}
