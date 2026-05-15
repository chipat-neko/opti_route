import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import 'image_preprocess_service.dart';

/// Service OCR base sur Google ML Kit (on-device, gratuit, fonctionne
/// hors ligne apres telechargement du modele).
///
/// Le modele latin (couvre francais, anglais, espagnol, etc.) est
/// d'environ 10 Mo et telecharge a la 1ere utilisation.
class OcrService {
  OcrService({ImagePreprocessService? preprocessor})
      : _recognizer = TextRecognizer(script: TextRecognitionScript.latin),
        _preprocessor = preprocessor ?? ImagePreprocessService();

  final TextRecognizer _recognizer;
  final ImagePreprocessService _preprocessor;

  /// Reconnait le texte dans une image et retourne :
  ///   - `fullText` : tout le texte detecte concatene
  ///   - `lines` : liste des lignes individuelles (pour selection UI)
  Future<OcrResult> extractFromFile(File image) async {
    final input = InputImage.fromFile(image);
    final recognized = await _recognizer.processImage(input);

    final lines = <String>[];
    for (final block in recognized.blocks) {
      for (final line in block.lines) {
        final text = line.text.trim();
        if (text.isNotEmpty) lines.add(text);
      }
    }

    return OcrResult(
      fullText: recognized.text,
      lines: lines,
    );
  }

  /// Variante "robuste" qui pre-traite l'image puis essaie plusieurs
  /// orientations si le 1er OCR donne un resultat pauvre.
  ///
  /// **Strategie Phase B** (cf docs/plan-ocr-85pct.md) :
  /// 1. Pre-traitement image : bake EXIF orientation + boost contraste
  ///    + auto-crop bordereau (cf [ImagePreprocessService.enhance]).
  ///    1 seul appel, cout ~50-200ms cote CPU. Couvre le 80 % des cas
  ///    "OCR ratait juste a cause de l'orientation EXIF / contraste".
  /// 2. OCR de l'image enhancee. Si le score qualite est >=
  ///    [qualityThreshold], on garde et on sort.
  /// 3. Sinon, on retombe sur les rotations 90/180/270 classiques
  ///    (Phase A) au cas ou le pre-traitement EXIF n'a pas suffi.
  ///
  /// Use case : livreur scanne un bordereau a l'envers (-> bake EXIF
  /// remet droit en 1 passe) OU bordereau dans l'ombre d'une voiture
  /// (-> contraste boost rend le texte lisible).
  ///
  /// Cout : 1 enhance + 1 OCR si l'image est bien orientee (cas 99 %),
  /// jusqu'a 1 enhance + 4 OCR dans le pire cas (~3s sur phone moyen).
  Future<OcrRotatedResult> extractFromFileWithRotations(
    File image, {
    int qualityThreshold = 8,
  }) async {
    // Etape 0 : pre-traitement image. Best-effort : si ca rate
    // (format exotique, image corrompue), on utilise l'image originale.
    File workingImage = image;
    File? preprocessedFile;
    try {
      preprocessedFile = await _preprocessor.enhance(image);
      workingImage = preprocessedFile;
    } catch (_) {/* fallback sur l'image originale */}

    try {
      // Etape 1 : OCR de l'image (eventuellement pre-traitee).
      final base = await extractFromFile(workingImage);
      final baseScore = _qualityScore(base);
      if (baseScore >= qualityThreshold) {
        return OcrRotatedResult(
          result: base,
          rotationDegrees: 0,
          qualityScore: baseScore,
          attemptedRotations: const [0],
        );
      }

      // Etape 2 : essai des 3 autres rotations sur l'image pre-traitee
      // (qui a deja l'EXIF bake correctement -- inutile de re-baker).
      final attempted = <int>[0];
      OcrResult bestResult = base;
      int bestScore = baseScore;
      int bestRotation = 0;

      for (final degrees in [90, 180, 270]) {
        try {
          final rotatedFile = await _rotateImageToTempFile(
            workingImage,
            degrees,
          );
          if (rotatedFile == null) continue;
          final rotated = await extractFromFile(rotatedFile);
          final score = _qualityScore(rotated);
          attempted.add(degrees);
          if (score > bestScore) {
            bestResult = rotated;
            bestScore = score;
            bestRotation = degrees;
          }
          // Nettoyage best-effort du fichier temporaire (ne bloque pas
          // si l'OS le refuse, ca finira par etre purge).
          unawaited(rotatedFile.delete().catchError((_) => rotatedFile));
          // Si on trouve un excellent score apres 1 rotation, pas besoin
          // de continuer (court-circuit pour economiser des cycles).
          if (bestScore >= qualityThreshold) break;
        } catch (_) {
          // On n'arrete pas tout pour une rotation qui foire, on tente
          // la suivante.
        }
      }

      return OcrRotatedResult(
        result: bestResult,
        rotationDegrees: bestRotation,
        qualityScore: bestScore,
        attemptedRotations: attempted,
      );
    } finally {
      // Nettoie le fichier pre-traite (different de l'image originale
      // que le caller veut garder).
      if (preprocessedFile != null && preprocessedFile.path != image.path) {
        unawaited(
            preprocessedFile.delete().catchError((_) => preprocessedFile!));
      }
    }
  }

