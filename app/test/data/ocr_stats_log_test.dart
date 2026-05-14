import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_extraction.dart';
import 'package:opti_route/data/ocr_stats_log.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Tests du logger CSV append-only [OcrStatsLog]. Le path_provider
/// est mocke via [_FakePathProvider] (meme pattern que
/// backup_service_test.dart).
void main() {
  late _FakePathProvider fake;

  setUp(() async {
    fake = _FakePathProvider();
    await fake.setUpDirs();
    PathProviderPlatform.instance = fake;
    // Reset le singleton pour garantir l'isolation entre tests : le
    // fichier precedent (autre dossier docs) ne doit pas influencer.
    await OcrStatsLog.instance.clear();
  });

  tearDown(() async {
    await OcrStatsLog.instance.clear();
    await fake.cleanup();
  });

  test('log : cree le fichier avec header au 1er appel', () async {
    expect(await OcrStatsLog.instance.count(), 0);
    await OcrStatsLog.instance.log(
      parser: 'mesexp',
      confidence: ExtractionConfidence.high,
      rotationDeg: 0,
      attempts: 1,
      banValidated: true,
      validationScore: 0.95,
      durationMs: 850,
    );
    expect(await OcrStatsLog.instance.count(), 1);
    final file = File('${fake.docsDir.path}/ocr_stats.csv');
    expect(await file.exists(), isTrue);
    final lines = await file.readAsLines();
    expect(lines, hasLength(2)); // header + 1 entree
    expect(lines.first,
        'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms');
    expect(lines[1], contains('mesexp'));
    expect(lines[1], contains('high'));
    expect(lines[1], contains('0.950'));
    expect(lines[1], contains('850'));
  });

  test('log : append plusieurs entrees sans ecraser', () async {
    await OcrStatsLog.instance.log(
      parser: 'colissimo',
      confidence: ExtractionConfidence.low,
      rotationDeg: 90,
      attempts: 2,
      banValidated: false,
      durationMs: 1500,
    );
    await OcrStatsLog.instance.log(
      parser: 'chronopost',
      confidence: ExtractionConfidence.none,
      rotationDeg: 180,
      attempts: 4,
      banValidated: false,
      durationMs: 3200,
    );
    expect(await OcrStatsLog.instance.count(), 2);
  });

  test('validationScore null : champ vide dans CSV', () async {
    await OcrStatsLog.instance.log(
      parser: 'mesexp',
      confidence: ExtractionConfidence.high,
      rotationDeg: 0,
      attempts: 1,
      banValidated: false,
      validationScore: null,
      durationMs: 500,
    );
    final file = File('${fake.docsDir.path}/ocr_stats.csv');
    final lines = await file.readAsLines();
    // Format : timestamp,parser,confidence,rot,att,ban,score,dur
    // score doit etre vide entre deux virgules.
    expect(lines[1], matches(RegExp(r',false,,500$')));
  });

  test('count : 0 si fichier inexistant (apres clear)', () async {
    expect(await OcrStatsLog.instance.count(), 0);
  });

  test('clear : supprime le fichier idempotent', () async {
    await OcrStatsLog.instance.log(
      parser: 'mesexp',
      confidence: ExtractionConfidence.high,
      rotationDeg: 0,
      attempts: 1,
      banValidated: false,
      durationMs: 100,
    );
    expect(await OcrStatsLog.instance.count(), 1);
    await OcrStatsLog.instance.clear();
    expect(await OcrStatsLog.instance.count(), 0);
    // 2eme clear : pas d'erreur (idempotent).
    await OcrStatsLog.instance.clear();
    expect(await OcrStatsLog.instance.count(), 0);
  });
}

/// Mock minimal de PathProviderPlatform. Re-utilise le pattern de
/// backup_service_test.dart : 1 dossier temp par test, isole et auto-
/// nettoye en tearDown.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  late Directory docsDir;
  late Directory tmpDir;

  Future<void> setUpDirs() async {
    final base = await Directory.systemTemp.createTemp('opti_route_ocr_test_');
    docsDir = Directory('${base.path}/docs')..createSync();
    tmpDir = Directory('${base.path}/tmp')..createSync();
  }

  Future<void> cleanup() async {
    try {
      final base = docsDir.parent;
      if (await base.exists()) await base.delete(recursive: true);
    } catch (_) {/* best-effort */}
  }

  @override
  Future<String?> getApplicationDocumentsPath() async => docsDir.path;

  @override
  Future<String?> getTemporaryPath() async => tmpDir.path;
}
