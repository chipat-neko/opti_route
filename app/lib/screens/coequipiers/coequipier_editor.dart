import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Bottom sheet d'edition / creation d'un coequipier.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `coequipiers_screen.dart` (513 lignes initiales). Inclut
/// aussi le widget [ColorDot] reutilise dans le selecteur de couleur
/// d'avatar, et la fonction helper [showCoequipierEditor] qui ouvre
/// la bottom sheet (appelable depuis n'importe quel ecran qui veut
/// laisser le user creer / editer un coequipier).

/// Helper qui ouvre la bottom sheet d'edition. Si `edit` est null,
/// mode creation. Sinon, mode modification.
///
/// Public car appele depuis [CoequipiersScreen] (le screen principal)
/// ET depuis [CoequipierTile._onMenuAction] (l'action "Modifier" du
/// popup menu).
Future<void> showCoequipierEditor(
  BuildContext context, {
  Coequipier? edit,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.r22),
      ),
    ),
    builder: (_) => CoequipierEditor(edit: edit),
  );
}

/// Bottom sheet du formulaire de coequipier : nom + telephone +
/// couleur d'avatar. Bouton "Enregistrer" / "Ajouter" selon le mode.
class CoequipierEditor extends ConsumerStatefulWidget {
  const CoequipierEditor({super.key, this.edit});

  final Coequipier? edit;

  @override
  ConsumerState<CoequipierEditor> createState() => _CoequipierEditorState();
}

class _CoequipierEditorState extends ConsumerState<CoequipierEditor> {
  late final TextEditingController _nomCtrl;
  late final TextEditingController _telCtrl;
  String? _colorTag;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.edit;
    _nomCtrl = TextEditingController(text: e?.nom ?? '');
    _telCtrl = TextEditingController(text: e?.telephone ?? '');
    _colorTag = e?.colorTag;
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _telCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isEdit = widget.edit != null;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.x18,
          AppSpacing.x14,
          AppSpacing.x18,
          AppSpacing.x18 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.x14),
                decoration: BoxDecoration(
                  color: p.inkLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              isEdit ? 'Modifier ${widget.edit!.nom}' : 'Nouveau coequipier',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x18),
            TextField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom court',
                hintText: 'Ex: Papa, Lucas, Maman',
                helperText: 'Max 20 caracteres. Affiche en avatar dans la liste.',
                helperMaxLines: 2,
                prefixIcon: Icon(Icons.person_outline),
              ),
              maxLength: 20,
              autofocus: !isEdit,
            ),
            const SizedBox(height: AppSpacing.x10),
            TextField(
              controller: _telCtrl,
              decoration: const InputDecoration(
                labelText: 'Telephone (optionnel)',
                hintText: 'Ex: 06 12 34 56 78',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: AppSpacing.x18),
            Text(
              'Couleur d\'avatar',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x8),
            Wrap(
              spacing: AppSpacing.x8,
              runSpacing: AppSpacing.x8,
              children: [
                for (final (tag, color) in colorTagOptions)
                  ColorDot(
                    color: color,
                    selected: _colorTag == tag,
                    onTap: () => setState(() => _colorTag = tag),
                  ),
                ColorDot(
                  color: p.inkLine,
                  selected: _colorTag == null,
                  onTap: () => setState(() => _colorTag = null),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x22),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.lime,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(isEdit ? 'Enregistrer' : 'Ajouter'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final nom = _nomCtrl.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis un nom')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(coequipiersRepositoryProvider);
      final tel = _telCtrl.text.trim();
      if (widget.edit == null) {
        await repo.create(
          nom: nom,
          colorTag: _colorTag,
          telephone: tel.isEmpty ? null : tel,
        );
      } else {
        await repo.update(
          widget.edit!.id,
          nom: nom,
          colorTag: _colorTag,
          telephone: tel,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
      );
    }
  }
}

/// Pastille colore selectionnable pour le picker de couleur d'avatar.
/// Quand selectionnee, ajoute un border + une icone check.
class ColorDot extends StatelessWidget {
  const ColorDot({
    super.key,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? p.ink : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: selected
            ? Icon(Icons.check, size: 18, color: p.ink)
            : null,
      ),
    );
  }
}
