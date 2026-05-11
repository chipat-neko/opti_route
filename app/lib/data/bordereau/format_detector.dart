/// Detecte le format d'un bordereau de livraison a partir des lignes
/// OCR brutes. Utile pour dispatcher vers le bon sous-parser.
///
/// Heuristique simple basee sur les marqueurs distinctifs :
/// - **MESEXP** : presence des mots cles "MESEXP", "Messagerie Express",
///   ou de la triade "Destinataire" + "Lieu de livraison" + "Total colis".
/// - **Colis** : format des etiquettes collees sur les colis (marqueurs
///   distinctifs a affiner avec les photos de reference Noah). Heuristique
///   placeholder pour l'instant.
/// - **Unknown** : aucun marqueur reconnu.
enum BordereauFormat {
  mesexp,
  colis,
  unknown,
}

/// Score-based detection : chaque format calcule un score de probabilite,
/// on prend le max. Si tous les scores sont nuls, retourne `unknown`.
class BordereauFormatDetector {
  const BordereauFormatDetector();

  BordereauFormat detect(List<String> rawLines) {
    final lines = rawLines.map((l) => l.trim().toLowerCase()).toList();
    final mesexpScore = _scoreMesexp(lines);
    final colisScore = _scoreColis(lines);

    if (mesexpScore == 0 && colisScore == 0) return BordereauFormat.unknown;
    if (mesexpScore >= colisScore) return BordereauFormat.mesexp;
    return BordereauFormat.colis;
  }

  /// Score MESEXP : +3 par marqueur principal trouve, +1 par marqueur
  /// secondaire. Permet la tolerance OCR (un marqueur peut etre mal
  /// reconnu mais on a les autres).
  int _scoreMesexp(List<String> lowercased) {
    var score = 0;
    const primary = [
      'mesexp',
      'messagerie express',
    ];
    const secondary = [
      'destinataire',
      'desinataire', // tolerance OCR (sans le t)
      'lieu de livraison',
      'lieu livraison',
      'total colis',
      'contact destinataire',
      'lettre de voiture',
    ];
    for (final line in lowercased) {
      for (final marker in primary) {
        if (line.contains(marker)) score += 3;
      }
      for (final marker in secondary) {
        if (line.contains(marker)) score += 1;
      }
    }
    return score;
  }

  /// Score Colis : marqueurs distinctifs des etiquettes collees sur les
  /// colis. **A affiner avec les photos de reference Noah** (vague 3).
  /// Pour l'instant, heuristique conservatrice basee sur des indices
  /// genericistes (code barres + numero de tracking + petit format).
  int _scoreColis(List<String> lowercased) {
    var score = 0;
    // Marqueurs probables (a confirmer avec les photos reelles) :
    const indicators = [
      'tracking',
      'suivi',
      'colis n',
      'code barre',
      'envoi n',
      'expedition n',
      'reference colis',
    ];
    for (final line in lowercased) {
      for (final marker in indicators) {
        if (line.contains(marker)) score += 2;
      }
    }
    return score;
  }
}
