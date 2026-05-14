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
  Future<List<SearchHit>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return const [];

    final hits = <SearchHit>[];

    // 1. Tournees
    try {
      final tournees = await _db.select(_db.tournees).get();
      final tourneeHits = <SearchHitTournee>[];
      for (final t in tournees) {
        final score = _scoreFields(q, [t.nom]);
        if (score <= _scoreThreshold) {
          tourneeHits.add(SearchHitTournee(tournee: t, score: score));
        }
      }
      tourneeHits.sort((a, b) => a.score.compareTo(b.score));
      hits.addAll(tourneeHits.take(_maxResultsPerCategory));
    } catch (_) {/* best-effort */}

    // 2. Stops (joints avec leur tournee parente)
    try {
      final stops = await _db.select(_db.stops).get();
      final stopHits = <SearchHitStop>[];
      // Index tournees pour la jointure rapide
      final tourneesMap = <int, Tournee>{};
      for (final s in stops) {
        if (!tourneesMap.containsKey(s.tourneeId)) {
          final t = await (_db.select(_db.tournees)
                ..where((tt) => tt.id.equals(s.tourneeId)))
              .getSingleOrNull();
          if (t != null) tourneesMap[s.tourneeId] = t;
        }
        final tournee = tourneesMap[s.tourneeId];
        if (tournee == null) continue;
        final score = _scoreFields(q, [
          s.nomClient,
          s.adresseBrute,
          s.adresseNormalisee,
          s.notes,
        ]);
        if (score <= _scoreThreshold) {
          stopHits.add(SearchHitStop(
            stop: s,
            tournee: tournee,
            score: score,
          ));
        }
      }
      stopHits.sort((a, b) => a.score.compareTo(b.score));
      hits.addAll(stopHits.take(_maxResultsPerCategory));
    } catch (_) {/* best-effort */}

    // 3. Carnet (savedDestinations)
    try {
      final clients = await _db.select(_db.savedDestinations).get();
      final clientHits = <SearchHitClient>[];
      for (final c in clients) {
        final score = _scoreFields(q, [
          c.nomClient,
          c.adresseDisplay,
          c.rue,
          c.ville,
        ]);
        if (score <= _scoreThreshold) {
          clientHits.add(SearchHitClient(client: c, score: score));
        }
      }
      clientHits.sort((a, b) => a.score.compareTo(b.score));
      hits.addAll(clientHits.take(_maxResultsPerCategory));
    } catch (_) {/* best-effort */}

    // Tri global par score
    hits.sort((a, b) => a.score.compareTo(b.score));
    return hits;
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
