import 'database.dart';
import 'geo_utils.dart';

/// Calcul d'insertion d'un POI temporaire (carburant/poste/pharmacie)
/// dans l'ordre courant des arrets. Carte #299.
///
/// Strategie : on insere le POI dans la liste des `a_livrer` a l'index
/// qui minimise le detour total (point d'insertion ou la somme des
/// distances "stop precedent -> POI -> stop suivant" est la plus
/// faible). Pure fn.
class PoiDetour {
  PoiDetour._();

  /// Retourne l'index optimal d'insertion DANS [pending] (entre 0 et
  /// pending.length inclus). 0 = avant le 1er pending, length = apres le
  /// dernier.
  ///
  /// [origin] : point de depart actuel (typiquement la position GPS
  /// courante). [pending] = stops a livrer, dans l'ordre courant. [poi] =
  /// coords du POI a inserer.
  ///
  /// Les stops sans coordonnees ne peuvent pas participer au calcul du
  /// detour (on ignore ou ils sont) mais ils comptent dans l'index
  /// retourne : celui-ci se rapporte toujours a [pending] telle que
  /// l'appelant la connait. Avant ce remappage, l'index designait une
  /// position dans la liste filtree, donc un seul stop non geocode en
  /// amont suffisait a decaler l'insertion. Convention retenue : on
  /// insere juste AVANT le stop geocode retenu, ou en fin de liste si le
  /// POI vient apres le dernier d'entre eux.
  static int bestInsertionIndex({
    required (double lat, double lng) origin,
    required List<Stop> pending,
    required (double lat, double lng) poi,
  }) {
    // Index (dans `pending`) des stops exploitables pour le calcul.
    final geoIdx = <int>[];
    for (var i = 0; i < pending.length; i++) {
      final s = pending[i];
      if (s.lat != null && s.lng != null) geoIdx.add(i);
    }
    if (geoIdx.isEmpty) return 0;
    final geo = [for (final i in geoIdx) pending[i]];
    double bestDelta = double.infinity;
    int bestIdx = 0;
    // candidat : insertion a l'index i = entre geo[i-1] et geo[i].
    // origin avant geo[0], rien apres geo[last].
    for (var i = 0; i <= geo.length; i++) {
      final prev = i == 0
          ? origin
          : (geo[i - 1].lat!, geo[i - 1].lng!);
      final next = i == geo.length
          ? null
          : (geo[i].lat!, geo[i].lng!);
      final directBefore = next == null
          ? 0.0
          : GeoUtils.haversineMeters(
              lat1: prev.$1,
              lon1: prev.$2,
              lat2: next.$1,
              lon2: next.$2,
            );
      final viaPoiPrev = GeoUtils.haversineMeters(
        lat1: prev.$1,
        lon1: prev.$2,
        lat2: poi.$1,
        lon2: poi.$2,
      );
      final viaPoiNext = next == null
          ? 0.0
          : GeoUtils.haversineMeters(
              lat1: poi.$1,
              lon1: poi.$2,
              lat2: next.$1,
              lon2: next.$2,
            );
      final delta = (viaPoiPrev + viaPoiNext) - directBefore;
      if (delta < bestDelta) {
        bestDelta = delta;
        // Retour a l'index dans `pending` : devant le i-eme stop
        // geocode, ou en fin de liste s'il n'y en a plus apres.
        bestIdx = i == geo.length ? pending.length : geoIdx[i];
      }
    }
    return bestIdx;
  }
}
