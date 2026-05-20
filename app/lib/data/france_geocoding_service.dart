import 'address_suggestion.dart';
import 'ban_geocoding_service.dart';
import 'geocoding_service.dart';
import 'photon_service.dart';
import 'recherche_entreprises_service.dart';

/// Geocoder hybride a 3 sources, optimise pour la livraison en France :
///
/// 1. **BAN** (api-adresse.data.gouv.fr) — adresses postales,
///    couverture quasi exhaustive France grace au cadastre DGFiP.
/// 2. **Recherche d'Entreprises** (recherche-entreprises.api.gouv.fr)
///    — base SIRENE/INSEE, toute entreprise francaise declaree
///    legalement (par leur **nom legal**, ex: "SAS GARAGE DUPONT").
/// 3. **Photon (OSM)** — pour les **enseignes / marques** que SIRENE
///    ne connait pas (ex: "Citroen", "Carrefour", "McDonald's") parce
///    que OSM les indexe via les tags `brand=...` / `name=...`.
///
/// Strategie intelligente :
/// - Requete commence par un chiffre (adresse) -> ordre BAN, Photon,
///   Recherche-Entreprises.
/// - Sinon (nom d'entreprise / enseigne) -> ordre Recherche-Entreprises,
///   Photon, BAN. SIRENE en 1er pour les vraies entreprises (siege,
///   etablissements), Photon en 2eme pour rattraper les enseignes.
/// - On s'arrete des qu'une source retourne au moins un resultat
///   precis (numero de rue OU POI nomme).
class FranceGeocodingService implements GeocodingService {
  FranceGeocodingService({
    required this.ban,
    required this.entreprises,
    required this.photon,
  });

  final BanGeocodingService ban;
  final RechercheEntreprisesService entreprises;
  final PhotonService photon;

  @override
  String get providerKey => 'france';

  @override
  Future<List<AddressSuggestion>> search(
    String query, {
    int limit = 10,
    String acceptLanguage = 'fr-FR',
  }) async {
    // Strategie 2026-05-20 (style Spoke) : lance les 3 sources EN
    // PARALLELE plutot qu'en cascade sequentielle. Gain de vitesse
    // perçue 2-3x car la latence totale = max(t_ban, t_sirene,
    // t_photon) au lieu de t_ban + t_sirene + t_photon.
    //
    // Trade-off : on consomme 3 quotas API au lieu d'1 en moyenne.
    // Acceptable car les 3 APIs sont gratuites et tres genereuses
    // (BAN gov.fr no limit officiel, SIRENE gov.fr, Photon Komoot
    // 5 req/s).
    //
    // Le `looksLikeAddress` reste utilise pour TRIER les resultats :
    // l'ordre privilegie BAN si requete commence par chiffre, sinon
    // entreprises en tete. Ca preserve la pertinence sans attendre
    // la fin du 1er appel.
    final looksLikeAddress = _looksLikeAddress(query);
    final primaryOrder = looksLikeAddress
        ? <GeocodingService>[ban, photon, entreprises]
        : <GeocodingService>[entreprises, photon, ban];

    // Lance les 3 en parallele. Chaque future swallow ses erreurs
    // pour ne pas couler le Future.wait global.
    Future<List<AddressSuggestion>> safe(GeocodingService s) async {
      try {
        return await s.search(query, limit: limit);
      } catch (_) {
        return const <AddressSuggestion>[];
      }
    }
    final results = await Future.wait(primaryOrder.map(safe));

    // Concatene dans l'ordre de priorite (results[0] = source la plus
    // pertinente pour ce type de query) puis dedupe par coords.
    final accumulated = <AddressSuggestion>[];
    for (final r in results) {
      accumulated.addAll(r);
    }
    return _dedupe(accumulated);
  }

  bool _looksLikeAddress(String query) {
    return RegExp(r'^\s*\d', caseSensitive: false).hasMatch(query);
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
    photon.close();
  }
}
