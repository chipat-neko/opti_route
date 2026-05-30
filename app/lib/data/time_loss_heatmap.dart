import 'database.dart';

/// "Où je perds du temps" (carte #322) : agrege le delta prévu/réel
/// par stop, regroupe par code postal pour visualiser les zones
/// coûteuses. Pure fn.
class TimeLossHeatmap {
  TimeLossHeatmap._();

  static final RegExp _cp = RegExp(r'\b(\d{5})\b');

  /// Map cp -> total des minutes de dépassement (réel > prévu) pour
  /// les stops livrés. Ignore les stops sans livreLe ou sans ETA prévu.
  ///
  /// [etasPrevues] : map stopId -> DateTime ETA prévu (souvent issu de
  /// `etasParStopProvider` snapshoté au démarrage de la tournée).
  static Map<String, int> compute({
    required List<Stop> stops,
    required Map<int, DateTime> etasPrevues,
  }) {
    final out = <String, int>{};
    for (final s in stops) {
      if (s.statutLivraison != 'livre') continue;
      final eta = etasPrevues[s.id];
      if (eta == null || s.livreLe == null) continue;
      final delta = s.livreLe!.difference(eta).inMinutes;
      if (delta <= 0) continue;
      final cp = _extractCp(s);
      out[cp] = (out[cp] ?? 0) + delta;
    }
    return out;
  }

  /// Top N cps les plus coûteux (tri descendant).
  static List<({String cp, int minutesLoss})> top(
    List<Stop> stops,
    Map<int, DateTime> etasPrevues, {
    int limit = 5,
  }) {
    final m = compute(stops: stops, etasPrevues: etasPrevues);
    final entries = m.entries
        .map((e) => (cp: e.key, minutesLoss: e.value))
        .toList()
      ..sort((a, b) => b.minutesLoss.compareTo(a.minutesLoss));
    return entries.take(limit).toList();
  }

  static String _extractCp(Stop s) {
    final src = '${s.adresseNormalisee ?? ''} ${s.adresseBrute}';
    return _cp.firstMatch(src)?.group(1) ?? '?';
  }
}
