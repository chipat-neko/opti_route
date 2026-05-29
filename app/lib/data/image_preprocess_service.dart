import 'dart:io';

import 'package:flutter/foundation.dart';
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
    // Le calcul pixel (decode + bake + contraste + crop + encode) tourne
    // dans un isolate via compute() pour ne pas bloquer l'UI pendant le
    // scan (#212). Le disque + path_provider restent sur l'isolate
    // principal. Retourne null si le format est invalide -> on garde la
    // source intacte (contrat teste).
    final encoded = await compute(
      _enhanceIsolate,
      _EnhanceArgs(bytes, boostContrast, autoCrop),
    );
    if (encoded == null) return source;
    return _writeTemp(encoded);
  }

  /// Detecte si une image est trop FLOUE pour donner un OCR fiable.
  ///
  /// Methode : variance du Laplacien. On convolutionne l'image
  /// grayscale avec un kernel Laplacien 3x3, puis on calcule la
  /// variance des valeurs resultantes. Une image nette a beaucoup de
  /// transitions abruptes (bords) -> haute variance. Une image floue
  /// a des gradients lisses -> faible variance.
  ///
  /// Seuils typiques (sur image 1080p) :
  /// - variance > 200 : tres net (OCR optimal)
  /// - variance 50-200 : acceptable (OCR fonctionne)
  /// - variance < 50 : trop floue (OCR va probablement rater)
  ///
  /// Retourne la valeur de variance (0 = uniforme, ~1000+ = tres
  /// net). Le caller decide du seuil ([blurThreshold] default 50).
  ///
  /// Cout : ~50-200ms pour une image 1080p (downsamplee en interne
  /// a 480p pour accelerer). Best-effort : si decode echoue, retourne
  /// double.maxFinite (= net, ne bloque pas le flow OCR).
  ///
  /// Sprint 2.C audit refactor 2026-05-22.
  Future<double> detectBlur(File source) async {
    final Uint8List bytes;
    try {
      bytes = await source.readAsBytes();
    } catch (_) {
      return double.maxFinite; // ne bloque pas le flow OCR
    }
    // Convolution Laplacien = CPU-bound -> isolate (#212).
    return compute(_detectBlurIsolate, bytes);
  }

  /// Version "exif-only" : ne fait QUE baker l'orientation EXIF.
  /// Utile en preview (preview a 0 cout) avant decider d'enhancer plus.
  Future<File> bakeExifOnly(File source) async {
    final bytes = await source.readAsBytes();
    final encoded = await compute(_bakeExifIsolate, bytes);
    if (encoded == null) return source; // bytes corrompus / format invalide
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

/// ════════════════════════════════════════════════════════════════
/// Fonctions exécutées dans un isolate via `compute()` (#212).
/// ════════════════════════════════════════════════════════════════
/// Elles ne font QUE du calcul pixel (package:image, pur Dart) : aucun
/// accès disque ni canal plateforme (path_provider reste sur l'isolate
/// principal). Top-level car `compute` exige une fonction statique.

/// Arguments serialisables pour [_enhanceIsolate] (envoyes par copie a
/// l'isolate).
class _EnhanceArgs {
  const _EnhanceArgs(this.bytes, this.boostContrast, this.autoCrop);
  final Uint8List bytes;
  final double boostContrast;
  final bool autoCrop;
}

/// Pipeline d'amelioration complet. Retourne les bytes JPG encodes, ou
/// null si le format est invalide (le caller garde alors la source).
Uint8List? _enhanceIsolate(_EnhanceArgs args) {
  // decodeImage peut throw sur bytes corrompus (ex: header PSD malforme
  // leve RangeError) au lieu de retourner null -> wrap.
  img.Image? decoded;
  try {
    decoded = img.decodeImage(args.bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null; // format non supporte

  // 1. EXIF orientation -- toujours bake (idempotent + leger)
  img.Image processed = img.bakeOrientation(decoded);

  // 2. Boost contraste si demande
  if (args.boostContrast != 1.0) {
    processed = img.adjustColor(processed, contrast: args.boostContrast);
  }

  // 3. Auto-crop sur le bordereau (best-effort)
  if (args.autoCrop) {
    final cropped = ImagePreprocessService._tryAutoCrop(processed);
    if (cropped != null) processed = cropped;
  }

  return Uint8List.fromList(img.encodeJpg(processed, quality: 90));
}

/// EXIF-only : bake l'orientation et reencode. Null si format invalide.
Uint8List? _bakeExifIsolate(Uint8List bytes) {
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;
  final baked = img.bakeOrientation(decoded);
  return Uint8List.fromList(img.encodeJpg(baked, quality: 92));
}

/// Variance du Laplacien (mesure de nettete). Retourne double.maxFinite
/// si decode echoue (= net, ne bloque pas le flow OCR).
double _detectBlurIsolate(Uint8List bytes) {
  try {
    var decoded = img.decodeImage(bytes);
    if (decoded == null) return double.maxFinite;
    decoded = img.bakeOrientation(decoded);
    // Downsample a 480 px de large max pour rapidite. La variance du
    // Laplacien est relativement robuste au downscale.
    if (decoded.width > 480) {
      decoded = img.copyResize(decoded, width: 480);
    }
    final gray = img.grayscale(decoded);
    final w = gray.width;
    final h = gray.height;
    // Kernel Laplacien 3x3 : [0,1,0;1,-4,1;0,1,0]. On parcourt
    // l'interieur (1..w-2, 1..h-2) et on accumule les valeurs.
    final values = <double>[];
    for (var y = 1; y < h - 1; y++) {
      for (var x = 1; x < w - 1; x++) {
        final c = gray.getPixel(x, y).luminance;
        final up = gray.getPixel(x, y - 1).luminance;
        final down = gray.getPixel(x, y + 1).luminance;
        final left = gray.getPixel(x - 1, y).luminance;
        final right = gray.getPixel(x + 1, y).luminance;
        final lap = up + down + left + right - 4 * c;
        values.add(lap.toDouble());
      }
    }
    if (values.isEmpty) return double.maxFinite;
    // Variance = moyenne des (x - mean)^2.
    var sum = 0.0;
    for (final v in values) {
      sum += v;
    }
    final mean = sum / values.length;
    var sq = 0.0;
    for (final v in values) {
      final d = v - mean;
      sq += d * d;
    }
    return sq / values.length;
  } catch (_) {
    return double.maxFinite; // ne bloque pas le flow OCR
  }
}
