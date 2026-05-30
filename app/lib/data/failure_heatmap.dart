import 'database.dart';

/// Heatmap des echecs par (zone CP, tranche horaire) (carte #302).
/// Aide a reveler "ce quartier est toujours absent avant 11h" -> on
/// reorganise l'ordre de passage.
class FailureHeatmap {
  FailureHeatmap._();

  static final RegExp _cp = RegExp(r'\b(\d{5})\b');

  /// Map (cp, hour) -> nb d'echecs. Ignore les stops sans livreLe (pas
  /// d'heure detectable) et ceux non echec.
  static Map<({String cp, int hour}), int> compute(List<Stop> stops) {
    final out = <({String cp, int hour}), int>{};
    for (final s in stops) {
      if (s.statutLivraison != 'echec') continue;
      if (s.livreLe == null) continue;
      final src = '${s.adresseNormalisee ?? ''} ${s.adresseBrute}';
      final cp = _cp.firstMatch(src)?.group(1) ?? '?';
      final key = (cp: cp, hour: s.livreLe!.hour);
      out[key] = (out[key] ?? 0) + 1;
    }
    return out;
  }

  /// Top N cellules (cp, hour) avec le plus d'echecs.
  static List<({String cp, int hour, int count})> top(
    List<Stop> stops, {
    int limit = 5,
  }) {
    final m = compute(stops);
    final entries = m.entries
        .map((e) => (cp: e.key.cp, hour: e.key.hour, count: e.value))
        .toList();
    entries.sort((a, b) => b.count.compareTo(a.count));
    return entries.take(limit).toList();
  }
}
