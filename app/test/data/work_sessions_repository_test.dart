import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/work_sessions_repository.dart';

void main() {
  late AppDatabase db;
  late WorkSessionsRepository repo;
  final now = DateTime(2026, 5, 30, 14, 0);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = WorkSessionsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('startSession + endCurrentSession', () {
    test('start cree une session, getCurrent la retourne', () async {
      final s = await repo.startSession(now: now);
      expect(s.startedAt, now);
      expect(s.endedAt, isNull);
      final cur = await repo.getCurrent();
      expect(cur!.id, s.id);
    });

    test('startSession no-op si deja une session ouverte', () async {
      final s1 = await repo.startSession(now: now);
      final s2 = await repo
          .startSession(now: now.add(const Duration(minutes: 5)));
      expect(s1.id, s2.id, reason: 'meme session, pas de duplicate');
      expect(s2.startedAt, now, reason: 'startedAt inchange');
    });

    test('endCurrentSession ferme la session ouverte', () async {
      await repo.startSession(now: now);
      final ended = await repo
          .endCurrentSession(now: now.add(const Duration(hours: 2)));
      expect(ended, isTrue);
      expect(await repo.getCurrent(), isNull);
    });

    test('endCurrentSession no-op si rien d\'ouvert', () async {
      expect(await repo.endCurrentSession(now: now), isFalse);
    });

    test('apres end, nouveau start cree une 2e session', () async {
      await repo.startSession(now: now);
      await repo.endCurrentSession(now: now.add(const Duration(hours: 1)));
      final s2 = await repo
          .startSession(now: now.add(const Duration(hours: 2)));
      expect(s2.endedAt, isNull);
      final all = await db.select(db.workSessions).get();
      expect(all, hasLength(2));
    });
  });

  group('durationForDay', () {
    test('aucune session -> 0', () async {
      expect(await repo.durationForDay(now), Duration.zero);
    });

    test('session fermee de 2h dans la journee -> 2h', () async {
      final start = now.copyWith(hour: 8);
      final end = now.copyWith(hour: 10);
      await repo.startSession(now: start);
      await repo.endCurrentSession(now: end);
      final d = await repo.durationForDay(now);
      expect(d, const Duration(hours: 2));
    });

    test('session ouverte cappee a now', () async {
      final start = now.copyWith(hour: 8);
      await repo.startSession(now: start);
      // pas de end => session encore en cours
      final d = await repo.durationForDay(now, now: now);
      expect(d, const Duration(hours: 6), reason: 'now - 8h = 6h');
    });

    test('session avant la journee : tronquee au debut de jour', () async {
      // session 23h hier -> 02h aujourd'hui
      final start =
          now.copyWith(hour: 23).subtract(const Duration(days: 1));
      final end = now.copyWith(hour: 2);
      await repo.startSession(now: start);
      await repo.endCurrentSession(now: end);
      final d = await repo.durationForDay(now);
      expect(d, const Duration(hours: 2),
          reason: 'tronque entre 00h et 02h aujourd\'hui');
    });

    test('multiple sessions cumulent', () async {
      // 8h-10h (2h) + 14h-16h (2h)
      await repo.startSession(now: now.copyWith(hour: 8));
      await repo.endCurrentSession(now: now.copyWith(hour: 10));
      await repo.startSession(now: now.copyWith(hour: 14));
      await repo.endCurrentSession(now: now.copyWith(hour: 16));
      expect(await repo.durationForDay(now), const Duration(hours: 4));
    });
  });

  group('watchCurrent', () {
    test('emet la session ouverte puis null apres end', () async {
      final values = <WorkSession?>[];
      final sub = repo.watchCurrent().listen(values.add);
      await repo.startSession(now: now);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await repo.endCurrentSession(now: now.add(const Duration(hours: 1)));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await sub.cancel();
      expect(values.any((v) => v != null), isTrue);
      expect(values.last, isNull);
    });
  });
}
