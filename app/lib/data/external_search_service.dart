import 'package:url_launcher/url_launcher.dart';

/// Service de fallback "recherche externe" : quand la cascade
/// BAN/SIRENE/Photon n'a rien trouve, on permet a l'utilisateur de
/// chercher l'adresse / le nom de l'entreprise via Google (Maps ou
/// Search) dans le navigateur natif.
///
/// **Aucune API Google n'est appelee par l'app** : on construit
/// simplement une URL `https://www.google.com/maps/search/...` et on
/// l'ouvre via `url_launcher`. C'est 100 % cote utilisateur, gratuit,
/// pas de CB requise, pas de quota.
///
/// L'utilisateur lit le resultat sur Google, retourne dans opti_route,
/// et tape l'adresse correcte dans le champ. La cascade BAN/SIRENE/
/// Photon le geocodera proprement cette fois.
class ExternalSearchService {
  const ExternalSearchService();

  /// URL Google Maps Search pour une requete textuelle.
  /// Format : `https://www.google.com/maps/search/?api=1&query=...`
  /// (URL officielle Google Maps Universal URL).
  static Uri googleMapsUrl(String query) {
    final encoded = Uri.encodeQueryComponent(query.trim());
    return Uri.parse('https://www.google.com/maps/search/?api=1&query=$encoded');
  }

  /// URL Google Search classique (resultats web).
  /// Utile si on cherche une entreprise sans adresse connue.
  static Uri googleSearchUrl(String query) {
    final encoded = Uri.encodeQueryComponent(query.trim());
    return Uri.parse('https://www.google.com/search?q=$encoded');
  }

  /// Ouvre la recherche dans le navigateur / l'app Google Maps native
  /// si installee. Sur Android, Google Maps installee = ouverture
  /// dans l'app, sinon Chrome.
  Future<bool> launchGoogleMaps(String query) async {
    final url = googleMapsUrl(query);
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<bool> launchGoogleSearch(String query) async {
    final url = googleSearchUrl(query);
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}
