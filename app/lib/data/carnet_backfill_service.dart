import 'package:drift/drift.dart';

import 'database.dart';
import 'saved_destinations_repository.dart';

/// Resultat d'un backfill du carnet d'adresses depuis l'historique des
/// tournees. Indique combien de stops ont ete scannes, combien d'entrees
/// ont ete creees vs fusionnees avec un client existant, et combien ont
/// ete skipees (lat/lng manquants).
class CarnetBackfillResult {
  const CarnetBackfillResult({
    required this.totalStops,
    required this.created,
    required this.merged,
    required this.skipped,
  });

  /// Nombre total de stops parcourus dans la DB.
  final int totalStops;

  /// Nouvelles entrees ajoutees au carnet.
  final int created;

  /// Stops qui matchent une entree carnet existante (meme nomClient ou
  /// meme coords ~11 m). On a juste incremente le useCount.
  final int merged;

  /// Stops skipes : lat/lng null (jamais geocodes) OU adresse vide.
  final int skipped;

  /// True si quelque chose a ete fait (utile pour decider d'afficher
  /// un toast "rien a importer" ou un resume).
  bool get hasActivity => created + merged + skipped > 0;
}

/// Service qui peuple le carnet d'adresses ([SavedDestinations]) depuis
/// l'historique des [Stops] deja faits (toutes tournees confondues).
///
/// Use case Noah : alimenter rapidement la memoire client (cf
/// [ClientMemoryService]) sans avoir a re-livrer 100 fois les memes
/// adresses. Marche pour tous les stops qui ont deja ete geocodes
/// (lat/lng non null), peu importe leur statut (a_livrer / livre /
/// echec) : on prend toutes les adresses connues.
///
/// **Idempotent** : appelable plusieurs fois sans creer de doublons,
/// car [SavedDestinationsRepository.upsertFromValidatedStop] gere la
/// dedup par nomClient + proximite GPS.
class CarnetBackfillService {
  CarnetBackfillService(this._db, this._repo);

  final AppDatabase _db;
  final SavedDestinationsRepository _repo;

  /// Parcourt TOUS les stops de la DB qui ont des coords valides et
  /// upsert chacun dans le carnet. Retourne un resume comptable.
  ///
  /// Performance : O(N) avec 1 query select + 1 upsert par stop. Pour
  /// 1000 stops, compte ~3-5s sur un Xiaomi moyen. Pas de progress
  /// callback pour V1 (le caller affiche juste un spinner).
  Future<CarnetBackfillResult> backfillFromStops() async {
    // SELECT * FROM stops WHERE lat IS NOT NULL AND lng IS NOT NULL
    final stops = await (_db.select(_db.stops)
          ..where((s) => s.lat.isNotNull() & s.lng.isNotNull()))
        .get();

    var created = 0;
    var merged = 0;
    var skipped = 0;

    for (final stop in stops) {
      // Adresse a afficher dans le carnet : la version normalisee si
      // dispo, sinon la version brute saisie.
      final addr = stop.adresseNormalisee ?? stop.adresseBrute;
      if (addr.isEmpty) {
        skipped++;
        continue;
      }
      if (stop.lat == null || stop.lng == null) {
        skipped++;
        continue;
      }
      // Snapshot du count avant pour savoir si upsert a cree une nouvelle
      // entree ou fusionne avec une existante. Pas optimal (2 queries/upsert)
      // mais le backfill est ponctuel donc OK.
      final before = await _repo.count();
      await _repo.upsertFromValidatedStop(
        nomClient: stop.nomClient,
        adresseDisplay: addr,
        lat: stop.lat!,
        lng: stop.lng!,
        // Stops n'a pas rue/cp/ville separes (juste adresseBrute/
        // adresseNormalisee), donc on ne renseigne pas ces champs.
        // La memoire client matchera par nom + coords proches.
      );
      final after = await _repo.count();
      if (after > before) {
        created++;
      } else {
        merged++;
      }
    }

    return CarnetBackfillResult(
      totalStops: stops.length,
      created: created,
      merged: merged,
      skipped: skipped,
    );
  }
}
