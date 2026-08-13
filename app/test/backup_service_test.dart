// Tests E2E pour BackupService et AutoBackupService.
//
// Les services utilisent `getApplicationDocumentsDirectory()` et
// `getExternalStorageDirectory()` qui sont des plugins natifs Android.
// En test, on les mock via PathProviderPlatform pour pointer vers des
// dossiers temporaires controles.

import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/auto_backup_service.dart';
import 'package:opti_route/data/backup_service.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'helpers/test_db.dart';

/// Horloge figee de la suite (F8a) : mercredi 13 mai 2026, 10h30.
/// Injectee dans [AutoBackupService] via `now:` pour rendre le seuil de
/// periode (7j / 30j) et l'horodatage du zip independants de la date
/// reelle de la machine.
final kNow = DateTime(2026, 5, 13, 10, 30);

/// Nom de fichier attendu quand le backup est genere a [kNow] :
/// l'horodatage vient de `now().toIso8601String()` avec les `:`
/// remplaces par des `-`.
const kZipNameAtNow = 'opti_route_auto_2026-05-13T10-30-00.zip';

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

  group('BackupService.prepareRestore', () {
    test('rejette un fichier zip inexistant', () async {
      final svc = BackupService();
      await expectLater(
        () => svc.prepareRestore('${fakePaths.tmpDir.path}/inexistant.zip'),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('introuvable'),
        )),
      );
    });

    test('rejette un fichier non-zip (rejet via manifest)', () async {
      // Note : `ZipDecoder` est tres permissif : un fichier texte
      // brut est decode comme une archive vide plutot que de throw.
      // Du coup notre flow rejette via le check "manifest absent",
      // pas via "corrompu". Defense-in-depth : les 2 messages sont
      // acceptables tant qu'on refuse l'import.
      final fake = File('${fakePaths.tmpDir.path}/fake.zip');
      await fake.writeAsString('pas un zip du tout');
      final svc = BackupService();
      await expectLater(
        () => svc.prepareRestore(fake.path),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          anyOf(contains('corrompu'), contains('manifest.json absent')),
        )),
      );
    });

    test('rejette un zip sans manifest.json', () async {
      final zip = '${fakePaths.tmpDir.path}/no_manifest.zip';
      final encoder = ZipFileEncoder()..create(zip);
      final dummy = File('${fakePaths.tmpDir.path}/dummy.txt');
      await dummy.writeAsString('hello');
      await encoder.addFile(dummy, 'random.txt');
      await encoder.close();
      final svc = BackupService();
      await expectLater(
        () => svc.prepareRestore(zip),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('manifest.json absent'),
        )),
      );
    });

    test('rejette un zip avec manifest mais format inconnu', () async {
      final zip = await _buildBackupZip(
        outPath: '${fakePaths.tmpDir.path}/wrong_format.zip',
        manifestBody:
            '{"format": "autre_app_backup_v3", "exportedAt": "2026-01-01"}',
        dbContent: [1, 2, 3],
      );
      final svc = BackupService();
      await expectLater(
        () => svc.prepareRestore(zip),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('non supporte'),
        )),
      );
    });

    test('rejette un zip sans database.sqlite', () async {
      final zip = '${fakePaths.tmpDir.path}/no_db.zip';
      final encoder = ZipFileEncoder()..create(zip);
      final manifest = File('${fakePaths.tmpDir.path}/manifest.json');
      await manifest
          .writeAsString('{"format": "opti_route_backup_v1"}');
      await encoder.addFile(manifest, 'manifest.json');
      await encoder.close();
      await manifest.delete();
      final svc = BackupService();
      await expectLater(
        () => svc.prepareRestore(zip),
        throwsA(isA<BackupException>().having(
          (e) => e.message,
          'message',
          contains('database.sqlite absent'),
        )),
      );
    });

    test('pose le .pending_restore avec le contenu de la DB du zip',
        () async {
      final dbBytes = [0x53, 0x51, 0x4c, 0x69, 0x74, 0x65]; // "SQLite"
      final zip = await _buildBackupZip(
        outPath: '${fakePaths.tmpDir.path}/ok.zip',
        manifestBody: '{"format": "opti_route_backup_v1"}',
        dbContent: dbBytes,
      );
      final svc = BackupService();
      await svc.prepareRestore(zip);

      final pending = File(
        '${fakePaths.docsDir.path}/opti_route.sqlite.pending_restore',
      );
      expect(await pending.exists(), true);
      expect(await pending.readAsBytes(), dbBytes);
    });

    test('extrait les photos preuves dans <docs>/preuves/', () async {
      final zip = '${fakePaths.tmpDir.path}/with_preuves.zip';
      final encoder = ZipFileEncoder()..create(zip);
      final manifest = File('${fakePaths.tmpDir.path}/manifest.json');
      await manifest
          .writeAsString('{"format": "opti_route_backup_v1"}');
      await encoder.addFile(manifest, 'manifest.json');
      final dummyDb = File('${fakePaths.tmpDir.path}/dummy.sqlite');
      await dummyDb.writeAsBytes([1, 2, 3]);
      await encoder.addFile(dummyDb, 'database.sqlite');
      // Deux fausses photos preuves
      final p1 = File('${fakePaths.tmpDir.path}/p1.jpg');
      await p1.writeAsBytes([0xFF, 0xD8, 0xFF]); // header JPEG
      await encoder.addFile(p1, 'preuves/123_2026.jpg');
      final p2 = File('${fakePaths.tmpDir.path}/p2.jpg');
      await p2.writeAsBytes([0xFF, 0xD8, 0xFF, 0xE0]);
      await encoder.addFile(p2, 'preuves/456_2026.jpg');
      await encoder.close();

      final svc = BackupService();
      await svc.prepareRestore(zip);

      final restoredDir = Directory('${fakePaths.docsDir.path}/preuves');
      expect(await restoredDir.exists(), true);
      final files = restoredDir.listSync().whereType<File>().toList();
      expect(files, hasLength(2));
      expect(
        files.map((f) => f.path.split(Platform.pathSeparator).last).toSet(),
        {'123_2026.jpg', '456_2026.jpg'},
      );
    });
  });

  group('BackupService.applyPendingRestoreIfAny', () {
    test('retourne false si aucun .pending_restore', () async {
      final applied = await BackupService.applyPendingRestoreIfAny();
      expect(applied, false);
    });

    test('swap le pending vers le path principal + garde .pre_restore',
        () async {
      // Setup : DB courante + pending
      final current = File('${fakePaths.docsDir.path}/opti_route.sqlite');
      await current.writeAsBytes([0xAA, 0xAA]);
      final pending = File(
        '${fakePaths.docsDir.path}/opti_route.sqlite.pending_restore',
      );
      await pending.writeAsBytes([0xBB, 0xBB]);

      final applied = await BackupService.applyPendingRestoreIfAny();
      expect(applied, true);
      // Le pending a disparu (renomme)
      expect(await pending.exists(), false);
      // La DB courante contient maintenant le contenu du pending
      expect(await current.readAsBytes(), [0xBB, 0xBB]);
      // L'ancienne est sauvee en .pre_restore
      final preRestore =
          File('${fakePaths.docsDir.path}/opti_route.sqlite.pre_restore');
      expect(await preRestore.exists(), true);
      expect(await preRestore.readAsBytes(), [0xAA, 0xAA]);
    });

    test('si pas de DB courante existante : swap quand meme propre',
        () async {
      // Cas : 1ere installation puis import direct du backup
      final pending = File(
        '${fakePaths.docsDir.path}/opti_route.sqlite.pending_restore',
      );
      await pending.writeAsBytes([0xCC, 0xCC]);
      final applied = await BackupService.applyPendingRestoreIfAny();
      expect(applied, true);
      final current = File('${fakePaths.docsDir.path}/opti_route.sqlite');
      expect(await current.exists(), true);
      expect(await current.readAsBytes(), [0xCC, 0xCC]);
    });
  });

  group('AutoBackupService', () {
    late AppDatabase db;
    late ParametresRepository params;

    setUp(() {
      db = makeTestDb();
      params = ParametresRepository(db);
    });

    tearDown(() async {
      await db.close();
    });

    /// Service cale sur une horloge figee ([kNow] par defaut).
    AutoBackupService svcAt([DateTime? fixed]) =>
        AutoBackupService(params, now: () => fixed ?? kNow);

    test('period "jamais" : ne genere rien', () async {
      // Pose une fausse DB pour ne pas avoir Exception "DB introuvable"
      await File('${fakePaths.docsDir.path}/opti_route.sqlite')
          .writeAsBytes([1, 2, 3]);

      final svc = svcAt();
      // Periode par defaut = 'jamais', pas besoin de la set
      await svc.maybeRunAutoBackup();

      final dir = Directory('${fakePaths.externalDir.path}/auto_backups');
      // Dossier non cree ou vide
      expect(
        !await dir.exists() || dir.listSync().isEmpty,
        true,
      );
      // lastAt reste null (pas mis a jour)
      expect(await params.getLastAutoBackupAt(), isNull);
    });

    test('period "hebdo" + lastAt recent : skip', () async {
      await File('${fakePaths.docsDir.path}/opti_route.sqlite')
          .writeAsBytes([1, 2, 3]);
      await params.setAutoBackupPeriod('hebdo');
      // Dernier backup il y a 2 jours -> on est pas encore a 7j
      final twoDaysAgo = kNow.subtract(const Duration(days: 2));
      await params.setLastAutoBackupAt(twoDaysAgo);

      final svc = svcAt();
      await svc.maybeRunAutoBackup();

      final dir = Directory('${fakePaths.externalDir.path}/auto_backups');
      expect(
        !await dir.exists() || dir.listSync().isEmpty,
        true,
      );
      // lastAt n'a pas bouge
      final newLastAt = await params.getLastAutoBackupAt();
      expect(newLastAt, twoDaysAgo);
    });

    test('period "hebdo" + lastAt > 7j : genere un backup', () async {
      await File('${fakePaths.docsDir.path}/opti_route.sqlite')
          .writeAsBytes([1, 2, 3, 4]);
      await params.setAutoBackupPeriod('hebdo');
      // Dernier backup il y a 10 jours
      await params.setLastAutoBackupAt(
        kNow.subtract(const Duration(days: 10)),
      );

      final svc = svcAt();
      await svc.maybeRunAutoBackup();

      final dir = Directory('${fakePaths.externalDir.path}/auto_backups');
      expect(await dir.exists(), true);
      final zips = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.zip'))
          .toList();
      expect(zips, hasLength(1));
      // Le nom du zip est horodate par l'horloge injectee : plus besoin
      // d'une assertion floue sur "un nom qui commence par...".
      expect(
        zips.single.path.split(Platform.pathSeparator).last,
        kZipNameAtNow,
      );
      // lastAt mis a jour, exactement a l'instant injecte (avant : une
      // tolerance de 10 secondes sur l'horloge reelle).
      expect(await params.getLastAutoBackupAt(), kNow);
    });

    test('rotation : garde seulement les 5 derniers backups', () async {
      await File('${fakePaths.docsDir.path}/opti_route.sqlite')
          .writeAsBytes([1, 2, 3]);
      await params.setAutoBackupPeriod('hebdo');

      // Pose 7 anciens zips a la main dans le dossier auto_backups,
      // avec des mtime distincts et croissants. Dates fixes tres
      // anciennes : le mtime du zip genere par le service vient du
      // systeme de fichiers (pas de l'horloge injectee), il sera donc
      // forcement le plus recent des 8.
      final dir =
          Directory('${fakePaths.externalDir.path}/auto_backups');
      await dir.create(recursive: true);
      for (var i = 0; i < 7; i++) {
        final f = File(
          '${dir.path}${Platform.pathSeparator}opti_route_auto_old_$i.zip',
        );
        await f.writeAsBytes([i]);
        // i = 0 est le plus vieux, i = 6 le plus recent.
        await f.setLastModified(DateTime(2020, 1, 1).add(Duration(days: i)));
      }

      // Force le run en posant lastAt il y a 100 jours
      await params.setLastAutoBackupAt(
        kNow.subtract(const Duration(days: 100)),
      );

      final svc = svcAt();
      await svc.maybeRunAutoBackup();

      final zips = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.zip'))
          .toList();
      // 7 anciens + 1 nouveau = 8, rotation a 5 -> il en reste 5
      expect(zips, hasLength(5));
      final names = zips
          .map((f) => f.path.split(Platform.pathSeparator).last)
          .toSet();
      // Le nouveau est conserve, les 3 plus vieux sont supprimes.
      expect(names, contains(kZipNameAtNow));
      expect(names.any((n) => n.contains('old_0.zip')), false);
      expect(names.any((n) => n.contains('old_1.zip')), false);
      expect(names.any((n) => n.contains('old_2.zip')), false);
    });

    // ──────────────────────────────────────────────────────────────
    // F8a — bornes exactes de la periode. Avant l'injection d'horloge
    // ces cas etaient intestables : `_isPeriodExceeded` comparait
    // `lastAt` a l'heure reelle, donc un `lastAt` pose "il y a
    // exactement 7 jours" glissait de quelques microsecondes entre
    // l'ecriture et la lecture.
    // ──────────────────────────────────────────────────────────────
    test('hebdo : 6j23h -> skip, exactement 7j -> genere', () async {
      await File('${fakePaths.docsDir.path}/opti_route.sqlite')
          .writeAsBytes([1, 2, 3]);
      await params.setAutoBackupPeriod('hebdo');
      final dir = Directory('${fakePaths.externalDir.path}/auto_backups');

      // 6 jours et 23 heures : le seuil (inDays >= 7) n'est pas atteint.
      await params.setLastAutoBackupAt(
        kNow.subtract(const Duration(days: 6, hours: 23)),
      );
      await svcAt().maybeRunAutoBackup();
      expect(!await dir.exists() || dir.listSync().isEmpty, true);

      // Exactement 7 jours : le seuil est atteint (comparaison >=).
      await params.setLastAutoBackupAt(
        kNow.subtract(const Duration(days: 7)),
      );
      await svcAt().maybeRunAutoBackup();
      expect(dir.listSync().whereType<File>(), hasLength(1));
      expect(await params.getLastAutoBackupAt(), kNow);
    });

    test('mensuel : le seuil de 30j se compte en jours reels, pas en '
        'mois calendaires', () async {
      await File('${fakePaths.docsDir.path}/opti_route.sqlite')
          .writeAsBytes([1, 2, 3]);
      await params.setAutoBackupPeriod('mensuel');
      await params.setLastAutoBackupAt(DateTime(2026, 1, 31, 8));
      final dir = Directory('${fakePaths.externalDir.path}/auto_backups');

      // 1er mars : fevrier 2026 ne fait que 28 jours -> 29 jours
      // ecoules seulement, donc pas encore de backup malgre le
      // changement de mois.
      await svcAt(DateTime(2026, 3, 1, 8)).maybeRunAutoBackup();
      expect(!await dir.exists() || dir.listSync().isEmpty, true);
      expect(await params.getLastAutoBackupAt(), DateTime(2026, 1, 31, 8));

      // 2 mars : 30 jours pleins -> backup.
      await svcAt(DateTime(2026, 3, 2, 8)).maybeRunAutoBackup();
      expect(dir.listSync().whereType<File>(), hasLength(1));
      expect(await params.getLastAutoBackupAt(), DateTime(2026, 3, 2, 8));
    });

    test('runBackupNow ignore la periode et horodate a l horloge',
        () async {
      await File('${fakePaths.docsDir.path}/opti_route.sqlite')
          .writeAsBytes([1, 2, 3]);
      // Periode 'jamais' : maybeRunAutoBackup ne ferait rien.
      await svcAt().runBackupNow();

      final dir = Directory('${fakePaths.externalDir.path}/auto_backups');
      final zips = dir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.zip'))
          .toList();
      expect(zips, hasLength(1));
      expect(
        zips.single.path.split(Platform.pathSeparator).last,
        kZipNameAtNow,
      );
      expect(await params.getLastAutoBackupAt(), kNow);
    });
  });
}

