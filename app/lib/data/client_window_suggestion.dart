import 'database.dart';

/// Suggestion automatique d'une "fenêtre conseillée" pour un client,
/// dérivée de son historique (carte #323). Pure fn.
///
/// Strategie : prend les heures où les livraisons ont REUSSI dans le
/// passé, calcule min/max, propose `fenetreDebut`/`fenetreFin` au format
/// "HH:MM" arrondies à l'heure pleine entourante.
class ClientWindowSuggestion {
  const ClientWindowSuggestion({
    required this.fenetreDebut,
    required this.fenetreFin,
    required this.basedOnHits,
  });

  /// "HH:MM" début (arrondi à l'heure pleine entourant la plage).
  final String fenetreDebut;

  /// "HH:MM" fin.
  final String fenetreFin;

  /// Nb de livraisons utilisées pour la suggestion.
  final int basedOnHits;

  /// Suggestion seulement si on a >= 3 hits (sinon pas assez fiable).
  static const int minHitsForSuggestion = 3;

  /// Calcule la suggestion à partir de l'historique. Retourne null si
  /// pas assez d'historique livre.
  static ClientWindowSuggestion? compute(List<Stop> historicalStops) {
    final hits = historicalStops
        .where((s) => s.statutLivraison == 'livre' && s.livreLe != null)
        .toList();
    if (hits.length < minHitsForSuggestion) return null;
    final hours = hits.map((s) => s.livreLe!.hour).toList()..sort();
    final minH = hours.first;
    final maxH = hours.last + 1; // +1 pour englober la dernière heure
    return ClientWindowSuggestion(
      fenetreDebut: '${minH.toString().padLeft(2, '0')}:00',
      fenetreFin:
          '${maxH.clamp(0, 23).toString().padLeft(2, '0')}:00',
      basedOnHits: hits.length,
    );
  }
}
