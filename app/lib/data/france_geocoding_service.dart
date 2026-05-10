import 'address_suggestion.dart';
import 'ban_geocoding_service.dart';
import 'geocoding_service.dart';
import 'recherche_entreprises_service.dart';

/// Geocoder hybride utilisant les deux APIs officielles francaises :
///
/// 1. **BAN** (api-adresse.data.gouv.fr) — adresses postales,
///    couverture quasi exhaustive France.
/// 2. **Recherche d'Entreprises** (recherche-entreprises.api.gouv.fr) —
///    base SIRENE/INSEE, toute entreprise francaise declaree.
///
/// Strategie : on detecte si la requete ressemble a une adresse
/// (commence par un chiffre, ex "14 rue de Charonne") ou a un nom
/// d'entreprise ("Carrosserie Coculo"). On interroge le bon en
/// premier, et on fallback sur l'autre si rien ou peu de resultats.
class FranceGeocodingService implements GeocodingService {
  FranceGeocodingService({
    required this.ban,
    required this.entreprises,
  });

  final BanGeocodingService ban;
  final RechercheEntreprisesService entreprises;

  @override
  String get providerKey => 'france';

  @override
  Future<List<AddressSuggestion>> search(
    String query, {
    int limit = 10,
    String acceptLanguage = 'fr-FR',
  }) async {
    final looksLikeAddress = _looksLikeAddress(query);

    final primary = looksLikeAddress ? ban : entreprises;
    final secondary = looksLikeAddress ? entreprises : ban;

    final accumulated = <AddressSuggestion>[];

    try {
      final primaryResults = await primary.search(query, limit: limit);
      accumulated.addAll(primaryResults);
      // Si le primaire trouve un resultat precis (numero de rue OU
      // POI nomme), on s'arrete : pas besoin d'une 2eme requete.
      if (primaryResults.any((s) => _isPrecise(s))) {
        return _dedupe(accumulated);
      }
    } catch (_) {
      // Erreur reseau ou parsing : on tente le secondaire en silencieux.
    }

    try {
      final secondaryResults = await secondary.search(query, limit: limit);
      accumulated.addAll(secondaryResults);
    } catch (_) {
      if (accumulated.isEmpty) rethrow;
    }

    return _dedupe(accumulated);
  }

  /// La requete commence par un chiffre (avec eventuellement bis/ter)
  /// -> tres probablement une adresse.
  bool _looksLikeAddress(String query) {
    return RegExp(r'^\s*\d', caseSensitive: false).hasMatch(query);
  }

  /// "Precis" = a un numero de rue OU est un POI.
  bool _isPrecise(AddressSuggestion s) {
    if (s.isPoi) return true;
    final n = s.houseNumber;
    return n != null && n.isNotEmpty;
  }

  List<AddressSuggestion> _dedupe(List<AddressSuggestion> all) {
    final seen = <String>{};
    final out = <AddressSuggestion>[];
    for (final s in all) {
      final key = '${s.lat.toStringAsFixed(5)}_${s.lon.toStringAsFixed(5)}';
      if (seen.add(key)) out.add(s);
    }
    return out;
  }

  @override
  void close() {
    ban.close();
    entreprises.close();
  }
}
