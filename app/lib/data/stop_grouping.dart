import '../utils/text_normalize.dart';
import 'database.dart';
import 'geo_utils.dart';

/// Groupage des stops d'une tournee qui partagent la meme adresse /
/// le meme immeuble : un seul stationnement, plusieurs destinataires.
/// Carte #282.
///
/// Strategie : 2 stops sont consideres "au meme endroit" si :
/// - ils ont tous deux lat/lng et leur distance haversine est < 50 m
/// - OU leur adresse normalisee (lowercase + trim) est identique
///
/// Retourne une liste de groupes. Un groupe = 1 stop ou plus. L'ordre
/// est preserve : le 1er stop d'un groupe est celui qui apparait en
/// premier dans la liste d'entree.
class StopGrouping {
  StopGrouping._();

  /// Seuil de proximite GPS pour considerer 2 stops comme au meme
  /// endroit (50 m = un immeuble / une rue courte).
  static const double sameSpotMeters = 50;

  static List<List<Stop>> compute(List<Stop> stops) {
    final groups = <List<Stop>>[];
    for (final s in stops) {
      // Cherche un groupe existant qui matche
      var added = false;
      for (final g in groups) {
        if (_sameSpot(s, g.first)) {
          g.add(s);
          added = true;
          break;
        }
      }
      if (!added) groups.add([s]);
    }
    return groups;
  }

  static bool _sameSpot(Stop a, Stop b) {
    if (a.lat != null && a.lng != null && b.lat != null && b.lng != null) {
      final d = GeoUtils.haversineMeters(
        lat1: a.lat!,
        lon1: a.lng!,
        lat2: b.lat!,
        lon2: b.lng!,
      );
      if (d < sameSpotMeters) return true;
    }
    // normalizeKey (et pas normalizeText) : reprend a l'identique le
    // comportement d'avant la factorisation (trim + minuscules +
    // espaces aplatis, accents CONSERVES). Passer a normalizeText
    // regrouperait "rue de Luce" avec "rue de Lucé" : ce serait un
    // changement de comportement, pas une simple factorisation.
    final na = normalizeKey(a.adresseBrute);
    final nb = normalizeKey(b.adresseBrute);
    return na.isNotEmpty && na == nb;
  }
}
