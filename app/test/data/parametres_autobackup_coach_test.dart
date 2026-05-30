import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/parametres_repository.dart';

// Tests des helpers AutoBackup (period + lastAt) et CoachCarnetDone +
// resetAllCoachMarks, pas couverts ailleurs.
void main() {
  late AppDatabase db;
  late ParametresRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = ParametresRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('AutoBackupPeriod', () {
    test('defaut : "jamais"', () async {
      expect(await repo.getAutoBackupPeriod(), 'jamais');
    });

    test('set "hebdo" / "mensuel" round-trip', () async {
      await repo.setAutoBackupPeriod('hebdo');
      expect(await repo.getAutoBackupPeriod(), 'hebdo');
      await repo.setAutoBackupPeriod('mensuel');
      expect(await repo.getAutoBackupPeriod(), 'mensuel');
    });

    test('watchAutoBackupPeriod : emit defaut puis update', () async {
      final values = <String>[];
      final sub = repo.watchAutoBackupPeriod().listen(values.add);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await repo.setAutoBackupPeriod('hebdo');
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(values, contains('jamais'));
      expect(values, contains('hebdo'));
    });
  });

  group('LastAutoBackupAt', () {
    test('defaut : null', () async {
      expect(await repo.getLastAutoBackupAt(), isNull);
    });

    test('set/get round-trip ISO8601', () async {
      final when = DateTime(2026, 5, 29, 14, 30);
      await repo.setLastAutoBackupAt(when);
      expect(await repo.getLastAutoBackupAt(), when);
    });

    test('set le plus recent ecrase l\'ancien', () async {
      await repo.setLastAutoBackupAt(DateTime(2026, 5, 1));
      await repo.setLastAutoBackupAt(DateTime(2026, 5, 29));
      expect(
        await repo.getLastAutoBackupAt(),
        DateTime(2026, 5, 29),
      );
    });
  });

  group('CoachCarnetDone', () {
    test('defaut : false', () async {
      expect(await repo.getCoachCarnetDone(), isFalse);
    });

    test('setCoachCarnetDone : 1-way passe a true', () async {
      await repo.setCoachCarnetDone();
      expect(await repo.getCoachCarnetDone(), isTrue);
    });
  });

  group('resetAllCoachMarks', () {
    test('efface les 4 flags coach simultanement', () async {
      // Active les 4
      await repo.setCoachTourneeDone();
      await repo.setCoachScanDone();
      await repo.setCoachParametresDone();
      await repo.setCoachCarnetDone();
      expect(await repo.getCoachTourneeDone(), isTrue);
      expect(await repo.getCoachScanDone(), isTrue);
      expect(await repo.getCoachParametresDone(), isTrue);
      expect(await repo.getCoachCarnetDone(), isTrue);

      await repo.resetAllCoachMarks();

      expect(await repo.getCoachTourneeDone(), isFalse);
      expect(await repo.getCoachScanDone(), isFalse);
      expect(await repo.getCoachParametresDone(), isFalse);
      expect(await repo.getCoachCarnetDone(), isFalse);
    });

    test('idempotent : 2eme reset ne casse rien', () async {
      await repo.resetAllCoachMarks();
      await repo.resetAllCoachMarks();
      expect(await repo.getCoachTourneeDone(), isFalse);
    });
  });
}
