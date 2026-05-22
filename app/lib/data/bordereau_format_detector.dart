import 'bordereau_extraction.dart' show BordereauFormat;
import 'bordereau_patterns.dart';

/// Detecte si un bordereau OCR est un **ENLEVEMENT** (ramasse) ou une
/// **LIVRAISON** classique. Extrait de [BordereauParser] le 2026-05-22
/// (audit refactor P0 #2).
///
/// Sur les bordereaux MESEXP Eure et Loir Acheminement (cas Noah), le
/// label visuel "ENLEVEMENT" est present en gros sur la moitie haute,
/// et le tableau a des colonnes "à enlever chez" / "destination".
///
/// Pour Noah : ENLEVEMENT = il va RAMASSER chez le client (lieu "à
/// enlever chez"). LIVRAISON = il va DEPOSER chez le destinataire.
abstract final class BordereauFormatDetector {
  /// Cles de detection ENLEVEMENT (n'importe laquelle suffit) :
  /// - label `ENLEVEMENT` en majuscules (gros texte sur le bordereau)
  /// - header de colonne `à enlever chez` / `a enlever chez`
  /// - mention `Contact et lieu d'enlèvement` en bas
  /// - `période d'enlèvement` / `date d'enlèvement` en haut du tableau
  /// - `Exemplaire à laisser sur le lieu d'enlèvement` en footer
  ///
  /// Si aucune cle n'est trouvee : `BordereauFormat.livraison` par
  /// defaut (parsers Chronopost / Colissimo / MESEXP livraison).
  static BordereauFormat detect(List<String> lines) {
    for (final l in lines) {
      final lower = l.toLowerCase();
      if (lower.contains('enlever chez')) return BordereauFormat.enlevement;
      if (lower.contains("d'enlèvement") ||
          lower.contains("d'enlevement")) {
        return BordereauFormat.enlevement;
      }
      // "ENLEVEMENT" en majuscules entoure de word boundaries. On match
      // meme dans une phrase ("Mode : ENLEVEMENT obligatoire") mais pas
      // dans des phrases libres ou le mot apparait minuscule.
      if (BordereauPatterns.enlevementLabelRegex.hasMatch(l)) {
        return BordereauFormat.enlevement;
      }
    }
    return BordereauFormat.livraison;
  }
}
