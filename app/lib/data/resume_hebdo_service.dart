import 'package:drift/drift.dart';

import 'database.dart';

/// Service de calcul du resume hebdomadaire (carte Trello #101).
///
/// Pour une semaine donnee (lundi 00:00 -> dimanche 23:59), agrege :
/// - Nombre de tournees, dont terminees
/// - Nombre d'arrets total, livres, echecs, taux reussite
/// - Distance totale (km), duree totale (h)
/// - Top N clients (par nb livraisons, groupes par nomClient)
/// - Coequipier le plus actif (par nb livres)
/// - Liste detaillee des tournees realisees
/// - Comparatif vs semaine precedente (variation %)
///
/// Le calcul est volontairement borne en RAM (pas de SQL aggregation
/// complexe) car les volumes de Noah sont petits (~30 tournees max par
/// semaine, ~30 stops par tournee = 900 rows max).
class ResumeHebdoService {
  /// [now] : horloge injectable (F8a). Par defaut l'heure systeme ;
  /// les tests passent une horloge figee pour que le calage sur le
  /// lundi ne depende plus du jour ou tourne la suite (un test lance
  /// un dimanche a 23h59 basculait de semaine sans raison).
  ResumeHebdoService(this._db, {DateTime Function() now = DateTime.now})
      : _now = now;

  final AppDatabase _db;

  /// Source de l'heure courante. Ne jamais rappeler `DateTime.now()`
  /// directement dans ce service : passer par `_now()`.
  final DateTime Function() _now;

  /// Calcule le resume pour la semaine contenant [reference] (par
  /// defaut : maintenant). La semaine commence le lundi 00:00:00.
  ///
  /// [reference] sert au lundi-calage : si on appelle avec un mardi,
  /// on resume la semaine "lundi-dimanche" qui contient ce mardi.
  /// Pour la semaine derniere, passer une reference reculee de 7 jours
  /// (`maintenant - Duration(days: 7)`).
  Future<ResumeHebdo> computeWeek({DateTime? reference}) async {
    final ref = reference ?? _now();
    final lundi = weekStart(ref);
    final dimancheFin = lundi.add(const Duration(days: 7));

    // Charge tournees + stops de la semaine
    final current = await _loadWindow(lundi, dimancheFin);
    // Charge la semaine precedente pour le comparatif
    final lundiPrec = lundi.subtract(const Duration(days: 7));
    final previous = await _loadWindow(lundiPrec, lundi);

    return ResumeHebdo._(
      semaineDebut: lundi,
      semaineFin: dimancheFin.subtract(const Duration(seconds: 1)),
      current: current,
      previous: previous,
    );
  }

  /// Charge les tournees datees dans [start, end[ + tous leurs stops.
  /// Filtre cote SQL pour eviter de charger 1 an d'historique en RAM.
  Future<_WindowData> _loadWindow(DateTime start, DateTime end) async {
    final tournees = await (_db.select(_db.tournees)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(start) &
              t.date.isSmallerThanValue(end)))
        .get();
    if (tournees.isEmpty) return const _WindowData(tournees: [], stops: []);
    final ids = tournees.map((t) => t.id).toList();
    final stops = await (_db.select(_db.stops)
          ..where((s) => s.tourneeId.isIn(ids)))
        .get();
    return _WindowData(tournees: tournees, stops: stops);
  }

  /// Renvoie le lundi 00:00:00 de la semaine contenant [d]. Si [d]
  /// est deja un lundi, renvoie ce lundi a 00:00.
  ///
  /// Convention ISO 8601 : DateTime.weekday vaut 1 pour lundi, 7 pour
  /// dimanche. On soustrait (weekday - 1) jours, et on tronque l'heure.
  static DateTime weekStart(DateTime d) {
    final daysFromMonday = d.weekday - 1;
    final lundi = DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: daysFromMonday));
    return lundi;
  }
}

/// Snapshot immuable d'une semaine (carte Trello #101).
class ResumeHebdo {
  ResumeHebdo._({
    required this.semaineDebut,
    required this.semaineFin,
    required _WindowData current,
    required _WindowData previous,
  })  : _current = current,
        _previous = previous,
        _agg = _Aggregates.from(current),
        _aggPrev = _Aggregates.from(previous);

  /// Lundi 00:00 de la semaine courante.
  final DateTime semaineDebut;

  /// Dimanche 23:59:59 de la semaine courante.
  final DateTime semaineFin;

  final _WindowData _current;
  // ignore: unused_field
  final _WindowData _previous;
  final _Aggregates _agg;
  final _Aggregates _aggPrev;

  /// Liste des tournees realisees cette semaine, triees par date asc.
  List<Tournee> get tournees {
    final sorted = [..._current.tournees];
    sorted.sort((a, b) => a.date.compareTo(b.date));
    return sorted;
  }

  /// Map stopId -> Stop pour acces rapide depuis l'UI si besoin.
  List<Stop> get stops => _current.stops;

  /// Indique si la semaine est vide (aucune tournee planifiee).
  bool get isEmpty => _current.tournees.isEmpty;

  int get nbTournees => _agg.nbTournees;
  int get nbTourneesTerminees => _agg.nbTourneesTerminees;
  int get nbStops => _agg.nbStops;
  int get nbLivres => _agg.nbLivres;
  int get nbEchecs => _agg.nbEchecs;
  int get nbColisLivres => _agg.nbColisLivres;
  int get distanceMeters => _agg.distanceMeters;
  int get durationSeconds => _agg.durationSeconds;

  /// Taux de reussite : livres / (livres + echecs). 0 si rien valide.
  double get tauxReussite => _agg.tauxReussite;

