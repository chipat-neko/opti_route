import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';

/// Ecran "Mon equipe" : gestion CRUD des coequipiers / aidants
/// livraison. Accessible depuis Parametres.
///
/// Cas d'usage : Noah ajoute ses aidants reguliers (Papa, Lucas, etc.)
/// pour pouvoir leur affecter des arrets sur une tournee partagee.
class CoequipiersScreen extends ConsumerWidget {
  const CoequipiersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(coequipiersAllProvider);
    final list = async.asData?.value ?? const <Coequipier>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Mon equipe')),
      body: list.isEmpty
          ? _EmptyState(onAdd: () => _showEditor(context, ref))
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.x18),
              children: [
                Text(
                  'Ajoute les personnes qui te donnent un coup de main '
                  'en tournee. Tu pourras ensuite leur affecter des '
                  'arrets depuis la liste.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: p.textMute,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.x18),
                for (final c in list) _CoequipierTile(coequipier: c),
              ],
            ),
      floatingActionButton: list.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showEditor(context, ref),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Ajouter'),
            ),
    );
  }

  static Future<void> _showEditor(
    BuildContext context,
    WidgetRef ref, {
    Coequipier? edit,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (_) => _CoequipierEditor(edit: edit),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.groups_outlined, size: 48, color: p.textFaint),
            const SizedBox(height: AppSpacing.x14),
            Text(
              'Aucun coequipier pour l\'instant',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              'Ajoute les aidants qui partagent tes tournees pour '
              'tracker qui livre quoi.',
              style: TextStyle(
                fontSize: 13,
                color: p.textMute,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.x22),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Ajouter un coequipier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoequipierTile extends ConsumerWidget {
  const _CoequipierTile({required this.coequipier});

  final Coequipier coequipier;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final isActif = coequipier.actif;
    final avatarColor = colorFromTag(
      coequipier.colorTag,
      defaultColor: AppColors.lime,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x8,
        ),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(color: p.divider),
        ),
        child: Row(
          children: [
            // Avatar avec initiales colorees
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActif ? avatarColor : p.creamSoft,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials(coequipier.nom),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isActif ? AppColors.ink : p.textMute,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          coequipier.nom,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: isActif ? p.ink : p.textMute,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!isActif) ...[
                        const SizedBox(width: AppSpacing.x6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: p.creamSoft,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'ARCHIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: p.textMute,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (coequipier.telephone != null &&
                      coequipier.telephone!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      coequipier.telephone!,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textMute,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: p.textMute, size: 20),
              onSelected: (action) =>
                  _onMenuAction(context, ref, action),
              itemBuilder: (_) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Modifier'),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(isActif ? 'Archiver' : 'Restaurer'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Supprimer',
                      style: TextStyle(color: AppColors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenuAction(
    BuildContext context,
    WidgetRef ref,
    String action,
  ) async {
    final repo = ref.read(coequipiersRepositoryProvider);
    switch (action) {
      case 'edit':
        await CoequipiersScreen._showEditor(context, ref, edit: coequipier);
      case 'toggle':
        await repo.toggleActif(coequipier.id);
      case 'delete':
        if (!context.mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text('Supprimer ${coequipier.nom} ?'),
            content: const Text(
              'Cette action est definitive. Les arrets historiques '
              'qui lui etaient affectes garderont la trace, mais le '
              'nom n\'apparaitra plus dans le selecteur.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Annuler'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.red,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        );
        if (confirmed == true) {
          await repo.delete(coequipier.id);
        }
    }
  }

  static String _initials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// Bottom sheet d'edition / creation. Si `edit` est null, mode creation.
class _CoequipierEditor extends ConsumerStatefulWidget {
  const _CoequipierEditor({this.edit});

  final Coequipier? edit;

  @override
  ConsumerState<_CoequipierEditor> createState() =>
      _CoequipierEditorState();
}

class _CoequipierEditorState extends ConsumerState<_CoequipierEditor> {
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
                  _ColorDot(
                    color: color,
                    selected: _colorTag == tag,
                    onTap: () => setState(() => _colorTag = tag),
                  ),
                _ColorDot(
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
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
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
