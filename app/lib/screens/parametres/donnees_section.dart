import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/backup_service.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Donnees" de l'ecran Parametres.
/// ════════════════════════════════════════════════════════════════
///
/// Regroupe les 3 tiles lies a la sauvegarde / restauration :
/// - [BackupTile]     : creer un .zip + share natif Android
/// - [RestoreTile]    : importer un .zip + deferred swap au boot
/// - [AutoBackupTile] : configurer la frequence des backups auto
///
/// Extrait de `parametres_screen.dart` pour alleger ce dernier
/// (initialement 1522 lignes). Les 3 tiles sont autonomes : ils
/// gerent leur propre state local (`_running` pour le loader) et
/// leurs propres providers (period / lastAt).

/// Tile "Creer une sauvegarde" : genere un zip avec la DB SQLite +
/// le dossier preuves/ et declenche le share natif Android.
/// Operation potentiellement longue (selon nb de photos), donc
/// loading state pendant le travail.
class BackupTile extends ConsumerStatefulWidget {
  const BackupTile({super.key});

  @override
  ConsumerState<BackupTile> createState() => _BackupTileState();
}

class _BackupTileState extends ConsumerState<BackupTile> {
  bool _running = false;

  Future<void> _onBackup() async {
    setState(() => _running = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await BackupService().createBackup();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Backup pret (share annule)'
                : 'Backup partage avec succes',
          ),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup refuse : ${e.message}'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur backup : ${humanizeAnyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.archive_outlined),
      title: const Text('Creer une sauvegarde (.zip)'),
      subtitle: const Text(
        'DB + photos preuves dans un fichier partageable',
        style: TextStyle(fontSize: 12),
      ),
      trailing: _running
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share),
      onTap: _running ? null : _onBackup,
    );
  }
}

/// Tile "Restaurer depuis un .zip".
///
/// Workflow (cf BackupService.prepareRestore) :
/// 1. Dialog de confirmation forte (irreversible : remplace TOUTE
///    la donnee courante).
/// 2. file_picker pour choisir le zip.
/// 3. `prepareRestore` decompresse + valide manifest + pose la DB
///    en `.pending_restore` + extrait les photos preuves.
/// 4. Dialog "Redemarre l'app pour finaliser". Au prochain boot,
///    [BackupService.applyPendingRestoreIfAny] dans main() swap la
///    DB et l'app demarre sur les donnees restaurees.
class RestoreTile extends ConsumerStatefulWidget {
  const RestoreTile({super.key});

  @override
  ConsumerState<RestoreTile> createState() => _RestoreTileState();
}

class _RestoreTileState extends ConsumerState<RestoreTile> {
  bool _running = false;

  Future<void> _onRestore() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // 1. Confirmation forte (operation irreversible)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurer un backup ?'),
        content: const Text(
          'Cette action va REMPLACER toutes tes donnees actuelles '
          '(tournees, arrets, carnet, parametres) par celles du fichier '
          'zip choisi. Cette operation est IRREVERSIBLE.\n\n'
          'Continuer ?',
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
    if (!mounted) return;

    // 2. file_picker
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Choisir un backup opti_route (.zip)',
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) return;
    if (!mounted) return;

    setState(() => _running = true);
    try {
      // 3. Prepare le restore (deferred swap)
      await BackupService().prepareRestore(path);
      if (!mounted) return;
      // 4. Dialog "Redemarre l'app"
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Restore prepare'),
          content: const Text(
            'Le backup a ete charge avec succes. Ferme completement '
            'l\'app (swipe out du multitache) et relance-la pour que '
            'tes donnees soient restaurees.',
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
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Restore refuse : ${e.message}'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur restore : ${humanizeAnyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.unarchive_outlined),
      title: const Text('Restaurer depuis un .zip'),
      subtitle: const Text(
        'Remplace les donnees actuelles par celles du backup',
        style: TextStyle(fontSize: 12),
      ),
      trailing: _running
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _running ? null : _onRestore,
    );
  }
}

/// Tile "Sauvegarde auto" : permet a l'utilisateur de configurer la
/// frequence des backups automatiques (jamais / hebdo / mensuel).
///
/// Les backups auto sont generes au demarrage de l'app si la periode
/// est echue (cf AutoBackupService.maybeRunAutoBackup), dans le
/// dossier `/Android/data/<pkg>/files/auto_backups/`. Rotation des 5
/// derniers pour eviter le gonflement.
///
/// Affiche aussi la date du dernier backup auto reussi pour donner
/// du feedback a l'utilisateur ("ah ok, ca tourne bien").
class AutoBackupTile extends ConsumerWidget {
  const AutoBackupTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(autoBackupPeriodProvider).asData?.value ??
        'jamais';
    final lastAtAsync = ref.watch(lastAutoBackupAtProvider);
    final lastAt = lastAtAsync.asData?.value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history),
      title: const Text('Sauvegarde auto'),
      subtitle: Text(
        _subtitle(period, lastAt),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: DropdownButton<String>(
        value: period,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'jamais', child: Text('Jamais')),
          DropdownMenuItem(value: 'hebdo', child: Text('Hebdo')),
          DropdownMenuItem(value: 'mensuel', child: Text('Mensuel')),
        ],
        onChanged: (v) async {
          if (v == null) return;
          await ref
              .read(parametresRepositoryProvider)
              .setAutoBackupPeriod(v);
        },
      ),
    );
  }

  static String _subtitle(String period, DateTime? lastAt) {
    if (period == 'jamais') {
      return 'Active pour generer un .zip dans Android/data/<app>/files/';
    }
    if (lastAt == null) {
      return 'Programme ($period) - premier backup au prochain demarrage';
    }
    final now = DateTime.now();
    final d = now.difference(lastAt);
    final ago = d.inDays > 0
        ? 'il y a ${d.inDays}j'
        : d.inHours > 0
            ? 'il y a ${d.inHours}h'
            : 'a l\'instant';
    return 'Programme ($period) - dernier $ago';
  }
}

/// Stream du auto_backup_period courant (jamais / hebdo / mensuel).
final autoBackupPeriodProvider = StreamProvider<String>((ref) {
  return ref.watch(parametresRepositoryProvider).watchAutoBackupPeriod();
});

/// Future du dernier timestamp de backup auto. Non-stream car valeur
/// figee jusqu'au prochain run du service ; lecture one-shot
/// suffisante pour l'affichage "dernier il y a Nj".
final lastAutoBackupAtProvider = FutureProvider<DateTime?>((ref) {
  // On watch la periode pour re-lire le timestamp quand l'user toggle.
  ref.watch(autoBackupPeriodProvider);
  return ref.read(parametresRepositoryProvider).getLastAutoBackupAt();
});