  /// Top [limit] clients par nombre de livraisons reussies sur la
  /// semaine. Filtres : stops `livre` avec `nomClient` non-null/empty.
  List<({String nomClient, int nbLivraisons, int nbColis})> topClients({
    int limit = 3,
  }) {
    final byClient = <String, ({int nbLivraisons, int nbColis})>{};
    for (final s in _current.stops) {
      if (s.statutLivraison != 'livre') continue;
      final nom = s.nomClient?.trim();
      if (nom == null || nom.isEmpty) continue;
      final prev = byClient[nom];
      byClient[nom] = (
        nbLivraisons: (prev?.nbLivraisons ?? 0) + 1,
        nbColis: (prev?.nbColis ?? 0) + s.nbColis,
      );
    }
    final entries = byClient.entries.toList()
      ..sort((a, b) => b.value.nbLivraisons.compareTo(a.value.nbLivraisons));
    return entries
        .take(limit)
        .map((e) => (
              nomClient: e.key,
              nbLivraisons: e.value.nbLivraisons,
              nbColis: e.value.nbColis,
            ))
        .toList(growable: false);
  }

  /// Coequipier le plus actif (par nb livres) ou null si solo (que la
  /// cle null = Noah). Retourne (coequipierId, nbLivres) -- l'UI
  /// resoudra le nom via le repository.
  ({int? coequipierId, int nbLivres})? coequipierLePlusActif() {
    final byCoequipier = <int?, int>{};
    for (final s in _current.stops) {
      if (s.statutLivraison != 'livre') continue;
      byCoequipier[s.coequipierId] =
          (byCoequipier[s.coequipierId] ?? 0) + 1;
    }
    if (byCoequipier.isEmpty) return null;
    // Si seul Noah (cle null), pas de "plus actif" pertinent
    final hasAnyCoequipier = byCoequipier.keys.any((k) => k != null);
    if (!hasAnyCoequipier) return null;
    final entries = byCoequipier.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return (coequipierId: entries.first.key, nbLivres: entries.first.value);
  }

  /// Liste des alertes detectees (echecs anormaux, retards). Une
  /// alerte par tournee max, format string court. Vide si tout est OK.
  ///
  /// Heuristiques (volontairement simples pour la v1) :
  /// - Si tauxReussite < 70% : "Taux echec eleve"
  /// - Si nbEchecs >= 5 dans une seule tournee : "Tournee XXXX : 5+ echecs"
  List<String> alertes() {
    final out = <String>[];
    if (tauxReussite < 0.7 && (nbLivres + nbEchecs) > 0) {
      out.add(
        'Taux reussite faible : ${(tauxReussite * 100).round()}% '
        '(< 70% seuil)',
      );
    }
    // Echecs par tournee
    final echecsByTournee = <int, int>{};
    for (final s in _current.stops) {
      if (s.statutLivraison == 'echec') {
        echecsByTournee[s.tourneeId] =
            (echecsByTournee[s.tourneeId] ?? 0) + 1;
      }
    }
    final nomById = {for (final t in _current.tournees) t.id: t.nom};
    for (final entry in echecsByTournee.entries) {
      if (entry.value >= 5) {
        final nom = nomById[entry.key] ?? 'Tournee #${entry.key}';
        out.add('$nom : ${entry.value} echecs');
      }
    }
    return out;
  }

  /// Variation en % pour une metrique vs semaine precedente. Renvoie
  /// `null` si la semaine precedente est nulle sur cette metrique
  /// (division impossible -- l'UI affichera "—").
  double? variationVsPrev(String metric) {
    final cur = _agg.metric(metric);
    final prev = _aggPrev.metric(metric);
    if (prev == 0) return null;
    return (cur - prev) / prev;
  }

  /// Valeur brute de la semaine precedente (pour comparaison UI).
  num? previousValue(String metric) {
    final v = _aggPrev.metric(metric);
    if (_previous.tournees.isEmpty) return null;
    return v;
  }
}

class _WindowData {
  const _WindowData({required this.tournees, required this.stops});
  final List<Tournee> tournees;
  final List<Stop> stops;
}

class _Aggregates {
  const _Aggregates({
    required this.nbTournees,
    required this.nbTourneesTerminees,
    required this.nbStops,
    required this.nbLivres,
    required this.nbEchecs,
    required this.nbColisLivres,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  factory _Aggregates.from(_WindowData w) {
    final livres = w.stops.where((s) => s.statutLivraison == 'livre');
    final echecs = w.stops.where((s) => s.statutLivraison == 'echec');
    return _Aggregates(
      nbTournees: w.tournees.length,
      nbTourneesTerminees:
          w.tournees.where((t) => t.statut == 'terminee').length,
      nbStops: w.stops.length,
      nbLivres: livres.length,
      nbEchecs: echecs.length,
      nbColisLivres: livres.fold<int>(0, (sum, s) => sum + s.nbColis),
      distanceMeters:
          w.tournees.fold<int>(0, (sum, t) => sum + (t.distanceTotaleM ?? 0)),
      durationSeconds:
          w.tournees.fold<int>(0, (sum, t) => sum + (t.dureeTotaleS ?? 0)),
    );
  }

  final int nbTournees;
  final int nbTourneesTerminees;
  final int nbStops;
  final int nbLivres;
  final int nbEchecs;
  final int nbColisLivres;
  final int distanceMeters;
  final int durationSeconds;

  double get tauxReussite {
    final total = nbLivres + nbEchecs;
    if (total == 0) return 0;
    return nbLivres / total;
  }

  num metric(String name) {
    return switch (name) {
      'tournees' => nbTournees,
      'colis_livres' => nbColisLivres,
      'nb_livres' => nbLivres,
      'nb_echecs' => nbEchecs,
      'distance_m' => distanceMeters,
      'duree_s' => durationSeconds,
      _ => throw ArgumentError('Metric inconnue : $name'),
    };
  }
}
