import '../bordereau_extraction.dart';

/// Parser dedie aux etiquettes "collees sur les colis" — format reporte
/// par Noah comme distinct du MESEXP, et qu'il s'engage a transferer
/// en photos de reference pour qu'on l'implemente proprement (vague 3).
///
/// **STUB pour l'instant.** L'implementation reelle viendra une fois
/// les photos disponibles dans `D:\opti_route\bordereaux_test\2_colis\`
/// (cf `docs/play_store/` et la memoire
/// `project_bordereaux_pipeline.md`).
///
/// Retourne `ExtractionConfidence.none` pour que l'UI affiche la carte
/// "incertain" et que l'utilisateur sache qu'il doit re-saisir
/// manuellement.
class ColisBordereauParser {
  const ColisBordereauParser();

  BordereauExtraction parse(List<String> rawLines) {
    // TODO(vague-3) : implementation reelle a partir des photos Noah.
    // Champs cibles a extraire (similaires au MESEXP) :
    //   - nomDestinataire (souvent en gros caracteres centres en haut
    //     de l'etiquette)
    //   - rue + cp + ville (zone adresse generalement en bloc)
    //   - nbColis (souvent absent sur l'etiquette colis individuel,
    //     1 par defaut)
    //   - telephone (rare sur etiquette colis)
    //
    // L'OCR sur etiquette colis est typiquement plus propre que sur
    // un bordereau MESEXP papier (moins de filigrane, moins de
    // tableaux), mais le contenu est plus succinct.
    return const BordereauExtraction(
      confidence: ExtractionConfidence.none,
    );
  }
}
