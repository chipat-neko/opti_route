import 'bordereau_extraction.dart';

/// Parser pour les bordereaux **Colissimo / La Poste**.
///
/// Format typique (en haut a gauche du bordereau A6) :
/// ```
/// Colissimo
/// N° 6A12345678901
/// Destinataire :
/// MR DUPONT JEAN
/// 12 RUE DES LILAS
/// 28100 DREUX
/// Tel : 0612345678
/// ```
///
/// Strategie heuristique distincte du `BordereauParser` MESEXP :
/// - On cherche le marqueur "Destinataire" (souvent suivi des ":" ou
///   d'un saut de ligne).
/// - Le bloc qui suit, sur 3-5 lignes, contient le nom, l'adresse,
///   le CP+ville, parfois un telephone.
/// - Le N° de tracking (commence par 6A, 8L, 9N selon La Poste) est
///   ignore (pas utile pour la livraison physique).
class ColissimoBordereauParser {
  static final _cpVilleRegex = RegExp(
    "\\b(\\d{5})\\s+([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ\\s\\-']+)",
  );
  static final _cpRegex = RegExp(r'\b(\d{5})\b');
  static final _telRegex = RegExp(
    r'\b(0\d[\s.\-]?\d{2}[\s.\-]?\d{2}[\s.\-]?\d{2}[\s.\-]?\d{2})\b',
  );

  /// Marqueur "destinataire" tolerant aux variations de casse / accents.
  static final _destMarker = RegExp(
    r'^\s*destinataire\s*:?\s*$',
    caseSensitive: false,
  );

  /// Marqueurs qui terminent le bloc destinataire (utile pour les
  /// bordereaux qui mettent l'expediteur ou le code-barres sous le
  /// destinataire).
  static final _stopMarkers = <RegExp>[
    RegExp(r'^\s*expediteur', caseSensitive: false),
    RegExp(r'^\s*exp\s*:', caseSensitive: false),
    RegExp(r'^\s*n[°o]\s*tracking', caseSensitive: false),
    RegExp(r'^\s*colissimo', caseSensitive: false),
    RegExp(r'^\s*la\s+poste', caseSensitive: false),
    RegExp(r'^\s*signature', caseSensitive: false),
  ];

  /// Detecte si les lignes OCR ressemblent a un bordereau Colissimo.
  /// Sert au routeur OCR pour choisir le bon parser sans en lancer
  /// plusieurs.
  static bool looksLikeColissimo(List<String> lines) {
    final joined = lines.join('\n').toLowerCase();
    return joined.contains('colissimo') ||
        joined.contains('la poste') ||
        RegExp(r'\b[68][a-z]\d{11}\b').hasMatch(joined);
  }

  BordereauExtraction parse(List<String> rawLines) {
    final lines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    final destIdx = _findIndex(lines, _destMarker);
    if (destIdx == -1) {
      // Pas de marqueur destinataire explicite : fallback minimal sur
      // les regex CP/Ville et telephone.
      return _fallbackParse(lines);
    }

    // Bloc destinataire : lignes apres "Destinataire :" jusqu'au
    // prochain stop marker (ou 5 lignes max, ou fin du texte).
    final blockEnd = _findBlockEnd(lines, destIdx + 1);
    final block = lines.sublist(destIdx + 1, blockEnd);
    if (block.isEmpty) return _fallbackParse(lines);

    // Premiere ligne du bloc = nom destinataire.
    final nom = block.first;
    // Les lignes suivantes contiennent adresse + cp/ville + tel.
    final reste = block.skip(1).toList();

    String? rue;
    String? cp;
    String? ville;
    String? tel;
    int? nbColis;

    for (final line in reste) {
      final cpVilleMatch = _cpVilleRegex.firstMatch(line);
      final telMatch = _telRegex.firstMatch(line);
      if (cpVilleMatch != null && cp == null) {
        cp = cpVilleMatch.group(1);
        ville = cpVilleMatch.group(2)?.trim();
      } else if (telMatch != null && tel == null) {
        tel = telMatch.group(1);
      } else {
        // Premiere ligne non-CP non-tel = la rue.
        rue ??= line;
      }
    }

    // Si on n'a pas trouve de CP via le pattern "CP Ville", on tente
    // CP seul sur tout le bloc.
    if (cp == null) {
      for (final line in reste) {
        final m = _cpRegex.firstMatch(line);
        if (m != null) {
          cp = m.group(1);
          break;
        }
      }
    }

    final hasRueOrVille = (rue != null && rue.isNotEmpty) ||
        (cp != null && cp.isNotEmpty);
    return BordereauExtraction(
      nomDestinataire: nom,
      rue: rue,
      codePostal: cp,
      ville: ville,
      telephone: tel,
      nbColis: nbColis,
      confidence:
          hasRueOrVille ? ExtractionConfidence.high : ExtractionConfidence.low,
    );
  }

  /// Fallback quand le marqueur "Destinataire" est absent : on ne
  /// retourne que CP/ville/tel via regex. Pas de nom fiable.
  BordereauExtraction _fallbackParse(List<String> lines) {
    final joined = lines.join('\n');
    final cpVilleMatch = _cpVilleRegex.firstMatch(joined);
    final telMatch = _telRegex.firstMatch(joined);
    if (cpVilleMatch == null && telMatch == null) {
      return const BordereauExtraction(confidence: ExtractionConfidence.none);
    }
    return BordereauExtraction(
      codePostal: cpVilleMatch?.group(1),
      ville: cpVilleMatch?.group(2)?.trim(),
      telephone: telMatch?.group(1),
      confidence: ExtractionConfidence.low,
    );
  }

  static int _findIndex(List<String> lines, RegExp pattern) {
    for (var i = 0; i < lines.length; i++) {
      if (pattern.hasMatch(lines[i])) return i;
    }
    return -1;
  }

  /// Cherche la fin du bloc destinataire : premiere ligne qui matche
  /// un stop marker, ou max 5 lignes apres `start`.
  static int _findBlockEnd(List<String> lines, int start) {
    final hardLimit = start + 5;
    for (var i = start; i < lines.length && i < hardLimit; i++) {
      for (final stop in _stopMarkers) {
        if (stop.hasMatch(lines[i])) return i;
      }
    }
    return lines.length < hardLimit ? lines.length : hardLimit;
  }
}
