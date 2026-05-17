import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

/// ════════════════════════════════════════════════════════════════
/// Pre-traitement d'image pour OCR (Phase B du plan OCR 85 %).
/// ════════════════════════════════════════════════════════════════
///
/// Cible : ameliorer le taux de "carte verte" (ExtractionConfidence.high)
/// du scan OCR de Noah sans dependance OpenCV (100 % Dart pur, marche
/// aussi en web).
///
/// Trois etapes possibles, appliquees sequentiellement par
/// [enhance] :
///
/// 1. **EXIF orientation** : certaines images JPG portent un flag EXIF
///    (1..8) qui dit "afficher-moi tournee de 90/180/270" mais les
///    pixels sont stockes a 0. Sans bake, l'OCR voit les pixels bruts
///    et rate les bordereaux scannes "verticalement". `bakeOrientation`
///    applique le flag et reset l'EXIF.
///
/// 2. **Boost contraste** : sur les photos sombres (livraison en
///    interieur, fin de journee), le texte se confond avec le fond.
///    Un contraste +25 % rend les caracteres mieux dissocies.
///
/// 3. **Detection bordereau (optionnelle)** : crop sur la bounding
///    box des pixels clairs (background blanc du bordereau). Reduit
///    le bruit visuel des doigts / table / sol autour.
///
/// **Strategie d'usage** : appelee depuis [OcrService.extractFromFile]
/// AVANT le 1er essai ML Kit. Si la qualite est suffisante, on s'arrete
/// la ; sinon on passe aux rotations (cf [OcrService]).
class ImagePreprocessService {
  ImagePreprocessService();

  /// Pre-traite [source] et renvoie un fichier JPG temporaire (ou
  /// `source` si aucune transformation utile n'a ete appliquee). Le
  /// caller est responsable de supprimer le fichier temp apres usage
  /// (recommande : `unawaited(file.delete())`).
  ///
  /// [boostContrast] : facteur a appliquer (1.0 = inchangé, 1.25 =
  /// +25 % contraste). Mettre 1.0 pour desactiver le boost.
  ///
  /// [autoCrop] : si true, tente de detecter le rectangle clair du
  /// bordereau et crop autour. Best-effort : si la detection echoue
  /// (image entiere claire / sombre), retourne l'image originale.
  Future<File> enhance(
    File source, {
    double boostContrast = 1.25,
    bool autoCrop = true,
  }) async {
    final bytes = await source.readAsBytes();
    // decodeImage peut throw sur certains bytes corrompus (ex: header
    // PSD malforme leve RangeError) au lieu de retourner null. Wrap
    // dans try-catch pour garder le contrat "format invalide -> source
    // intacte" (test ajoute 2026-05-17).
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return source;
    }
    if (decoded == null) return source; // format non supporte

    // 1. EXIF orientation -- toujours bake (idempotent + leger)
    img.Image processed = img.bakeOrientation(decoded);

    // 2. Boost contraste si demande
    if (boostContrast != 1.0) {
      processed = img.adjustColor(processed, contrast: boostContrast);
    }

    // 3. Auto-crop sur le bordereau (best-effort)
    if (autoCrop) {
      final cropped = _tryAutoCrop(processed);
      if (cropped != null) processed = cropped;
    }

    // Encode + ecrit dans /tmp avec un nom horodate.
    final encoded = img.encodeJpg(processed, quality: 90);
    return _writeTemp(encoded);
  }

  /// Version "exif-only" : ne fait QUE baker l'orientation EXIF.
  /// Utile en preview (preview a 0 cout) avant decider d'enhancer plus.
  Future<File> bakeExifOnly(File source) async {
    final bytes = await source.readAsBytes();
    // Cf enhance : decodeImage peut throw. Wrap pour garantir source
    // intacte en cas de bytes corrompus.
    img.Image? decoded;
    try {
      decoded = img.decodeImage(bytes);
    } catch (_) {
      return source;
    }
    if (decoded == null) return source;
    final baked = img.bakeOrientation(decoded);
    final encoded = img.encodeJpg(baked, quality: 92);
    return _writeTemp(encoded);
  }

  /// Detecte la bounding box rectangulaire des pixels "clairs"
  /// (luminance > [_lightThreshold]) et crop l'image autour avec une
  /// marge de [_cropMarginPx] pixels pour ne pas couper trop pres du
  /// texte au bord.
  ///
  /// Retourne null si la detection est inutilisable :
  /// - aucun pixel clair (image entierement sombre)
  /// - bbox couvre > 90 % de l'image (rien a gagner a cropper)
  /// - bbox < 30 % de l'image (probablement une erreur, on garde l'orig)
  static img.Image? _tryAutoCrop(img.Image src) {
    final w = src.width;
    final h = src.height;
    if (w < 100 || h < 100) return null; // image trop petite

    // Sample par pas de [_scanStep] pour ne pas iterer pixel par pixel
    // sur une 12 MP (4000x3000) -- meme avec un step de 8, on couvre
    // 188k samples = quelques ms.
    const scanStep = 8;
    int minX = w, minY = h, maxX = -1, maxY = -1;
    for (var y = 0; y < h; y += scanStep) {
      for (var x = 0; x < w; x += scanStep) {
        final px = src.getPixel(x, y);
        // Luminance simple : (R + G + B) / 3
        final lum = (px.r + px.g + px.b) / 3;
        if (lum > _lightThreshold) {
          if (x < minX) minX = x;
          if (y < minY) minY = y;
          if (x > maxX) maxX = x;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX < 0) return null; // pas de pixel clair detecte

    // Marge securite : evite de cropper le texte tout au bord du
    // bordereau.
    minX = (minX - _cropMarginPx).clamp(0, w - 1);
    minY = (minY - _cropMarginPx).clamp(0, h - 1);
    maxX = (maxX + _cropMarginPx).clamp(0, w - 1);
    maxY = (maxY + _cropMarginPx).clamp(0, h - 1);

    final cropW = maxX - minX;
    final cropH = maxY - minY;
    final coverageRatio = (cropW * cropH) / (w * h);
    if (coverageRatio > 0.90) return null; // rien a gagner
    if (coverageRatio < 0.30) return null; // suspect, garde l'orig

    return img.copyCrop(
      src,
      x: minX,
      y: minY,
      width: cropW,
      height: cropH,
    );
  }

  static Future<File> _writeTemp(Uint8List bytes) async {
    final tmpDir = await getTemporaryDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final out = File('${tmpDir.path}/ocr_pre_$ts.jpg');
    await out.writeAsBytes(bytes);
    return out;
  }

  /// Seuil luminance pour considerer un pixel comme "fond clair"
  /// (bordereau papier blanc). 200/255 = pixels franchement blancs,
  /// laisse les pixels gris (table, sol) en dehors.
  static const int _lightThreshold = 200;

  /// Marge en pixels autour de la bbox detectee pour ne pas couper
  /// le texte du bordereau si il est proche du bord.
  static const int _cropMarginPx = 20;
}