  /// Score heuristique evaluant la qualite d'un resultat OCR. Plus
  /// c'est haut, mieux c'est. Pas une vraie metrique, juste un
  /// indicateur "suffisamment de matiere extraite pour qu'on tente
  /// le parser".
  ///
  /// Critere actuel : nombre de lignes contenant au moins 3 caracteres
  /// **alphanumeriques contigus** (filtre les lignes de bruit qui ne
  /// contiennent que ponctuation / chiffres epars).
  static int _qualityScore(OcrResult r) {
    final richLineRe = RegExp(r'[A-Za-z0-9]{3,}');
    var count = 0;
    for (final line in r.lines) {
      if (richLineRe.hasMatch(line)) count++;
    }
    return count;
  }

  /// Decode l'image source, la tourne de [degrees] (90/180/270) et
  /// l'ecrit dans un fichier JPG temporaire dont on renvoie le path.
  /// Retourne null si le decodage echoue (format non supporte, fichier
  /// corrompu).
  static Future<File?> _rotateImageToTempFile(
    File source,
    int degrees,
  ) async {
    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final rotated = img.copyRotate(decoded, angle: degrees);
    final encoded = img.encodeJpg(rotated, quality: 90);
    final tmpDir = await getTemporaryDirectory();
    final ts = DateTime.now().microsecondsSinceEpoch;
    final out = File('${tmpDir.path}/ocr_rot_${degrees}_$ts.jpg');
    await out.writeAsBytes(encoded);
    return out;
  }

  void close() => _recognizer.close();
}

/// Resultat brut d'un OCR (sortie de [OcrService.extractFromFile]).
class OcrResult {
  const OcrResult({required this.fullText, required this.lines});

  final String fullText;
  final List<String> lines;
}

/// Resultat enrichi de [OcrService.extractFromFileWithRotations] :
/// contient l'OcrResult retenu + meta-donnees sur la rotation gagnante
/// pour debug et affichage UI (ex: badge "Image tournee de 90 deg").
class OcrRotatedResult {
  const OcrRotatedResult({
    required this.result,
    required this.rotationDegrees,
    required this.qualityScore,
    required this.attemptedRotations,
  });

  /// Le meilleur OcrResult (texte + lignes).
  final OcrResult result;

  /// Rotation appliquee a l'image source pour obtenir ce resultat
  /// (0, 90, 180, ou 270). 0 = image originale, pas de rotation.
  final int rotationDegrees;

  /// Score qualite du resultat retenu (cf [_qualityScore]). Sert au
  /// caller pour decider d'afficher la card extraction ou non.
  final int qualityScore;

  /// Liste des rotations tentees (toujours commence par [0]). Utile
  /// pour le debug et les logs.
  final List<int> attemptedRotations;
}

/// `unawaited` minimaliste : marque explicitement qu'on ne se soucie
/// pas du Future retourne. Evite le warning analyzer.
void unawaited(Future<dynamic> _) {}
