import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets de debug et selection manuelle des lignes OCR.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `scan_bordereau_screen.dart` (850 lignes initiales).
/// Regroupe 2 widgets :
/// - [DebugRawTextSection] : section repliable affichant tout le texte
///                            OCR ligne par ligne avec numero + bouton
///                            de copie. Utile pour debugger quand
///                            l'extraction auto se trompe.
/// - [LineTile]            : tile de selection manuelle d'une ligne
///                            (cases a cocher). Reagit visuellement
///                            si la ligne ressemble a une adresse.

/// Section repliable affichant tout le texte OCR ligne par ligne avec
/// numero, et un bouton pour copier dans le presse-papiers. Utile
/// pour debugger le parser quand l'extraction auto se trompe  -  Noah
/// peut copier le texte et l'envoyer au dev pour ajuster les
/// heuristiques aux vraies donnees ML Kit.
class DebugRawTextSection extends StatefulWidget {
  const DebugRawTextSection({super.key, required this.lines});
  final List<String> lines;

  @override
  State<DebugRawTextSection> createState() => _DebugRawTextSectionState();
}

class _DebugRawTextSectionState extends State<DebugRawTextSection> {
  bool _expanded = false;

  String get _numbered =>
      widget.lines.asMap().entries.map((e) => '${e.key.toString().padLeft(2, "0")}: ${e.value}').join('\n');

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.creamSoft,
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
                  Icon(Icons.bug_report_outlined, size: 18, color: p.ink),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      _expanded ? 'Texte brut OCR' : 'Voir le texte brut OCR',
                      style: appMonoStyle(
                        fontSize: 11,
                        color: p.ink,
                        letterSpacing: 0.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: p.ink,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            Divider(height: 1, color: p.inkLine),
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
                          color: p.ink,
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

/// Tile de selection manuelle d'une ligne OCR. Trois etats visuels :
/// - selected : fond lime + bordure ink + checkbox cochee
/// - looksLikeAddress (non selected) : fond amber clair + bordure
///   amber, attire l'attention (parser pense que c'est une adresse)
/// - default : fond paper + bordure inkLine, neutre
class LineTile extends StatelessWidget {
  const LineTile({
    super.key,
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
    final p = context.palette;
    final bg = selected
        ? AppColors.lime.withValues(alpha: 0.4)
        : (looksLikeAddress ? AppColors.amber.withValues(alpha: 0.15) : p.paper);
    final borderColor = selected
        ? p.ink
        : (looksLikeAddress ? AppColors.amber : p.inkLine);

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
              color: selected ? p.ink : p.textMute,
            ),
            const SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: looksLikeAddress ? FontWeight.w700 : FontWeight.w500,
                  color: p.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
