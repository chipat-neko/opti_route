import 'database.dart';

/// Surveillance chaine du froid (carte #328). Pure fn : à partir d'un
/// stop "froid" + l'heure courante, dit s'il faut alerter / livrer
/// d'urgence / si c'est perdu.
///
/// Conventions :
/// - On stocke l'heure limite côté caller (champ texte libre dans
///   notes ou via une colonne future). Pour le MVP cette pure fn
///   prend `loadedAt` + `maxHoursAtAmbient` en paramètres.
class ColdChain {
  ColdChain._();

  /// Heures par defaut tolérables hors chaine du froid pour les
  /// produits frais standards (Picard sous-traité = 30 min ; pharma
  /// = 2h ; viande/poisson = 1h ; voir avec donneur d'ordre).
  static const double defaultMaxHours = 1.0;

  /// Etat actuel.
  static ColdChainState evaluate({
    required DateTime loadedAt,
    required DateTime now,
    double maxHours = defaultMaxHours,
  }) {
    final elapsed = now.difference(loadedAt);
    final maxDuration =
        Duration(seconds: (maxHours * 3600).round());
    final ratio = elapsed.inSeconds / maxDuration.inSeconds;
    if (ratio >= 1) return ColdChainState.lost;
    if (ratio >= 0.75) return ColdChainState.critical;
    if (ratio >= 0.5) return ColdChainState.warning;
    return ColdChainState.ok;
  }

  /// Minutes restantes avant expiration (peut être negatif).
  static int remainingMinutes({
    required DateTime loadedAt,
    required DateTime now,
    double maxHours = defaultMaxHours,
  }) {
    final maxDuration =
        Duration(seconds: (maxHours * 3600).round());
    return maxDuration.inMinutes - now.difference(loadedAt).inMinutes;
  }

  /// Sélectionne les stops "froid" à livrer en priorité absolue.
  /// Le caller filtre la liste sur un flag/notes contenant "frais"
  /// ou "froid" avant d'appeler.
  static List<Stop> sortByExpiry({
    required List<Stop> coldStops,
    required DateTime loadedAt,
  }) {
    // Pas de coldExpiresAt en base pour le MVP -> tous loadedAt
    // identiques, on trie par ordre déjà optimisé (pas de re-tri).
    return List<Stop>.of(coldStops);
  }
}

enum ColdChainState { ok, warning, critical, lost }
