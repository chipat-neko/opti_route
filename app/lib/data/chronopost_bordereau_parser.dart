import 'bordereau_extraction.dart';

/// Parser pour les bordereaux **Chronopost**.
///
/// Format typique (etiquette ~10x15 cm) :
/// ```
/// CHRONOPOST
/// LIVRAISON 13H / 18H
/// XR123456789FR        ← numero de tracking
///
/// EXPEDITEUR :
/// AMAZON FRANCE
/// 78290 CROISSY S/SEINE
///
/// DESTINATAIRE :
/// CALOTE NOAH
/// 12 RUE DES LILAS
/// 28100 DREUX
/// FRANCE
/// 06 12 34 56 78
/// ```
///
/// Distinction principale avec Colissimo : Chronopost utilise tres
/// souvent un bloc "EXPEDITEUR :" AVANT le destinataire, et le N° de
/// tracking suit le pattern `XR\d{9}FR` ou `XE\d{9}FR`.
class ChronopostBordereauParser {
  static final _cpVilleRegex = RegExp(
    "\\b(\\d{5})\\s+([A-Za-zÀ-ÿ][A-Za-zÀ-ÿ\\s\\-']+)",
  );
  static final _cpRegex = RegExp(r'\b(\d{5})\b');
  static final _telRegex = RegExp(
    r'\b(0\d[\s.\-]?\d{2}[\s.\-]?\d{2}[\s.\-]?\d{2}[\s.\-]?\d{2})\b',
  );
  static final _trackingRegex = RegExp(
    r'\b[XR][A-Z]\d{9}FR\b',
    caseSensitive: false,
  );

  /// Marqueur destinataire (tolerant a casse, accents, espacements).
  static final _destMarker = RegExp(
    r'^\s*destinataire\s*:?\s*$',
    caseSensitive: false,
  );

  /// Marqueur expediteur (pour delimiter le bloc destinataire).
  static final _expMarker = RegExp(
    r'^\s*(?:expediteur|exp\.?)\s*:?\s*$',
    caseSensitive: false,
  );

  static final _stopMarkers = <RegExp>[
    _expMarker,
    RegExp(r'^\s*chronopost', caseSensitive: false),
    RegExp(r'^\s*livraison\s+\d', caseSensitive: false),
    RegExp(r'^\s*signature', caseSensitive: false),
    RegExp(r'^\s*tracking', caseSensitive: false),
  ];

  /// Detecte si les lignes OCR ressemblent a un bordereau Chronopost.
  static bool looksLikeChronopost(List<String> lines) {
    final joined = lines.join('\n').toLowerCase();
    return joined.contains('chronopost') ||
        _trackingRegex.hasMatch(joined);
  }

  BordereauExtraction parse(List<String> rawLines) {
    final lines = rawLines
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList(growable: false);

    final destIdx = _findIndex(lines, _destMarker);
    if (destIdx == -1) {
      return _fallbackParse(lines);
    }

    final blockEnd = _findBlockEnd(lines, destIdx + 1);
    final block = lines.sublist(destIdx + 1, blockEnd);
    if (block.isEmpty) return _fallbackParse(lines);

    final nom = block.first;
    final reste = block.skip(1).toList();

    String? rue;
    String? cp;
    String? ville;
    String? tel;

    for (final line in reste) {
      // FRANCE seul : on ignore (Chronopost le rajoute systematiquement).
      if (RegExp(r'^\s*france\s*$', caseSensitive: false).hasMatch(line)) {
        continue;
      }
      final cpVilleMatch = _cpVilleRegex.firstMatch(line);
      final telMatch = _telRegex.firstMatch(line);
      if (cpVilleMatch != null && cp == null) {
        cp = cpVilleMatch.group(1);
        ville = cpVilleMatch.group(2)?.trim();
      } else if (telMatch != null && tel == null) {
        tel = telMatch.group(1);
      } else {
        rue ??= line;
      }
    }

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
      confidence:
          hasRueOrVille ? ExtractionConfidence.high : ExtractionConfidence.low,
    );
  }

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

  static int _findBlockEnd(List<String> lines, int start) {
    final hardLimit = start + 6; // un poil plus large que Colissimo
    for (var i = start; i < lines.length && i < hardLimit; i++) {
      for (final stop in _stopMarkers) {
        if (stop.hasMatch(lines[i])) return i;
      }
    }
    return lines.length < hardLimit ? lines.length : hardLimit;
  }
}
