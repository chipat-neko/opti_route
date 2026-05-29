import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/recurrence_service.dart';

// Complete recurrence_service_test : branches default / null inputs,
// edge dates, constantes du namespace RecurrenceFrequence.
void main() {
  group('RecurrenceFrequence (constantes)', () {
    test('all contient les 4 valeurs supportees', () {
      expect(RecurrenceFrequence.all, hasLength(4));
      expect(RecurrenceFrequence.all, containsAll(const [
        RecurrenceFrequence.quotidien,
        RecurrenceFrequence.joursOuvres,
        RecurrenceFrequence.hebdo,
        RecurrenceFrequence.mensuel,
      ]));
    });

    test('chaque constante est non vide', () {
      for (final f in RecurrenceFrequence.all) {
        expect(f, isNotEmpty);
      }
    });

    test('toutes uniques (pas de doublon)', () {
      expect(
        RecurrenceFrequence.all.toSet().length,
        RecurrenceFrequence.all.length,
      );
    });
  });

  group('shouldGenerateOn — branches null / inconnues', () {
    test('frequence inconnue -> false (branche default)', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: 'xyz_pas_supportee',
          actif: true,
          date: DateTime(2026, 5, 28),
        ),
        isFalse,
      );
    });

    test('hebdo avec jourSemaine null -> false', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.hebdo,
          actif: true,
          date: DateTime(2026, 5, 28), // jeudi
        ),
        isFalse,
      );
    });

    test('mensuel avec jourMois null -> false', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.mensuel,
          actif: true,
          date: DateTime(2026, 5, 15),
        ),
        isFalse,
      );
    });
  });

  group('shouldGenerateOn — dates limites', () {
    test('mensuel jour 31 + fevrier (28 jours) -> false', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.mensuel,
          actif: true,
          jourMois: 31,
          date: DateTime(2026, 2, 28),
        ),
        isFalse,
        reason: '28 fev != 31 -> pas genere ce mois',
      );
    });

    test('mensuel jour 31 + 31 juillet -> true', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.mensuel,
          actif: true,
          jourMois: 31,
          date: DateTime(2026, 7, 31),
        ),
        isTrue,
      );
    });

    test('hebdo lundi (1) match DateTime.monday', () {
      // 2026-05-25 = lundi
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.hebdo,
          actif: true,
          jourSemaine: DateTime.monday,
          date: DateTime(2026, 5, 25),
        ),
        isTrue,
      );
    });

    test('hebdo dimanche (7) match DateTime.sunday', () {
      // 2026-05-31 = dimanche
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.hebdo,
          actif: true,
          jourSemaine: DateTime.sunday,
          date: DateTime(2026, 5, 31),
        ),
        isTrue,
      );
    });

    test('jours_ouvres samedi -> false', () {
      // 2026-05-30 = samedi
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.joursOuvres,
          actif: true,
          date: DateTime(2026, 5, 30),
        ),
        isFalse,
      );
    });

    test('jours_ouvres dimanche -> false', () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.joursOuvres,
          actif: true,
          date: DateTime(2026, 5, 31),
        ),
        isFalse,
      );
    });
  });

  group('shouldGenerateOn — dedup intra-jour', () {
    test('derniere generation a 23h59 + check a 00h01 lendemain -> regenere',
        () {
      // Calendrier different -> _sameDay = false -> on regenere.
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.quotidien,
          actif: true,
          derniereGeneration: DateTime(2026, 5, 28, 23, 59),
          date: DateTime(2026, 5, 29, 0, 1),
        ),
        isTrue,
      );
    });

    test('derniere generation a 00h01 + check a 23h59 meme jour -> dedup',
        () {
      expect(
        RecurrenceService.shouldGenerateOn(
          frequence: RecurrenceFrequence.quotidien,
          actif: true,
          derniereGeneration: DateTime(2026, 5, 28, 0, 1),
          date: DateTime(2026, 5, 28, 23, 59),
        ),
        isFalse,
        reason: 'meme jour calendaire -> dedup',
      );
    });
  });
}
