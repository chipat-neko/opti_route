import 'package:drift/drift.dart' show OrderingTerm;

import 'database.dart';
import 'geocoding_service.dart';
import 'stops_repository.dart';

/// Resultat d'une session de re-geocodage des arrets sans coordonnees.
class BatchGeocodeResult {
  const BatchGeocodeResult({
    required this.totalCandidats,
    required this.resolved,
    required this.unresolved,
  });

  /// Nombre d'arrets sans coords qu'on a essaye de geocoder.
  final int totalCandidats;

  /// Liste des Stops effectivement geocodes (avec leurs nouvelles coords).
  final List<Stop> resolved;

  /// Liste des Stops pour lesquels aucune adresse n'a ete trouvee.
  final List<Stop> unresolved;
}

/// Service de re-geocodage des arrets sauves en mode hors-ligne.
/// Parcourt les arrets qui ont `lat == null`, retape chaque
/// `adresseBrute` dans le geocoder cascade (BAN/SIRENE/Photon),
/// et update les coords pour le premier resultat trouve.
///
/// Utilise dans 2 contextes :
/// 1. **Manuel** : bouton "Geolocaliser hors-ligne" du menu Plus
///    d'une tournee -> appelle [retryFor] sur la tournee courante.
/// 2. **Automatique** : `OfflineGeocodeAutomation` ecoute la
///    connectivite et appelle [retryAllPending] au retour du reseau.
class StopsGeocodeRetryService {
  StopsGeocodeRetryService({
    required this.repo,
    required this.geocoder,
    required this.db,
  });

  final StopsRepository repo;
  final GeocodingService geocoder;
  final AppDatabase db;

  /// Pour chaque arret de [tourneeId] sans coords, tente un geocodage.
  /// Met a jour le stop si trouve. Retourne un bilan structure.
  Future<BatchGeocodeResult> retryFor(int tourneeId) async {
    final all = await repo.getByTournee(tourneeId);
    final missing = all.where((s) => s.lat == null || s.lng == null).toList();
    return _processStops(missing);
  }

  /// Retente le geocodage de **tous** les arrets sans coords, toutes
  /// tournees confondues. Sert au retry automatique declenche par le
  /// retour de connectivite : on tente partout, pas juste sur l'ecran
  /// ou l'utilisateur se trouve.
  ///
  /// Trie par `creeLe DESC` pour traiter les plus recents en premier
  /// (les arrets ajoutes a la derniere tournee sont prioritaires sur
  /// d'eventuels stops orphelins d'anciennes tournees).
  ///
  /// Note : on filtre uniquement sur `lat IS NULL` (et pas `lng`) car
  /// les 2 colonnes sont **toujours** null/non-null ensemble. Le code
  /// d'insertion les pose conjointement, jamais une seule des deux.
  Future<BatchGeocodeResult> retryAllPending() async {
    final all = await (db.select(db.stops)
          ..where((s) => s.lat.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.creeLe)]))
        .get();
    return _processStops(all);
  }

  /// Compte le nombre d'arrets en attente de geocodage. Sert au badge
  /// UI "N arrets sans GPS".
  Future<int> countPending() async {
    final stops = await (db.select(db.stops)
          ..where((s) => s.lat.isNull()))
        .get();
    return stops.length;
  }

  /// Logique commune entre retryFor / retryAllPending : itere sur la
  /// liste, tente le geocodage, update les coords si succes. Continue
  /// meme si un stop echoue (best-effort).
  Future<BatchGeocodeResult> _processStops(List<Stop> missing) async {
    final resolved = <Stop>[];
    final unresolved = <Stop>[];

    for (final stop in missing) {
      try {
        final suggestions = await geocoder.search(stop.adresseBrute, limit: 1);
        if (suggestions.isEmpty) {
          unresolved.add(stop);
          continue;
        }
        final s = suggestions.first;
        await repo.updateCoords(
          stopId: stop.id,
          lat: s.lat,
          lng: s.lon,
          adresseNormalisee: s.adressePostale,
        );
        resolved.add(stop);
      } catch (_) {
        // Erreur reseau, timeout, etc. : on considere l'arret comme
        // non resolu et on continue avec le suivant pour ne pas tout
        // bloquer.
        unresolved.add(stop);
      }
    }

    return BatchGeocodeResult(
      totalCandidats: missing.length,
      resolved: resolved,
      unresolved: unresolved,
    );
  }
}
