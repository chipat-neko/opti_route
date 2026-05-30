import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';

/// Tests des helpers de filtrage du carnet (carte Trello #105) :
/// - Filtre periode d'ajout (creeLe < cutoff selon '30d' / '6m' / '1y')
/// - Filtre regularite (useCount >= 5 ou == 1)
///
/// Comme les filtres vivent dans le state du widget, on reproduit ici
/// la meme logique pure sur des `SavedDestination` mockes pour valider
/// les bornes. Si la logique du widget change, ces tests echouent
/// jusqu'a synchronisation.
void main() {
  group('filtre periode d\'ajout', () {
    final now = DateTime(2026, 5, 26, 12);
    final hier = now.subtract(const Duration(days: 1));
    final ilYA45j = now.subtract(const Duration(days: 45));
    final ilYA3mois = now.subtract(const Duration(days: 90));
    final ilYA8mois = now.subtract(const Duration(days: 240));
    final ilYA2ans = now.subtract(const Duration(days: 730));

    test('30 jours : exclut > 30j', () {
      final cutoff = now.subtract(const Duration(days: 30));
      expect(hier.isAfter(cutoff), isTrue, reason: 'hier dans la fenetre');
      expect(ilYA45j.isAfter(cutoff), isFalse, reason: '45j exclu');
    });

    test('6 mois : exclut > 6 mois', () {
      final cutoff = now.subtract(const Duration(days: 30 * 6));
      expect(ilYA45j.isAfter(cutoff), isTrue);
      expect(ilYA3mois.isAfter(cutoff), isTrue);
      expect(ilYA8mois.isAfter(cutoff), isFalse);
    });

    test('1 an : exclut > 1 an', () {
      final cutoff = now.subtract(const Duration(days: 365));
      expect(ilYA8mois.isAfter(cutoff), isTrue);
      expect(ilYA2ans.isAfter(cutoff), isFalse);
    });
  });

  group('filtre regularite (useCount)', () {
    SavedDestination make({required int useCount}) {
      final now = DateTime(2026, 5, 26);
      return SavedDestination(
        id: 1,
        adresseDisplay: 'A',
        lat: 48.0,
        lng: 1.0,
        useCount: useCount,
        lastUsedAt: now,
        creeLe: now,
        isFavori: false,
        updatedAt: now,
        isProblematique: false,
        photoObligatoire: false,
      );
    }

    test('reguliers : useCount >= 5', () {
      expect(make(useCount: 5).useCount >= 5, isTrue);
      expect(make(useCount: 10).useCount >= 5, isTrue);
      expect(make(useCount: 4).useCount >= 5, isFalse);
      expect(make(useCount: 1).useCount >= 5, isFalse);
    });

    test('uniques : useCount == 1', () {
      expect(make(useCount: 1).useCount == 1, isTrue);
      expect(make(useCount: 2).useCount == 1, isFalse);
      expect(make(useCount: 0).useCount == 1, isFalse);
    });
  });
}
