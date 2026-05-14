import 'address_suggestion.dart';
import 'ban_geocoding_service.dart';
import 'bordereau_extraction.dart';
import 'levenshtein.dart';

/// Resultat de la validation d'un [BordereauExtraction] contre la BAN.
///
/// Le validateur prend l'extraction OCR brute, interroge la **Base
/// Adresse Nationale** (api-adresse.data.gouv.fr) et essaie de la
/// "valider" : confirmer qu'une adresse correspondant existe vraiment.
///
/// Si la BAN retourne une suggestion proche, on peut :
/// 1. **Corriger** la ville extraite (l'OCR avait "BORDEAUS" -> BAN
///    renvoie "BORDEAUX")
/// 2. **Pre-remplir** lat/lng dans l'arret (geocodage gratuit + cache)
/// 3. **Augmenter** la confiance affichee a l'utilisateur (carte verte
///    "Detection validee" au lieu de "Detection auto")
class BordereauValidationResult {
  const BordereauValidationResult({
    required this.extraction,
    required this.validated,
    this.banSuggestion,
    this.validationScore,
    this.correctionsApplied = const [],
  });

  /// L'extraction (possiblement corrigee a partir de la BAN).
  final BordereauExtraction extraction;

  /// True si la BAN a renvoye une adresse proche de l'extraction OCR.
  /// L'UI peut afficher une chip "Adresse validee BAN" emerald.
  final bool validated;

  /// Suggestion BAN la plus proche (si trouvee). Contient lat/lng
  /// utilisables pour pre-remplir le geocodage de l'arret.
  final AddressSuggestion? banSuggestion;

  /// Score de similarite Levenshtein entre l'adresse OCR et l'adresse
  /// BAN retournee, dans [0.0 (identique), 1.0 (totalement different)].
  /// Null si pas de validation tentee.
  final double? validationScore;

  /// Liste des corrections appliquees a l'extraction (pour debug et
  /// affichage UI "Ville corrigee : BORDEAUS -> BORDEAUX").
  final List<String> correctionsApplied;
}

/// Service qui valide / corrige une extraction OCR via la BAN.
///
/// Pas de side-effects : on lit la BAN, on retourne un resultat
/// enrichi. Le caller decide quoi faire (afficher chip validee,
/// pre-remplir lat/lng, etc.).
///
/// Injection du BanGeocodingService par le constructeur pour pouvoir
/// fournir un fake dans les tests sans appeler le vrai HTTP.
class BordereauValidator {
  BordereauValidator(this._ban);

  final BanGeocodingService _ban;

  /// Seuil Levenshtein normalise sous lequel on considere l'OCR et la
  /// BAN comme "raisonnablement similaires". 0.3 = on tolere ~30 %
  /// de differences (faute de frappe + petites variantes).
  static const _similarityThreshold = 0.3;

