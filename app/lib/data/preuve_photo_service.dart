import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Service de capture et stockage local des photos preuves de livraison.
///
/// Cas d'usage : Noah depose un colis devant une porte sans signature
/// (livraison express), ou un colis a son nom mais le destinataire n'est
/// pas la. La photo sert de preuve de passage en cas de litige client.
///
/// Stockage : `app_documents/preuves/<stopId>_<timestamp>.jpg`. Reste
/// local au telephone, jamais uploade. L'utilisateur peut consulter
/// depuis l'historique du carnet ou supprimer manuellement.
class PreuvePhotoService {
  PreuvePhotoService({ImagePicker? picker})
      : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Capture une photo via la camera native et la copie dans le
  /// repertoire prive de l'app. Retourne le chemin absolu, ou null si
  /// l'utilisateur a annule, OU si la permission est refusee / le
  /// disque plein / un autre I/O echoue. Best-effort : on ne laisse
  /// jamais une exception remonter a l'UI (deja un fallback SnackBar
  /// en amont).
  Future<String?> capturer({required int stopId}) async {
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 70,
        maxWidth: 1600,
        maxHeight: 1600,
      );
      if (xfile == null) return null;

      final dir = await _preuvesDir();
      final ts = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${dir.path}/${stopId}_$ts.jpg';
      await File(xfile.path).copy(destPath);
      return destPath;
    } catch (_) {
      // Permission refusee / source supprimee entre pick et copy /
      // disque plein. On retourne null silencieusement.
      return null;
    }
  }

  /// Supprime un fichier preuve s'il existe. Safe : ne plante pas si
  /// le fichier a deja ete supprime ou si l'I/O echoue.
  Future<void> supprimer(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {
      // best-effort
    }
  }

  Future<Directory> _preuvesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/preuves');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }
}
