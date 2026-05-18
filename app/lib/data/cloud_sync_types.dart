/// ════════════════════════════════════════════════════════════════
/// Types data du module sync cloud — extraits de [CloudSyncService]
/// pour alleger le fichier principal (1299 -> ~1180 lignes) et faciliter
/// la lecture. Ces types sont purement structurels (data classes).
/// ════════════════════════════════════════════════════════════════
library;

/// Erreur de synchronisation cloud avec un message FR explicite, pret
/// a etre affiche dans une SnackBar par les screens UI.
class CloudSyncException implements Exception {
  const CloudSyncException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Resume du resultat d'un pull cloud → local. Affiche par l'UI dans
/// une SnackBar : "12 elements synchronises (3 tournees, 8 arrets, 1
/// coequipier)".
class CloudPullResult {
  const CloudPullResult({
    required this.coequipiers,
    required this.tournees,
    required this.stops,
    required this.savedDestinations,
  });

  final CloudPullStats coequipiers;
  final CloudPullStats tournees;
  final CloudPullStats stops;
  final CloudPullStats savedDestinations;

  int get totalChanged =>
      coequipiers.total + tournees.total + stops.total + savedDestinations.total;

  /// Nombre total de rows ignorees par le last-write-wins (cloud plus
  /// ancien ou egal au local). Sous-jalon 2.D-1c.
  int get totalSkipped =>
      coequipiers.skipped +
      tournees.skipped +
      stops.skipped +
      savedDestinations.skipped;

  /// Phrase courte pour SnackBar / dialog de fin de pull.
  String get summary {
    if (totalChanged == 0) {
      if (totalSkipped > 0) {
        return 'Tout etait deja a jour ($totalSkipped element(s) cloud '
            'plus ancien(s) que la version locale).';
      }
      return 'Tout etait deja a jour. Rien a synchroniser.';
    }
    final parts = <String>[];
    if (tournees.total > 0) parts.add('${tournees.total} tournee(s)');
    if (stops.total > 0) parts.add('${stops.total} arret(s)');
    if (coequipiers.total > 0) parts.add('${coequipiers.total} coequipier(s)');
    if (savedDestinations.total > 0) {
      parts.add('${savedDestinations.total} entree(s) carnet');
    }
    final suffix = totalSkipped > 0 ? ' ($totalSkipped ignore(s))' : '';
    return '$totalChanged element(s) synchronise(s) : '
        '${parts.join(', ')}$suffix';
  }
}

/// Compteur interne (inserted + updated + skipped) pour une table donnee.
/// `skipped` = rows cloud ignorees par le last-write-wins (sous-jalon
/// 2.D-1c) car la version locale est plus recente ou egale. `total`
/// reste le nombre de changements appliques (insert + update), pas le
/// nombre de rows lues du cloud.
class CloudPullStats {
  const CloudPullStats({
    required this.inserted,
    required this.updated,
    this.skipped = 0,
  });
  final int inserted;
  final int updated;
  final int skipped;
  int get total => inserted + updated;
}

/// Info affichable d'un membre de tournee partagee (sous-jalon 3.B).
/// Returned par la RPC `list_tournee_members`. Sert a la section
/// "Coequipiers" de l'ecran tournee + au badge "Equipe (N)" sur tile.
class TourneeMembreInfo {
  const TourneeMembreInfo({
    required this.userCloudId,
    required this.email,
    required this.role,
    required this.joinedAt,
  });

  final String userCloudId;
  final String email;
  final String role; // 'owner' ou 'member'
  final DateTime joinedAt;

  bool get isOwner => role == 'owner';
}
