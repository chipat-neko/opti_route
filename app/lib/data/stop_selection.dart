import 'database.dart';

/// ════════════════════════════════════════════════════════════════
/// Regles de selection d'un arret dans une tournee.
/// ════════════════════════════════════════════════════════════════
///
/// Fonctions pures, sans BuildContext ni provider : elles vivent dans
/// `data/` parce que plusieurs couches les consultent (un widget, mais
/// aussi un provider), et qu'un import `providers/ -> screens/`
/// inverserait le sens des couches decrit dans ARCHITECTURE.md.

/// Selectionne le **premier** stop encore `a_livrer` qui a des coords
/// GPS dans [list]. Centralise la regle pour que l'affichage ET les
/// boutons Maps/Waze utilisent strictement la meme logique de
/// selection (carte Trello #149 -- evite la divergence entre "ce que
/// l'UI affiche comme prochain" et "ce que le tap Maps/Waze lance").
///
/// Les stops sans coordonnees sont ignores : on ne peut ni calculer
/// leur distance, ni proposer la navigation.
///
/// Deux consommateurs aujourd'hui, d'ou le fait qu'elle ne soit
/// recopiee nulle part :
///   - `ProchainArretCard`, qui affiche cet arret et sa distance ;
///   - `arretsProchesProvider`, dont le bandeau de proximite EXCLUT
///     cet arret, justement parce que la card l'affiche deja.
/// Toute modification de la regle doit donc etre pensee pour les deux.
Stop? firstAlivrerWithCoords(List<Stop> list) {
  for (final s in list) {
    if (s.statutLivraison == 'a_livrer' && s.lat != null && s.lng != null) {
      return s;
    }
  }
  return null;
}
