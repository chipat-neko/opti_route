import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/cloud_error_humanizer.dart';
import '../data/backup_service.dart';
import '../data/backups_list_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Future provider qui rafraichit la liste des backups disponibles.
/// Pour forcer un refresh apres une action (delete, restore prepared),
/// on appelle `ref.invalidate(_backupsListProvider)` -- Riverpod
/// declenche un nouveau fetch transparemment.
final _backupsListProvider = FutureProvider<List<BackupFile>>((ref) {
  return BackupsListService().listBackups();
});

/// ════════════════════════════════════════════════════════════════
/// Ecran "Mes backups" : liste tous les .zip auto-generes avec
/// taille + date + actions par entree (Restaurer / Partager /
/// Supprimer).
/// ════════════════════════════════════════════════════════════════
///
/// Accessible depuis Parametres > Donnees > "Mes backups". Evite
/// au user de naviguer dans le file manager Android pour gerer ses
/// backups.
///
/// **Etat vide** : si aucun backup auto n'a encore tourne (periode
/// 'jamais' ou app trop recente), on affiche un hint d'activation.
class BackupsListScreen extends ConsumerWidget {
  const BackupsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(_backupsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes backups'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _onCreateBackupNow(context, ref),
        icon: const Icon(Icons.backup_outlined),
        label: const Text('Backup maintenant'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Erreur de lecture : $e',
            style: const TextStyle(color: AppColors.red),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return _EmptyState(palette: p);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(_backupsListProvider);
              await Future<void>.delayed(const Duration(milliseconds: 200));
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x14),
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.x8),
              itemBuilder: (_, i) => _BackupTile(backup: list[i]),
            ),
          );
        },
      ),
    );
  }

  /// Force la creation d'un backup *maintenant* dans le dossier
  /// `auto_backups/`. Affiche un loader pendant la generation (peut
  /// prendre 1-3 s pour zipper DB + photos preuves), invalide la liste
  /// pour qu'il apparaisse, et snack le resultat.
  Future<void> _onCreateBackupNow(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    // Loader bloquant : si Noah tape 2x rapidement, on evite 2 zips.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.x18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: AppSpacing.x12),
                Text('Creation du backup...'),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await ref.read(autoBackupServiceProvider).runBackupNow();
      ref.invalidate(_backupsListProvider);
      if (!context.mounted) return;
      Navigator.of(context).pop(); // ferme le loader
      messenger.showSnackBar(
        SnackBar(
          content: const Text('Backup cree'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context).pop(); // ferme le loader
      messenger.showSnackBar(
        SnackBar(
          content: Text('Erreur creation backup : ${humanizeAnyError(e)}'),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: palette.textMute, size: 56),
            const SizedBox(height: AppSpacing.x14),
            Text(
              'Aucun backup automatique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: palette.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              'Active la sauvegarde auto dans Parametres > Donnees pour '
              'que des .zip soient generes regulierement.\n\n'
              'Tu peux aussi creer une sauvegarde manuelle a tout moment '
              'depuis le meme ecran.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: palette.textMute,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackupTile extends ConsumerWidget {
  const _BackupTile({required this.backup});
  final BackupFile backup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final df = DateFormat('d MMM yyyy a HH:mm', 'fr');
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: p.divider),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.archive_outlined, size: 18),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  df.format(backup.modifiedAt),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ),
              Text(
                backup.sizeHuman,
                style: appMonoStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: p.textMute,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            backup.name,
            style: appMonoStyle(
              fontSize: 11,
              color: p.textMute,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.x10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onShare(context),
                  icon: const Icon(Icons.ios_share, size: 16),
                  label: const Text('Partager'),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _onRestore(context, ref),
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('Restaurer'),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              IconButton(
                onPressed: () => _onDelete(context, ref),
                icon: const Icon(Icons.delete_outline),
                color: AppColors.red,
                tooltip: 'Supprimer',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _onShare(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await BackupsListService().shareBackup(backup.path);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur partage : ${humanizeAnyError(e)}')),
      );
    }
  }

  Future<void> _onRestore(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // Confirmation forte (operation irreversible : remplace TOUTE la
    // donnee actuelle).
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurer ce backup ?'),
        content: Text(
          'Cette action va REMPLACER toutes tes donnees actuelles par '
          'celles du backup du ${DateFormat('d MMM yyyy', 'fr').format(backup.modifiedAt)}.\n\n'
          'Operation IRREVERSIBLE. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      await BackupsListService().restoreBackup(backup.path);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Restore prepare'),
          content: const Text(
            'Le backup a ete charge. Ferme completement l\'app '
            '(swipe out) et relance-la pour finaliser la restauration.',
          ),
          actions: [
            FilledButton(
              onPressed: () => navigator.pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on BackupException catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Restore refuse : ${e.message}'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur restore : ${humanizeAnyError(e)}')),
      );
    }
  }

  Future<void> _onDelete(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce backup ?'),
        content: Text(
          'Le fichier ${backup.name} sera definitivement supprime de '
          'ton telephone. Cette action est irreversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await BackupsListService().deleteBackup(backup.path);
      // Force le refresh de la liste
      ref.invalidate(_backupsListProvider);
      if (!context.mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Backup supprime')),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur suppression : ${humanizeAnyError(e)}')),
      );
    }
  }
}
