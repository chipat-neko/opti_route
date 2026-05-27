import 'database.dart';

/// Gravite d'une alerte du tableau de bord chef.
enum ChefAlerteSeverite { info, attention, critique }

/// Une alerte affichee dans le panneau stats du jour (epopee #88,
/// [#88·4]). Calculee de maniere deterministe a partir des donnees du
/// jour (pas de dependance a l'heure courante, pour rester testable).
class ChefAlerte {
  const ChefAlerte(this.severite, this.message);

  final ChefAlerteSeverite severite;
  final String message;

  @override
  bool operator ==(Object other) =>
      other is ChefAlerte &&
      other.severite == severite &&
      other.message == message;

  @override
  int get hashCode => Object.hash(severite, message);

  @override
  String toString() => 'ChefAlerte($severite, $message)';
}

/// Stats agregees de la journee pour toute l'equipe, destinees au
/// panneau "stats du jour" du logiciel chef (epopee #88, sous-carte
/// [#88·4]).
///
/// 100% derive des tournees datees d'aujourd'hui + leurs stops. Le
/// calcul vit dans [computeFromBundle] (fonction pure, testable sans
/// DB ni horloge).
class ChefStatsJour {
  const ChefStatsJour({
    required this.nbTournees,
    required this.nbTourneesEnCours,
    required this.nbTourneesTerminees,
    required this.totalStops,
    required this.nbLivres,
    required this.nbEchecs,
    required this.colisLivres,
    required this.distanceMeters,
    required this.alertes,
  });

  static const empty = ChefStatsJour(
    nbTournees: 0,
    nbTourneesEnCours: 0,
    nbTourneesTerminees: 0,
    totalStops: 0,
    nbLivres: 0,
    nbEchecs: 0,
    colisLivres: 0,
    distanceMeters: 0,
    alertes: <ChefAlerte>[],
  );

  final int nbTournees;
  final int nbTourneesEnCours;
  final int nbTourneesTerminees;
  final int totalStops;
  final int nbLivres;
  final int nbEchecs;
  final int colisLivres;
  final int distanceMeters;
  final List<ChefAlerte> alertes;

  /// Stops ni livres ni en echec (= encore a livrer).
  int get restants => totalStops - nbLivres - nbEchecs;

  /// Distance cumulee en km (arrondie au dixieme via le getter UI).
  double get distanceKm => distanceMeters / 1000;

  /// Taux de reussite (livres / tentatives). 0 si aucune tentative.
  double get tauxReussite {
    final tentatives = nbLivres + nbEchecs;
    if (tentatives == 0) return 0;
    return nbLivres / tentatives;
  }

  /// Seuil de taux d'echec au-dela duquel on leve une alerte critique
  /// (et nombre minimal de tentatives pour eviter le faux positif sur
  /// un tout petit echantillon).
  static const double kSeuilTauxEchec = 0.20;
  static const int kMinTentativesPourAlerte = 5;

  /// Nombre minimal de stops d'une tournee en cours sans aucune
  /// livraison pour la signaler comme potentiellement bloquee.
  static const int kMinStopsBloquee = 3;

  /// Calcule les stats + alertes a partir des tournees du jour et de
  /// leurs stops. Fonction pure : meme entree -> meme sortie, aucune
  /// lecture d'horloge.
  static ChefStatsJour computeFromBundle({
    required List<Tournee> tournees,
    required List<Stop> stops,
  }) {
    if (tournees.isEmpty) return empty;

    final tourneeIds = tournees.map((t) => t.id).toSet();
    final ownStops =
        stops.where((s) => tourneeIds.contains(s.tourneeId)).toList();

    var nbLivres = 0;
    var nbEchecs = 0;
    var colisLivres = 0;
    final byTournee = <int, ({int total, int livres, int echecs})>{};
    for (final s in ownStops) {
      final cur = byTournee[s.tourneeId] ?? (total: 0, livres: 0, echecs: 0);
      final isLivre = s.statutLivraison == 'livre';
      final isEchec = s.statutLivraison == 'echec';
      byTournee[s.tourneeId] = (
        total: cur.total + 1,
        livres: cur.livres + (isLivre ? 1 : 0),
        echecs: cur.echecs + (isEchec ? 1 : 0),
      );
      if (isLivre) {
        nbLivres++;
        colisLivres += s.nbColis;
      } else if (isEchec) {
        nbEchecs++;
      }
    }

    final distanceMeters =
        tournees.fold<int>(0, (a, t) => a + (t.distanceTotaleM ?? 0));

    final alertes = <ChefAlerte>[];

    // Alerte 1 : taux d'echec global eleve (sur un echantillon
    // suffisant pour eviter le faux positif).
    final tentatives = nbLivres + nbEchecs;
    if (tentatives >= kMinTentativesPourAlerte) {
      final tauxEchec = nbEchecs / tentatives;
      if (tauxEchec > kSeuilTauxEchec) {
        final pct = (tauxEchec * 100).round();
        alertes.add(ChefAlerte(
          ChefAlerteSeverite.critique,
          'Taux d\'echec eleve : $pct% ($nbEchecs echec'
          '${nbEchecs > 1 ? "s" : ""} sur $tentatives)',
        ));
      }
    }

    // Alertes par tournee en cours.
    for (final t in tournees) {
      if (t.statut != 'en_cours') continue;
      final agg = byTournee[t.id] ?? (total: 0, livres: 0, echecs: 0);
      // Tournee demarree mais aucune livraison alors qu'il y a des
      // stops -> chauffeur peut-etre bloque.
      if (agg.livres == 0 &&
          agg.echecs == 0 &&
          agg.total >= kMinStopsBloquee) {
        alertes.add(ChefAlerte(
          ChefAlerteSeverite.attention,
          'Tournee "${t.nom}" : demarree, aucune livraison pour '
          'l\'instant (${agg.total} arrets)',
        ));
      } else if (agg.total > 0 && agg.livres + agg.echecs == agg.total) {
        // Tous les stops traites mais la tournee est encore en_cours
        // -> a clore.
        alertes.add(ChefAlerte(
          ChefAlerteSeverite.info,
          'Tournee "${t.nom}" : tous les arrets traites, a cloturer',
        ));
      }
    }

    // Tri par gravite decroissante (critique d'abord), ordre stable
    // sinon (preserve l'ordre d'insertion).
    alertes.sort((a, b) => b.severite.index.compareTo(a.severite.index));

    return ChefStatsJour(
      nbTournees: tournees.length,
      nbTourneesEnCours:
          tournees.where((t) => t.statut == 'en_cours').length,
      nbTourneesTerminees:
          tournees.where((t) => t.statut == 'terminee').length,
      totalStops: ownStops.length,
      nbLivres: nbLivres,
      nbEchecs: nbEchecs,
      colisLivres: colisLivres,
      distanceMeters: distanceMeters,
      alertes: alertes,
    );
  }
}
