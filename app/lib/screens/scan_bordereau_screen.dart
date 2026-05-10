import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/ocr_service.dart';
import '../providers/ocr_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ecran de scan de bordereau de livraison :
/// 1. Capture photo (camera ou galerie).
/// 2. OCR via ML Kit (on-device, hors ligne).
/// 3. Affiche les lignes detectees, surligne celles qui ressemblent a
///    une adresse (code postal francais).
/// 4. L'utilisateur tape sur les lignes a inclure dans l'adresse.
/// 5. Bouton "Utiliser cette adresse" -> pop avec la string concatenee.
///
/// Returns via Navigator.pop : `String?` (null si annule).
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
              const SizedBox(height: AppSpacing.x14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TEXTE DETECTE · ${lines.length} LIGNE${lines.length > 1 ? "S" : ""}',
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
              const Text(
                'Tape sur les lignes qui composent l\'adresse '
                '(les lignes avec un code postal sont surlignees).',
                style: TextStyle(
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
      setState(() {
        _imageFile = file;
        _ocr = result;
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

  void _confirm() {
    final composed = _composeAddress();
    Navigator.of(context).pop(composed);
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
