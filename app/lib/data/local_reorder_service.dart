import 'database.dart';
import 'geo_utils.dart';
import 'stops_repository.dart';
import 'tournees_repository.dart';

/// Re-ordonnancement LOCAL des arrets d'une tournee via heuristique
/// **nearest-neighbor** (vol d'oiseau, haversine). Zero appel reseau,
/// zero quota consomme.
///
/// L'algo nearest-neighbor n'est PAS optimal (~ 25 % de detour en plus
/// que VROOM dans le pire cas) mais donne un ordre raisonnable
/// instantanement. Sert a maintenir la liste d'arrets visuellement
/// triee a chaque ajout/suppression, avant que l'utilisateur ne lance
/// la vraie optimisation VROOM/ORS qui prend en compte les routes
/// reelles et les fenetres horaires.
///
/// Respecte les contraintes de priorite :
/// - `obligatoire_premier` : place en debut, ordre figue par
///   `ordrePriorite` (1, 2, 3 dans le groupe)
/// - `flexible`            : passe au nearest-neighbor
/// - `obligatoire_dernier` : place en fin, ordre figue par `ordrePriorite`
/// - `eviter`              : tout a la fin, ordre stable par id
///
/// Les arrets sans coordonnees (lat/lng null, ex: ajoutes hors-ligne
/// avant geocodage) sont ignores pour le calcul mais conserves a leur
/// position id-asc en fin de liste.
class LocalReorderService {
  LocalReorderService(this._stopsRepo, this._tourneesRepo);

  final StopsRepository _stopsRepo;
  final TourneesRepository _tourneesRepo;

  /// Recharge la tournee + ses stops, calcule un nouvel ordre, et
  /// l'applique en transaction. Idempotent : si rien n'a change,
  /// reapplique le meme ordre (cout : 1 update / stop, negligeable).
  Future<void> reorder(int tourneeId) async {
    final tournee = await _tourneesRepo.getById(tourneeId);
    if (tournee == null) return;
    final stops = await _stopsRepo.getByTournee(tourneeId);
    if (stops.length < 2) return; // 0 ou 1 stop : rien a re-ordonner
    final ordered = computeOrder(
      tournee: tournee,
      stops: stops,
    );
    await _stopsRepo.applyOptimizedOrder(ordered);
  }

  /// Variante pure (sans I/O), exposee pour les tests unitaires.
  /// Retourne les ids des stops dans l'ordre de visite recommande.
  static List<int> computeOrder({
    required Tournee tournee,
    required List<Stop> stops,
  }) {
    // 1. Separe par priorite.
    final premiers = <Stop>[];
    final flexibles = <Stop>[];
    final derniers = <Stop>[];
    final eviter = <Stop>[];
    final sansCoords = <Stop>[];

    for (final s in stops) {
      if (s.lat == null || s.lng == null) {
        sansCoords.add(s);
        continue;
      }
      switch (s.priorite) {
        case 'obligatoire_premier':
          premiers.add(s);
        case 'obligatoire_dernier':
          derniers.add(s);
        case 'eviter':
          eviter.add(s);
        default:
          flexibles.add(s);
      }
    }

    // 2. Tri stable des groupes a ordre fige (premier / dernier).
    premiers.sort(_compareOrdrePriorite);
    derniers.sort(_compareOrdrePriorite);
    // "eviter" garde l'ordre de creation (id ascendant) pour stabilite.
    eviter.sort((a, b) => a.id.compareTo(b.id));

    // 3. Nearest-neighbor sur les flexibles, en partant :
    //    - du dernier point du groupe "premier" s'il existe
    //    - sinon du depot de la tournee
    final startLat = premiers.isNotEmpty
        ? premiers.last.lat!
        : tournee.pointDepartLat;
    final startLng = premiers.isNotEmpty
        ? premiers.last.lng!
        : tournee.pointDepartLng;
    final flexiblesOrdered =
        _nearestNeighbor(start: (startLat, startLng), stops: flexibles);

    // 4. Concatene : premiers + flexibles(NN) + derniers + eviter +
    //    sans-coords (ces derniers a la fin, l'utilisateur les
    //    geocodera plus tard).
    return [
      ...premiers.map((s) => s.id),
      ...flexiblesOrdered.map((s) => s.id),
      ...derniers.map((s) => s.id),
      ...eviter.map((s) => s.id),
      ...sansCoords.map((s) => s.id),
    ];
  }

  /// Compare deux stops par `ordrePriorite` (null > non-null pour eviter
  /// que les non-renseignes ne se mettent devant les renseignes). Tie-break
  /// sur `id` pour rester stable.
  static int _compareOrdrePriorite(Stop a, Stop b) {
    final aa = a.ordrePriorite;
    final bb = b.ordrePriorite;
    if (aa != null && bb != null) {
      final cmp = aa.compareTo(bb);
      if (cmp != 0) return cmp;
    } else if (aa != null) {
      return -1;
    } else if (bb != null) {
      return 1;
    }
    return a.id.compareTo(b.id);
  }

  /// Algo glouton : depuis [start], a chaque etape on prend le stop
  /// restant le plus proche (haversine). Complexite O(n^2), pour n=50
  /// stops = 2500 comparaisons = < 1 ms sur un phone moyen.
  static List<Stop> _nearestNeighbor({
    required (double, double) start,
    required List<Stop> stops,
  }) {
    if (stops.isEmpty) return const [];
    final remaining = List<Stop>.of(stops);
    final ordered = <Stop>[];
    var curLat = start.$1;
    var curLng = start.$2;
    while (remaining.isNotEmpty) {
      var bestIdx = 0;
      var bestDist = double.infinity;
      for (var i = 0; i < remaining.length; i++) {
        final s = remaining[i];
        final d = GeoUtils.haversineMeters(
          lat1: curLat,
          lon1: curLng,
          lat2: s.lat!,
          lon2: s.lng!,
        );
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      final picked = remaining.removeAt(bestIdx);
      ordered.add(picked);
      curLat = picked.lat!;
      curLng = picked.lng!;
    }
    return ordered;
  }
}
