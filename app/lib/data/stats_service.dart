import 'package:drift/drift.dart';

import 'database.dart';

/// Service de calcul des statistiques cumulatives sur l'activite de
/// livraison de Noah. Aggregations par fenetre temporelle (7j / 30j /
/// 365j) :
/// - Nombre de tournees terminees
/// - Nombre d'arrets total
/// - Nombre de colis livres (statut == 'livre')
/// - Nombre d'echecs (statut == 'echec')
/// - Distance totale parcourue (somme des `distanceTotaleM`)
/// - Duree totale (somme des `dureeTotaleS`)
class StatsService {
  StatsService(this._db);

  final AppDatabase _db;

  /// Calcule les stats sur une fenetre `[since, now]`. On filtre sur
  /// la **date de la tournee** (pas `cree_le`), pour avoir les vraies
  /// metriques metier ("colis livres cette semaine").
  Future<TourneeStats> compute({required DateTime since}) async {
    // Tournees datees dans la fenetre.
    final tournees = await (_db.select(_db.tournees)
          ..where((t) => t.date.isBiggerOrEqualValue(since)))
        .get();

    if (tournees.isEmpty) {
      return TourneeStats.empty;
    }

    final tourneeIds = tournees.map((t) => t.id).toList();
    // Tous les stops de ces tournees, en une seule requete.
    final stops = await (_db.select(_db.stops)
          ..where((s) => s.tourneeId.isIn(tourneeIds)))
        .get();

    final livres =
        stops.where((s) => s.statutLivraison == 'livre').toList();
    final echecs =
        stops.where((s) => s.statutLivraison == 'echec').length;

    final colisLivres = livres.fold<int>(0, (sum, s) => sum + s.nbColis);
    final distanceM = tournees.fold<int>(
      0,
      (sum, t) => sum + (t.distanceTotaleM ?? 0),
    );
    final dureeS = tournees.fold<int>(
      0,
      (sum, t) => sum + (t.dureeTotaleS ?? 0),
    );

    return TourneeStats(
      nbTournees: tournees.length,
      nbTourneesTerminees:
          tournees.where((t) => t.statut == 'terminee').length,
      nbArrets: stops.length,
      nbColisLivres: colisLivres,
      nbLivres: livres.length,
      nbEchecs: echecs,
      distanceMeters: distanceM,
      durationSeconds: dureeS,
    );
  }

  /// Somme totale des distances (en metres) des tournees dans la
  /// fenetre. Sert ensuite a estimer le cout carburant cumule, en
  /// passant ce nombre a `ParametresRepository.estimerCoutCarburant`.
  Future<int> distanceTotaleMeters({required DateTime since}) async {
    final tournees = await (_db.select(_db.tournees)
          ..where((t) => t.date.isBiggerOrEqualValue(since)))
        .get();
    return tournees.fold<int>(0, (s, t) => s + (t.distanceTotaleM ?? 0));
  }

  /// Decompte le nombre de colis livres par jour de la semaine sur la
  /// fenetre `[since, now]`. Indice : 1 = lundi, 7 = dimanche (norme
  /// ISO 8601 / DateTime.weekday). Une carte ordonnee par jour.
  /// Permet a Noah de detecter ses jours les plus charges.
  Future<Map<int, int>> colisParJourDeSemaine(
      {required DateTime since}) async {
    final tournees = await (_db.select(_db.tournees)
          ..where((t) => t.date.isBiggerOrEqualValue(since)))
        .get();
    if (tournees.isEmpty) return const {};

    final tourneeIds = tournees.map((t) => t.id).toList();
    final stops = await (_db.select(_db.stops)
          ..where((s) =>
              s.tourneeId.isIn(tourneeIds) &
              s.statutLivraison.equals('livre')))
        .get();

    // Map id-tournee -> weekday pour ne pas refaire le lookup pour
    // chaque stop.
    final weekdayByTournee = {
      for (final t in tournees) t.id: t.date.weekday,
    };
    final out = <int, int>{};
    for (final s in stops) {
      final wd = weekdayByTournee[s.tourneeId];
      if (wd == null) continue;
      out[wd] = (out[wd] ?? 0) + s.nbColis;
    }
    return out;
  }
}

/// Aggregation immuable retournee par [StatsService.compute].
class TourneeStats {
  const TourneeStats({
    required this.nbTournees,
    required this.nbTourneesTerminees,
    required this.nbArrets,
    required this.nbColisLivres,
    required this.nbLivres,
    required this.nbEchecs,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  static const empty = TourneeStats(
    nbTournees: 0,
    nbTourneesTerminees: 0,
    nbArrets: 0,
    nbColisLivres: 0,
    nbLivres: 0,
    nbEchecs: 0,
    distanceMeters: 0,
    durationSeconds: 0,
  );

  final int nbTournees;
  final int nbTourneesTerminees;
  final int nbArrets;

  /// Total des `nbColis` des arrets livres (vrai compteur metier --
  /// 1 arret peut avoir plusieurs colis).
  final int nbColisLivres;

  final int nbLivres;
  final int nbEchecs;
  final int distanceMeters;
  final int durationSeconds;

  /// Taux de reussite (livres / (livres + echecs)). 0 si aucune
  /// tentative dans la fenetre.
  double get tauxReussite {
    final total = nbLivres + nbEchecs;
    if (total == 0) return 0;
    return nbLivres / total;
  }
}
