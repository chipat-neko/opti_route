import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/bordereau_extraction.dart';
import '../data/pdf_page_render_service.dart';
import '../data/bordereau_parser.dart';
import '../data/chronopost_bordereau_parser.dart';
import '../data/client_memory_service.dart';
import '../data/colissimo_bordereau_parser.dart';
import '../data/france_alliance_bordereau_parser.dart';
import '../data/image_preprocess_service.dart';
import '../data/ocr_llm_enhance_service.dart';
import '../data/ocr_service.dart';
import '../data/ocr_stats_log.dart';
import '../providers/database_providers.dart';
import '../widgets/web_unsupported.dart';
import '../providers/ocr_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'scan_bordereau/debug_section.dart';
import 'scan_bordereau/detection_cards.dart';

/// Logs d'instrumentation OCR (lignes du bordereau = noms/adresses).
/// Guarde par kDebugMode pour ne JAMAIS exposer de PII dans logcat en
/// release (audit #178). En debug, garde le workflow
/// `adb logcat -s flutter:V | grep OCRDUMP`.
void _ocrDump(String message) {
  if (kDebugMode) debugPrint(message);
}

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
/// Returns via Navigator.pop : `BordereauExtraction?` (null si annule)
/// en mode normal, OU `List<BordereauExtraction>` en mode [batch]
/// (carte #119 : scan en rafale, on accumule sans valider entre chaque
/// puis "Terminer" renvoie tout le lot).
class ScanBordereauScreen extends ConsumerStatefulWidget {
  const ScanBordereauScreen({super.key, this.batch = false});

  /// Mode rafale (#119) : chaque scan reussi est empile dans un lot au
  /// lieu d'ouvrir l'ecran de validation. "Terminer" pop la
  /// `List<BordereauExtraction>`.
  final bool batch;

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

  /// Lot accumule en mode batch (#119).
  final List<BordereauExtraction> _batch = [];

  @override
  Widget build(BuildContext context) {
    // Caméra + OCR + rendu PDF dépendent de plugins natifs indisponibles
    // sur navigateur : on évite le crash en informant l'utilisateur.
    if (kIsWeb) {
      return const WebUnsupportedScreen(
        titre: 'Scanner un bordereau',
        message: 'Le scan de bordereaux (caméra + reconnaissance de texte) '
            'fonctionne sur l\'application mobile. Sur ordinateur, ajoute '
            'tes arrêts manuellement ou par collage d\'une liste d\'adresses.',
      );
    }
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
          const SizedBox(height: AppSpacing.x10),
          // Import PDF (carte #118) : un bordereau recu par mail, souvent
          // multi-pages. En mode rafale, toutes les pages sont importees.
          OutlinedButton.icon(
            onPressed: _processing ? null : _importPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Importer un PDF'),
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
          // Mode batch (#119) : compteur + bouton Terminer qui renvoie
          // le lot accumule a l'appelant.
          if (widget.batch && _batch.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.x18),
            Container(
              padding: const EdgeInsets.all(AppSpacing.x12),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.r12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined,
                      color: AppColors.emerald),
                  const SizedBox(width: AppSpacing.x10),
                  Expanded(
                    child: Text(
                      '${_batch.length} bordereau'
                      '${_batch.length > 1 ? "x" : ""} scanne'
                      '${_batch.length > 1 ? "s" : ""} — '
                      'continue ou termine.',
                      style: TextStyle(fontSize: 13, color: p.ink),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: p.paper,
                minimumSize: const Size(0, 52),
              ),
              onPressed: _processing
                  ? null
                  : () => Navigator.of(context)
                      .pop(List<BordereauExtraction>.of(_batch)),
              icon: const Icon(Icons.check),
              label: Text(
                'Terminer (${_batch.length})',
                style: const TextStyle(fontWeight: FontWeight.w700),
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
      await _processFile(File(picked.path));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Echec de la lecture : $e';
      });
    }
  }

