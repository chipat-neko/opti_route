import 'database.dart';

/// Groupe les stops d'une tournee terminee en categories de "choses
/// a ramener au depot" : echecs (colis non livres) + ramasses recoltees
/// (colis collectes a rapporter). Carte #275.
///
/// Fonction PURE, ne touche pas a la DB ni au cloud. La sortie est
/// directement consommee par [RecapDepotCard] pour l'affichage.
class RecapDepot {
  const RecapDepot({
    required this.echecsARendre,
    required this.ramassesRecuperees,
  });

  /// Stops type 'livraison' avec statut 'echec' : le colis est rentre
  /// dans le camion et doit etre rapporte au depot pour re-tentative
  /// ou retour expediteur.
  final List<Stop> echecsARendre;

  /// Stops type 'ramasse' avec statut 'livre' : le colis a ete collecte
  /// chez le client et doit etre depose au depot pour reexpedition.
  final List<Stop> ramassesRecuperees;

  /// Total des colis a decharger au depot (somme des deux categories).
  int get totalColis =>
      echecsARendre.fold<int>(0, (sum, s) => sum + s.nbColis) +
      ramassesRecuperees.fold<int>(0, (sum, s) => sum + s.nbColis);

  /// True si quelque chose est a rapporter au depot.
  bool get aQuelqueChose =>
      echecsARendre.isNotEmpty || ramassesRecuperees.isNotEmpty;

  static RecapDepot compute(List<Stop> stops) {
    final echecs = <Stop>[];
    final ramasses = <Stop>[];
    for (final s in stops) {
      if (s.type == 'livraison' && s.statutLivraison == 'echec') {
        echecs.add(s);
      } else if (s.type == 'ramasse' && s.statutLivraison == 'livre') {
        ramasses.add(s);
      }
    }
    return RecapDepot(
      echecsARendre: echecs,
      ramassesRecuperees: ramasses,
    );
  }
}
