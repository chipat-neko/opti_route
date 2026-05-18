import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/bordereau_extraction.dart';
import '../data/bordereau_parser.dart';
import '../data/chronopost_bordereau_parser.dart';
import '../data/colissimo_bordereau_parser.dart';
import '../data/ocr_service.dart';
import '../data/ocr_stats_log.dart';
import '../providers/ocr_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'scan_bordereau/debug_section.dart';
import 'scan_bordereau/detection_cards.dart';

/// Ecran de scan de bordereau de livraison.
///
/// Flow :
/// 1. Capture photo (camera ou galerie).
/// 2. OCR via ML Kit (on-device, hors ligne).
/// 3. Le BordereauParser tente une extraction automatique (nom
///    destinataire, adresse, ville, CP, nb colis) en utilisant les
///    marqueurs typiques (`Destinataire`, `Lieu de livraison`,
///    `Total colis`).
/// 4. Si l'extraction trouve quelque chose -> carte "Detection auto"
///    en haut avec bouton "Utiliser ces infos" qui pop le
///    [BordereauExtraction].
/// 5. Toujours possible de selectionner manuellement les lignes en
///    dessous (mode fallback). Auquel cas on pop un
///    [BordereauExtraction] avec uniquement `rue` rempli.
///
/// Returns via Navigator.pop : `BordereauExtraction?` (null si annule).
class ScanBordereauScreen extends ConsumerStatefulWidget {
  const ScanBordereauScreen({super.key});

  @override
  ConsumerState<ScanBordereauScreen> createState() =>
      _ScanBordereauScreenState();
}

class _ScanBordereauScreenState extends ConsumerState<ScanBordereauScreen> {
  static final _frenchPostcodeRegex = RegExp(r'\b\d{5}\b');

