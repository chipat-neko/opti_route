import 'bordereau_extraction.dart';
import 'database.dart';
import 'levenshtein.dart';
import 'saved_destinations_repository.dart';

/// Service de **memorisation des clients connus** : enrichit le resultat
/// OCR du parser local en cherchant un client similaire dans le carnet
/// d'adresses ([SavedDestinations]).
///
/// Workflow Sprint 2.A (audit refactor 2026-05-22) :
/// 1. Au scan bordereau, le parser local extrait un `nomDestinataire`
/// 2. Ce service fait un fuzzy match (Levenshtein) du nom contre tous
///    les `nomClient` du carnet
/// 3. Si match avec distance <= [maxDistance] (3 par defaut) OR ratio
///    de similarite >= [minRatio] (0.85 par defaut) :
///    -> retourne une [BordereauExtraction] enrichie avec :
///       - nom EXACT du carnet (corrige les fautes OCR)
///       - adresse complete (rue, cp, ville) du carnet (validee user)
///       - source = [ExtractionSource.clientMemory]
///       - confidence = high
/// 4. Sinon : retourne null et l'app garde le resultat OCR brut
///
/// **Apprentissage** : a chaque nouveau scan valide par l'utilisateur,
/// l'app appelle [SavedDestinationsRepository.upsertFromValidatedStop]
/// qui ajoute/incremente l'entree dans le carnet. Plus Noah utilise
/// l'app, plus la memoire grossit, plus les scans sont precis.
class ClientMemoryService {
  ClientMemoryService(this._repo);

  final SavedDestinationsRepository _repo;

  /// Distance Levenshtein max pour considerer un match. 3 par defaut
  /// (tolerant aux fautes OCR : "GARAGE LANCTIN" vs "GARAGE LANTCIN"
  /// = distance 2 -> match accepte).
  static const int defaultMaxDistance = 3;

  /// Ratio de similarite min (0..1). Sert pour les noms longs ou la
  /// distance absolue peut etre > 3 sans etre une faute (ex: "GARAGE
  /// LANCTIN DAMIEN" vs "GARAGE LANCTIN" -> distance 7 mais ratio
  /// 0.72 = pas un match). Si le ratio est >= [minRatio], on accepte.
  static const double defaultMinRatio = 0.85;

  /// Cherche un client connu dans le carnet qui matche fuzzy le nom
  /// fourni. Retourne null si aucun match au-dessus du seuil.
  ///
  /// Si [ville] est fourni, on boost la confiance des matches dont la
  /// ville correspond aussi (utile quand on a 2 clients de meme nom
  /// dans 2 villes differentes : GARAGE LANCTIN a Courville vs GARAGE
  /// LANCTIN a Nogent -> on prend celui de la bonne ville).
  Future<SavedDestination?> findSimilarClient(
    String nomDestinataire, {
    String? ville,
    int maxDistance = defaultMaxDistance,
    double minRatio = defaultMinRatio,
  }) async {
    final normalized = _normalize(nomDestinataire);
    if (normalized.length < 3) return null;

    // Recupere tout le carnet (taille typique < 1000 entrees, donc OK
    // de tout charger en memoire pour le fuzzy matching).
    final all = await _repo.getAll();
    if (all.isEmpty) return null;

    SavedDestination? best;
    int bestDist = 999;
    double bestRatio = 0;
    for (final d in all) {
      final candidate = d.nomClient;
      if (candidate == null || candidate.isEmpty) continue;
      final candNorm = _normalize(candidate);
      if (candNorm.length < 3) continue;
      final dist = Levenshtein.distance(normalized, candNorm);
      final maxLen = normalized.length > candNorm.length
          ? normalized.length
          : candNorm.length;
      final ratio = maxLen == 0 ? 0.0 : 1 - (dist / maxLen);
      // Critere d'acceptation : (distance <= max) OU (ratio >= min)
      final accepted = dist <= maxDistance || ratio >= minRatio;
      if (!accepted) continue;
      // Bonus ville : si la ville matche, on prefere ce candidat
      // (penalise les autres en augmentant artificiellement leur dist)
      var effectiveDist = dist;
      if (ville != null && d.ville != null) {
        if (_normalize(ville) == _normalize(d.ville!)) {
          effectiveDist = effectiveDist - 5; // bonus
        }
      }
      if (effectiveDist < bestDist) {
        best = d;
        bestDist = effectiveDist;
        bestRatio = ratio;
      } else if (effectiveDist == bestDist && ratio > bestRatio) {
        best = d;
        bestRatio = ratio;
      }
    }
    return best;
  }

  /// Si [extraction] a un nomDestinataire et qu'un client similaire
  /// existe dans le carnet, retourne une nouvelle extraction enrichie
  /// avec les infos du carnet (nom exact + adresse validee + source =
  /// clientMemory). Sinon retourne [extraction] inchangee.
  ///
  /// Garde le nbColis + telephone de l'extraction OCR (specifiques au
  /// scan courant). Override le nom + adresse (specifiques au client).
  Future<BordereauExtraction> enrichWithMemory(
    BordereauExtraction extraction,
  ) async {
    final nom = extraction.nomDestinataire;
    if (nom == null || nom.isEmpty) return extraction;
    final match = await findSimilarClient(
      nom,
      ville: extraction.ville,
    );
    if (match == null) return extraction;
    return BordereauExtraction(
      nomDestinataire: match.nomClient ?? nom,
      rue: match.rue ?? extraction.rue,
      codePostal: match.codePostal ?? extraction.codePostal,
      ville: match.ville ?? extraction.ville,
      telephone: extraction.telephone,
      nbColis: extraction.nbColis,
      confidence: ExtractionConfidence.high,
      format: extraction.format,
      source: ExtractionSource.clientMemory,
    );
  }

  /// Lowercase + strip diacritiques (compat avec [_normalize] du repo).
  static String _normalize(String s) {
    final lower = s.toLowerCase().trim();
    const map = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ÿ': 'y', 'ý': 'y',
      'ñ': 'n',
      'œ': 'oe', 'æ': 'ae',
    };
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }
}
