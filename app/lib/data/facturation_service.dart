import 'package:drift/drift.dart';

import 'database.dart';
import 'parametres_repository.dart';

/// Service de facturation mensuelle indicative.
///
/// Genere un recap "X tournees, Y arrets livres, Z km parcourus, cout
/// estime carburant" sur une periode donnee. Sert au livreur
/// independant qui veut savoir combien il a "gagne" en valeur de service
/// pour facturer son client donneur d'ordre.
///
/// **NB** : ce n'est PAS une vraie facture comptable (pas de TVA, pas
/// d'IBAN, pas de mentions legales obligatoires). C'est un recap
/// d'activite pour negociation tarifaire ou auto-controle. Pour la
/// vraie facturation, exporter en CSV et passer dans Pennylane / Sage.
class FacturationService {
  FacturationService(this._db, this._parametres);

  final AppDatabase _db;
  final ParametresRepository _parametres;

  /// Calcule la synthese facturable sur la periode `[since, until]`.
  /// Inclut uniquement les tournees `terminee` pour eviter d'inclure
  /// des donnees provisoires d'une tournee en cours.
  Future<FactureMensuelle> calculer({
    required DateTime since,
    required DateTime until,
    int? coequipierIdFilter,
    double? tarifParArretEur,
    double? tarifParColisEur,
    double? tarifKilometriqueEur,
  }) async {
    // Filtre les tournees datees dans la fenetre + terminees.
    final tournees = await (_db.select(_db.tournees)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(since) &
              t.date.isSmallerThanValue(until) &
              t.statut.equals('terminee')))
        .get();
    if (tournees.isEmpty) {
      return FactureMensuelle.empty(since: since, until: until);
    }

    final tourneeIds = tournees.map((t) => t.id).toList();
    var stops = await (_db.select(_db.stops)
          ..where((s) => s.tourneeId.isIn(tourneeIds)))
        .get();
    if (coequipierIdFilter != null) {
      stops = stops
          .where((s) => s.coequipierId == coequipierIdFilter)
          .toList();
    } else {
      // Sans filtre coequipier : on inclut tout (Moi + tous)
    }

    final livres = stops.where((s) => s.statutLivraison == 'livre').toList();
    final nbArretsLivres = livres.length;
    final nbColisLivres = livres.fold<int>(0, (acc, s) => acc + s.nbColis);
    final distanceTotaleM =
        tournees.fold<int>(0, (acc, t) => acc + (t.distanceTotaleM ?? 0));
    final kmTotal = distanceTotaleM / 1000.0;

    // Cout carburant estime via parametres.
    final coutCarburant =
        await _parametres.estimerCoutCarburant(distanceMeters: distanceTotaleM);

    // Calcul facturable selon tarifs fournis (tous optionnels).
    final mtArrets = (tarifParArretEur ?? 0) * nbArretsLivres;
    final mtColis = (tarifParColisEur ?? 0) * nbColisLivres;
    final mtKm = (tarifKilometriqueEur ?? 0) * kmTotal;
    final totalHt = mtArrets + mtColis + mtKm;

    return FactureMensuelle(
      since: since,
      until: until,
      nbTournees: tournees.length,
      nbArretsLivres: nbArretsLivres,
      nbColisLivres: nbColisLivres,
      kmTotal: kmTotal,
      coutCarburantEur: coutCarburant,
      tarifParArretEur: tarifParArretEur ?? 0,
      tarifParColisEur: tarifParColisEur ?? 0,
      tarifKilometriqueEur: tarifKilometriqueEur ?? 0,
      mtArrets: mtArrets,
      mtColis: mtColis,
      mtKm: mtKm,
      totalHt: totalHt,
      margeBruteEstimee: totalHt - coutCarburant,
    );
  }
}

/// Aggregat de facturation immutable.
class FactureMensuelle {
  const FactureMensuelle({
    required this.since,
    required this.until,
    required this.nbTournees,
    required this.nbArretsLivres,
    required this.nbColisLivres,
    required this.kmTotal,
    required this.coutCarburantEur,
    required this.tarifParArretEur,
    required this.tarifParColisEur,
    required this.tarifKilometriqueEur,
    required this.mtArrets,
    required this.mtColis,
    required this.mtKm,
    required this.totalHt,
    required this.margeBruteEstimee,
  });

  /// Constructeur "rien sur la periode" : evite d'avoir a checker
  /// null cote UI.
  factory FactureMensuelle.empty({
    required DateTime since,
    required DateTime until,
  }) {
    return FactureMensuelle(
      since: since,
      until: until,
      nbTournees: 0,
      nbArretsLivres: 0,
      nbColisLivres: 0,
      kmTotal: 0,
      coutCarburantEur: 0,
      tarifParArretEur: 0,
      tarifParColisEur: 0,
      tarifKilometriqueEur: 0,
      mtArrets: 0,
      mtColis: 0,
      mtKm: 0,
      totalHt: 0,
      margeBruteEstimee: 0,
    );
  }

  final DateTime since;
  final DateTime until;
  final int nbTournees;
  final int nbArretsLivres;
  final int nbColisLivres;
  final double kmTotal;
  final double coutCarburantEur;
  final double tarifParArretEur;
  final double tarifParColisEur;
  final double tarifKilometriqueEur;
  final double mtArrets;
  final double mtColis;
  final double mtKm;
  final double totalHt;

  /// Marge brute = total facturable - cout carburant. Pas un benefice
  /// net (manque salaires, vehicule, assurance...) mais donne une
  /// premiere idee.
  final double margeBruteEstimee;

  bool get isEmpty => nbTournees == 0;
}
