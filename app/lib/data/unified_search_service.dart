import 'package:flutter/foundation.dart' show compute;

import 'database.dart';
import 'levenshtein.dart';

/// ════════════════════════════════════════════════════════════════
/// Resultat unifie de recherche : tournee / arret / client.
/// ════════════════════════════════════════════════════════════════
///
/// Pattern sealed class : chaque sous-type expose ses champs propres,
/// le code consommateur dispatch via `switch (hit)`. Plus typé qu'un
/// `Map<String, dynamic>`, et exhaustif (analyzer Dart 3+ verifie).
///
/// Le `score` est une similarite Levenshtein normalisee :
/// - 0.0 = match exact (rare, ex: tape le nom exact d'un client)
/// - 0.5 = match approximatif (ex: "boul" matche "Boulangerie")
/// - 1.0 = aucune similarite (ne devrait pas remonter)
///
/// Plus le score est BAS, plus le hit est pertinent. Le service de
/// recherche filtre les hits au-dessus d'un seuil (typiquement 0.4)
/// et trie par score ascendant.
sealed class SearchHit {
  const SearchHit(this.score);

  /// Similarite Levenshtein normalisee 0..1. Plus c'est BAS, plus
  /// le hit est proche de la requete.
  final double score;
}

/// Hit "tournee" : la recherche a matche le nom de la tournee.
class SearchHitTournee extends SearchHit {
  const SearchHitTournee({required this.tournee, required double score})
      : super(score);

  final Tournee tournee;
}

/// Hit "arret" : la recherche a matche le nom client, l'adresse ou
/// les notes d'un stop. On joint la tournee parente pour permettre
/// la navigation directe vers le mode terrain de la bonne tournee.
class SearchHitStop extends SearchHit {
  const SearchHitStop({
    required this.stop,
    required this.tournee,
    required double score,
  }) : super(score);

  final Stop stop;
  final Tournee tournee;
}

/// Hit "client" du carnet : nom + adresse normalisee.
class SearchHitClient extends SearchHit {
  const SearchHitClient({
    required this.client,
    required double score,
  }) : super(score);

  final SavedDestination client;
}

/// ════════════════════════════════════════════════════════════════
/// Service de recherche unifiee.
/// ════════════════════════════════════════════════════════════════
///
/// Scan en parallele les 3 sources (tournees, stops, carnet) et
/// retourne une liste typee de SearchHit, trie par pertinence.
///
/// Strategie de scoring :
/// 1. Pour chaque champ "interessant" (nom, adresse, notes), on
///    calcule la similarite Levenshtein avec la query.
/// 2. On garde le MEILLEUR score (= min) parmi les champs.
/// 3. Bonus -0.05 si la query est contenue mot-pour-mot dans un
///    champ (match exact partiel) : "boul" dans "Boulangerie".
///
/// Filtres :
/// - Query < 2 caracteres : retourne vide (evite de tout matcher).
/// - Hits avec score > 0.4 : exclus (trop loin de la query).
/// - Limite a [maxResultsPerCategory] par categorie pour eviter de
///   noyer l'UI quand on tape "a" et que ca matche 200 choses.
class UnifiedSearchService {
  UnifiedSearchService(this._db);

  final AppDatabase _db;

  /// Seuil de score sous lequel un hit est considere comme pertinent.
  /// 0.4 = on tolere des fautes de frappe / matches partiels.
  static const _scoreThreshold = 0.4;

  /// Limite par categorie (tournees / stops / clients) pour eviter
  /// les listes infinies sur des requetes vagues comme "a".
  static const _maxResultsPerCategory = 10;

  /// Lance la recherche unifiee pour [query] sur les 3 sources.
  /// Retourne la liste triee par score ascendant (plus pertinent
  /// en premier), entre-melee : pas de regroupement par categorie au
  /// niveau service. C'est a l'UI de regrouper / afficher comme elle
  /// veut.
  ///
  /// Best-effort : si une source crash, on retourne les autres.
  /// Au-dela de ce total de lignes (tournees+stops+clients), le scoring
  /// part dans un isolate. En dessous, le cout de spawn dominerait.
  static const _isolateThreshold = 200;

