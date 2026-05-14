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

  /// Restore : pas implemente dans cette premiere version. Le pattern
  /// est risque (remplace la DB en cours d'utilisation -> il faut
  /// fermer la connexion Drift + remplacer le fichier + relancer
  /// l'app). A faire dans un sprint dedie quand on aura besoin.
  ///
  /// Pour l'instant, en cas de perte, l'utilisateur peut decompresser
  /// le zip manuellement et copier `database.sqlite` au bon endroit
  /// avant de relancer l'app (procedure dans /docs).
  Future<void> restoreFromZip(String zipPath) async {
    throw UnimplementedError(
      'Restore not yet implemented - decompresse manuellement le zip '
      'et copie database.sqlite dans le dossier de l\'app, ou attends '
      'la v2 du backup service.',
    );
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
