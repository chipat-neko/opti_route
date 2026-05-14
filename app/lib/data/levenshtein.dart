/// Distance de Levenshtein entre 2 chaines : nombre minimal de
/// modifications (insertion, suppression, substitution d'un caractere)
/// pour passer de l'une a l'autre.
///
/// Utilise principalement pour la tolerance OCR :
///   - "BORDEAUS" vs "BORDEAUX" -> distance 1 (substitution X<->S)
///   - "ARTRES" vs "CHARTRES" -> distance 2 (deux suppressions)
///   - "DESINATAIRE" vs "DESTINATAIRE" -> distance 1 (insertion T)
///
/// Algorithme : programmation dynamique classique, complexite O(n*m)
/// ou n et m sont les longueurs des 2 chaines. Pour les usages OCR
/// (chaines courtes < 50 caracteres), c'est negligeable.
class Levenshtein {
  Levenshtein._();

  /// Calcule la distance de Levenshtein entre [a] et [b].
  /// Retourne 0 si les chaines sont identiques, max(len(a), len(b))
  /// si elles n'ont rien en commun.
  static int distance(String a, String b) {
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    // On utilise 2 lignes du tableau au lieu de la matrice complete :
    // pour calculer la ligne i, on n'a besoin que de la ligne i-1.
    // Reduction memoire O(n*m) -> O(min(n, m)).
    final n = a.length;
    final m = b.length;
    var prev = List<int>.generate(m + 1, (i) => i);
    var curr = List<int>.filled(m + 1, 0);

    for (var i = 1; i <= n; i++) {
      curr[0] = i;
      for (var j = 1; j <= m; j++) {
        final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
        // min(suppression, insertion, substitution)
        final del = prev[j] + 1;
        final ins = curr[j - 1] + 1;
        final sub = prev[j - 1] + cost;
        var min = del < ins ? del : ins;
        if (sub < min) min = sub;
        curr[j] = min;
      }
      // Swap : la ligne courante devient la precedente.
      final tmp = prev;
      prev = curr;
      curr = tmp;
    }

    return prev[m];
  }

  /// Variante normalisee : retourne un score entre 0 (identique) et 1
  /// (totalement different) base sur la distance / longueur max.
  /// Plus pratique pour les seuils ("similaire si < 0.2").
  static double similarity(String a, String b) {
    if (a.isEmpty && b.isEmpty) return 0.0;
    final maxLen = a.length > b.length ? a.length : b.length;
    return distance(a, b) / maxLen;
  }

  /// Cherche dans [candidates] la chaine la plus proche de [needle],
  /// avec une tolerance maximale en distance Levenshtein.
  /// Retourne null si aucun candidat n'est dans la tolerance.
  ///
  /// Comparaison **case-insensitive** : "Bordeaux" et "BORDEAUX" sont
  /// vus comme identiques. Pour l'OCR de bordereaux ou tout est en
  /// majuscules, c'est ce qu'on veut.
  static String? closestMatch(
    String needle,
    Iterable<String> candidates, {
    int maxDistance = 2,
  }) {
    final needleLower = needle.toLowerCase();
    String? best;
    int bestDist = maxDistance + 1;
    for (final c in candidates) {
      final d = distance(needleLower, c.toLowerCase());
      if (d < bestDist) {
        bestDist = d;
        best = c;
        if (d == 0) break; // exact match, inutile de chercher plus
      }
    }
    return bestDist <= maxDistance ? best : null;
  }
}
