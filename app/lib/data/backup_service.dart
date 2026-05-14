import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// ════════════════════════════════════════════════════════════════
/// Service de backup / restore complet de l'app.
/// ════════════════════════════════════════════════════════════════
///
/// **Phase 1, pas de cloud** : permet a Noah de sauvegarder
/// l'integralite de ses donnees dans un fichier zip portable, qu'il
/// peut stocker sur Drive / mail / clef USB / autre phone. En cas
/// de perte du phone, reset usine, ou changement d'appareil, il peut
/// restaurer en quelques tap.
///
/// **Contenu du backup** :
/// 1. `database.sqlite` : tout l'etat metier Drift (tournees, stops,
///    coequipiers, carnet, parametres, cache geocode, historique).
/// 2. Dossier `preuves/` : toutes les photos preuves de livraison
///    (.jpg references par Stop.preuvePhotoPath).
/// 3. `manifest.json` : metadata (version app, date export, nb
///    enregistrements par table). Sert au sanity-check au restore.
///
/// **Format** : zip standard, ouvrable avec n'importe quel outil.
/// L'utilisateur peut meme inspecter le contenu manuellement si
/// besoin de debug.
class BackupService {
  /// Genere un fichier `opti_route_backup_<timestamp>.zip` dans le
  /// dossier temp, contenant DB + photos preuves + manifest, puis
  /// declenche le share natif Android (Drive, mail, etc.).
  ///
  /// Retourne le path du fichier genere (ou null si share annule).
  /// Best-effort : si une photo individuelle est introuvable, on la
  /// skip et on continue. La DB est obligatoire (throw si absente).
  Future<String?> createBackup() async {
    final dbFile = await _findDatabaseFile();
    if (dbFile == null || !await dbFile.exists()) {
      throw const BackupException('Fichier DB introuvable');
    }

    final encoder = ZipFileEncoder();
    final tmpDir = await getTemporaryDirectory();
    final ts = DateTime.now()
        .toIso8601String()
        .split('.')
        .first
        .replaceAll(':', '-');
    final outPath = '${tmpDir.path}/opti_route_backup_$ts.zip';
    encoder.create(outPath);

    try {
      // 1. La DB SQLite a la racine du zip.
      await encoder.addFile(dbFile, 'database.sqlite');

      // 2. Le dossier preuves/ (best-effort, manquant = pas grave si
      // Noah n'a jamais pris de photo preuve).
      final preuvesDir = await _findPreuvesDir();
      if (preuvesDir != null && await preuvesDir.exists()) {
        final files = preuvesDir
            .listSync()
            .whereType<File>()
            .where((f) => f.path.toLowerCase().endsWith('.jpg'))
            .toList();
        for (final f in files) {
          final name = f.path.split(Platform.pathSeparator).last;
          try {
            await encoder.addFile(f, 'preuves/$name');
          } catch (_) {/* skip ce fichier */}
        }
      }

      // 3. Manifest avec metadonnees. Permet au restore de detecter
      // un zip qui n'est pas un backup opti_route.
      final manifestPath = '${tmpDir.path}/manifest_$ts.json';
      final manifest = File(manifestPath);
      await manifest.writeAsString(
        '{"format": "opti_route_backup_v1", "exportedAt": "$ts"}',
      );
      await encoder.addFile(manifest, 'manifest.json');
      // Ne pas oublier de cleanup le manifest temporaire apres
      // l'avoir embarque dans le zip.
      try {
        await manifest.delete();
      } catch (_) {/* best-effort */}
    } finally {
      await encoder.close();
    }

    // Share natif via share_plus
    final result = await SharePlus.instance.share(
      ShareParams(
        files: [XFile(outPath)],
        subject: 'Backup opti_route',
        text:
            'Sauvegarde complete opti_route (DB + photos preuves). A '
            'conserver dans un endroit sur (Drive, clef USB...).',
      ),
    );
    if (result.status == ShareResultStatus.dismissed) return null;
    return outPath;
  }

  /// Prepare un restore depuis [zipPath].
  ///
  /// **Strategie deferred** : on ne peut pas remplacer le fichier DB
  /// pendant que Drift y tient une connexion ouverte. Solution :
  /// 1. Decompresser le zip dans `temp/restore/`.
  /// 2. Valider le manifest (eviter qu'on restore depuis un zip qui
  ///    n'est pas un backup opti_route).
  /// 3. Copier `database.sqlite` du zip vers
  ///    `<docs>/opti_route.sqlite.pending_restore`.
  /// 4. Copier toutes les photos `preuves/*.jpg` extraites vers
  ///    `<docs>/preuves/` (operation immediate, pas de fichier ouvert).
  /// 5. Demander a l'utilisateur de **redemarrer l'app**. Au prochain
  ///    boot, [applyPendingRestoreIfAny] detecte le fichier
  ///    `.pending_restore` et swap avant d'ouvrir Drift.
  ///
  /// Throws [BackupException] si zip invalide, manifest absent, ou
  /// `database.sqlite` manquant a l'interieur.
  Future<void> prepareRestore(String zipPath) async {
    final zipFile = File(zipPath);
    if (!await zipFile.exists()) {
      throw const BackupException('Fichier zip introuvable');
    }
    final bytes = await zipFile.readAsBytes();
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const BackupException('Fichier zip corrompu ou illisible');
    }

