import 'address_suggestion.dart';

/// Interface commune pour les fournisseurs de geocodage.
/// Permet de basculer entre Nominatim, Photon, TomTom, Google Maps...
/// sans toucher au widget d'autocomplete.
abstract class GeocodingService {
  /// Code court qui identifie le fournisseur (ex: "photon", "nominatim").
  /// Utilise pour prefixer les cles de cache et eviter de melanger les
  /// reponses entre fournisseurs.
  String get providerKey;

  /// Cherche des suggestions pour [query].
  ///
  /// - Retourne une liste vide si la requete est trop courte ou nulle.
  /// - Lance [GeocodingException] en cas d'erreur reseau ou format.
  Future<List<AddressSuggestion>> search(
    String query, {
    int limit,
    String acceptLanguage,
  });

  void close();
}

class GeocodingException implements Exception {
  const GeocodingException(this.message);
  final String message;

  @override
  String toString() => 'GeocodingException: $message';
}
