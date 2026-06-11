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
    // Cascade 2 etages (2026-06-11, audit quota). L'ancienne strategie
    // 2026-05-20 lançait les 3 sources en parallele a CHAQUE recherche :
    // latence percue optimale mais 3 quotas brules par frappe (apres
    // debounce). La cascade ci-dessous garde la meme latence sur le cas
    // dominant et ne consulte les sources secondaires que si la
    // primaire ne donne rien de precis :
    //
    // - Query adresse ("12 rue...") : BAN seul. Il couvre quasi 100%
    //   des adresses postales France ; Photon/SIRENE n'apportent rien
    //   de plus quand BAN a un hit precis. Fallback : Photon + SIRENE
    //   en parallele si BAN ne retourne aucun hit precis.
    // - Query nom ("Carrefour...") : SIRENE + Photon en parallele (ils
    //   sont complementaires : noms legaux vs enseignes). BAN seulement
    //   en secours si aucun hit precis.
    //
    // "Precis" = numero de rue OU POI nomme (meme critere que la
    // cascade historique d'avant 2026-05-20).
    Future<List<AddressSuggestion>> safe(GeocodingService s) async {
      try {
        return await s.search(query, limit: limit);
      } catch (_) {
        return const <AddressSuggestion>[];
      }
    }

    if (_looksLikeAddress(query)) {
      final banResults = await safe(ban);
      if (banResults.any(_isPrecise)) return _dedupe(banResults);
      final rest = await Future.wait([safe(photon), safe(entreprises)]);
      return _dedupe([...banResults, ...rest[0], ...rest[1]]);
    }

    final firsts = await Future.wait([safe(entreprises), safe(photon)]);
    final accumulated = [...firsts[0], ...firsts[1]];
    if (accumulated.any(_isPrecise)) return _dedupe(accumulated);
    final banResults = await safe(ban);
    return _dedupe([...accumulated, ...banResults]);
  }

  bool _looksLikeAddress(String query) {
    return RegExp(r'^\s*\d', caseSensitive: false).hasMatch(query);
  }

  /// Hit "precis" : numero de rue (adresse complete) ou POI nomme.
  static bool _isPrecise(AddressSuggestion s) {
    final hn = s.houseNumber;
    final poi = s.poiName;
    return (hn != null && hn.isNotEmpty) || (poi != null && poi.isNotEmpty);
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
