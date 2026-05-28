import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/notifications_service.dart';
import 'package:opti_route/data/recurrence_service.dart';
import 'package:opti_route/data/recurrences_repository.dart';
import 'package:opti_route/data/tournees_repository.dart';

/// Tests des tournees recurrentes (carte #113) : logique pure
/// [RecurrenceService.shouldGenerateOn] + integration [runDue] (DB
/// memoire). Le canal de notifications est mocke (no-op).
void main() {
  // 2026-05-25 = lundi, 2026-05-30 = samedi, 2026-05-15 = vendredi.
  final lundi = DateTime(2026, 5, 25);
  final samedi = DateTime(2026, 5, 30);
  final quinze = DateTime(2026, 5, 15);

  group('shouldGenerateOn (pur)', () {
    test('quotidien -> toujours true', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.quotidien,
          actif: true,
          date: samedi,
        ),
        isTrue,
      );
    });

    test('inactif -> false meme si le jour matche', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.quotidien,
          actif: false,
          date: lundi,
        ),
        isFalse,
      );
    });

    test('jours_ouvres : true en semaine, false le week-end', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.joursOuvres,
          actif: true,
          date: lundi,
        ),
        isTrue,
      );
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.joursOuvres,
          actif: true,
          date: samedi,
        ),
        isFalse,
      );
    });

    test('hebdo : true seulement le bon jour de semaine', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.hebdo,
          actif: true,
          jourSemaine: DateTime.monday,
          date: lundi,
        ),
        isTrue,
      );
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.hebdo,
          actif: true,
          jourSemaine: DateTime.tuesday,
          date: lundi,
        ),
        isFalse,
      );
    });

    test('mensuel : true seulement le bon jour du mois', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.mensuel,
          actif: true,
          jourMois: 15,
          date: quinze,
        ),
        isTrue,
      );
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.mensuel,
          actif: true,
          jourMois: 16,
          date: quinze,
        ),
        isFalse,
      );
    });

    test('dedup : false si deja genere le meme jour', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.quotidien,
          actif: true,
          derniereGeneration: DateTime(2026, 5, 25, 6),
          date: DateTime(2026, 5, 25, 18),
        ),
        isFalse,
      );
    });

    test('dedup : true si la derniere generation etait un autre jour', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.quotidien,
          actif: true,
          derniereGeneration: DateTime(2026, 5, 24, 18),
          date: DateTime(2026, 5, 25, 6),
        ),
        isTrue,
      );
    });
  });

  group('runDue (DB memoire)', () {
    late AppDatabase db;
    late RecurrencesRepository recurrences;
    late TourneesRepository tournees;
    late RecurrenceService service;

    setUpAll(() {
      TestWidgetsFlutterBinding.ensureInitialized();
      // Mock du canal flutter_local_notifications -> no-op (sinon la
      // notif de generation tente d'appeler la plateforme).
      const channel = MethodChannel('dexterous.com/flutter/local_notifications');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);
    });

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      recurrences = RecurrencesRepository(db);
      tournees = TourneesRepository(db);
      service = RecurrenceService(
        recurrences,
        tournees,
        NotificationsService.instance,
      );
    });

    tearDown(() async {
      await db.close();
    });

    Future<int> seedTemplate() async {
      final id = await db.into(db.tournees).insert(
            TourneesCompanion.insert(
              nom: 'Tournee mardi',
              date: DateTime(2026, 5, 1),
              pointDepartLat: 48.0,
              pointDepartLng: 1.0,
              pointDepartLabel: 'Depot',
              isTemplate: const Value(true),
            ),
          );
      await db.into(db.stops).insert(
            StopsCompanion.insert(tourneeId: id, adresseBrute: '1 rue A'),
          );
      return id;
    }

    test('genere une tournee le jour cible + marque la generation',
        () async {
      final templateId = await seedTemplate();
      await recurrences.upsert(
        templateId: templateId,
        frequence: RecurrenceFrequence.joursOuvres,
      );

      final n = await service.runDue(now: lundi);
      expect(n, 1);

      // Une nouvelle tournee (le clone) a ete creee.
      final all = await tournees.watchAll().first;
      expect(all.length, 2);
      expect(all.any((t) => t.nom.contains('copie')), isTrue);

      // La recurrence est marquee generee -> dedup.
      final rec = await recurrences.getByTemplate(templateId);
      expect(rec!.derniereGenerationLe, isNotNull);
    });

    test('dedup : un 2e runDue le meme jour ne regenere pas', () async {
      final templateId = await seedTemplate();
      await recurrences.upsert(
        templateId: templateId,
        frequence: RecurrenceFrequence.quotidien,
      );
      expect(await service.runDue(now: lundi), 1);
      expect(await service.runDue(now: lundi), 0); // deja fait ce jour
    });

    test('jour non cible -> rien', () async {
      final templateId = await seedTemplate();
      await recurrences.upsert(
        templateId: templateId,
        frequence: RecurrenceFrequence.joursOuvres,
      );
      expect(await service.runDue(now: samedi), 0); // samedi exclu
    });

    test('recurrence inactive -> rien', () async {
      final templateId = await seedTemplate();
      await recurrences.upsert(
        templateId: templateId,
        frequence: RecurrenceFrequence.quotidien,
        actif: false,
      );
      expect(await service.runDue(now: lundi), 0);
    });
  });
}