  /// Import d'un bordereau PDF (carte #118) : file_picker -> rendu des
  /// pages en images (pdfx) -> chaque page passe dans le meme pipeline
  /// OCR que les photos. En mode rafale [widget.batch], toutes les pages
  /// sont empilees ; sinon seule la 1re page est traitee (validation
  /// unitaire) avec un message si le PDF en contient plusieurs.
  Future<void> _importPdf() async {
    setState(() {
      _processing = true;
      _errorMessage = null;
    });
    try {
      final picked = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      final path = picked?.files.singleOrNull?.path;
      if (path == null) {
        if (mounted) setState(() => _processing = false);
        return;
      }
      final pages = await PdfPageRenderService().renderToImages(File(path));
      if (pages.isEmpty) {
        if (!mounted) return;
        setState(() {
          _processing = false;
          _errorMessage = 'PDF illisible ou vide.';
        });
        return;
      }
      // Mode rafale : toutes les pages. Sinon : la 1re seulement.
      final toProcess = widget.batch ? pages : [pages.first];
      for (final p in toProcess) {
        await _processFile(p);
      }
      if (mounted) setState(() => _processing = false);
      if (!widget.batch && pages.length > 1 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF multi-pages : seule la 1re page importee. '
              'Utilise "Scan rafale" pour tout importer d\'un coup.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _processing = false;
        _errorMessage = 'Echec lecture PDF : $e';
      });
    }
  }

  /// Pipeline OCR complet sur un fichier image (photo camera/galerie OU
  /// page de PDF rendue, carte #118). Blur -> OCR rotations -> parser ->
  /// BAN -> carnet -> LLM -> stats, puis empile (mode batch) ou affiche
  /// la validation unitaire. [_processing] est gere par l'appelant.
  Future<void> _processFile(File file) async {
    // Chrono pour mesurer la duree totale du pipeline (OCR + parse +
    // validation BAN). Persiste dans le CSV de stats baseline.
    final scanStarted = DateTime.now();
    try {
      // Sprint 2.C : detection de flou en amont. Variance du Laplacien
      // sur l'image downsamplee a 480 px. Si trop floue (< 50), on
      // affiche un avertissement non-bloquant pour que Noah puisse
      // reprendre la photo. L'OCR est tente quand meme.
      try {
        final blur = await ImagePreprocessService().detectBlur(file);
        if (blur < 50 && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              backgroundColor: AppColors.amber,
              content: Text(
                'Photo un peu floue, OCR moins fiable. Tu peux reprendre.',
                style: TextStyle(color: AppColors.ink),
              ),
              duration: Duration(seconds: 4),
            ),
          );
        }
        _ocrDump('OCRDUMP === BLUR variance: ${blur.toStringAsFixed(1)}');
      } catch (_) {
        // silent : pas critique
      }
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
      _ocrDump('OCRDUMP === START (${result.lines.length} lignes, '
          'rotation ${rotated.rotationDegrees} deg, score ${rotated.qualityScore}, '
          'tentatives ${rotated.attemptedRotations}) ===');
      for (var i = 0; i < result.lines.length; i++) {
        _ocrDump('OCRDUMP ${i.toString().padLeft(2, "0")}: ${result.lines[i]}');
      }
      _ocrDump('OCRDUMP === END ===');

      // Auto-detection format : Chronopost (tracking XR.../XE...FR)
      // puis Colissimo (6A.../6L...), puis France Alliance (etiquettes
      // ALLIANCE PR / CSG / GETTYGO / FA28), sinon parser MESEXP par defaut.
      BordereauExtraction extraction;
      final String parserUsed;
      if (ChronopostBordereauParser.looksLikeChronopost(result.lines)) {
        extraction = ChronopostBordereauParser().parse(result.lines);
        parserUsed = 'chronopost';
      } else if (ColissimoBordereauParser.looksLikeColissimo(result.lines)) {
        extraction = ColissimoBordereauParser().parse(result.lines);
        parserUsed = 'colissimo';
      } else if (FranceAllianceBordereauParser.looksLikeFranceAlliance(
          result.lines)) {
        extraction = FranceAllianceBordereauParser().parse(result.lines);
        parserUsed = 'france_alliance';
      } else {
        // Nouvelle approche spatiale (feedback Noah 2026-05-23) :
        // 1. trouver le label "destinataire" / "a enlever chez"
        // 2. prendre le RECTANGLE EN DESSOUS comme contenu
        // 3. extraire nom + adresse purement par position spatiale
        //
        // Plus fiable que les heuristiques de contenu. Fallback sur
        // parseFromBlocks (ancien ciblage bbox) si aucun label trouve,
        // puis parse(lines) si pas de blocks du tout.
        // Sprint v7 (feedback Noah 2026-05-23) : passer l'adresse du
        // depot de la tournee courante au parser. Le parser exclut
        // les blocs OCR qui contiennent cette adresse (= bloc
        // transporteur, pas destinataire).
        final currentTournee =
            ref.read(currentTourneeProvider).value;
        final depotAddress = currentTournee?.pointDepartLabel;
        BordereauExtraction? spatial;
        if (result.blocks.isNotEmpty) {
          spatial = BordereauParser().parseFromBlocksSpatial(
            result.blocks,
            depotAddress: depotAddress,
          );
        }
        if (spatial != null) {
          extraction = spatial;
          _ocrDump('OCRDUMP === SPATIAL OK (label -> bloc dessous) ===');
        } else if (result.blocks.isNotEmpty) {
          extraction = BordereauParser().parseFromBlocks(result.blocks);
        } else {
          extraction = BordereauParser().parse(result.lines);
        }
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
            _ocrDump('OCRDUMP === VALIDATION BAN ===');
            for (final c in validation.correctionsApplied) {
              _ocrDump('OCRDUMP corr: $c');
            }
            _ocrDump('OCRDUMP score: ${validation.validationScore}');
          }
        }
      } catch (_) {
        // best-effort : on garde l'extraction non validee
      }
      // Sprint 2.A : memoire clients (carnet d'adresses local).
      // Si le nom OCR matche un client deja connu (fuzzy Levenshtein
      // distance <= 3 OU ratio >= 0.85), on remplace nom + adresse
      // par les infos validees du carnet. 100% offline.
      try {
        final repo = ref.read(savedDestinationsRepositoryProvider);
        final memory = ClientMemoryService(repo);
        final enriched = await memory.enrichWithMemory(extraction);
        if (enriched.source == ExtractionSource.clientMemory) {
          extraction = enriched;
          _ocrDump('OCRDUMP === CLIENT MEMORY MATCH ===');
        }
      } catch (_) {
        // silent : carnet vide ou erreur DB, on garde extraction OCR
      }
      // Boost LLM cloud : appel parallele a l'Edge Function Supabase
      // (Gemini Flash, free tier 1500 req/jour). Best-effort silent :
      // si pas connecte / quota depasse / timeout, on garde le resultat
      // local. Si Gemini retourne quelque chose de SOLIDE, on bascule
      // dessus pour avoir une carte verte avec badge "IA".
      // Gemini en pause : on garde l'appel best-effort silent (au cas
      // ou l'utilisateur active a nouveau plus tard) mais on ne pollue
      // pas l'UI avec des SnackBars debug.
      try {
        final enhanced = await OcrLlmEnhanceService().enhance(
          ocrLines: result.lines,
          formatHint: extraction.format,
          parserUsed: parserUsed,
        );
        if (enhanced != null && _isBetterThan(enhanced, extraction)) {
          extraction = enhanced;
          _ocrDump('OCRDUMP === LLM ENHANCE OK (Gemini) ===');
        }
      } catch (_) {
        // silent : on garde l'extraction locale (offline-first)
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
        // Phase mesure terrain (mai 2026) : on logue aussi les champs
        // extraits pour pouvoir mesurer le win rate par champ
        // (destinataire + nb_colis) et identifier les patterns
        // d'echec specifiques au-dela du score global.
        extraction: extraction,
        imageFilename: file.path.split(Platform.pathSeparator).last,
      ));
      if (!mounted) return;
      // Mode batch (#119) : on empile l'extraction et on reste sur
      // l'ecran de capture pour scanner le suivant (pas de validation
      // unitaire). Un SnackBar confirme + le compteur s'incremente.
      if (widget.batch) {
        setState(() {
          _batch.add(extraction);
          _processing = false;
        });
        final nom = extraction.nomDestinataire?.trim();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scanne : ${nom != null && nom.isNotEmpty ? nom : "bordereau"} '
              '(${_batch.length} au total)',
            ),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
          ),
        );
        return;
      }
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

  /// Vrai si [enhanced] (typiquement renvoyee par le LLM Gemini)
  /// apporte plus d'info utile que [local] (parser heuristique).
  /// Criteres :
  /// - Si enhanced a un nom + adresse complete (rue OU cp+ville) ET
  ///   local n'a pas, c'est mieux.
  /// - Si confidence enhanced > local, c'est mieux (high > low > none).
  /// - Si confidence egale + score "champs remplis" superieur, c'est
  ///   mieux.
  /// Sinon on garde local (offline-first, parser deja valide).
  bool _isBetterThan(BordereauExtraction enhanced, BordereauExtraction local) {
    final order = {
      ExtractionConfidence.high: 2,
      ExtractionConfidence.low: 1,
      ExtractionConfidence.none: 0,
    };
    final ec = order[enhanced.confidence] ?? 0;
    final lc = order[local.confidence] ?? 0;
    if (ec > lc) return true;
    if (ec < lc) return false;
    int score(BordereauExtraction e) {
      var n = 0;
      if (e.nomDestinataire?.isNotEmpty ?? false) n += 3;
      if (e.rue?.isNotEmpty ?? false) n += 2;
      if (e.codePostal?.isNotEmpty ?? false) n += 1;
      if (e.ville?.isNotEmpty ?? false) n += 1;
      if (e.nbColis != null) n += 1;
      if (e.telephone?.isNotEmpty ?? false) n += 1;
      return n;
    }
    return score(enhanced) > score(local);
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
