import 'address_suggestion.dart';
import 'ban_geocoding_service.dart';
import 'geocoding_service.dart';
import 'photon_service.dart';
import 'query_type_detector.dart';
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
    // V7.4 : detection fine du type de query via QueryTypeDetector.
    // Permet de choisir l'ordre optimal des sources et de court-
    // circuiter sur les identifiants numeriques (SIRET/SIREN).
    final type = QueryTypeDetector.detect(query);

    // Court-circuit SIRET / SIREN -> SIRENE direct.
    if (type == QueryType.siret || type == QueryType.siren) {
      final siret = extractSiret(query);
      if (siret != null) {
        try {
          final results = await entreprises.search(siret, limit: limit);
          if (results.isNotEmpty) return _dedupe(results);
        } catch (_) {
          // Echec : on continue avec la cascade normale en repli.
        }
      }
    }

    // Ordre des sources selon le type detecte. Logique :
    // - address : BAN d'abord (cadastre officiel), Photon si POI,
    //   SIRENE en derniere chance.
    // - locality : BAN d'abord (qui sait les communes), puis Photon
    //   pour les POI nommes (mairies, gares...), SIRENE en derniere.
    // - business / unknown : SIRENE d'abord (vrais noms juridiques),
    //   Photon pour les enseignes / chaines (que SIRENE ne couvre pas),
    //   BAN en derniere chance pour rattraper si on a un nom de
    //   societe au milieu d'une adresse postale.
    // - phone : pas exploite pour l'instant, cascade par defaut.
    final order = switch (type) {
      QueryType.address => <GeocodingService>[ban, photon, entreprises],
      QueryType.locality => <GeocodingService>[ban, photon, entreprises],
      QueryType.business => <GeocodingService>[entreprises, photon, ban],
      QueryType.phone => <GeocodingService>[entreprises, photon, ban],
      QueryType.siret ||
      QueryType.siren =>
        <GeocodingService>[entreprises, photon, ban],
      QueryType.unknown => <GeocodingService>[entreprises, photon, ban],
    };

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
      // V7.3 : auto-correct des communes. Aucune des 3 sources n'a
      // trouve. Si la query semble contenir un nom de ville (au moins
      // 4 lettres), on demande a BAN un best-match parmi les
      // communes francaises (type=municipality). Ca rattrape les
      // fautes de frappe : "Charters" -> "Chartres", "Marseile" ->
      // "Marseille".
      if (query.trim().length >= 4) {
        try {
          final corrections = await ban.searchMunicipalities(query);
          if (corrections.isNotEmpty) return _dedupe(corrections);
        } catch (_) {
          // Echec silencieux.
        }
      }
      return const [];
    }
    return _dedupe(accumulated);
  }

  /// Detecte si la query contient un SIRET (14 chiffres consecutifs)
  /// ou SIREN (9 chiffres consecutifs). Tolere espaces et tirets pour
  /// que Noah puisse coller depuis un bordereau au format "832 023 558
  /// 00018".
  ///
  /// Retourne le SIRET nettoye (14 chiffres) ou SIREN (9 chiffres), ou
  /// null si la query ne contient pas ce format.
  ///
  /// Public visible pour les tests, mais ne pas appeler depuis l'UI :
  /// la cascade `search()` l'utilise deja en interne pour court-
  /// circuiter et taper directement SIRENE.
  static String? extractSiret(String query) {
    final digitsOnly = query.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length == 14) return digitsOnly;
    if (digitsOnly.length == 9) return digitsOnly;
    return null;
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
