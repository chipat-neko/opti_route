import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import 'coequipiers/coequipier_editor.dart';
import 'coequipiers/coequipier_tile.dart';

/// Ecran "Mon equipe" : gestion CRUD des coequipiers / aidants
/// livraison. Accessible depuis Parametres.
///
/// Cas d'usage : Noah ajoute ses aidants reguliers (Papa, Lucas, etc.)
/// pour pouvoir leur affecter des arrets sur une tournee partagee.
///
/// **Refactor 2026-05-14** : extrait [CoequipierTile] / [EmptyState]
/// dans `coequipiers/coequipier_tile.dart` et [CoequipierEditor] /
/// [ColorDot] dans `coequipiers/coequipier_editor.dart`. Le screen
/// principal ne garde que l'orchestration (liste, FAB, hint texte).
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
          ? EmptyState(onAdd: () => showCoequipierEditor(context))
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
                for (final c in list) CoequipierTile(coequipier: c),
              ],
            ),
      floatingActionButton: list.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showCoequipierEditor(context),
              icon: const Icon(Icons.person_add_outlined),
              label: const Text('Ajouter'),
            ),
    );
  }
}
