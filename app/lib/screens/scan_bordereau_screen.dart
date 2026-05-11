import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/bordereau_extraction.dart';
import '../data/bordereau/multi_parser.dart';
import '../data/ocr_service.dart';
import '../providers/ocr_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

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
              color: AppColors.creamSoft,
              borderRadius: BorderRadius.circular(AppRadius.r18),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.document_scanner_outlined,
                  size: 56,
                  color: AppColors.ink,
                ),
                const SizedBox(height: AppSpacing.x12),
                const Text(
                  'Photographie ton bordereau',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.x6),
                Text(
                  'Le texte sera lu localement (hors ligne, gratuit). '
                  'Choisis la photo nette, bordereau a plat.',
                  textAlign: TextAlign.center,
                  style: appMonoStyle(
                    fontSize: 11.5,
                    color: AppColors.textMute,
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.ink,
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
                _AutoDetectionCard(
                  extraction: extraction,
                  onUse: () => _confirmExtraction(extraction),
                ),
              ] else if (extraction != null &&
                  extraction.confidence == ExtractionConfidence.low) ...[
                const SizedBox(height: AppSpacing.x14),
                _UncertainDetectionCard(extraction: extraction),
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
                      color: AppColors.textMute,
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
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMute,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              if (lines.isEmpty)
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: AppColors.creamSoft,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: const Text(
                    'Aucun texte detecte. Reessaie avec une photo plus nette '
                    'et bien eclairee.',
                    style: TextStyle(fontSize: 13, color: AppColors.ink),
                  ),
                ),
              for (var i = 0; i < lines.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x8),
                  child: _LineTile(
                    text: lines[i],
                    selected: _selectedLineIndices.contains(i),
                    looksLikeAddress:
                        _frenchPostcodeRegex.hasMatch(lines[i]),
                    onTap: () => _toggleLine(i),
                  ),
                ),
              const SizedBox(height: AppSpacing.x18),
              _DebugRawTextSection(lines: lines),
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
          decoration: const BoxDecoration(
            color: AppColors.paper,
            border: Border(top: BorderSide(color: AppColors.divider)),
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
                        color: AppColors.textMute,
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
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
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

      final file = File(picked.path);
      final result = await ref.read(ocrServiceProvider).extractFromFile(file);

      if (!mounted) return;
      // Dump des lignes OCR dans logcat (filtrable via tag OCRDUMP)
      // pour debug a distance via `adb logcat -s flutter:V | grep OCRDUMP`.
      debugPrint('OCRDUMP === START (${result.lines.length} lignes) ===');
      for (var i = 0; i < result.lines.length; i++) {
        debugPrint('OCRDUMP ${i.toString().padLeft(2, "0")}: ${result.lines[i]}');
      }
      debugPrint('OCRDUMP === END ===');

      final parseResult =
          const MultiFormatBordereauParser().parse(result.lines);
      debugPrint('OCRDUMP format detecte : ${parseResult.format.name}');
      final extraction = parseResult.extraction;
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
    final composed = _composeAddress();
    Navigator.of(context).pop(BordereauExtraction(rue: composed));
  }

  /// Confirmation depuis la detection auto : on retourne tout.
  void _confirmExtraction(BordereauExtraction extraction) {
    Navigator.of(context).pop(extraction);
  }
}

/// Carte orange quand le parser a trouve quelque chose mais n'est
/// pas confiant : il y a des champs detectes mais soit incomplets,
/// soit ambigus. On invite l'utilisateur a verifier manuellement
/// au lieu de pre-remplir automatiquement.
class _UncertainDetectionCard extends StatelessWidget {
  const _UncertainDetectionCard({required this.extraction});

  final BordereauExtraction extraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: AppColors.amber, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.warning_amber_outlined,
                color: AppColors.ink,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.x8),
              Text(
                'DETECTION INCERTAINE',
                style: appMonoStyle(
                  fontSize: 11,
                  color: AppColors.ink,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          const Text(
            'Le bordereau ne suit pas un format que je reconnais '
            'parfaitement. Verifie les bonnes lignes manuellement '
            'ci-dessous pour eviter une mauvaise adresse.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.ink,
              height: 1.4,
            ),
          ),
          if (extraction.codePostal != null ||
              extraction.ville != null ||
              extraction.nbColis != null) ...[
            const SizedBox(height: AppSpacing.x10),
            Text(
              'Champs detectes (a verifier) :',
              style: appMonoStyle(
                fontSize: 10,
                color: AppColors.ink.withValues(alpha: 0.7),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            if (extraction.codePostal != null || extraction.ville != null)
              _ExtractedRow(
                label: 'VILLE?',
                value: [
                  if (extraction.codePostal != null) extraction.codePostal!,
                  if (extraction.ville != null) extraction.ville!,
                ].join(' '),
              ),
            if (extraction.nbColis != null)
              _ExtractedRow(
                label: 'COLIS?',
                value: '${extraction.nbColis}',
                mono: true,
              ),
          ],
        ],
      ),
    );
  }
}

