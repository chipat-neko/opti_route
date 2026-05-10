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
    final looksLikeAddress = _looksLikeAddress(query);

    final order = looksLikeAddress
        ? <GeocodingService>[ban, photon, entreprises]
        : <GeocodingService>[entreprises, photon, ban];

    final accumulated = <AddressSuggestion>[];

    for (var i = 0; i < order.length; i++) {
      final source = order[i];
      try {
        final results = await source.search(query, limit: limit);
        accumulated.addAll(results);

        // Arret precoce : si la source courante a deja trouve du precis,
        // pas besoin d'interroger les suivantes.
        if (results.any(_isPrecise)) {
          return _dedupe(accumulated);
        }
      } catch (_) {
        // Erreur reseau ou parsing : on tente la suivante en silencieux.
      }
    }

    if (accumulated.isEmpty) {
      return const [];
    }
    return _dedupe(accumulated);
  }

  bool _looksLikeAddress(String query) {
    return RegExp(r'^\s*\d', caseSensitive: false).hasMatch(query);
  }

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
    photon.close();
  }
}
