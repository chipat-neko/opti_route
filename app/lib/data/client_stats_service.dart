import 'package:drift/drift.dart';

import 'database.dart';

/// Statistiques agregees pour un client donne du carnet d'adresses :
/// combien de fois on l'a deja livre, combien d'echecs, derniere
/// livraison, raisons d'echecs frequentes.
///
/// Sert a l'ecran d'edition du carnet (`CarnetEditScreen`) pour
/// afficher un mini-dashboard "Mme Dupont = 12 livraisons, 2 absences,
/// dernier passage le 03/05/2026".
class ClientStatsService {
  ClientStatsService(this._db);

  final AppDatabase _db;

  /// Calcule les stats pour une entree du carnet. Match les stops
  /// historiques par :
  /// 1. `nom_client` egal (case-insensitive), s'il est defini sur la
  ///    SavedDestination
  /// 2. OU coords arrondies a ~110m (lat/lng a 3 decimales)
  Future<ClientStats> computeFor(SavedDestination client) async {
    final stops = await _matchingStops(client);
    if (stops.isEmpty) return ClientStats.empty;

    final livres = stops.where((s) => s.statutLivraison == 'livre').toList();
    final echecs = stops.where((s) => s.statutLivraison == 'echec').toList();

    // Derniere livraison : on prefere `livreLe` (timestamp reel de
    // validation) puis `creeLe` (date de creation de l'arret).
    DateTime? derniere;
    for (final s in livres) {
      final dt = s.livreLe ?? s.creeLe;
      if (derniere == null || dt.isAfter(derniere)) derniere = dt;
    }

    // Top 3 des raisons d'echec.
    final raisonsCount = <String, int>{};
    for (final s in echecs) {
      final r = s.raisonEchec;
      if (r != null && r.isNotEmpty) {
        raisonsCount[r] = (raisonsCount[r] ?? 0) + 1;
      }
    }
    final raisons = raisonsCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topRaisons = raisons.take(3).map((e) => (raison: e.key, n: e.value))
        .toList();

    return ClientStats(
      nbLivraisons: livres.length,
      nbEchecs: echecs.length,
      derniereLivraison: derniere,
      raisonsEchecCourantes: topRaisons,
    );
  }

  Future<List<Stop>> _matchingStops(SavedDestination c) async {
    final cName = c.nomClient?.trim().toLowerCase();
    // Box lat/lng ~110 m (3 decimales). Pre-filtre SQL hautement
    // selectif vs l'ancien `select(stops).get()` qui chargeait toute
    // la table en memoire pour chaque appel.
    final latLow = c.lat - 0.001;
    final latHigh = c.lat + 0.001;
    final lngLow = c.lng - 0.001;
    final lngHigh = c.lng + 0.001;

    final query = _db.select(_db.stops)
      ..where((s) {
        final boxMatch = s.lat.isBetweenValues(latLow, latHigh) &
            s.lng.isBetweenValues(lngLow, lngHigh);
        if (cName == null || cName.isEmpty) return boxMatch;
        // lower() SQLite est ASCII-only : "Élise" reste "Élise" cote
        // SQL alors que Dart "Élise".toLowerCase() = "élise". Pour
        // les noms FR courants (M. / Mme + nom ASCII) c'est OK ;
        // les rares cas accentues majuscules seront rattrapes par le
        // post-filtre Dart ci-dessous (qui ne voit que les rows
        // pre-filtres -- limitation acceptee).
        final nameMatch = s.nomClient.lower().equals(cName);
        return boxMatch | nameMatch;
      });
    final prefiltered = await query.get();

    // Post-filtre Dart : meme regle qu'avant, sur un set deja reduit.
    // Garde la semantique d'origine (case-insensitive Dart, accents
    // normalises selon les regles Unicode de String.toLowerCase).
    return prefiltered.where((s) {
      if (cName != null && cName.isNotEmpty) {
        final stopName = (s.nomClient ?? '').trim().toLowerCase();
        if (stopName == cName) return true;
      }
      if (s.lat != null && s.lng != null) {
        if ((s.lat! - c.lat).abs() < 0.001 &&
            (s.lng! - c.lng).abs() < 0.001) {
          return true;
        }
      }
      return false;
    }).toList();
  }
}

/// Aggregation immuable retournee par [ClientStatsService.computeFor].
class ClientStats {
  const ClientStats({
    required this.nbLivraisons,
    required this.nbEchecs,
    required this.derniereLivraison,
    required this.raisonsEchecCourantes,
  });

  static const empty = ClientStats(
    nbLivraisons: 0,
    nbEchecs: 0,
    derniereLivraison: null,
    raisonsEchecCourantes: [],
  );

  final int nbLivraisons;
  final int nbEchecs;
  final DateTime? derniereLivraison;

  /// Top 3 des raisons d'echec sur cet arret, triees du plus frequent
  /// au moins frequent.
  final List<({String raison, int n})> raisonsEchecCourantes;

  /// Taux de reussite (0..1). 0 si aucune tentative.
  double get tauxReussite {
    final total = nbLivraisons + nbEchecs;
    if (total == 0) return 0;
    return nbLivraisons / total;
  }

  bool get isEmpty => nbLivraisons == 0 && nbEchecs == 0;
}