/// Carte affichee en haut quand le parser a reussi a extraire au
/// moins un champ. Permet a l'utilisateur de tout valider en 1 tap.
class _AutoDetectionCard extends StatelessWidget {
  const _AutoDetectionCard({
    required this.extraction,
    required this.onUse,
  });

  final BordereauExtraction extraction;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.ink, size: 18),
              const SizedBox(width: AppSpacing.x8),
              Text(
                'DETECTION AUTOMATIQUE',
                style: appMonoStyle(
                  fontSize: 11,
                  color: AppColors.ink,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          if (extraction.nomDestinataire != null)
            _ExtractedRow(
              label: 'CLIENT',
              value: extraction.nomDestinataire!,
              bold: true,
            ),
          if (extraction.rue != null)
            _ExtractedRow(label: 'RUE', value: extraction.rue!),
          if (extraction.codePostal != null || extraction.ville != null)
            _ExtractedRow(
              label: 'VILLE',
              value: [
                if (extraction.codePostal != null) extraction.codePostal!,
                if (extraction.ville != null) extraction.ville!,
              ].join(' '),
            ),
          if (extraction.nbColis != null)
            _ExtractedRow(
              label: 'COLIS',
              value: '${extraction.nbColis}',
              mono: true,
            ),
          if (extraction.telephone != null)
            _ExtractedRow(
              label: 'TEL',
              value: extraction.telephone!,
              mono: true,
            ),
          const SizedBox(height: AppSpacing.x12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onUse,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.lime,
                minimumSize: const Size(0, 48),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Utiliser ces infos'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExtractedRow extends StatelessWidget {
  const _ExtractedRow({
    required this.label,
    required this.value,
    this.bold = false,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: appMonoStyle(
                fontSize: 10,
                color: AppColors.ink.withValues(alpha: 0.6),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? appMonoStyle(
                      fontSize: 13,
                      color: AppColors.ink,
                      fontWeight:
                          bold ? FontWeight.w800 : FontWeight.w700,
                    )
                  : TextStyle(
                      fontSize: 13,
                      color: AppColors.ink,
                      fontWeight:
                          bold ? FontWeight.w800 : FontWeight.w600,
                      height: 1.3,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section repliable affichant tout le texte OCR ligne par ligne avec
/// numero, et un bouton pour copier dans le presse-papiers. Utile
/// pour debugger le parser quand l'extraction auto se trompe — Noah
/// peut copier le texte et me l'envoyer pour que j'ajuste les
/// heuristiques aux vraies donnees ML Kit.
class _DebugRawTextSection extends StatefulWidget {
  const _DebugRawTextSection({required this.lines});
  final List<String> lines;

  @override
  State<_DebugRawTextSection> createState() => _DebugRawTextSectionState();
}

class _DebugRawTextSectionState extends State<_DebugRawTextSection> {
  bool _expanded = false;

  String get _numbered =>
      widget.lines.asMap().entries.map((e) => '${e.key.toString().padLeft(2, "0")}: ${e.value}').join('\n');

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Row(
                children: [
                  const Icon(Icons.bug_report_outlined, size: 18, color: AppColors.ink),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      _expanded ? 'Texte brut OCR' : 'Voir le texte brut OCR',
                      style: appMonoStyle(
                        fontSize: 11,
                        color: AppColors.ink,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.ink,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1, color: AppColors.inkLine),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x14,
                AppSpacing.x10,
                AppSpacing.x14,
                AppSpacing.x10,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 320),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        _numbered,
                        style: appMonoStyle(
                          fontSize: 11,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x10),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _numbered));
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Texte OCR copie dans le presse-papiers',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.content_copy, size: 16),
                    label: const Text('Copier le texte brut'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LineTile extends StatelessWidget {
  const _LineTile({
    required this.text,
    required this.selected,
    required this.looksLikeAddress,
    required this.onTap,
  });

  final String text;
  final bool selected;
  final bool looksLikeAddress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.lime.withValues(alpha: 0.4)
        : (looksLikeAddress ? AppColors.amber.withValues(alpha: 0.15) : AppColors.paper);
    final borderColor = selected
        ? AppColors.ink
        : (looksLikeAddress ? AppColors.amber : AppColors.inkLine);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x14,
          vertical: AppSpacing.x12,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_box : Icons.check_box_outline_blank,
              size: 20,
              color: selected ? AppColors.ink : AppColors.textMute,
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: looksLikeAddress ? FontWeight.w700 : FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