/// Helper : construit un zip "backup-like" avec un manifest custom
/// et un contenu DB arbitraire. Retourne le path du zip.
Future<String> _buildBackupZip({
  required String outPath,
  required String manifestBody,
  required List<int> dbContent,
}) async {
  final encoder = ZipFileEncoder()..create(outPath);
  final manifestFile = File('${outPath}_manifest.json');
  await manifestFile.writeAsString(manifestBody);
  await encoder.addFile(manifestFile, 'manifest.json');
  final dbFile = File('${outPath}_db.sqlite');
  await dbFile.writeAsBytes(dbContent);
  await encoder.addFile(dbFile, 'database.sqlite');
  await encoder.close();
  await manifestFile.delete();
  await dbFile.delete();
  return outPath;
}

/// Mock de PathProviderPlatform : redirige les dossiers systeme vers
/// des sous-dossiers temporaires controles par le test.
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  late Directory tmpDir;
  late Directory docsDir;
  late Directory externalDir;

  /// Cree les 3 sous-dossiers dans le temp systeme pour la duree
  /// d'un test. A appeler dans `setUp`.
  Future<void> setUpDirs() async {
    final base = await Directory.systemTemp.createTemp('opti_route_test_');
    tmpDir = Directory('${base.path}/tmp')..createSync();
    docsDir = Directory('${base.path}/docs')..createSync();
    externalDir = Directory('${base.path}/external')..createSync();
  }

  /// Cleanup : supprime recursivement les 3 dossiers. A appeler dans
  /// `tearDown` pour ne pas accumuler du temp entre les tests.
  Future<void> cleanup() async {
    try {
      // tmpDir.parent contient les 3 dossiers
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
