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
    // Filtrage SQL prefiltre, puis matching fin en Dart (Drift gere
    // mal le case-insensitive sur les colonnes texte avec accents,
    // et on veut aussi matcher par coords approximatives).
    final all = await _db.select(_db.stops).get();
    final cName = c.nomClient?.trim().toLowerCase();
    return all.where((s) {
      if (cName != null && cName.isNotEmpty) {
        final stopName = (s.nomClient ?? '').trim().toLowerCase();
        if (stopName == cName) return true;
      }
      // Match par coords arrondies a 3 decimales (~110 m).
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
