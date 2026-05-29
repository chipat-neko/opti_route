import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/app_constants.dart';

// Verrouille les invariants metier des constantes globales. Un test
// echoue si quelqu'un modifie une de ces constantes sans verifier la
// contrainte associee (ex: lien tracking > 20 chars).
void main() {
  group('app_constants — contraintes metier', () {
    test('lien tracking total : "https://<domaine>/<code>" <= 20 chars', () {
      // Contrainte stricte logiciel Amazon Auneau (cf doc carte #141).
      final lien = 'https://$kTrackingDomain/${'x' * kTrackingCodeLength}';
      expect(lien.length, lessThanOrEqualTo(20),
          reason: 'depasser 20 chars casse Amazon Auneau, cf #141');
    });

    test('kTrackingDomain non vide et sans https://', () {
      expect(kTrackingDomain, isNotEmpty);
      expect(kTrackingDomain.contains('://'), isFalse,
          reason: 'le schema est ajoute par le caller, pas dans la constante');
    });

    test('kTrackingCodeLength >= 3 (collisions raisonnables)', () {
      // 3 chars [a-z0-9] = 36^3 = 46656 combinaisons, deja confortable.
      expect(kTrackingCodeLength, greaterThanOrEqualTo(3));
    });

    test('seuils geo coherents : doublon < geocodeCache', () {
      // Deux points a moins de 30m sont consideres doublons. Le cache
      // tolere jusqu'a 50m pour la reutilisation. Inverser casserait
      // la detection de doublons.
      expect(kDoublonSeuilMetres, lessThan(kGeocodeCacheSeuilMetres));
    });

    test('http timeouts ordonnes : edge < short < long', () {
      expect(kEdgeFunctionTimeout, lessThan(kHttpTimeoutShort));
      expect(kHttpTimeoutShort, lessThan(kHttpTimeoutLong));
    });

    test('kBlurThresholdLaplacian > 0', () {
      expect(kBlurThresholdLaplacian, greaterThan(0));
    });

    test('kOrsDailyQuota = 500 (palier gratuit officiel)', () {
      expect(kOrsDailyQuota, 500);
    });

    test('kCarnetWarningSize > 100 (sinon spam)', () {
      expect(kCarnetWarningSize, greaterThan(100));
    });
  });

  group('app_constants — zone geographique Noah', () {
    test('kCodePostalPrefere = 2 chars numeriques', () {
      expect(kCodePostalPrefere.length, 2);
      expect(int.tryParse(kCodePostalPrefere), isNotNull);
    });

    test('kCodePostalPreferes contient kCodePostalPrefere', () {
      expect(kCodePostalPreferes, contains(kCodePostalPrefere));
    });

    test('kCodePostalPrefere est en tete de kCodePostalPreferes', () {
      // Pour que le matching prefere d'abord le departement principal,
      // il doit etre le 1er dans la liste etendue.
      expect(kCodePostalPreferes.first, kCodePostalPrefere);
    });

    test('kCodePostalPreferes : tous 2 chars numeriques uniques', () {
      for (final cp in kCodePostalPreferes) {
        expect(cp.length, 2);
        expect(int.tryParse(cp), isNotNull);
      }
      expect(kCodePostalPreferes.toSet().length, kCodePostalPreferes.length,
          reason: 'pas de doublon');
    });
  });

  group('app_constants — fuzzy matching carnet', () {
    test('kClientMemoryMinRatio dans [0, 1]', () {
      expect(kClientMemoryMinRatio, inInclusiveRange(0.0, 1.0));
    });

    test('kClientMemoryMaxDistance >= 1', () {
      expect(kClientMemoryMaxDistance, greaterThanOrEqualTo(1));
    });
  });
}
