import 'database.dart';

/// Stats d'historique de passage chez un client (carte #294).
/// Aide a planifier l'heure de passage : "M. Durand jamais la avant
/// 17h", "Mme Lebrun : 3 echecs sur 5 passages".
class ClientHistoryStats {
  const ClientHistoryStats({
    required this.totalPassages,
    required this.livres,
    required this.echecs,
    required this.bestHour,
    required this.worstHour,
  });

  /// Nb total de passages effectifs (livre + echec ; les a_livrer
  /// pending ne comptent pas car non terminés).
  final int totalPassages;

  /// Nb de passages livres.
  final int livres;

  /// Nb de passages echec (toutes raisons confondues).
  final int echecs;

  /// Heure du jour (0-23) avec le meilleur taux de livraison (livre /
  /// total des passages dans cette heure). Null si pas de donnees.
  final int? bestHour;

  /// Heure du jour (0-23) avec le pire taux. Null si pas de donnees.
  final int? worstHour;

  double get tauxReussite =>
      totalPassages == 0 ? 0 : livres / totalPassages;

  static ClientHistoryStats compute(List<Stop> historicalStops) {
    final actes =
        historicalStops.where((s) => s.livreLe != null).toList(growable: false);
    final livres = actes.where((s) => s.statutLivraison == 'livre').length;
    final echecs = actes.where((s) => s.statutLivraison == 'echec').length;

    // Group par heure
    final perHour = <int, ({int livres, int total})>{};
    for (final s in actes) {
      final h = s.livreLe!.hour;
      final cur = perHour[h] ?? (livres: 0, total: 0);
      perHour[h] = (
        livres: cur.livres + (s.statutLivraison == 'livre' ? 1 : 0),
        total: cur.total + 1,
      );
    }

    int? best;
    int? worst;
    double? bestRatio;
    double? worstRatio;
    for (final e in perHour.entries) {
      final r = e.value.total == 0 ? 0.0 : e.value.livres / e.value.total;
      if (bestRatio == null || r > bestRatio) {
        bestRatio = r;
        best = e.key;
      }
      if (worstRatio == null || r < worstRatio) {
        worstRatio = r;
        worst = e.key;
      }
    }

    return ClientHistoryStats(
      totalPassages: actes.length,
      livres: livres,
      echecs: echecs,
      bestHour: best,
      worstHour: worst,
    );
  }
}
