import 'package:flutter_test/flutter_test.dart';

import 'package:opti_route/data/tournee_reminder_plan.dart';

/// Tests de la logique pure du rappel "tournee non terminee" (carte
/// #121). Pas de plugin / plateforme : juste le calcul de l'echeance.
void main() {
  group('TourneeReminderPlan', () {
    test('seuil par defaut = 8h', () {
      expect(TourneeReminderPlan.seuil, const Duration(hours: 8));
    });

    test('reminderAt = demareeLe + seuil', () {
      final demaree = DateTime(2026, 5, 28, 7, 30);
      expect(
        TourneeReminderPlan.reminderAt(demaree),
        DateTime(2026, 5, 28, 15, 30),
      );
    });

    test('reminderAt accepte un seuil custom', () {
      final demaree = DateTime(2026, 5, 28, 7, 0);
      expect(
        TourneeReminderPlan.reminderAt(demaree, seuil: const Duration(hours: 2)),
        DateTime(2026, 5, 28, 9, 0),
      );
    });

    test('reminderAt null si pas demarree', () {
      expect(TourneeReminderPlan.reminderAt(null), isNull);
    });

    test('isOverdue : false avant l\'echeance', () {
      final demaree = DateTime(2026, 5, 28, 7, 0);
      final now = DateTime(2026, 5, 28, 12, 0); // +5h < 8h
      expect(
        TourneeReminderPlan.isOverdue(demareeLe: demaree, now: now),
        isFalse,
      );
    });

    test('isOverdue : true au-dela du seuil', () {
      final demaree = DateTime(2026, 5, 28, 7, 0);
      final now = DateTime(2026, 5, 28, 16, 0); // +9h > 8h
      expect(
        TourneeReminderPlan.isOverdue(demareeLe: demaree, now: now),
        isTrue,
      );
    });

    test('isOverdue : true pile a l\'echeance (8h)', () {
      final demaree = DateTime(2026, 5, 28, 7, 0);
      final now = DateTime(2026, 5, 28, 15, 0); // +8h exactement
      expect(
        TourneeReminderPlan.isOverdue(demareeLe: demaree, now: now),
        isTrue,
      );
    });

    test('isOverdue : false si jamais demarree', () {
      expect(
        TourneeReminderPlan.isOverdue(
          demareeLe: null,
          now: DateTime(2026, 5, 28, 23, 0),
        ),
        isFalse,
      );
    });
  });
}
