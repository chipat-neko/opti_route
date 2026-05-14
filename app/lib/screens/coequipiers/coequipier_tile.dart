import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import 'coequipier_editor.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets de la liste des coequipiers.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `coequipiers_screen.dart` :
/// - [EmptyState]      : ecran central "Aucun coequipier" + invite a
///                       creer (FAB enabled meme quand vide)
/// - [CoequipierTile]  : tile dans la liste avec avatar colore +
///                       nom + tel + menu (Modifier / Archiver /
///                       Supprimer)

/// Affichage central quand la liste des coequipiers est vide. Bouton
/// "Ajouter un coequipier" pour declencher la creation directement
/// depuis l'etat vide (au lieu de devoir scroll vers un FAB cache).
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.onAdd});

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

/// Tile dans la liste avec avatar colore + nom + telephone + popup
/// menu (Modifier / Archiver-Restaurer / Supprimer). Si le coequipier
/// est archive (actif = false), affiche un badge "ARCHIVE" et grise
/// les couleurs.
class CoequipierTile extends ConsumerWidget {
  const CoequipierTile({super.key, required this.coequipier});

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
        await showCoequipierEditor(context, edit: coequipier);
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
