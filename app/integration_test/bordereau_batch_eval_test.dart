// Harness d'evaluation batch du pipeline OCR + parser bordereau.
//
// **But** : mesurer le win rate (taux d'extraction reussie) du parser
// MESEXP sur un batch de N images reelles, sans devoir scanner chaque
// bordereau manuellement dans l'app. Permet de tester rapidement des
// modifications du parser et de comparer avant/apres.
//
// **Workflow** :
// 1. Push les images sur le device : `adb push *.jpg /sdcard/Download/
//    bordereaux_batch_eval/`
// 2. Lance le test :
//    `flutter test integration_test/bordereau_batch_eval_test.dart \
//        -d <device-id>`
// 3. Pull le CSV de resultats :
//    `adb pull /sdcard/Download/batch_eval_results.csv`
// 4. Analyser le CSV (script Python ou manuel) en croisant avec un
//    ground truth labelle a la main.
//
// **Format du CSV** :
//   image,nom_destinataire,rue,code_postal,ville,nb_colis,telephone,
//   confidence,rotation_deg,attempts,duration_ms,raw_first_5_lines
//
// La colonne `raw_first_5_lines` aide a debugger les echecs : on voit
// directement ce que ML Kit a extrait sans avoir besoin de re-OCRiser.

import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/bordereau_parser.dart';
import 'package:opti_route/data/ocr_service.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Bordereau batch eval', () {
    test(
      'OCR + parse N images, dump CSV',
      () async {
        // Strategie 2026-05-22 : sur Android 16 + MIUI, scoped storage
        // bloque /sdcard/Download/ et /sdcard/Pictures/ pour les apps
        // debug sans permission MediaStore (complexe a obtenir).
        // Solution : bundler les images dans les assets de l'APK debug
        // via pubspec `assets: - assets/test_bordereaux/`. Le test
        // copie chaque asset dans un fichier temporaire (necessaire
        // car OcrService prend un File, pas des bytes) puis OCRise.
        //
        // Pour ajouter de nouvelles images : copier dans
        // `app/assets/test_bordereaux/` + ajouter au manifest ci-dessous.
        //
        // Le CSV de sortie est ecrit dans getApplicationDocumentsDirectory()
        // (path connu `/data/data/<pkg>/app_flutter/`), accessible via
        // `adb shell run-as com.optiroute.opti_route cat <path>`.
        const assetPrefix = 'assets/test_bordereaux/';
        // Liste statique des 38 pages (gen via :
        //   ls assets/test_bordereaux/ | sort).
        final assetNames = [
          for (int i = 1; i <= 38; i++)
            'page_${i.toString().padLeft(2, '0')}.jpg',
        ];

        final docsDir = await getApplicationDocumentsDirectory();
        final outputCsv = '${docsDir.path}/batch_eval_results.csv';
        final tmpDir = Directory('${docsDir.path}/_batch_tmp')
          ..createSync(recursive: true);
        debugPrint('=== Assets : ${assetNames.length} images bundled');
        debugPrint('=== Output CSV : $outputCsv');

        // Extract assets to temp files (OcrService needs File path).
        final files = <File>[];
        for (final name in assetNames) {
          final assetPath = '$assetPrefix$name';
          try {
            final bytes = await rootBundle.load(assetPath);
            final f = File('${tmpDir.path}/$name');
            await f.writeAsBytes(bytes.buffer.asUint8List());
            files.add(f);
          } catch (e) {
            debugPrint('  [SKIP] Asset $name not loadable: $e');
          }
        }
        if (files.isEmpty) {
          fail('No images extracted from assets. Check pubspec.yaml '
              'has `assets: - assets/test_bordereaux/` declared and '
              '`flutter pub get` was run.');
        }
        files.sort((a, b) => a.path.compareTo(b.path));
        debugPrint('=== BATCH EVAL : ${files.length} images ===');

        final ocrService = OcrService();
        final parser = BordereauParser();

        // Header CSV avec colonne raw_first_5_lines pour debug.
        // Echappement RFC 4180.
        final csvLines = <String>[
          'image,nom_destinataire,rue,code_postal,ville,nb_colis,'
              'telephone,confidence,rotation_deg,attempts,duration_ms,'
              'raw_first_5_lines',
        ];

        int idx = 0;
        for (final file in files) {
          idx++;
          final name = file.path.split(Platform.pathSeparator).last;
          final start = DateTime.now();
          OcrRotatedResult? rotated;
          String? error;
          try {
            rotated = await ocrService.extractFromFileWithRotations(file);
          } catch (e) {
            error = '$e';
            debugPrint('  [ERROR] $name: $e');
          }
          final duration = DateTime.now().difference(start).inMilliseconds;

          if (rotated == null) {
            csvLines.add([
              _esc(name),
              '', '', '', '', '', '', // champs extraits vides
              'error',
              '0', '0',
              duration.toString(),
              _esc(error ?? 'unknown_error'),
            ].join(','));
            continue;
          }

          // Sprint v9 (2026-05-23) : utiliser parseFromBlocksSpatial
          // (nouvelle approche pure geometrique) avec depotAddress
          // simule = adresse depot Noah. Fallback parseFromBlocks puis
          // parse(lines).
          const depotAddress = '24 Avenue Louis Pasteur 28630 Gellainville';
          BordereauExtraction? extraction;
          if (rotated.result.blocks.isNotEmpty) {
            extraction = parser.parseFromBlocksSpatial(
              rotated.result.blocks,
              depotAddress: depotAddress,
            );
          }
          extraction ??= rotated.result.blocks.isNotEmpty
              ? parser.parseFromBlocks(rotated.result.blocks)
              : parser.parse(rotated.result.lines);
          final raw = rotated.result.lines.take(5).join(' | ');

          csvLines.add([
            _esc(name),
            _esc(extraction.nomDestinataire),
            _esc(extraction.rue),
            _esc(extraction.codePostal),
            _esc(extraction.ville),
            _esc(extraction.nbColis?.toString()),
            _esc(extraction.telephone),
            extraction.confidence.name,
            rotated.rotationDegrees.toString(),
            rotated.attemptedRotations.length.toString(),
            duration.toString(),
            _esc(raw),
          ].join(','));

          debugPrint('  [$idx/${files.length}] $name : '
              '${extraction.confidence.name} '
              '(rot=${rotated.rotationDegrees}°, ${duration}ms) '
              'nom="${extraction.nomDestinataire ?? '?'}" '
              'colis=${extraction.nbColis ?? '?'}');
        }

        // Ecrit le CSV dans app docs (peut etre inaccessible apres
        // cleanup uninstall flutter integration_test).
        final outFile = File(outputCsv);
        await outFile.writeAsString(csvLines.join('\n'));
        debugPrint('=== CSV written : $outputCsv (${csvLines.length} lines)');

        // Aussi dump le CSV complet ligne par ligne dans les logs
        // flutter test. Permet de recuperer le CSV depuis la sortie
        // background du test (workaround scoped storage Android 16 +
        // cleanup auto integration_test).
        debugPrint('=== BEGIN CSV ===');
        for (final line in csvLines) {
          debugPrint('CSV: $line');
        }
        debugPrint('=== END CSV ===');

        // Resume console : breakdown par confidence.
        int high = 0, low = 0, none = 0, error = 0;
        for (final line in csvLines.skip(1)) {
          final parts = line.split(',');
          if (parts.length < 8) continue;
          // Trouve la colonne confidence : index 7 dans le CSV.
          final conf = parts[7];
          switch (conf) {
            case 'high':
              high++;
            case 'low':
              low++;
            case 'none':
              none++;
            case 'error':
              error++;
          }
        }
        final total = high + low + none + error;
        String pct(int n) =>
            total == 0 ? '0%' : '${(100 * n / total).toStringAsFixed(1)}%';
        debugPrint('');
        debugPrint('=== RESUME ===');
        debugPrint('Total           : $total');
        debugPrint('Carte verte     : $high (${pct(high)})');
        debugPrint('Carte orange    : $low (${pct(low)})');
        debugPrint('Carte rouge     : $none (${pct(none)})');
        debugPrint('Erreurs         : $error (${pct(error)})');
      },
      // Le test peut prendre plusieurs minutes pour 30+ images.
      timeout: const Timeout(Duration(minutes: 15)),
    );
  });
}

/// Echappement CSV RFC 4180.
String _esc(String? v) {
  if (v == null || v.isEmpty) return '';
  if (v.contains(',') ||
      v.contains('"') ||
      v.contains('\n') ||
      v.contains('\r')) {
    return '"${v.replaceAll('"', '""')}"';
  }
  return v;
}
