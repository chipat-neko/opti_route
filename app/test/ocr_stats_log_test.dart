import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/ocr_stats_log.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Stub `path_provider` redirige getApplicationDocumentsDirectory vers
/// un tmp dir Dart pour permettre les tests sans plugin Android/iOS.
class _FakePathProvider extends PathProviderPlatform with MockPlatformInterfaceMixin {
  _FakePathProvider(this.docsPath);
  final String docsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsPath;
}

void main() {
  late Directory tempDir;
  late File csvFile;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('ocr_stats_test_');
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
    csvFile = File('${tempDir.path}/ocr_stats.csv');
  });

  tearDownAll(() async {
    await tempDir.delete(recursive: true);
  });

  setUp(() async {
    // Reset CSV avant chaque test pour isolation
    if (await csvFile.exists()) await csvFile.delete();
  });

  group('OcrStatsLog.computeBaseline', () {
    test('fichier inexistant -> empty stats (total=0)', () async {
      final stats = await OcrStatsLog.instance.computeBaseline();
      expect(stats.total, 0);
      expect(stats.greenRate, 0);
      expect(stats.orangeRate, 0);
      expect(stats.redRate, 0);
    });

    test('fichier vide (juste header) -> empty stats', () async {
      await csvFile.writeAsString(
          'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms\n');
      final stats = await OcrStatsLog.instance.computeBaseline();
      expect(stats.total, 0);
    });

    test('1 ligne high -> total=1, greenRate=100%', () async {
      await csvFile.writeAsString(
        'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms\n'
        '2026-05-17T10:00:00,mesexp,high,0,1,true,0.95,1234\n',
      );
      final stats = await OcrStatsLog.instance.computeBaseline();
      expect(stats.total, 1);
      expect(stats.highCount, 1);
      expect(stats.greenRate, 1.0);
      expect(stats.orangeRate, 0);
      expect(stats.redRate, 0);
    });

    test('mix 2 high + 1 low + 1 none -> rates correctes', () async {
      await csvFile.writeAsString(
        'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms\n'
        '2026-05-17T10:00:00,mesexp,high,0,1,true,0.95,1234\n'
        '2026-05-17T10:01:00,mesexp,high,0,1,true,0.92,1500\n'
        '2026-05-17T10:02:00,colissimo,low,90,2,false,,2100\n'
        '2026-05-17T10:03:00,chronopost,none,180,4,false,,3500\n',
      );
      final stats = await OcrStatsLog.instance.computeBaseline();
      expect(stats.total, 4);
      expect(stats.highCount, 2);
      expect(stats.lowCount, 1);
      expect(stats.noneCount, 1);
      expect(stats.greenRate, 0.5);
      expect(stats.orangeRate, 0.25);
      expect(stats.redRate, 0.25);
    });

    test('lignes vides au milieu : ignorees', () async {
      await csvFile.writeAsString(
        'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms\n'
        '2026-05-17T10:00:00,mesexp,high,0,1,true,0.95,1234\n'
        '\n'
        '2026-05-17T10:01:00,mesexp,high,0,1,true,0.92,1500\n'
        '   \n',
      );
      final stats = await OcrStatsLog.instance.computeBaseline();
      expect(stats.total, 2);
    });

    test('lignes mal formees (< 3 colonnes) : ignorees', () async {
      await csvFile.writeAsString(
        'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms\n'
        '2026-05-17T10:00:00,mesexp,high,0,1,true,0.95,1234\n'
        'corrupted_line_no_commas\n'
        ',\n',
      );
      final stats = await OcrStatsLog.instance.computeBaseline();
      expect(stats.total, 1);
      expect(stats.highCount, 1);
    });

    test('confidence inconnu (ex: medium) : ignore', () async {
      await csvFile.writeAsString(
        'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms\n'
        '2026-05-17T10:00:00,mesexp,high,0,1,true,0.95,1234\n'
        '2026-05-17T10:01:00,mesexp,MEDIUM,0,1,true,0.7,1500\n'
        '2026-05-17T10:02:00,mesexp,unknown,0,1,true,0.5,1600\n',
      );
      final stats = await OcrStatsLog.instance.computeBaseline();
      expect(stats.total, 1); // seul high a ete compte
      expect(stats.highCount, 1);
    });

    test('100 scans : 85 high / 10 low / 5 none -> greenRate=0.85', () async {
      final buffer = StringBuffer(
        'timestamp,parser,confidence,rotation_deg,attempts,ban_validated,validation_score,duration_ms\n',
      );
      for (var i = 0; i < 85; i++) {
        buffer.write('2026,m,high,0,1,t,0.9,100\n');
      }
      for (var i = 0; i < 10; i++) {
        buffer.write('2026,m,low,0,1,f,,100\n');
      }
      for (var i = 0; i < 5; i++) {
        buffer.write('2026,m,none,0,1,f,,100\n');
      }
      await csvFile.writeAsString(buffer.toString());
      final stats = await OcrStatsLog.instance.computeBaseline();
      expect(stats.total, 100);
      expect(stats.greenRate, closeTo(0.85, 0.001));
      expect(stats.orangeRate, closeTo(0.10, 0.001));
      expect(stats.redRate, closeTo(0.05, 0.001));
    });
  });

  group('OcrBaselineStats.empty', () {
    test('toutes les valeurs a 0', () {
      const empty = OcrBaselineStats.empty();
      expect(empty.total, 0);
      expect(empty.highCount, 0);
      expect(empty.lowCount, 0);
      expect(empty.noneCount, 0);
      expect(empty.greenRate, 0);
    });
  });

  group('OcrBaselineStats - rates', () {
    test('total=0 : tous les rates = 0 (no divide by zero)', () {
      const stats =
          OcrBaselineStats(highCount: 0, lowCount: 0, noneCount: 0);
      expect(stats.greenRate, 0);
      expect(stats.orangeRate, 0);
      expect(stats.redRate, 0);
    });

    test('total non zero : rates somment a 1.0', () {
      const stats =
          OcrBaselineStats(highCount: 7, lowCount: 2, noneCount: 1);
      final sum = stats.greenRate + stats.orangeRate + stats.redRate;
      expect(sum, closeTo(1.0, 0.001));
    });
  });
}
