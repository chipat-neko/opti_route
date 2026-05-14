// Tests E2E pour BackupsListService.
//
// Comme BackupService, ce service utilise getExternalStorageDirectory()
// et getApplicationDocumentsDirectory(). On reuse le meme pattern de
// mock (PathProviderPlatform) que dans backup_service_test.dart.

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/backup_service.dart';
import 'package:opti_route/data/backups_list_service.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  late _FakePathProvider fakePaths;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    fakePaths = _FakePathProvider();
    PathProviderPlatform.instance = fakePaths;
    await fakePaths.setUpDirs();
  });

  tearDown(() async {
    await fakePaths.cleanup();
  });

  group('BackupsListService.listBackups', () {
    test('retourne liste vide si le dossier auto_backups n\'existe pas',
        () async {
      final svc = BackupsListService();
      final list = await svc.listBackups();
      expect(list, isEmpty);
    });

    test('retourne liste vide si dossier existe mais aucun .zip', () async {
      final dir = Directory(
        '${fakePaths.externalDir.path}${Platform.pathSeparator}auto_backups',
      );
      await dir.create(recursive: true);
      // Pose un fichier .txt pour verifier qu'on filtre bien
      await File(
        '${dir.path}${Platform.pathSeparator}readme.txt',
      ).writeAsString('hello');
      final svc = BackupsListService();
      final list = await svc.listBackups();
      expect(list, isEmpty);
    });

    test('liste les .zip tries par date descendante avec metadonnees',
        () async {
      final dir = Directory(
        '${fakePaths.externalDir.path}${Platform.pathSeparator}auto_backups',
      );
      await dir.create(recursive: true);
      final now = DateTime.now();
      // Cree 3 zips avec des mtime distincts
      final old = File(
        '${dir.path}${Platform.pathSeparator}opti_route_auto_2025-01-01.zip',
      );
      await old.writeAsBytes([1, 2, 3]);
      await old.setLastModified(now.subtract(const Duration(days: 30)));
      final mid = File(
        '${dir.path}${Platform.pathSeparator}opti_route_auto_2025-06-01.zip',
      );
      await mid.writeAsBytes([1, 2, 3, 4, 5]);
      await mid.setLastModified(now.subtract(const Duration(days: 7)));
      final recent = File(
        '${dir.path}${Platform.pathSeparator}opti_route_auto_2026-05-14.zip',
      );
      await recent.writeAsBytes(List<int>.filled(2048, 0));
      await recent.setLastModified(now);

      final svc = BackupsListService();
      final list = await svc.listBackups();
      expect(list, hasLength(3));
      // Tri par date desc : recent en premier
      expect(list[0].name, contains('2026-05-14'));
      expect(list[1].name, contains('2025-06-01'));
      expect(list[2].name, contains('2025-01-01'));
      // Tailles preservees
      expect(list[0].sizeBytes, 2048);
      expect(list[1].sizeBytes, 5);
      expect(list[2].sizeBytes, 3);
    });
  });

  group('BackupsListService.deleteBackup', () {
    test('supprime un fichier existant', () async {
      final dir = Directory(
        '${fakePaths.externalDir.path}${Platform.pathSeparator}auto_backups',
      );
      await dir.create(recursive: true);
      final f = File(
        '${dir.path}${Platform.pathSeparator}opti_route_auto.zip',
      );
      await f.writeAsBytes([1, 2, 3]);
      expect(await f.exists(), true);

      await BackupsListService().deleteBackup(f.path);
      expect(await f.exists(), false);
    });

    test('swallow si fichier deja absent (idempotent)', () async {
      final ghost = '${fakePaths.tmpDir.path}/inexistant.zip';
      // Ne doit pas throw
      await BackupsListService().deleteBackup(ghost);
    });
  });

  group('BackupsListService.restoreBackup', () {
    test('rejette un path inexistant avec BackupException', () async {
      final ghost = '${fakePaths.tmpDir.path}/jamais_existe.zip';
      await expectLater(
        () => BackupsListService().restoreBackup(ghost),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('introuvable'),
        )),
      );
    });

    test('prepare bien un .pending_restore pour un zip valide', () async {
      // Construit un zip backup minimal valide
      final zip = '${fakePaths.tmpDir.path}/valid.zip';
      final encoder = ZipFileEncoder()..create(zip);
      final manifest = File('${fakePaths.tmpDir.path}/manifest.json');
      await manifest.writeAsString('{"format": "opti_route_backup_v1"}');
      await encoder.addFile(manifest, 'manifest.json');
      final db = File('${fakePaths.tmpDir.path}/db.sqlite');
      final dbBytes = [0x53, 0x51, 0x4c, 0x69]; // "SQLi"
      await db.writeAsBytes(dbBytes);
      await encoder.addFile(db, 'database.sqlite');
      await encoder.close();

      await BackupsListService().restoreBackup(zip);

      // Verifie que le .pending_restore contient bien les bytes de la
      // DB extraite du zip.
      final pending = File(
        '${fakePaths.docsDir.path}/opti_route.sqlite.pending_restore',
      );
      expect(await pending.exists(), true);
      expect(await pending.readAsBytes(), dbBytes);
    });
  });

  group('BackupFile.sizeHuman', () {
    test('formatte en B / KB / MB selon le seuil', () {
      final dummyDate = DateTime(2026);
      final small = BackupFile(
        path: '/tmp/a.zip',
        sizeBytes: 42,
        modifiedAt: dummyDate,
      ).sizeHuman;
      expect(small, '42 B');
      // KB sans decimale
      final kb = BackupFile(
        path: '/tmp/b.zip',
        sizeBytes: 5120, // 5 KB pile
        modifiedAt: dummyDate,
      ).sizeHuman;
      expect(kb, '5 KB');
      // MB avec 1 decimale
      final mb = BackupFile(
        path: '/tmp/c.zip',
        sizeBytes: 1024 * 1024 * 3 + 1024 * 200, // 3.2 MB
        modifiedAt: dummyDate,
      ).sizeHuman;
      expect(mb, '3.2 MB');
    });
  });
}

/// Reuse exactement le pattern de backup_service_test.dart.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  late Directory tmpDir;
  late Directory docsDir;
  late Directory externalDir;

  Future<void> setUpDirs() async {
    final base = await Directory.systemTemp.createTemp('opti_route_test_');
    tmpDir = Directory('${base.path}/tmp')..createSync();
    docsDir = Directory('${base.path}/docs')..createSync();
    externalDir = Directory('${base.path}/external')..createSync();
  }

  Future<void> cleanup() async {
    try {
      final base = tmpDir.parent;
      if (await base.exists()) await base.delete(recursive: true);
    } catch (_) {/* best-effort */}
  }

  @override
  Future<String?> getTemporaryPath() async => tmpDir.path;

  @override
  Future<String?> getApplicationDocumentsPath() async => docsDir.path;

  @override
  Future<String?> getExternalStoragePath() async => externalDir.path;
}
