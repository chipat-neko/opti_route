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
/// Parcourt les arrets de la tournee qui ont `lat == null`, retape
/// chaque `adresseBrute` dans le geocoder cascade (BAN/SIRENE/Photon),
/// et update les coords pour le premier resultat trouve.
class StopsGeocodeRetryService {
  StopsGeocodeRetryService({
    required this.repo,
    required this.geocoder,
  });

  final StopsRepository repo;
  final GeocodingService geocoder;

  /// Pour chaque arret de [tourneeId] sans coords, tente un geocodage.
  /// Met a jour le stop si trouve. Retourne un bilan structure.
  Future<BatchGeocodeResult> retryFor(int tourneeId) async {
    final all = await repo.getByTournee(tourneeId);
    final missing = all.where((s) => s.lat == null || s.lng == null).toList();

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