  File? _imageFile;
  OcrResult? _ocr;
  BordereauExtraction? _extraction;
  final Set<int> _selectedLineIndices = {};
  bool _processing = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner un bordereau'),
      ),
      body: SafeArea(
        child: _ocr == null ? _buildEmpty() : _buildResult(),
      ),
    );
  }

  Widget _buildEmpty() {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.x18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.x22),
            decoration: BoxDecoration(
              color: p.creamSoft,
              borderRadius: BorderRadius.circular(AppRadius.r18),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.document_scanner_outlined,
                  size: 56,
                  color: p.ink,
                ),
                const SizedBox(height: AppSpacing.x12),
                Text(
                  'Photographie ton bordereau',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.x6),
                Text(
                  'Le texte sera lu localement (hors ligne, gratuit). '
                  'Choisis la photo nette, bordereau a plat.',
                  textAlign: TextAlign.center,
                  style: appMonoStyle(
                    fontSize: 11.5,
                    color: p.textMute,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x22),
          FilledButton.icon(
            onPressed: _processing ? null : () => _pick(ImageSource.camera),
            icon: _processing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.lime,
                    ),
                  )
                : const Icon(Icons.photo_camera_outlined),
            label: const Text('Prendre une photo'),
          ),
          const SizedBox(height: AppSpacing.x10),
          OutlinedButton.icon(
            onPressed: _processing ? null : () => _pick(ImageSource.gallery),
            icon: const Icon(Icons.photo_library_outlined),
            label: const Text('Choisir depuis la galerie'),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.x18),
            Container(
              padding: const EdgeInsets.all(AppSpacing.x12),
              decoration: BoxDecoration(
                color: AppColors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.red),
                  const SizedBox(width: AppSpacing.x10),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 13,
                        color: p.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResult() {
    final p = context.palette;
    final lines = _ocr!.lines;
    final extraction = _extraction;
    // Carte verte uniquement si confidence = high. Sinon carte orange
    // (confidence = low) ou aucune carte (confidence = none).
    final hasAutoExtraction = extraction != null &&
        extraction.hasUsefulData &&
        extraction.confidence == ExtractionConfidence.high;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.x18),
            children: [
              if (_imageFile != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  child: Image.file(
                    _imageFile!,
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              if (hasAutoExtraction) ...[
                const SizedBox(height: AppSpacing.x14),
                AutoDetectionCard(
                  extraction: extraction,
                  onUse: () => _confirmExtraction(extraction),
                ),
              ] else if (extraction != null &&
                  extraction.confidence == ExtractionConfidence.low) ...[
                const SizedBox(height: AppSpacing.x14),
                UncertainDetectionCard(extraction: extraction),
              ],
              const SizedBox(height: AppSpacing.x14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    hasAutoExtraction
                        ? 'OU SELECTION MANUELLE · ${lines.length} LIGNE${lines.length > 1 ? "S" : ""}'
                        : 'TEXTE DETECTE · ${lines.length} LIGNE${lines.length > 1 ? "S" : ""}',
                    style: appMonoStyle(
                      fontSize: 11,
                      color: p.textMute,
                      letterSpacing: 0.6,
                    ),
                  ),
                  TextButton(
                    onPressed: _retake,
                    child: const Text('Reprendre'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(
                hasAutoExtraction
                    ? 'Si la detection auto ci-dessus est incomplete, '
                        'compose l\'adresse en cochant les bonnes lignes.'
                    : 'Tape sur les lignes qui composent l\'adresse '
                        '(les lignes avec un code postal sont surlignees).',
                style: TextStyle(
                  fontSize: 12,
                  color: p.textMute,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              if (lines.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: p.creamSoft,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Text(
                    'Aucun texte detecte. Reessaie avec une photo plus nette '
                    'et bien eclairee.',
                    style: TextStyle(fontSize: 13, color: p.ink),
                  ),
                ),
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x8),
                  child: LineTile(
                    text: lines[i],
                    selected: _selectedLineIndices.contains(i),
                    looksLikeAddress:
                        _frenchPostcodeRegex.hasMatch(lines[i]),
                    onTap: () => _toggleLine(i),
                  ),
                ),
              const SizedBox(height: AppSpacing.x18),
              DebugRawTextSection(lines: lines),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x18,
            AppSpacing.x12,
            AppSpacing.x18,
            AppSpacing.x18,
          ),
          decoration: BoxDecoration(
            color: p.paper,
            border: Border(top: BorderSide(color: p.divider)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECTION',
                      style: appMonoStyle(
                        fontSize: 10,
                        color: p.textMute,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _selectedLineIndices.isEmpty
                          ? 'Aucune ligne'
                          : _composeAddress(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              FilledButton.icon(
                onPressed: _selectedLineIndices.isEmpty ? null : _confirm,
                icon: const Icon(Icons.check),
                label: const Text('Utiliser'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pick(ImageSource source) async {
    setState(() {
      _processing = true;
      _errorMessage = null;
    });
    // Chrono pour mesurer la duree totale du pipeline (pick + OCR +
    // parse + validation BAN). Persiste dans le CSV de stats baseline.
    final scanStarted = DateTime.now();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 2400,
      );
      if (picked == null) {
        if (!mounted) return;
        setState(() => _processing = false);
        return;
      }

      final file = File(picked.path);
      // OCR robuste : si le 1er essai donne un score qualite faible
      // (image scannee dans le mauvais sens / floutee), on retente
      // automatiquement avec rotations 90/180/270 et on garde le
      // meilleur resultat. Cas normal (image bien orientee) = 1 seul
      // appel ML Kit, donc pas de surcout.
      final rotated = await ref
          .read(ocrServiceProvider)
          .extractFromFileWithRotations(file);
      final result = rotated.result;

      if (!mounted) return;
      // Dump des lignes OCR dans logcat (filtrable via tag OCRDUMP)
      // pour debug a distance via `adb logcat -s flutter:V | grep OCRDUMP`.
      debugPrint('OCRDUMP === START (${result.lines.length} lignes, '
          'rotation ${rotated.rotationDegrees} deg, score ${rotated.qualityScore}, '
          'tentatives ${rotated.attemptedRotations}) ===');
      for (var i = 0; i < result.lines.length; i++) {
        debugPrint('OCRDUMP ${i.toString().padLeft(2, "0")}: ${result.lines[i]}');
      }
      debugPrint('OCRDUMP === END ===');

      // Auto-detection format : Chronopost (tracking XR.../XE...FR)
      // puis Colissimo (6A.../6L...), sinon parser MESEXP par defaut.
      BordereauExtraction extraction;
      final String parserUsed;
      if (ChronopostBordereauParser.looksLikeChronopost(result.lines)) {
        extraction = ChronopostBordereauParser().parse(result.lines);
        parserUsed = 'chronopost';
      } else if (ColissimoBordereauParser.looksLikeColissimo(result.lines)) {
        extraction = ColissimoBordereauParser().parse(result.lines);
        parserUsed = 'colissimo';
      } else {
        extraction = BordereauParser().parse(result.lines);
        parserUsed = 'mesexp';
      }
      // Validation BAN post-OCR : si l'extraction a une adresse, on
      // l'envoie a la BAN pour verifier l'existence + corriger la
      // ville / CP en cas de faute OCR. Best-effort (timeout 15s,
      // erreur reseau silencieuse).
      bool banValidated = false;
      double? validationScore;
      try {
        final validation = await ref
            .read(bordereauValidatorProvider)
            .validate(extraction);
        banValidated = validation.validated;
        validationScore = validation.validationScore;
        if (validation.validated) {
          extraction = validation.extraction;
          if (validation.correctionsApplied.isNotEmpty) {
            debugPrint('OCRDUMP === VALIDATION BAN ===');
            for (final c in validation.correctionsApplied) {
              debugPrint('OCRDUMP corr: $c');
            }
            debugPrint('OCRDUMP score: ${validation.validationScore}');
          }
        }
      } catch (_) {
        // best-effort : on garde l'extraction non validee
      }
      // Log stats baseline (best-effort, swallow toute erreur I/O).
      // Sert a mesurer le taux de "carte verte" reel sur les scans
      // Noah avant de demarrer la Phase B OCR (pre-traitement image).
      // Format CSV append-only dans <app_docs>/ocr_stats.csv, accessible
      // depuis Parametres > Stats OCR > Exporter.
      unawaited(OcrStatsLog.instance.log(
        parser: parserUsed,
        confidence: extraction.confidence,
        rotationDeg: rotated.rotationDegrees,
        attempts: rotated.attemptedRotations.length,
        banValidated: banValidated,
        validationScore: validationScore,
        durationMs:
            DateTime.now().difference(scanStarted).inMilliseconds,
      ));
      if (!mounted) return;
      setState(() {
        _imageFile = file;
        _ocr = result;
        _extraction = extraction;
        _selectedLineIndices.clear();
        // Pre-selection : si une ligne ressemble a une adresse, on la coche.
        for (var i = 0; i < result.lines.length; i++) {
          if (_frenchPostcodeRegex.hasMatch(result.lines[i])) {
            _selectedLineIndices.add(i);
            // On essaie de prendre aussi la ligne juste au-dessus (souvent la rue).
            if (i > 0) _selectedLineIndices.add(i - 1);
          }
        }
        _processing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Echec de la lecture : $e';
      });
    }
  }

  void _retake() {
    setState(() {
      _imageFile = null;
      _ocr = null;
      _extraction = null;
      _selectedLineIndices.clear();
    });
  }

  void _toggleLine(int index) {
    setState(() {
      if (!_selectedLineIndices.add(index)) {
        _selectedLineIndices.remove(index);
      }
    });
  }

  String _composeAddress() {
    final lines = _ocr?.lines ?? const [];
    final ordered = _selectedLineIndices.toList()..sort();
    return ordered.map((i) => lines[i]).join(', ');
  }

  /// Confirmation depuis la selection manuelle : on retourne un
  /// extraction avec juste `rue` rempli (l'utilisateur affinera dans
  /// le formulaire si besoin).
  void _confirm() {
    HapticFeedback.lightImpact();
    final composed = _composeAddress();
    Navigator.of(context).pop(BordereauExtraction(rue: composed));
  }

  /// Confirmation depuis la detection auto : on retourne tout.
  void _confirmExtraction(BordereauExtraction extraction) {
    // OCR + parser ont detecte une adresse complete : pulse moyen pour
    // confirmer "ok, on importe tel quel". Le caller (ajout_arret)
    // pre-remplit puis fait HapticFeedback.lightImpact a la sauvegarde.
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(extraction);
  }
}
