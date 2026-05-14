import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'backup_service.dart';

/// ════════════════════════════════════════════════════════════════
/// Service de gestion de la liste des fichiers backup.
/// ════════════════════════════════════════════════════════════════
///
/// Liste tous les `.zip` presents dans :
///   - `<external>/auto_backups/` (backups automatiques planifies par
///     [AutoBackupService])
///
/// **Operations** :
///   - [listBackups] : recupere les metadonnees (path / size / mtime)
///   - [deleteBackup] : supprime un fichier (irreversible)
///   - [shareBackup]  : declenche le share_plus pour exporter le zip
///                      vers Drive / mail / etc.
///   - [restoreBackup]: prepare un restore (deferred swap au prochain
///                      boot, cf [BackupService.prepareRestore])
///
/// Pas d'auto-rotation ici : c'est [AutoBackupService] qui gere la
/// retention au moment de la creation. Ici on expose juste l'inventaire
/// pour que l'utilisateur ait la main.
class BackupsListService {
  /// Retourne la liste des backups presents, tri par date de
  /// modification descendante (les plus recents en premier).
  /// Retourne une liste vide si le dossier n'existe pas (cas normal
  /// avant le 1er auto-backup).
  Future<List<BackupFile>> listBackups() async {
    final dir = await _autoBackupDir();
    if (!await dir.exists()) return const [];
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.zip'))
        .toList();
    files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files
        .map((f) {
          final stat = f.statSync();
          return BackupFile(
            path: f.path,
            sizeBytes: stat.size,
            modifiedAt: stat.modified,
          );
        })
        .toList(growable: false);
  }

  /// Supprime un backup. Best-effort : si le fichier n'existe pas
  /// (deja supprime par un autre processus), on swallow l'exception.
  Future<void> deleteBackup(String path) async {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  }

  /// Lance le share_plus natif pour exporter le zip vers Drive /
  /// mail / etc. Idempotent : si le user annule le share, pas
  /// d'erreur.
  Future<void> shareBackup(String path) async {
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path)],
        subject: 'Backup opti_route',
        text: 'Sauvegarde opti_route : '
            '${path.split(Platform.pathSeparator).last}',
      ),
    );
  }

  /// Prepare un restore depuis ce backup. Wrapper pratique sur
  /// [BackupService.prepareRestore] qui ajoute juste la verification
  /// d'existence + transmet le path.
  ///
  /// Le swap effectif n'a lieu qu'au prochain redemarrage de l'app
  /// (cf [BackupService.applyPendingRestoreIfAny]).
  Future<void> restoreBackup(String path) async {
    final f = File(path);
    if (!await f.exists()) {
      throw const BackupException('Fichier introuvable');
    }
    await BackupService().prepareRestore(path);
  }

  /// Resolution du dossier auto_backups. Identique a la logique de
  /// [AutoBackupService] : `getExternalStorageDirectory()` quand
  /// dispo, sinon fallback `getApplicationDocumentsDirectory()`.
  static Future<Directory> _autoBackupDir() async {
    final external = await getExternalStorageDirectory();
    final base = external ?? await getApplicationDocumentsDirectory();
    return Directory('${base.path}${Platform.pathSeparator}auto_backups');
  }
}

/// Metadonnees d'un fichier backup pour l'UI.
class BackupFile {
  const BackupFile({
    required this.path,
    required this.sizeBytes,
    required this.modifiedAt,
  });

  final String path;
  final int sizeBytes;
  final DateTime modifiedAt;

  /// Nom de fichier seul (sans le path complet), pour l'affichage UI.
  String get name => path.split(Platform.pathSeparator).last;

  /// Taille formatee "5.2 MB" / "523 KB" / "42 B".
  String get sizeHuman {
    const kb = 1024;
    const mb = kb * 1024;
    if (sizeBytes >= mb) {
      return '${(sizeBytes / mb).toStringAsFixed(1)} MB';
    }
    if (sizeBytes >= kb) {
      return '${(sizeBytes / kb).toStringAsFixed(0)} KB';
    }
    return '$sizeBytes B';
  }
}
