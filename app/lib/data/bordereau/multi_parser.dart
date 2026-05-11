import '../bordereau_extraction.dart';
import '../bordereau_parser.dart';
import 'colis_parser.dart';
import 'format_detector.dart';

/// Dispatcher multi-format pour les bordereaux : detecte le format en
/// premier puis delegue au sous-parser approprie. Conserve l'API du
/// `BordereauParser` historique (`parse(List<String>)` -> retourne une
/// `BordereauExtraction`).
///
/// Usage cote UI :
/// ```dart
/// final result = const MultiFormatBordereauParser().parse(lines);
/// // result.format -> BordereauFormat detecte (mesexp / colis / unknown)
/// // result.extraction -> les champs structures
/// ```
///
/// Si le format est `unknown`, on tente quand meme le parser MESEXP en
/// fallback (best-effort) plutot que de renvoyer un resultat vide.
class MultiFormatBordereauParser {
  const MultiFormatBordereauParser({
    this.detector = const BordereauFormatDetector(),
  });

  final BordereauFormatDetector detector;

  MultiFormatParseResult parse(List<String> rawLines) {
    final format = detector.detect(rawLines);

    switch (format) {
      case BordereauFormat.mesexp:
        final extraction = BordereauParser().parse(rawLines);
        return MultiFormatParseResult(
          format: BordereauFormat.mesexp,
          extraction: extraction,
        );
      case BordereauFormat.colis:
        final extraction = const ColisBordereauParser().parse(rawLines);
        return MultiFormatParseResult(
          format: BordereauFormat.colis,
          extraction: extraction,
        );
      case BordereauFormat.unknown:
        // Fallback : on tente MESEXP en best-effort (l'OCR peut ne pas
        // avoir capture les marqueurs distinctifs).
        final extraction = BordereauParser().parse(rawLines);
        return MultiFormatParseResult(
          format: BordereauFormat.unknown,
          extraction: extraction,
        );
    }
  }
}

class MultiFormatParseResult {
  const MultiFormatParseResult({
    required this.format,
    required this.extraction,
  });

  final BordereauFormat format;
  final BordereauExtraction extraction;
}
