import 'dart:io';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Service OCR base sur Google ML Kit (on-device, gratuit, fonctionne
/// hors ligne apres telechargement du modele).
///
/// Le modele latin (couvre francais, anglais, espagnol, etc.) est
/// d'environ 10 Mo et telecharge a la 1ere utilisation.
class OcrService {
  OcrService() : _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  final TextRecognizer _recognizer;

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

  void close() => _recognizer.close();
}

class OcrResult {
  const OcrResult({required this.fullText, required this.lines});

  final String fullText;
  final List<String> lines;
}
