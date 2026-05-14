import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Sous-modals secondaires de [StopActionSheet].
/// ════════════════════════════════════════════════════════════════
///
/// Extraits du fichier `stop_action_sheet.dart` (696 lignes initiales).
/// Ces 2 modals partagent le pattern "bottom sheet de selection" :
/// liste d'items + tap = pop avec l'id selectionne. Pas d'etat local,
/// donc des `Future<T?>` top-level conviennent (au lieu de classes
/// stateful).
///
/// - [showCoequipierPicker] : choisir le coequipier auquel affecter
///   l'arret, ou "Moi" pour reset (coequipierId -> null). Modifie
///   directement la base via le repo (side-effect).
/// - [showTargetTourneePicker] : choisir une autre tournee pour
///   deplacer l'arret. Retourne juste l'id, le caller fait le pop
///   avec [MoveToTourneeAction].

/// Bottom sheet de selection d'un coequipier auquel affecter l'arret.
/// "Moi (par defaut)" en haut reset l'affectation (coequipierId -> null).
/// Modal ferme sans selection (back / tap exterieur) -> aucun changement.
/// Side-effect : appelle directement `setCoequipier` sur le repo si
/// l'utilisateur selectionne quelque chose de different.
Future<void> showCoequipierPicker({
  required BuildContext context,
  required WidgetRef ref,
  required Stop stop,
  required List<Coequipier> coequipiers,
}) async {
  final p = context.palette;
  final currentId = stop.coequipierId;
  final picked = await showModalBottomSheet<int?>(
    context: context,
    backgroundColor: p.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.r22),
      ),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x18,
          vertical: AppSpacing.x14,
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
              'Affecter a',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x14),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.lime,
                child: Icon(Icons.person, color: AppColors.ink),
              ),
              title: const Text('Moi (par defaut)'),
              trailing: currentId == null
                  ? const Icon(Icons.check, color: AppColors.emerald)
                  : null,
              onTap: () => Navigator.of(context).pop(null),
            ),
            const Divider(),
            for (final c in coequipiers)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: colorFromTag(
                    c.colorTag,
                    defaultColor: AppColors.creamSoft,
                  ),
                  child: Text(
                    _initialsFor(c.nom),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                title: Text(c.nom),
                trailing: c.id == currentId
                    ? const Icon(Icons.check, color: AppColors.emerald)
                    : null,
                onTap: () => Navigator.of(context).pop(c.id),
              ),
          ],
        ),
      ),
    ),
  );
  if (!context.mounted) return;
  if (picked == currentId) return;
  await ref.read(stopsRepositoryProvider).setCoequipier(stop.id, picked);
}

/// Bottom sheet de selection d'une autre tournee pour deplacer l'arret.
/// Liste toutes les tournees != tournee courante, ordonnees par date
/// desc. Retourne l'id de la tournee choisie, ou null si annule.
///
/// Note : ne touche PAS a la base. Le caller (StopActionSheet) fait le
/// pop avec `MoveToTourneeAction(id)` pour que la tournee parent
/// traite le deplacement (invalidation des optims des 2 tournees +
/// reorder).
Future<int?> showTargetTourneePicker({
  required BuildContext context,
  required WidgetRef ref,
  required Stop stop,
}) async {
  final p = context.palette;
  final db = ref.read(appDatabaseProvider);
  final tournees = await (db.select(db.tournees)
        ..where((t) => t.id.isNotValue(stop.tourneeId))
        ..orderBy([(t) => OrderingTerm.desc(t.date)]))
      .get();
  if (!context.mounted) return null;
  if (tournees.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Aucune autre tournee disponible.')),
    );
    return null;
  }

  final df = DateFormat('d MMM yyyy', 'fr');
  return showModalBottomSheet<int>(
    context: context,
    backgroundColor: p.cream,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.r22),
      ),
    ),
    builder: (sheetCtx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x18,
          AppSpacing.x14,
          AppSpacing.x18,
          AppSpacing.x18,
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
              'Deplacer vers une tournee',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: tournees.length,
                itemBuilder: (_, i) {
                  final t = tournees[i];
                  return ListTile(
                    leading: const Icon(Icons.local_shipping_outlined),
                    title: Text(
                      t.nom,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(df.format(t.date)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(sheetCtx).pop(t.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Helper interne : extrait 1-2 initiales d'un nom de coequipier
/// pour l'avatar du picker. "Jean Dupont" -> "JD", "Lucas" -> "L".
String _initialsFor(String nom) {
  final parts = nom.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
