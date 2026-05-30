import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/recurrence_service.dart';

// Verrouille la variante shouldGenerate(TourneeRecurrence, DateTime)
// qui delegue a shouldGenerateOn. Ne test PAS shouldGenerateOn (cf
// recurrence_service_test + edge tests).
void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  Future<TourneeRecurrence> seedRec({
    String frequence = 'quotidien',
    bool actif = true,
    int? jourSemaine,
    int? jourMois,
    DateTime? derniereGeneration,
  }) async {
    final tId = await db.into(db.tournees).insert(
          TourneesCompanion.insert(
            nom: 'T',
            date: DateTime(2026, 5, 29),
            pointDepartLat: 48,
            pointDepartLng: 1,
            pointDepartLabel: 'D',
          ),
        );
    final id = await db.into(db.tourneeRecurrences).insert(
          TourneeRecurrencesCompanion.insert(
            templateId: tId,
            frequence: frequence,
            actif: Value(actif),
            jourSemaine: Value(jourSemaine),
            jourMois: Value(jourMois),
            derniereGenerationLe: Value(derniereGeneration),
          ),
        );
    return (db.select(db.tourneeRecurrences)
          ..where((r) => r.id.equals(id)))
        .getSingle();
  }

  group('RecurrenceService.shouldGenerate(rec, date) — delegation', () {
    test('quotidien actif : true', () async {
      final rec = await seedRec(frequence: 'quotidien');
      expect(RecurrenceService.shouldGenerate(rec, DateTime(2026, 5, 29)),
          isTrue);
    });

    test('quotidien INACTIF : false', () async {
      final rec = await seedRec(frequence: 'quotidien', actif: false);
      expect(RecurrenceService.shouldGenerate(rec, DateTime(2026, 5, 29)),
          isFalse);
    });

    test('hebdo lundi (1) : true le lundi 2026-05-25, false mardi 26',
        () async {
      final rec = await seedRec(frequence: 'hebdo', jourSemaine: 1);
      // 2026-05-25 = lundi
      expect(RecurrenceService.shouldGenerate(rec, DateTime(2026, 5, 25)),
          isTrue);
      // 2026-05-26 = mardi
      expect(RecurrenceService.shouldGenerate(rec, DateTime(2026, 5, 26)),
          isFalse);
    });

    test('mensuel jour 15 : true le 15, false le 16', () async {
      final rec = await seedRec(frequence: 'mensuel', jourMois: 15);
      expect(RecurrenceService.shouldGenerate(rec, DateTime(2026, 5, 15)),
          isTrue);
      expect(RecurrenceService.shouldGenerate(rec, DateTime(2026, 5, 16)),
          isFalse);
    });

    test('dedup : derniereGeneration le meme jour -> false', () async {
      final rec = await seedRec(
        frequence: 'quotidien',
        derniereGeneration: DateTime(2026, 5, 29, 8, 0),
      );
      expect(RecurrenceService.shouldGenerate(rec, DateTime(2026, 5, 29, 18)),
          isFalse);
    });
  });
}
