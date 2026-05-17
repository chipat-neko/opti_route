import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'bordereau_extraction.dart';

/// ════════════════════════════════════════════════════════════════
/// Logger CSV append-only pour les stats OCR baseline.
/// ════════════════════════════════════════════════════════════════
///
/// **Objectif** : mesurer le taux de "carte verte"
/// ([ExtractionConfidence.high]) sur le scan OCR des bordereaux Noah,
/// avant d'attaquer la Phase B (pre-traitement image) du plan OCR.
/// Sans baseline mesuree, on optimise a l'aveugle.
///
/// **Format** : 1 fichier CSV append-only dans le dossier app docs.
/// Pas de table Drift -> pas de migration de schema, pas de transaction,
/// pas de souci de timing avec Drift. Juste un `File.openWrite` en mode
/// append a chaque scan. L'export est immediat (share natif).
///
/// **Colonnes** : timestamp ISO 8601 ; parser (`mesexp` / `colissimo` /
/// `chronopost`) ; confidence (`high` / `low` / `none`) ; rotation_deg
/// (0/90/180/270) ; attempts (1..4) ; ban_validated (bool) ;
/// validation_score (0.0..1.0 ou vide) ; duration_ms.
class OcrStatsLog {
  /// Singleton : un seul logger pour toute la session de l'app.
  static final OcrStatsLog instance = OcrStatsLog._();
  OcrStatsLog._();

  static const _filename = 'ocr_stats.csv';
  static const _header =
      'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms';

  /// Enregistre une ligne pour un scan. Best-effort : si l'I/O echoue
  /// (disque plein, permission denied, etc.), on swallow car ce n'est
  /// pas une feature critique pour le scan lui-meme.
  Future<void> log({
    required String parser,
    required ExtractionConfidence confidence,
    required int rotationDeg,
    required int attempts,
    required bool banValidated,
    double? validationScore,
    required int durationMs,
  }) async {
    try {
      final file = await _getOrCreateFile();
      final line = [
        DateTime.now().toIso8601String(),
        parser,
        confidence.name,
        rotationDeg.toString(),
        attempts.toString(),
        banValidated.toString(),
        validationScore?.toStringAsFixed(3) ?? '',
        durationMs.toString(),
      ].join(',');
      await file.writeAsString('$line\n', mode: FileMode.append);
    } catch (_) {/* best-effort, jamais bloquant */}
  }

  /// Compte le nombre d'entrees (hors header). Retourne 0 si le fichier
  /// n'existe pas ou est illisible.
  Future<int> count() async {
    try {
      final file = await _file();
      if (!await file.exists()) return 0;
      final lines = await file.readAsLines();
      // -1 pour le header
      return (lines.length - 1).clamp(0, lines.length);
    } catch (_) {
      return 0;
    }
  }

  /// Lit le CSV et calcule le breakdown du taux carte verte / orange /
  /// rouge. Retourne `OcrBaselineStats.empty()` si pas de fichier ou
  /// erreur lecture (jamais throw — best-effort comme `log()`).
  ///
  /// Sert au tile Parametres > Stats OCR pour afficher directement le
  /// taux atteint sans devoir exporter le CSV.
  ///
  /// Format CSV attendu (cf [_header]) :
  /// `timestamp,parser,confidence,rotation_deg,attempts,ban_validated,
  /// validation_score,duration_ms`
  /// La colonne `confidence` est en index 2.
  Future<OcrBaselineStats> computeBaseline() async {
    try {
      final file = await _file();
      if (!await file.exists()) return OcrBaselineStats.empty();
      final lines = await file.readAsLines();
      if (lines.length < 2) return OcrBaselineStats.empty();
      int high = 0;
      int low = 0;
      int none = 0;
      // Skip line 0 (header)
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final parts = line.split(',');
        if (parts.length < 3) continue;
        final confidence = parts[2];
        switch (confidence) {
          case 'high':
            high++;
          case 'low':
            low++;
          case 'none':
            none++;
        }
      }
      return OcrBaselineStats(highCount: high, lowCount: low, noneCount: none);
    } catch (_) {
      return OcrBaselineStats.empty();
    }
  }

  /// Partage le fichier CSV via le selecteur natif (Drive / mail / etc.).
  /// Retourne false si pas de stats a partager.
  Future<bool> exportShare() async {
    final file = await _file();
    if (!await file.exists()) return false;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: 'Stats OCR opti_route',
        text: 'Export brut des scans OCR pour analyse de la baseline.',
      ),
    );
    return true;
  }

  /// Supprime le fichier (reset complet des stats). Idempotent.
  Future<void> clear() async {
    try {
      final file = await _file();
      if (await file.exists()) await file.delete();
    } catch (_) {/* best-effort */}
  }

  Future<File> _file() async {
    final docs = await getApplicationDocumentsDirectory();
    return File('${docs.path}${Platform.pathSeparator}$_filename');
  }

  /// Recupere le fichier, le cree avec le header si absent. Idempotent.
  Future<File> _getOrCreateFile() async {
    final file = await _file();
    if (!await file.exists()) {
      await file.writeAsString('$_header\n');
    }
    return file;
  }
}

/// Breakdown des scans OCR par niveau de confidence (cf [OcrStatsLog.
/// computeBaseline]). Sert au tile Stats OCR de Parametres pour
/// afficher inline le taux carte verte sans devoir exporter le CSV.
///
/// Convention couleur projet :
/// - **verte** = high (extraction tres confiante, prefill direct OK)
/// - **orange** = low (extraction incertaine, user doit verifier)
/// - **rouge** = none (extraction echouee, saisie manuelle forcee)
class OcrBaselineStats {
  const OcrBaselineStats({
    required this.highCount,
    required this.lowCount,
    required this.noneCount,
  });

  /// Factory : aucun scan enregistre. Tous les rates sont a 0%.
  const OcrBaselineStats.empty()
      : highCount = 0,
        lowCount = 0,
        noneCount = 0;

  final int highCount;
  final int lowCount;
  final int noneCount;

  int get total => highCount + lowCount + noneCount;

  /// Taux carte verte 0.0-1.0. Retourne 0 si aucun scan.
  double get greenRate => total == 0 ? 0 : highCount / total;
  double get orangeRate => total == 0 ? 0 : lowCount / total;
  double get redRate => total == 0 ? 0 : noneCount / total;
}
