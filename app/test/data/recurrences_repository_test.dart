import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/recurrences_repository.dart';

// Premier test pour RecurrencesRepository : couvre upsert (create + update
// + reset derniereGenerationLe), setActif, markGenerated, getActives, et
// deleteForTemplate. DB en memoire, schema v37 inchange.
void main() {
  late AppDatabase db;
  late RecurrencesRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = RecurrencesRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<int> seedTemplate() {
    return db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'Template',
            date: DateTime(2026, 5, 29),
            pointDepartLat: 48.0,
            pointDepartLng: 1.0,
            pointDepartLabel: 'D',
          ),
        );
  }

  group('RecurrencesRepository.upsert', () {
    test('cree une nouvelle ligne quand template sans recurrence', () async {
      final tid = await seedTemplate();
      await repo.upsert(
        templateId: tid,
        frequence: 'hebdo',
        jourSemaine: 1,
      );
      final r = await repo.getByTemplate(tid);
      expect(r, isNotNull);
      expect(r!.frequence, 'hebdo');
      expect(r.jourSemaine, 1);
      expect(r.actif, isTrue, reason: 'actif par defaut');
    });

    test('met a jour la ligne existante (meme template)', () async {
      final tid = await seedTemplate();
      await repo.upsert(templateId: tid, frequence: 'quotidien');
      await repo.upsert(
        templateId: tid,
        frequence: 'mensuel',
        jourMois: 15,
      );
      final all = await db.select(db.tourneeRecurrences).get();
      expect(all, hasLength(1),
          reason: 'doit etre upsert, pas creation supplementaire');
      expect(all.first.frequence, 'mensuel');
      expect(all.first.jourMois, 15);
    });

    test('reset derniereGenerationLe sur update', () async {
      final tid = await seedTemplate();
      await repo.upsert(templateId: tid, frequence: 'quotidien');
      // Simule une generation precedente
      final r = await repo.getByTemplate(tid);
      await repo.markGenerated(r!.id, DateTime(2026, 5, 28));
      final r2 = await repo.getByTemplate(tid);
      expect(r2!.derniereGenerationLe, isNotNull);
      // Re-config : le dedup doit etre reset pour que la prochaine
      // generation puisse s'executer.
      await repo.upsert(templateId: tid, frequence: 'hebdo', jourSemaine: 3);
      final r3 = await repo.getByTemplate(tid);
      expect(r3!.derniereGenerationLe, isNull);
    });

    test('actif=false explicite preserve sur create', () async {
      final tid = await seedTemplate();
      await repo.upsert(
        templateId: tid,
        frequence: 'quotidien',
        actif: false,
      );
      final r = await repo.getByTemplate(tid);
      expect(r!.actif, isFalse);
    });
  });

  group('RecurrencesRepository.setActif', () {
    test('toggle actif sans changer la frequence', () async {
      final tid = await seedTemplate();
      await repo.upsert(
        templateId: tid,
        frequence: 'hebdo',
        jourSemaine: 1,
      );
      await repo.setActif(tid, false);
      var r = await repo.getByTemplate(tid);
      expect(r!.actif, isFalse);
      expect(r.frequence, 'hebdo', reason: 'frequence inchangee');
      await repo.setActif(tid, true);
      r = await repo.getByTemplate(tid);
      expect(r!.actif, isTrue);
    });

    test('no-op silencieux si template inconnu', () async {
      // Ne doit pas crasher meme si aucune recurrence pour ce templateId.
      await repo.setActif(99999, false);
      expect(await repo.getByTemplate(99999), isNull);
    });
  });

  group('RecurrencesRepository.getActives', () {
    test('filtre actif=true', () async {
      final t1 = await seedTemplate();
      final t2 = await seedTemplate();
      final t3 = await seedTemplate();
      await repo.upsert(templateId: t1, frequence: 'quotidien');
      await repo.upsert(
          templateId: t2, frequence: 'quotidien', actif: false);
      await repo.upsert(templateId: t3, frequence: 'quotidien');
      final actives = await repo.getActives();
      expect(actives, hasLength(2));
      final ids = actives.map((r) => r.templateId).toSet();
      expect(ids, {t1, t3});
    });

    test('liste vide si aucune recurrence', () async {
      expect(await repo.getActives(), isEmpty);
    });
  });

  group('RecurrencesRepository.deleteForTemplate', () {
    test('supprime la recurrence du template', () async {
      final tid = await seedTemplate();
      await repo.upsert(templateId: tid, frequence: 'quotidien');
      final n = await repo.deleteForTemplate(tid);
      expect(n, 1);
      expect(await repo.getByTemplate(tid), isNull);
    });

    test('retourne 0 si template sans recurrence', () async {
      final tid = await seedTemplate();
      final n = await repo.deleteForTemplate(tid);
      expect(n, 0);
    });
  });

  group('RecurrencesRepository.markGenerated', () {
    test('persiste la date', () async {
      final tid = await seedTemplate();
      await repo.upsert(templateId: tid, frequence: 'quotidien');
      final r = await repo.getByTemplate(tid);
      final dt = DateTime(2026, 5, 29, 7, 30);
      await repo.markGenerated(r!.id, dt);
      final r2 = await repo.getByTemplate(tid);
      expect(r2!.derniereGenerationLe, dt);
    });
  });
}
