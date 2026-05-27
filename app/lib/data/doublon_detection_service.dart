import 'database.dart';
import 'geo_utils.dart';
import 'levenshtein.dart';

/// Une paire de fiches carnet suspectees d'etre des doublons, avec la
/// raison de la detection. [a] et [b] sont 2 [SavedDestination]
/// distinctes du carnet.
class DoublonPaire {
  const DoublonPaire({
    required this.a,
    required this.b,
    required this.raison,
    required this.distanceMeters,
  });

  final SavedDestination a;
  final SavedDestination b;

  /// Libelle court expliquant pourquoi la paire est suspectee.
  final String raison;

  /// Distance GPS entre les 2 fiches (metres). Sert au tri (les plus
  /// proches d'abord) et a l'affichage.
  final double distanceMeters;
}

/// Detecte les fiches clients en double dans le carnet (carte #103).
///
/// Heuristiques (la 1ere qui matche sur une paire l'emporte) :
/// 1. Nom similaire (Levenshtein <= 2, casse ignoree) ET GPS proche
///    (< 100 m) -> meme client, typo dans le nom.
/// 2. Meme adresse normalisee (rue+CP+ville, ou adresseDisplay) ->
///    meme lieu, peu importe le nom.
/// 3. Meme nom exact + meme ville -> meme client, GPS legerement
///    different (geocodage approximatif).
///
/// Fonction PURE : prend la liste des fiches, retourne les paires. O(n²)
/// sur le carnet (acceptable pour quelques centaines de fiches).
class DoublonDetectionService {
  DoublonDetectionService._();

  static const int kSeuilNomLevenshtein = 2;
  static const double kSeuilGpsMeters = 100;

  static String _norm(String? s) => (s ?? '').trim().toLowerCase();

  static List<DoublonPaire> detect(List<SavedDestination> entries) {
    final paires = <DoublonPaire>[];
    for (var i = 0; i < entries.length; i++) {
      for (var j = i + 1; j < entries.length; j++) {
        final a = entries[i];
        final b = entries[j];
        final raison = _raisonPour(a, b);
        if (raison != null) {
          paires.add(DoublonPaire(
            a: a,
            b: b,
            raison: raison,
            distanceMeters: GeoUtils.haversineMeters(
              lat1: a.lat,
              lon1: a.lng,
              lat2: b.lat,
              lon2: b.lng,
            ),
          ));
        }
      }
    }
    // Les plus proches geographiquement d'abord (doublons les plus surs).
    paires.sort((x, y) => x.distanceMeters.compareTo(y.distanceMeters));
    return paires;
  }

  /// Retourne la raison si [a] et [b] sont suspectees d'etre des
  /// doublons, sinon null.
  static String? _raisonPour(SavedDestination a, SavedDestination b) {
    final nomA = _norm(a.nomClient);
    final nomB = _norm(b.nomClient);
    final bothNamed = nomA.isNotEmpty && nomB.isNotEmpty;
    final distM = GeoUtils.haversineMeters(
      lat1: a.lat,
      lon1: a.lng,
      lat2: b.lat,
      lon2: b.lng,
    );

    // 1. Nom similaire + GPS proche.
    if (bothNamed &&
        distM < kSeuilGpsMeters &&
        Levenshtein.distance(nomA, nomB) <= kSeuilNomLevenshtein) {
      return 'Nom similaire + GPS proche (<100 m)';
    }

    // 2. Meme adresse.
    if (_memeAdresse(a, b)) {
      return 'Meme adresse';
    }

    // 3. Meme nom exact + meme ville.
    final villeA = _norm(a.ville);
    final villeB = _norm(b.ville);
    if (bothNamed &&
        nomA == nomB &&
        villeA.isNotEmpty &&
        villeA == villeB) {
      return 'Meme nom + meme ville';
    }

    return null;
  }

  static bool _memeAdresse(SavedDestination a, SavedDestination b) {
    // adresseDisplay identique (apres normalisation).
    final dispA = _norm(a.adresseDisplay);
    final dispB = _norm(b.adresseDisplay);
    if (dispA.isNotEmpty && dispA == dispB) return true;

    // Sinon rue + CP + ville tous renseignes et identiques.
    final rueA = _norm(a.rue);
    final rueB = _norm(b.rue);
    final cpA = _norm(a.codePostal);
    final cpB = _norm(b.codePostal);
    final villeA = _norm(a.ville);
    final villeB = _norm(b.ville);
    if (rueA.isEmpty || cpA.isEmpty || villeA.isEmpty) return false;
    return rueA == rueB && cpA == cpB && villeA == villeB;
  }
}
