import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

/// Rend les pages d'un PDF en images PNG temporaires (carte #118), pour
/// les passer ensuite dans le pipeline OCR existant (comme une photo).
///
/// Use case : Noah recoit un bordereau (souvent multi-pages = plusieurs
/// destinataires) par mail au format PDF. Au lieu de le photographier
/// page par page, il l'importe directement.
///
/// Plateforme uniquement (pdfx = PdfRenderer natif) : non testable en
/// unitaire, a valider sur device.
class PdfPageRenderService {
  /// Garde-fou : on ne rend pas plus de pages que ca en un import (un
  /// bordereau realiste fait < 30 pages ; au-dela c'est probablement une
  /// erreur de fichier).
  static const int maxPages = 30;

  /// Largeur de rendu cible (px). 2000 px : assez net pour l'OCR ML Kit
  /// sans exploser la memoire sur un PDF de 20 pages.
  static const double targetWidth = 2000;

  /// Rend chaque page de [pdf] en PNG temporaire et retourne la liste
  /// des fichiers (dans l'ordre des pages). Vide si le PDF est illisible.
  Future<List<File>> renderToImages(File pdf) async {
    final out = <File>[];
    final doc = await PdfDocument.openFile(pdf.path);
    try {
      final dir = await getTemporaryDirectory();
      final n = doc.pagesCount < maxPages ? doc.pagesCount : maxPages;
      final stamp = DateTime.now().microsecondsSinceEpoch;
      for (var i = 1; i <= n; i++) {
        final page = await doc.getPage(i);
        try {
          final ratio = page.height == 0 ? 1.0 : page.height / page.width;
          final img = await page.render(
            width: targetWidth,
            height: targetWidth * ratio,
            format: PdfPageImageFormat.png,
          );
          if (img != null) {
            final f = File('${dir.path}/pdf_page_${stamp}_$i.png');
            await f.writeAsBytes(img.bytes);
            out.add(f);
          }
        } finally {
          await page.close();
        }
      }
    } finally {
      await doc.close();
    }
    return out;
  }
}
