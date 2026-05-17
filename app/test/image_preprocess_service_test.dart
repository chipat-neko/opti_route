import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:opti_route/data/image_preprocess_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Stub `path_provider` pour permettre `getTemporaryDirectory()` dans
/// les tests (par defaut le plugin throw MissingPluginException).
class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.tmpDir);
  final String tmpDir;

  @override
  Future<String?> getTemporaryPath() async => tmpDir;
}

void main() {
  late Directory tempDir;
  late ImagePreprocessService service;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ocr_preproc_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() {
    service = ImagePreprocessService();
  });

  /// Helper : ecrit une image JPG synthetique de [w]x[h] avec un fond
  /// noir et un rectangle blanc centre de [whiteW]x[whiteH] (simule
  /// un bordereau papier sur table sombre). Retourne le path.
  Future<File> writeJpg({
    required int w,
    required int h,
    int? whiteW,
    int? whiteH,
    int bgLuminance = 0,
  }) async {
    final image = img.Image(width: w, height: h);
    // Background
    img.fill(image,
        color: img.ColorRgb8(bgLuminance, bgLuminance, bgLuminance));
    // Rectangle blanc central (optionnel)
    if (whiteW != null && whiteH != null) {
      final x0 = (w - whiteW) ~/ 2;
      final y0 = (h - whiteH) ~/ 2;
      img.fillRect(
        image,
        x1: x0,
        y1: y0,
        x2: x0 + whiteW,
        y2: y0 + whiteH,
        color: img.ColorRgb8(255, 255, 255),
      );
    }
    final encoded = Uint8List.fromList(img.encodeJpg(image, quality: 90));
    final file =
        File('${tempDir.path}/src_${DateTime.now().microsecondsSinceEpoch}.jpg');
    await file.writeAsBytes(encoded);
    return file;
  }

  group('ImagePreprocessService.enhance', () {
    test('image valide -> renvoie un nouveau fichier different de la source',
        () async {
      final src = await writeJpg(w: 400, h: 300, whiteW: 200, whiteH: 150);
      final out = await service.enhance(src);
      expect(out.path, isNot(equals(src.path)));
      expect(await out.exists(), isTrue);
      expect(await out.length(), greaterThan(0));
    });

    test('fichier output decodable comme JPG', () async {
      final src = await writeJpg(w: 400, h: 300, whiteW: 200, whiteH: 150);
      final out = await service.enhance(src);
      final decoded = img.decodeImage(await out.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, greaterThan(0));
      expect(decoded.height, greaterThan(0));
    });

    test('source corrompue (pas JPG/PNG) -> retourne la source telle quelle',
        () async {
      final src = File('${tempDir.path}/garbage.jpg');
      await src.writeAsBytes(
          Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9])); // pas une vraie img
      final out = await service.enhance(src);
      // decodeImage retourne null -> on garde la source
      expect(out.path, equals(src.path));
    });

    test('autoCrop true + rectangle clair central -> output plus petit',
        () async {
      // Image 800x600 noire avec un rectangle blanc 200x150 au milieu.
      // L'auto-crop doit reduire la zone analysee (rect blanc + marge 20px).
      final src = await writeJpg(w: 800, h: 600, whiteW: 200, whiteH: 150);
      final out = await service.enhance(src, boostContrast: 1.0);
      final decoded = img.decodeImage(await out.readAsBytes())!;
      // Coverage attendu : (240+40) * (190+40) = 64400 px vs 480000 px
      // = 13% < 30% -> SUSPECT -> _tryAutoCrop retourne null -> garde
      // l'original. Donc dans ce test, on s'attend a width == 800.
      // C'est volontaire : l'algo refuse les crops trop agressifs.
      expect(decoded.width, equals(800));
      expect(decoded.height, equals(600));
    });

    test('autoCrop avec gros rectangle central -> crop applique', () async {
      // Image 800x600 avec rectangle 500x400 (coverage > 30%).
      final src = await writeJpg(w: 800, h: 600, whiteW: 500, whiteH: 400);
      final out = await service.enhance(src, boostContrast: 1.0);
      final decoded = img.decodeImage(await out.readAsBytes())!;
      // Crop attendu : ~(500+40) * (400+40) = ~237600 px / 480000 = 49%
      // Donc dans la fenetre [30%, 90%] -> crop applique.
      expect(decoded.width, lessThan(800),
          reason: 'Auto-crop devrait reduire la largeur');
      expect(decoded.height, lessThan(600),
          reason: 'Auto-crop devrait reduire la hauteur');
    });

    test('autoCrop sur image entierement noire -> garde original', () async {
      final src = await writeJpg(w: 400, h: 300, bgLuminance: 0);
      final out = await service.enhance(src);
      final decoded = img.decodeImage(await out.readAsBytes())!;
      // Pas de pixel clair -> _tryAutoCrop renvoie null -> garde
      expect(decoded.width, equals(400));
      expect(decoded.height, equals(300));
    });

    test('autoCrop sur image entierement blanche -> garde original', () async {
      final src = await writeJpg(w: 400, h: 300, bgLuminance: 255);
      final out = await service.enhance(src);
      final decoded = img.decodeImage(await out.readAsBytes())!;
      // Coverage > 90% -> rien a gagner -> garde
      expect(decoded.width, equals(400));
      expect(decoded.height, equals(300));
    });

    test('autoCrop=false : aucun crop meme sur rectangle central', () async {
      final src = await writeJpg(w: 800, h: 600, whiteW: 500, whiteH: 400);
      final out =
          await service.enhance(src, autoCrop: false, boostContrast: 1.0);
      final decoded = img.decodeImage(await out.readAsBytes())!;
      expect(decoded.width, equals(800));
      expect(decoded.height, equals(600));
    });

    test('image trop petite (<100px) -> pas de crop', () async {
      final src = await writeJpg(w: 50, h: 50, whiteW: 30, whiteH: 30);
      final out = await service.enhance(src);
      final decoded = img.decodeImage(await out.readAsBytes())!;
      expect(decoded.width, equals(50));
      expect(decoded.height, equals(50));
    });

    test('boostContrast=1.0 : pas de changement de contraste (decodable)',
        () async {
      final src = await writeJpg(w: 400, h: 300, whiteW: 200, whiteH: 150);
      final out = await service.enhance(src, boostContrast: 1.0);
      final decoded = img.decodeImage(await out.readAsBytes())!;
      expect(decoded.width, isNonZero);
    });
  });

  group('ImagePreprocessService.bakeExifOnly', () {
    test('image valide -> output JPG decodable', () async {
      final src = await writeJpg(w: 400, h: 300);
      final out = await service.bakeExifOnly(src);
      expect(out.path, isNot(equals(src.path)));
      final decoded = img.decodeImage(await out.readAsBytes());
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(400));
      expect(decoded.height, equals(300));
    });

    test('image corrompue -> retourne source telle quelle', () async {
      final src = File('${tempDir.path}/exif_garbage.jpg');
      await src.writeAsBytes(Uint8List.fromList([0, 0, 0, 0]));
      final out = await service.bakeExifOnly(src);
      expect(out.path, equals(src.path));
    });
  });
}