    // Sanity-check : manifest present + format reconnu
    final manifestEntry = archive.files.firstWhere(
      (f) => f.name == 'manifest.json',
      orElse: () => ArchiveFile('', 0, []),
    );
    if (manifestEntry.size == 0) {
      throw const BackupException(
          'Pas un backup opti_route (manifest.json absent)');
    }
    final manifestBody = String.fromCharCodes(manifestEntry.content as List<int>);
    if (!manifestBody.contains('opti_route_backup_v1')) {
      throw const BackupException(
          'Format de backup non supporte (mis a jour de l\'app requise ?)');
    }

    // DB SQLite obligatoire
    final dbEntry = archive.files.firstWhere(
      (f) => f.name == 'database.sqlite',
      orElse: () => ArchiveFile('', 0, []),
    );
    if (dbEntry.size == 0) {
      throw const BackupException('database.sqlite absent du backup');
    }

    final docs = await getApplicationDocumentsDirectory();
    // Pose la DB en .pending_restore : le swap se fera au prochain boot.
    final pendingPath = '${docs.path}${Platform.pathSeparator}'
        'opti_route.sqlite.pending_restore';
    final pendingFile = File(pendingPath);
    await pendingFile.writeAsBytes(dbEntry.content as List<int>);

    // Photos preuves : on peut les restorer immediatement (aucun
    // fichier ouvert par l'app, juste de la lecture/ecriture disque).
    final preuvesDir = Directory(
        '${docs.path}${Platform.pathSeparator}preuves');
    if (!await preuvesDir.exists()) await preuvesDir.create();
    for (final entry in archive.files) {
      if (!entry.name.startsWith('preuves/')) continue;
      if (!entry.name.toLowerCase().endsWith('.jpg')) continue;
      if (entry.size == 0) continue;
      final outPath =
          '${preuvesDir.path}${Platform.pathSeparator}'
          '${entry.name.substring("preuves/".length)}';
      try {
        await File(outPath).writeAsBytes(entry.content as List<int>);
      } catch (_) {/* photo individuelle KO = on continue */}
    }
  }

  /// Verifie l'existence d'un fichier `.pending_restore` et l'applique
  /// (swap avec la DB courante). A appeler au boot **avant** d'ouvrir
  /// AppDatabase, sinon Drift va creer une connexion sur l'ancienne
  /// DB et le swap echouera (fichier verrouille).
  ///
  /// Retourne true si un restore a ete applique. L'UI peut alors
  /// afficher un toast "Restore reussi".
  static Future<bool> applyPendingRestoreIfAny() async {
    final docs = await getApplicationDocumentsDirectory();
    final pending = File('${docs.path}${Platform.pathSeparator}'
        'opti_route.sqlite.pending_restore');
    if (!await pending.exists()) return false;
    final target = File('${docs.path}${Platform.pathSeparator}'
        'opti_route.sqlite');
    try {
      // Si l'ancienne DB existe, on la garde en .pre_restore pour
      // safety (l'utilisateur peut revenir en arriere manuellement).
      if (await target.exists()) {
        final backupOldPath = '${target.path}.pre_restore';
        try {
          await target.copy(backupOldPath);
        } catch (_) {/* best-effort */}
        await target.delete();
      }
      await pending.rename(target.path);
      return true;
    } catch (e) {
      // Erreur de swap (permissions, disque plein...). On laisse le
      // .pending_restore en place pour retry au prochain boot.
      return false;
    }
  }

  /// Cherche le fichier DB SQLite genere par `drift_flutter`. Drift
  /// pose la DB dans `getApplicationDocumentsDirectory()` avec le nom
  /// "opti_route.sqlite" (cf AppDatabase constructor). On essaie
  /// quelques variantes au cas ou.
  static Future<File?> _findDatabaseFile() async {
    final docs = await getApplicationDocumentsDirectory();
    // Noms candidats par ordre de probabilite (Drift utilise .sqlite
    // par defaut, ou .db sur certaines versions).
    const candidates = [
      'opti_route.sqlite',
      'opti_route.db',
    ];
    for (final name in candidates) {
      final f = File('${docs.path}${Platform.pathSeparator}$name');
      if (await f.exists()) return f;
    }
    return null;
  }

  /// Cherche le dossier "preuves" dans
  /// `getApplicationDocumentsDirectory()` (cf [PreuvePhotoService]).
  static Future<Directory?> _findPreuvesDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir =
        Directory('${docs.path}${Platform.pathSeparator}preuves');
    if (await dir.exists()) return dir;
    return null;
  }
}

/// Exception specifique pour signaler une erreur de backup avec un
/// message comprehensible cote UI.
class BackupException implements Exception {
  const BackupException(this.message);
  final String message;

  @override
  String toString() => 'BackupException: $message';
}