  Future<List<SearchHit>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];

    // I/O sur l'isolate principal (rapide, async). Best-effort par source.
    List<Tournee> tournees = const [];
    try {
      tournees = await _db.select(_db.tournees).get();
    } catch (_) {/* best-effort */}
    List<Stop> stops = const [];
    try {
      stops = await _db.select(_db.stops).get();
    } catch (_) {/* best-effort */}
    List<SavedDestination> clients = const [];
    try {
      clients = await _db.select(_db.savedDestinations).get();
    } catch (_) {/* best-effort */}

    // Scoring Levenshtein (par mot, par champ, par ligne) = CPU-bound.
    // Sur un historique pluriannuel ca fige l'UI a chaque frappe (#216)
    // -> on le deporte dans un isolate des que le volume le justifie.
    final input = _SearchInput(q, tournees, stops, clients);
    final total = tournees.length + stops.length + clients.length;
    if (total < _isolateThreshold) {
      return _scoreAllSources(input);
    }
    return compute(_scoreAllSources, input);
  }

  /// Calcule le score pour une liste de champs (chacun nullable).
  /// Retourne le MIN des scores individuels (le meilleur match parmi
  /// les champs disponibles). Si aucun champ exploitable, retourne 1.0.
  ///
  /// Bonus -0.05 si la query est contenue **mot-pour-mot** dans le
  /// champ (substring), pour favoriser "boul" sur "Boulangerie" vs
  /// une simple proximite Levenshtein.
  static double _scoreFields(String q, List<String?> fields) {
    double best = 1.0;
    for (final raw in fields) {
      if (raw == null || raw.isEmpty) continue;
      final f = raw.toLowerCase();
      // Substring match -> bonus -0.05
      final substringBonus = f.contains(q) ? -0.05 : 0.0;
      // Sur des champs longs ("Boulangerie Martin 12 rue ..."), comparer
      // toute la chaine a la query courte donne un score artificiellement
      // haut. Solution : on compare la query a chaque mot du champ et
      // on garde le meilleur. C'est ce qui rend la recherche "fuzzy
      // par mot" et pas "fuzzy global".
      final words = f.split(RegExp(r'\s+'));
      for (final w in words) {
        if (w.isEmpty) continue;
        final s = Levenshtein.similarity(q, w) + substringBonus;
        if (s < best) best = s;
      }
    }
    return best.clamp(0.0, 1.0);
  }
}

/// Entree serialisable pour le scoring deporte en isolate (#216).
class _SearchInput {
  const _SearchInput(this.q, this.tournees, this.stops, this.clients);
  final String q;
  final List<Tournee> tournees;
  final List<Stop> stops;
  final List<SavedDestination> clients;
}

/// Score les 3 sources et retourne les hits tries (plus pertinent
/// d'abord). Fonction PURE (aucun I/O) -> executable dans un isolate via
/// compute(). Le scoring (Levenshtein par mot/champ/ligne) est identique
/// a l'ancienne version inline ; seul l'isolate d'execution change.
List<SearchHit> _scoreAllSources(_SearchInput input) {
  final q = input.q;
  final hits = <SearchHit>[];
  final tourneesMap = {for (final t in input.tournees) t.id: t};

  // 1. Tournees (match sur le nom).
  final tourneeHits = <SearchHitTournee>[];
  for (final t in input.tournees) {
    final score = UnifiedSearchService._scoreFields(q, [t.nom]);
    if (score <= UnifiedSearchService._scoreThreshold) {
      tourneeHits.add(SearchHitTournee(tournee: t, score: score));
    }
  }
  tourneeHits.sort((a, b) => a.score.compareTo(b.score));
  hits.addAll(tourneeHits.take(UnifiedSearchService._maxResultsPerCategory));

  // 2. Stops (joints avec leur tournee parente).
  final stopHits = <SearchHitStop>[];
  for (final s in input.stops) {
    final tournee = tourneesMap[s.tourneeId];
    if (tournee == null) continue;
    final score = UnifiedSearchService._scoreFields(q, [
      s.nomClient,
      s.adresseBrute,
      s.adresseNormalisee,
      s.notes,
    ]);
    if (score <= UnifiedSearchService._scoreThreshold) {
      stopHits.add(SearchHitStop(stop: s, tournee: tournee, score: score));
    }
  }
  stopHits.sort((a, b) => a.score.compareTo(b.score));
  hits.addAll(stopHits.take(UnifiedSearchService._maxResultsPerCategory));

  // 3. Carnet (savedDestinations).
  final clientHits = <SearchHitClient>[];
  for (final c in input.clients) {
    final score = UnifiedSearchService._scoreFields(q, [
      c.nomClient,
      c.adresseDisplay,
      c.rue,
      c.ville,
    ]);
    if (score <= UnifiedSearchService._scoreThreshold) {
      clientHits.add(SearchHitClient(client: c, score: score));
    }
  }
  clientHits.sort((a, b) => a.score.compareTo(b.score));
  hits.addAll(clientHits.take(UnifiedSearchService._maxResultsPerCategory));

  // Tri global par score.
  hits.sort((a, b) => a.score.compareTo(b.score));
  return hits;
}
