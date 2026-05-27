import 'database.dart';

/// Progression d'une tournee pour le panneau "tournees en cours" du
/// logiciel chef (epopee #88, [#88·2]).
///
/// Vue plate, derivee d'une tournee + ses stops, prete a afficher :
/// nom, statut, point de depart, total/livres/echecs + barre de
/// progression. Source 100% locale (Drift) : aujourd'hui ce sont les
/// tournees du chef ; quand le cloud sync equipe sera valide, la meme
/// base contiendra les tournees des coequipiers.
class ChefTourneeProgress {
  const ChefTourneeProgress({
    required this.tourneeId,
    required this.nom,
    required this.statut,
    required this.pointDepartLabel,
    required this.coequipierId,
    required this.total,
    required this.livres,
    required this.echecs,
    required this.enPause,
  });

  final int tourneeId;
  final String nom;
  final String statut;
  final String pointDepartLabel;

  /// Coequipier "proprietaire" de la tournee (null = Noah lui-meme).
  final int? coequipierId;

  final int total;
  final int livres;
  final int echecs;
  final bool enPause;

  /// Avancement (livres + echecs) / total. 0 si pas de stop.
  double get progression {
    if (total == 0) return 0;
    return ((livres + echecs) / total).clamp(0.0, 1.0);
  }

  bool get estEnCours => statut == 'en_cours';

  /// Construit la liste triee a partir des tournees + stops. Fonction
  /// pure (aucune lecture d'horloge ni de DB). Tri : tournees en cours
  /// d'abord, puis par nom (ordre alphabetique stable).
  static List<ChefTourneeProgress> computeFromBundle({
    required List<Tournee> tournees,
    required List<Stop> stops,
  }) {
    if (tournees.isEmpty) return const [];

    // Pre-agrege les stops par tournee (1 passe).
    final byTournee = <int, ({int total, int livres, int echecs})>{};
    for (final s in stops) {
      final cur = byTournee[s.tourneeId] ?? (total: 0, livres: 0, echecs: 0);
      byTournee[s.tourneeId] = (
        total: cur.total + 1,
        livres: cur.livres + (s.statutLivraison == 'livre' ? 1 : 0),
        echecs: cur.echecs + (s.statutLivraison == 'echec' ? 1 : 0),
      );
    }

    final out = <ChefTourneeProgress>[
      for (final t in tournees)
        ChefTourneeProgress(
          tourneeId: t.id,
          nom: t.nom,
          statut: t.statut,
          pointDepartLabel: t.pointDepartLabel,
          coequipierId: null,
          total: (byTournee[t.id] ?? (total: 0, livres: 0, echecs: 0)).total,
          livres: (byTournee[t.id] ?? (total: 0, livres: 0, echecs: 0)).livres,
          echecs: (byTournee[t.id] ?? (total: 0, livres: 0, echecs: 0)).echecs,
          enPause: t.pauseeLe != null,
        ),
    ];

    out.sort((a, b) {
      // en_cours en premier.
      if (a.estEnCours != b.estEnCours) {
        return a.estEnCours ? -1 : 1;
      }
      return a.nom.toLowerCase().compareTo(b.nom.toLowerCase());
    });
    return out;
  }
}
