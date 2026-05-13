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

  /// Heures travaillees par jour de la semaine (1=lundi -> 7=dimanche)
  /// sur la fenetre `[since, now]`. Calcule a partir de `dureeTotaleS`
  /// des tournees moins le cumul des pauses.
  Future<Map<int, double>> heuresParJourDeSemaine({
    required DateTime since,
  }) async {
    final tournees = await (_db.select(_db.tournees)
          ..where((t) => t.date.isBiggerOrEqualValue(since)))
        .get();
    if (tournees.isEmpty) return const {};

    final out = <int, double>{};
    for (final t in tournees) {
      final wd = t.date.weekday;
      final totalS = t.dureeTotaleS ?? 0;
      final actuelS = (totalS - t.pauseeSeconds).clamp(0, 24 * 3600);
      out[wd] = (out[wd] ?? 0) + actuelS / 3600.0;
    }
    return out;
  }

  /// Ratio (current / previous) entre la fenetre [now-days, now] et
  /// [now-2*days, now-days]. Retourne un double :
  /// - 1.0 = identique, 1.2 = +20%, 0.8 = -20%
  /// - 0 si la periode precedente etait vide (eviter division par 0)
  ///
  /// [metric] : 'tournees' / 'colis_livres' / 'distance_m' / 'duree_s'.
  Future<double> comparatifMoisPrecedent({
    required int days,
    String metric = 'colis_livres',
  }) async {
    final now = DateTime.now();
    final currentStart = now.subtract(Duration(days: days));
    final previousStart = now.subtract(Duration(days: 2 * days));

    final current = await compute(since: currentStart);
    final previousAll = await compute(since: previousStart);

    // previousAll inclut current; on soustrait.
    final currentVal = _metric(current, metric);
    final previousVal = _metric(previousAll, metric) - currentVal;

    if (previousVal <= 0) return 0;
    return currentVal / previousVal;
  }

  static num _metric(TourneeStats s, String m) {
    switch (m) {
      case 'tournees':
        return s.nbTournees;
      case 'colis_livres':
        return s.nbColisLivres;
      case 'distance_m':
        return s.distanceMeters;
      case 'duree_s':
        return s.durationSeconds;
      default:
        throw ArgumentError('Metric inconnue : $m');
    }
  }

  /// Stats agregees par coequipier sur la fenetre `[since, now]`.
  /// Retourne une map `coequipierId -> CoequipierStats`. La cle null
  /// represente "Moi" (Noah lui-meme, stops sans `coequipierId`).
  ///
  /// Si aucun coequipier n'a ete affecte sur la periode, retourne
  /// une map vide (l'UI doit gerer ce cas en n'affichant rien).
  Future<Map<int?, CoequipierStats>> statsParCoequipier({
    required DateTime since,
  }) async {
    final tournees = await (_db.select(_db.tournees)
          ..where((t) => t.date.isBiggerOrEqualValue(since)))
        .get();
    if (tournees.isEmpty) return const {};

    final tourneeIds = tournees.map((t) => t.id).toList();
    final stops = await (_db.select(_db.stops)
          ..where((s) => s.tourneeId.isIn(tourneeIds)))
        .get();

    final acc = <int?, _CoequipierAcc>{};
    for (final s in stops) {
      final entry = acc.putIfAbsent(
        s.coequipierId,
        () => _CoequipierAcc(),
      );
      entry.nbArrets++;
      if (s.statutLivraison == 'livre') {
        entry.nbLivres++;
        entry.colisLivres += s.nbColis;
      } else if (s.statutLivraison == 'echec') {
        entry.nbEchecs++;
      }
    }

    return {
      for (final e in acc.entries)
        e.key: CoequipierStats(
          coequipierId: e.key,
          nbArrets: e.value.nbArrets,
          nbLivres: e.value.nbLivres,
          nbEchecs: e.value.nbEchecs,
          colisLivres: e.value.colisLivres,
        ),
    };
  }

  /// Statistiques motivantes : compteurs cumules depuis le 1er
  /// janvier de l'annee courante, et streak en cours de tournees
  /// terminees a 100% (aucun echec). Sert au tile "Tu as parcouru X km
  /// cette annee" dans l'ecran Stats.
  Future<MotivationStats> compteursMotivants() async {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    final tournees = await (_db.select(_db.tournees)
          ..where((t) => t.date.isBiggerOrEqualValue(yearStart)))
        .get();
    if (tournees.isEmpty) return MotivationStats.empty;

    final stops = await (_db.select(_db.stops)
          ..where((s) =>
              s.tourneeId.isIn(tournees.map((t) => t.id).toList())))
        .get();

    final livresStops =
        stops.where((s) => s.statutLivraison == 'livre').toList();
    final echecsStops =
        stops.where((s) => s.statutLivraison == 'echec').toList();
    final colisLivresAnnee =
        livresStops.fold<int>(0, (acc, s) => acc + s.nbColis);
    final nbLivresAnnee = livresStops.length;
    final nbEchecsAnnee = echecsStops.length;
    final kmAnnee =
        tournees.fold<int>(0, (acc, t) => acc + (t.distanceTotaleM ?? 0)) /
            1000;

    // Streak : tournees terminees consecutives a 100% (aucun echec).
    // Trie les tournees par date desc et compte jusqu'au 1er echec.
    final sorted = [...tournees]
      ..sort((a, b) => b.date.compareTo(a.date));
    var streak = 0;
    for (final t in sorted) {
      if (t.statut != 'terminee') break;
      final tStops = stops.where((s) => s.tourneeId == t.id).toList();
      final hasEchec = tStops.any((s) => s.statutLivraison == 'echec');
      if (hasEchec) break;
      streak++;
    }

    return MotivationStats(
      colisLivresAnnee: colisLivresAnnee,
      nbLivresAnnee: nbLivresAnnee,
      nbEchecsAnnee: nbEchecsAnnee,
      kmAnnee: kmAnnee,
      tourneesAnnee: tournees.length,
      streakSansEchec: streak,
    );
  }

  /// Top N des raisons d'echec sur la fenetre `[since, now]`, triees
  /// du plus frequent au moins frequent. Sert au tile "Pourquoi tes
  /// echecs" dans Stats : Noah voit a quoi attribuer ses ratés pour
  /// agir (pre-appeler les clients absents, etc.).
  ///
  /// Retourne une liste de records `(raison, n)`. Vide si pas d'echec
  /// sur la periode.
  Future<List<({String raison, int n})>> topRaisonsEchecGlobales({
    required DateTime since,
    int limit = 5,
  }) async {
    final tournees = await (_db.select(_db.tournees)
          ..where((t) => t.date.isBiggerOrEqualValue(since)))
        .get();
    if (tournees.isEmpty) return const [];
    final stops = await (_db.select(_db.stops)
          ..where((s) =>
              s.tourneeId.isIn(tournees.map((t) => t.id).toList()) &
              s.statutLivraison.equals('echec')))
        .get();

    final raisonsCount = <String, int>{};
    for (final s in stops) {
      final r = s.raisonEchec;
      if (r != null && r.isNotEmpty) {
        raisonsCount[r] = (raisonsCount[r] ?? 0) + 1;
      }
    }
    final entries = raisonsCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries
        .take(limit)
        .map((e) => (raison: e.key, n: e.value))
        .toList(growable: false);
  }

  /// Genere un CSV des tournees dans la fenetre `[since, now]`. Une
  /// ligne par tournee. Sert au bouton "Exporter en Excel" dans Stats.
  Future<String> exportCsvTournees({required DateTime since}) async {
    final tournees = await (_db.select(_db.tournees)
          ..where((t) => t.date.isBiggerOrEqualValue(since))
          ..orderBy([(t) => OrderingTerm.asc(t.date)]))
        .get();
    final buf = StringBuffer();
    buf.writeln(
      'date,nom,statut,arrets,colis_livres,distance_km,duree_min,pause_min',
    );
    for (final t in tournees) {
      final stops = await (_db.select(_db.stops)
            ..where((s) => s.tourneeId.equals(t.id)))
          .get();
      final colisLivres = stops
          .where((s) => s.statutLivraison == 'livre')
          .fold<int>(0, (acc, s) => acc + s.nbColis);
      final km = ((t.distanceTotaleM ?? 0) / 1000).toStringAsFixed(1);
      final dureeMin = ((t.dureeTotaleS ?? 0) / 60).round();
      final pauseMin = (t.pauseeSeconds / 60).round();
      final dateIso = t.date.toIso8601String().split('T').first;
      buf.writeln(
        '$dateIso,"${t.nom.replaceAll('"', '""')}",${t.statut},'
        '${stops.length},$colisLivres,$km,$dureeMin,$pauseMin',
      );
    }
    return buf.toString();
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

/// Compteurs motivants pour le tile "Tu as deja fait X cette annee".
class MotivationStats {
  const MotivationStats({
    required this.colisLivresAnnee,
    required this.kmAnnee,
    required this.tourneesAnnee,
    required this.streakSansEchec,
    this.nbLivresAnnee = 0,
    this.nbEchecsAnnee = 0,
  });

  static const empty = MotivationStats(
    colisLivresAnnee: 0,
    kmAnnee: 0,
    tourneesAnnee: 0,
    streakSansEchec: 0,
  );

  final int colisLivresAnnee;
  final double kmAnnee;
  final int tourneesAnnee;

  /// Nombre de stops valides "livre" sur l'annee. Distinct de
  /// colisLivresAnnee qui somme nbColis (1 stop peut avoir N colis).
  final int nbLivresAnnee;

  /// Nombre de stops valides "echec" sur l'annee.
  final int nbEchecsAnnee;

  /// Nombre de tournees terminees consecutives sans aucun echec
  /// (depuis la derniere tournee). 0 si la derniere a un echec.
  final int streakSansEchec;

  /// Taux de reussite annuel (livres / (livres + echecs)). 0 si rien
  /// valide. Sert au badge dans MotivationCard pour celebrer la qualite
  /// du livreur, pas juste la quantite.
  double get tauxReussiteAnnee {
    final total = nbLivresAnnee + nbEchecsAnnee;
    if (total == 0) return 0;
    return nbLivresAnnee / total;
  }
}

/// Accumulateur interne pour le compute `statsParCoequipier` (mutable
/// au cours de l'iteration, converti en `CoequipierStats` immuable en
/// sortie).
class _CoequipierAcc {
  int nbArrets = 0;
  int nbLivres = 0;
  int nbEchecs = 0;
  int colisLivres = 0;
}

/// Stats agregees pour un coequipier (ou Noah lui-meme si
/// `coequipierId == null`).
class CoequipierStats {
  const CoequipierStats({
    required this.coequipierId,
    required this.nbArrets,
    required this.nbLivres,
    required this.nbEchecs,
    required this.colisLivres,
  });

  /// Null = Noah lui-meme (stops sans affectation).
  final int? coequipierId;
  final int nbArrets;
  final int nbLivres;
  final int nbEchecs;
  final int colisLivres;

  /// Taux de reussite (livres / (livres + echecs)). 0 si rien valide.
  double get tauxReussite {
    final total = nbLivres + nbEchecs;
    if (total == 0) return 0;
    return nbLivres / total;
  }
}
