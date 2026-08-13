import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/screens/carnet_adresses/carnet_filters.dart';

/// Tests des helpers de filtrage du carnet (carte Trello #105) :
/// - [periodeCutoff] : borne basse des chips '30d' / '6m' / '1y'
/// - [filterCarnet] : filtre regularite (useCount >= 5 / <= 1)
///
/// Les tests appellent les vraies fonctions de
/// `screens/carnet_adresses/carnet_filters.dart` (et non une copie de
/// leur logique) : si l'implementation change, ils echouent.
void main() {
  group('periodeCutoff', () {
    test('30 jours : duree exacte de 30 jours (inchange)', () {
      final now = DateTime(2026, 5, 26, 12, 30);
      expect(
        now.difference(periodeCutoff('30d', now: now)),
        const Duration(days: 30),
      );
    });

    test('6 mois : 6 mois calendaires, pas 180 jours', () {
      final now = DateTime(2026, 5, 26, 12, 30);
      final cutoff = periodeCutoff('6m', now: now);
      expect(cutoff, DateTime(2025, 11, 26, 12, 30));
      // L'ancien calcul (Duration(days: 30 * 6)) tombait au 27 novembre :
      // il coupait un jour trop tard et excluait les fiches creees le 26.
      expect(cutoff, isNot(now.subtract(const Duration(days: 180))));
    });

    test('6 mois : quantieme borne au dernier jour du mois cible', () {
      // 31 aout - 6 mois : le 31 fevrier n'existe pas. On rend le
      // 28 fevrier (dernier jour du mois) et non le 3 mars, ce que
      // donnerait la normalisation automatique de DateTime.
      final cutoff = periodeCutoff('6m', now: DateTime(2026, 8, 31, 9));
      expect(cutoff, DateTime(2026, 2, 28, 9));
    });

    test('6 mois : passage d\'annee', () {
      final cutoff = periodeCutoff('6m', now: DateTime(2026, 2, 15, 8));
      expect(cutoff, DateTime(2025, 8, 15, 8));
    });

    test('1 an : 12 mois calendaires (annee bissextile incluse)', () {
      // 2024 est bissextile : l'annee ecoulee fait 366 jours, donc
      // l'ancien `Duration(days: 365)` rendait le 27 mai 2023.
      final now = DateTime(2024, 5, 26, 12, 30);
      final cutoff = periodeCutoff('1y', now: now);
      expect(cutoff, DateTime(2023, 5, 26, 12, 30));
      expect(cutoff, isNot(now.subtract(const Duration(days: 365))));
    });

    test('1 an : 29 fevrier borne au 28 fevrier', () {
      final cutoff = periodeCutoff('1y', now: DateTime(2028, 2, 29, 7));
      expect(cutoff, DateTime(2027, 2, 28, 7));
    });

    test('periode inconnue : pas de borne (1970)', () {
      expect(periodeCutoff('bidon', now: DateTime(2026, 5, 26)),
          DateTime(1970));
    });
  });

  group('filtre regularite (useCount)', () {
    SavedDestination make({required int id, required int useCount}) {
      final now = DateTime(2026, 5, 26);
      return SavedDestination(
        id: id,
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

    // useCount demarre a 1 a la creation de la fiche (1re livraison) et
    // n'est incremente qu'aux suivantes (SavedDestinationsRepository
    // .upsertFromValidatedStop). 0 = fiche arrivee sans usage (pull cloud).
    final jamaisUtilise = make(id: 1, useCount: 0);
    final uneSeuleFois = make(id: 2, useCount: 1);
    final deuxFois = make(id: 3, useCount: 2);
    final regulier = make(id: 4, useCount: 5);
    final all = [jamaisUtilise, uneSeuleFois, deuxFois, regulier];

    test('reguliers : useCount >= 5', () {
      final out = filterCarnet(
        all,
        const CarnetFilters(regularite: 'reguliers'),
        '',
      );
      expect(out.map((d) => d.id).toList(), [4]);
    });

    test('uniques (jamais reutilises) : useCount 0 ET 1', () {
      final out = filterCarnet(
        all,
        const CarnetFilters(regularite: 'uniques'),
        '',
      );
      // Le `== 1` d'origine laissait echapper la fiche a useCount 0.
      expect(out.map((d) => d.id).toList(), [1, 2]);
    });

    test('sans filtre regularite : tout passe', () {
      expect(filterCarnet(all, CarnetFilters.none, '').length, 4);
    });
  });
}