  /// Valide [extraction] contre la BAN.
  ///
  /// Retourne :
  /// - validated=false + extraction inchangee si extraction insuffisante
  ///   (pas de rue ni cp+ville exploitables), ou si BAN ne retourne rien,
  ///   ou si erreur reseau.
  /// - validated=true + extraction (possiblement corrigee) +
  ///   banSuggestion sinon.
  ///
  /// Best-effort : ne throw jamais, en cas d'erreur reseau on retourne
  /// juste validated=false (l'utilisateur peut quand meme utiliser
  /// l'extraction OCR brute).
  Future<BordereauValidationResult> validate(
    BordereauExtraction extraction,
  ) async {
    // Pas la peine de tenter si pas de quoi composer une requete.
    final hasAddressInfo = (extraction.rue?.isNotEmpty ?? false) ||
        (extraction.codePostal?.isNotEmpty ?? false) ||
        (extraction.ville?.isNotEmpty ?? false);
    if (!hasAddressInfo) {
      return BordereauValidationResult(
        extraction: extraction,
        validated: false,
      );
    }

    // Construction de la requete BAN. Strategie : on tente l'adresse
    // la plus complete d'abord ; si rien, on retombe sur cp+ville.
    final queries = _buildQueries(extraction);
    if (queries.isEmpty) {
      return BordereauValidationResult(
        extraction: extraction,
        validated: false,
      );
    }

    AddressSuggestion? bestSuggestion;
    double bestScore = double.infinity;
    for (final query in queries) {
      try {
        final results = await _ban.search(query, limit: 3);
        if (results.isEmpty) continue;
        // On evalue chaque resultat en comparant son adresse postale
        // a l'extraction OCR concatenee.
        final extractedFlat = _flattenExtraction(extraction);
        for (final r in results) {
          final ref = _flattenSuggestion(r);
          final score = Levenshtein.similarity(extractedFlat, ref);
          if (score < bestScore) {
            bestScore = score;
            bestSuggestion = r;
          }
        }
        // Bon match trouve -> on arrete (evite des calls inutiles).
        if (bestScore < _similarityThreshold) break;
      } catch (_) {
        // Erreur reseau, timeout, etc. : on tente la requete suivante
        // ou on sort sans validation.
        continue;
      }
    }

    if (bestSuggestion == null || bestScore > _similarityThreshold) {
      return BordereauValidationResult(
        extraction: extraction,
        validated: false,
        validationScore: bestScore.isFinite ? bestScore : null,
      );
    }

    // Application des corrections : on remplace la ville et le CP
    // extraits par ceux de la BAN si la BAN en a et que l'OCR semble
    // moins fiable.
    final corrections = <String>[];
    String? correctedVille = extraction.ville;
    String? correctedCp = extraction.codePostal;
    if (bestSuggestion.city != null && bestSuggestion.city!.isNotEmpty) {
      final banVille = bestSuggestion.city!.toUpperCase();
      if (extraction.ville == null ||
          extraction.ville!.toUpperCase() != banVille) {
        corrections.add('Ville: ${extraction.ville ?? "(vide)"} -> $banVille');
        correctedVille = banVille;
      }
    }
    if (bestSuggestion.postcode != null &&
        bestSuggestion.postcode!.isNotEmpty &&
        extraction.codePostal != bestSuggestion.postcode) {
      corrections.add(
          'CP: ${extraction.codePostal ?? "(vide)"} -> ${bestSuggestion.postcode}');
      correctedCp = bestSuggestion.postcode;
    }

    final corrected = BordereauExtraction(
      nomDestinataire: extraction.nomDestinataire,
      rue: extraction.rue,
      codePostal: correctedCp,
      ville: correctedVille,
      telephone: extraction.telephone,
      nbColis: extraction.nbColis,
      confidence: ExtractionConfidence.high,
    );

    return BordereauValidationResult(
      extraction: corrected,
      validated: true,
      banSuggestion: bestSuggestion,
      validationScore: bestScore,
      correctionsApplied: corrections,
    );
  }

  /// Compose des requetes BAN candidates par ordre de specificite
  /// decroissante. On essaie la plus precise en premier ; si la BAN
  /// ne renvoie rien (adresse invalide / faute frappe), on retombe
  /// sur une recherche moins exigeante.
  static List<String> _buildQueries(BordereauExtraction e) {
    final qs = <String>[];
    final rue = e.rue?.split(' · ').first.trim(); // ignore BP, etc.
    final cp = e.codePostal;
    final ville = e.ville;

    // Plus precise : rue + cp + ville
    if (rue != null && rue.isNotEmpty && cp != null && ville != null) {
      qs.add('$rue, $cp $ville');
    }
    // Rue + ville seulement
    if (rue != null && rue.isNotEmpty && ville != null && ville.isNotEmpty) {
      qs.add('$rue, $ville');
    }
    // CP + ville (au cas ou la rue ait ete totalement loupee par l'OCR)
    if (cp != null && ville != null && ville.isNotEmpty) {
      qs.add('$cp $ville');
    }
    // Juste le CP
    if (cp != null) {
      qs.add(cp);
    }
    return qs;
  }

  /// Concatene les champs d'adresse de l'extraction pour la comparaison
  /// Levenshtein. On garde les majuscules pour rester homogene avec
  /// les sorties OCR.
  static String _flattenExtraction(BordereauExtraction e) {
    final parts = <String>[
      if (e.rue != null) e.rue!.split(' · ').first,
      if (e.codePostal != null) e.codePostal!,
      if (e.ville != null) e.ville!,
    ];
    return parts.join(' ').toUpperCase();
  }

  /// Concatene les champs d'adresse d'une suggestion BAN pour la
  /// comparaison.
  static String _flattenSuggestion(AddressSuggestion s) {
    final parts = <String>[
      if (s.houseNumber != null && s.houseNumber!.isNotEmpty) s.houseNumber!,
      if (s.road != null && s.road!.isNotEmpty) s.road!,
      if (s.postcode != null && s.postcode!.isNotEmpty) s.postcode!,
      if (s.city != null && s.city!.isNotEmpty) s.city!,
    ];
    return parts.join(' ').toUpperCase();
  }
}
