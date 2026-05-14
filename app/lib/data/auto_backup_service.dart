import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import 'notifications_service.dart';
import 'parametres_repository.dart';

/// ════════════════════════════════════════════════════════════════
/// Auto-backup local periodique (sans cloud).
/// ════════════════════════════════════════════════════════════════
///
/// Sauvegarde periodique en arriere-plan dans un dossier accessible
/// depuis n'importe quel file manager Android :
///
///     /storage/emulated/0/Android/data/com.optiroute.opti_route/files/auto_backups/
///
/// L'utilisateur peut copier ces fichiers vers Drive / clef USB s'il
/// veut une vraie sauvegarde off-device. Pas de Drive integre (Phase 2
/// avec Supabase) mais ca couvre 80 % du besoin.
///
/// **Periodicite** : configuree dans Parametres. Trois valeurs :
///   - 'jamais' (defaut) : aucun auto-backup
///   - 'hebdo'  : 1 fois par semaine (7 jours)
///   - 'mensuel': 1 fois par mois (30 jours)
///
/// **Rotation** : on garde les 5 derniers backups auto. Quand on
/// genere le 6e, le plus vieux est supprime. Evite que le dossier
/// gonfle indefiniment.
///
/// **Trigger** : appele depuis `main.dart` au boot. Le 1er check
/// s'execute en arriere-plan (unawaited) pour ne pas bloquer le
/// lancement. Si la periode n'est pas atteinte, no-op silencieux.
class AutoBackupService {
  AutoBackupService(this._params);

  final ParametresRepository _params;

  /// Nombre de backups auto conserves dans le dossier. Au-dela, on
  /// supprime le plus vieux a chaque nouvelle generation.
  static const _maxRetained = 5;

  /// Verifie la periode configuree et genere un backup si l'echeance
  /// est passee. Best-effort : ne throw jamais (log dans logcat
  /// uniquement pour ne pas spammer l'UI au boot).
  Future<void> maybeRunAutoBackup() async {
    try {
      final period = await _params.getAutoBackupPeriod();
      if (period == 'jamais') return;
      final lastAt = await _params.getLastAutoBackupAt();
      final now = DateTime.now();
      if (lastAt != null && !_isPeriodExceeded(period, lastAt, now)) {
        return; // dernier backup encore frais, on attend
      }
      await _runBackup();
      await _params.setLastAutoBackupAt(now);
      debugPrint('[AutoBackup] Backup auto OK ($period)');
    } catch (e) {
      debugPrint('[AutoBackup] Echec : $e');
      // Pas de rethrow : on prefere une app fonctionnelle sans backup
      // a un crash au boot a cause d'un disque plein.
    }
  }

  /// Force la generation d'un backup *maintenant*, sans tenir compte
  /// de la periode configuree. Utile pour le FAB "Creer un backup
  /// maintenant" de [BackupsListScreen] : l'utilisateur veut une
  /// sauvegarde a la demande dans le meme dossier que les
  /// auto-backups (pour qu'elle apparaisse dans la liste).
  ///
  /// Met aussi a jour `lastAt` pour que le prochain auto-backup soit
  /// reporte (sinon on aurait 2 backups consecutifs).
  ///
  /// Throw si la DB est introuvable (cas pratiquement impossible en
  /// runtime mais on prefere une erreur explicite).
  Future<void> runBackupNow() async {
    await _runBackup();
    await _params.setLastAutoBackupAt(DateTime.now());
  }

  /// Genere effectivement le zip dans le dossier external/auto_backups/.
  /// Reutilise la meme structure que BackupService (DB + photos +
  /// manifest) pour que les fichiers soient interoperables avec un
  /// futur restore manuel.
  Future<void> _runBackup() async {
    final dbFile = await _findDatabaseFile();
    if (dbFile == null || !await dbFile.exists()) {
      throw Exception('DB introuvable');
    }

    final outDir = await _getOrCreateAutoBackupDir();
    final ts = DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    final outPath = '${outDir.path}${Platform.pathSeparator}'
        'opti_route_auto_$ts.zip';

    final encoder = ZipFileEncoder();
    encoder.create(outPath);
    try {
      await encoder.addFile(dbFile, 'database.sqlite');
      final preuves = await _findPreuvesDir();
      if (preuves != null && await preuves.exists()) {
        for (final f in preuves
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.jpg'))) {
          final name = f.path.split(Platform.pathSeparator).last;
          try {
            await encoder.addFile(f, 'preuves/$name');
          } catch (_) {/* skip */}
        }
      }
      // Manifest minimal
      final tmpDir = await getTemporaryDirectory();
      final manifestPath = '${tmpDir.path}/manifest_auto_$ts.json';
      final manifest = File(manifestPath);
      await manifest.writeAsString(
        '{"format": "opti_route_backup_v1", "exportedAt": "$ts", '
        '"source": "auto"}',
      );
      await encoder.addFile(manifest, 'manifest.json');
      try {
        await manifest.delete();
      } catch (_) {/* ok */}
    } finally {
      await encoder.close();
    }

    // Rotation : supprime les plus vieux si on depasse _maxRetained.
    await _rotate(outDir);

    // Notif post-backup : signal discret (Importance.low) que ca
    // tourne bien en arriere-plan + taille du fichier pour donner
    // un signal "c'est de la vraie data, pas juste un evenement
    // technique". Best-effort : si stat ou notif echoue, on n'a
    // pas envie de re-throw apres un backup deja reussi.
    try {
      final outFile = File(outPath);
      final size = await outFile.length();
      final filename = outPath.split(Platform.pathSeparator).last;
      await NotificationsService.instance.showBackupSuccess(
        filename: filename,
        sizeBytes: size,
      );
    } catch (e) {
      debugPrint('[AutoBackup] notif backup-success failed: $e');
    }
  }

  /// Supprime les fichiers .zip les plus vieux au-dela de [_maxRetained].
  /// Tri par mtime descendant, on garde les N premiers.
  Future<void> _rotate(Directory dir) async {
    final files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.zip'))
        .toList();
    if (files.length <= _maxRetained) return;
    files.sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    for (var i = _maxRetained; i < files.length; i++) {
      try {
        await files[i].delete();
      } catch (_) {/* on continue */}
    }
  }

  /// Vrai si l'ecart entre [lastAt] et [now] depasse le seuil de la
  /// periode (7 jours pour hebdo, 30 jours pour mensuel).
  static bool _isPeriodExceeded(
      String period, DateTime lastAt, DateTime now) {
    final diff = now.difference(lastAt);
    switch (period) {
      case 'hebdo':
        return diff.inDays >= 7;
      case 'mensuel':
        return diff.inDays >= 30;
      default:
        return false;
    }
  }

  static Future<Directory> _getOrCreateAutoBackupDir() async {
    final external = await getExternalStorageDirectory();
    final base = external ?? await getApplicationDocumentsDirectory();
    final dir =
        Directory('${base.path}${Platform.pathSeparator}auto_backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static Future<File?> _findDatabaseFile() async {
    final docs = await getApplicationDocumentsDirectory();
    for (final name in const ['opti_route.sqlite', 'opti_route.db']) {
      final f = File('${docs.path}${Platform.pathSeparator}$name');
      if (await f.exists()) return f;
    }
    return null;
  }

  static Future<Directory?> _findPreuvesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}preuves');
    if (await dir.exists()) return dir;
    return null;
  }
}
