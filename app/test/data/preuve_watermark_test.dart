import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:opti_route/data/preuve_photo_service.dart';

/// Tests du filigrane des photos preuves (carte #397).
void main() {
  Uint8List solidJpeg(int w, int h, int gray) {
    final im = img.Image(width: w, height: h);
    img.fill(im, color: img.ColorRgb8(gray, gray, gray));
    return Uint8List.fromList(img.encodeJpg(im, quality: 92));
  }

  test('incruste le filigrane sans changer les dimensions + assombrit le bas',
      () {
    final src = solidJpeg(240, 240, 130);
    final out = PreuvePhotoService.applyWatermarkBytes(
      src,
      'Client Dupont\n03/06/2026 14:22 - 48.45670, 1.23450',
    );
    final decoded = img.decodeImage(out)!;
    expect(decoded.width, 240);
    expect(decoded.height, 240);
    // La bande basse (noir semi-transparent) doit être plus sombre que le
    // haut resté gris d'origine.
    final haut = decoded.getPixel(5, 10).r;
    final bas = decoded.getPixel(5, decoded.height - 4).r;
    expect(bas < haut, isTrue,
        reason: 'le bas (bande) doit être plus sombre que le haut');
  });

  test('texte vide / blancs -> bytes inchangés', () {
    final src = solidJpeg(60, 60, 100);
    expect(PreuvePhotoService.applyWatermarkBytes(src, '   '), src);
    expect(PreuvePhotoService.applyWatermarkBytes(src, ''), src);
  });

  test('bytes non décodables -> renvoyés tels quels (best-effort)', () {
    final junk = Uint8List.fromList([0, 1, 2, 3, 4, 5]);
    expect(PreuvePhotoService.applyWatermarkBytes(junk, 'X'), junk);
  });
}
