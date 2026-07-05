import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
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
///
/// Watermark (carte #397) : on peut incruster en bas de la photo un
/// filigrane (nom client + heure + GPS + n° arret) pour qu'une preuve
/// contestee soit verifiable instantanement.
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
  ///
  /// [watermark] : si non vide, incruste en bas de la photo (lignes
  /// separees par `\n`). Si l'incrustation echoue, on sauvegarde la photo
  /// SANS filigrane plutot que de perdre la preuve.
  Future<String?> capturer({required int stopId, String? watermark}) async {
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

      final wm = watermark?.trim();
      if (wm == null || wm.isEmpty) {
        await File(xfile.path).copy(destPath);
        return destPath;
      }

      // Incruste le filigrane. En cas d'echec (decodage impossible, etc.),
      // on retombe sur une copie simple : ne JAMAIS perdre la preuve.
      try {
        final src = await File(xfile.path).readAsBytes();
        final out = applyWatermarkBytes(src, wm);
        await File(destPath).writeAsBytes(out);
      } catch (_) {
        await File(xfile.path).copy(destPath);
      }
      return destPath;
    } catch (_) {
      // Permission refusee / source supprimee entre pick et copy /
      // disque plein. On retourne null silencieusement.
      return null;
    }
  }

  /// Incruste [text] (multi-lignes via `\n`) en bas de l'image JPEG/PNG
  /// fournie et renvoie les octets JPEG resultants. Fonction PURE (pas
  /// d'I/O), exposee pour les tests. Si l'image ne peut pas etre decodee,
  /// renvoie les octets d'entree inchanges (best-effort).
  static Uint8List applyWatermarkBytes(Uint8List bytes, String text) {
    final image = img.decodeImage(bytes);
    if (image == null) return bytes;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    if (lines.isEmpty) return bytes;

    final font = img.arial24;
    final lineH = font.lineHeight > 0 ? font.lineHeight : 28;
    const pad = 12;
    final bandH = lineH * lines.length + pad * 2;
    final top = (image.height - bandH).clamp(0, image.height - 1);

    // Bande noire semi-transparente pour la lisibilite du texte blanc.
    img.fillRect(
      image,
      x1: 0,
      y1: top,
      x2: image.width - 1,
      y2: image.height - 1,
      color: img.ColorRgba8(0, 0, 0, 150),
    );
    var y = top + pad;
    for (final line in lines) {
      img.drawString(
        image,
        line,
        font: font,
        x: pad,
        y: y,
        color: img.ColorRgba8(255, 255, 255, 255),
      );
      y += lineH;
    }
    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }

  /// Enregistre les octets PNG d'une signature dans le repertoire prive
  /// `app_documents/signatures/<stopId>_<ts>.png`. Retourne le chemin
  /// absolu, ou null si l'I/O echoue (best-effort). Demande Noah
  /// 2026-06-03 (signature au "Marquer livre").
  ///
  /// Les octets sont compresses avant ecriture (cf
  /// [compressSignatureBytes]) : un canvas plein ecran genere des PNG
  /// de plusieurs MB alors qu'une signature downscalee a 800px sur
  /// fond blanc pese quelques dizaines de KB (audit 2026-06-11).
  Future<String?> saveSignature({
    required int stopId,
    required Uint8List png,
  }) async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/signatures');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      final ts = DateTime.now().millisecondsSinceEpoch;
      final destPath = '${dir.path}/${stopId}_$ts.png';
      await File(destPath).writeAsBytes(compressSignatureBytes(png));
      return destPath;
    } catch (_) {
      return null;
    }
  }

  /// Reduit une signature PNG : composite sur fond blanc (le canvas de
  /// capture est transparent — un JPEG la rendrait noire, on RESTE en
  /// PNG) puis downscale a [maxWidth] px de large max. Un trait noir
  /// sur fond blanc compresse tres bien en PNG apres resize.
  ///
  /// Fonction PURE (pas d'I/O), exposee pour les tests. Best-effort :
  /// si le decodage echoue, renvoie les octets d'entree inchanges.
  static Uint8List compressSignatureBytes(
    Uint8List png, {
    int maxWidth = 800,
  }) {
    try {
      final decoded = img.decodeImage(png);
      if (decoded == null) return png;
      // Fond blanc opaque (gere la transparence du canvas).
      final canvas = img.Image(width: decoded.width, height: decoded.height);
      img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
      img.compositeImage(canvas, decoded);
      final resized = canvas.width > maxWidth
          ? img.copyResize(canvas, width: maxWidth)
          : canvas;
      return Uint8List.fromList(img.encodePng(resized));
    } catch (_) {
      return png;
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
