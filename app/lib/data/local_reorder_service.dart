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
    final flexiblesNN =
        _nearestNeighbor(start: (startLat, startLng), stops: flexibles);

    // 3b. Amelioration 2-opt : NN seul donne ~15-25% de detour vs
    //     optimal. Le 2-opt inverse iterativement des sous-segments
    //     pour reduire la longueur totale. Gain typique : -10% a
    //     -15% supplementaire, et converge en 2-3 passes pour les
    //     tournees Noah-sized (10-50 stops). Toujours local, O(n^2)
    //     par passe = <5ms sur phone moyen pour 50 stops.
    //
    //     End point pour le 2-opt : si "derniers" existe, on s'arrete
    //     juste avant le 1er d'entre eux (le NN a deja calcule l'ordre
    //     en partant du depart et en finissant librement, mais le
    //     2-opt veut savoir vers ou il "sort" pour comparer les bords).
    //     Sinon, pas de retour fixe (mode tournee aller-simple sans
    //     boucle, ce qui est le cas Noah).
    (double, double)? endHint;
    if (derniers.isNotEmpty) {
      endHint = (derniers.first.lat!, derniers.first.lng!);
    }
    final flexiblesOrdered = _twoOpt(
      start: (startLat, startLng),
      end: endHint,
      stops: flexiblesNN,
    );

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

  /// Amelioration **2-opt** d'un ordre existant (typiquement le sortie
  /// du nearest-neighbor). Inverse iterativement des sous-segments
  /// `[i..j]` quand l'inversion reduit la distance totale.
  ///
  /// Le 2-opt garantit un minimum local : a la fin, aucune inversion
  /// de segment n'ameliore plus. Gain typique vs NN seul : -10 a -15 %
  /// de distance totale.
  ///
  /// Complexite : O(n^2) par passe, O(n^2 * iter) au total. Pour
  /// n=50 stops et iter=5 (cas moyen), ~12500 ops = < 5 ms sur phone.
  /// `maxIterations` capte un fallback en cas d'oscillation (rare avec
  /// l'amelioration stricte `delta < -epsilon`).
  ///
  /// Bord externes :
  /// - [start] : point d'ou on arrive sur le 1er stop de la liste.
  /// - [end] : point ou on va apres le dernier stop (null = pas de
  ///   retour fixe, on ignore l'edge de sortie).
  ///
  /// **Invariant** : l'inversion d'un segment [i..j] ne change PAS
  /// la somme des distances intra-segment (on parcourt les memes
  /// aretes en sens inverse). Donc seul l'effet sur les 2 aretes
  /// "bords" `(stops[i-1] -> stops[i])` et `(stops[j] -> stops[j+1])`
  /// compte. Ca permet une comparaison delta en O(1) par paire.
  static List<Stop> _twoOpt({
    required (double, double) start,
    required (double, double)? end,
    required List<Stop> stops,
    int maxIterations = 100,
  }) {
    // Pour n < 4, 2-opt n'a aucun degre de liberte utile (le seul
    // segment inversable est la liste entiere, ce que NN aurait deja
    // capture s'il etait meilleur de partir vers l'autre cote).
    if (stops.length < 4) return stops;

    final current = List<Stop>.of(stops);
    const epsilon = 1e-6;

    // Helper : distance haversine entre 2 points (lat, lng).
    double dist((double, double) a, (double, double) b) =>
        GeoUtils.haversineMeters(
          lat1: a.$1,
          lon1: a.$2,
          lat2: b.$1,
          lon2: b.$2,
        );

    (double, double) coords(Stop s) => (s.lat!, s.lng!);

    bool improved = true;
    var iter = 0;
    while (improved && iter < maxIterations) {
      improved = false;
      iter++;
      // i parcourt de 0 a length-2, j de i+1 a length-1.
      // L'inversion swap les 2 aretes bords (prev->cur[i]) et
      // (cur[j]->next).
      for (var i = 0; i < current.length - 1; i++) {
        for (var j = i + 1; j < current.length; j++) {
          final prev = i == 0 ? start : coords(current[i - 1]);
          final ci = coords(current[i]);
          final cj = coords(current[j]);
          final next = j == current.length - 1
              ? end
              : coords(current[j + 1]);
          final beforeLeft = dist(prev, ci);
          final afterLeft = dist(prev, cj);
          double beforeRight = 0;
          double afterRight = 0;
          if (next != null) {
            beforeRight = dist(cj, next);
            afterRight = dist(ci, next);
          }
          final delta =
              (afterLeft + afterRight) - (beforeLeft + beforeRight);
          if (delta < -epsilon) {
            // Reverse segment [i..j] in place.
            var lo = i;
            var hi = j;
            while (lo < hi) {
              final tmp = current[lo];
              current[lo] = current[hi];
              current[hi] = tmp;
              lo++;
              hi--;
            }
            improved = true;
          }
        }
      }
    }
    return current;
  }
}
