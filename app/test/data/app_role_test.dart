import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/app_role.dart';

void main() {
  group('FeatureRegistry.requires', () {
    test('feature inconnue -> chauffeur (default visible)', () {
      expect(
        FeatureRegistry.requires('inexistante.feature'),
        AppRole.chauffeur,
      );
    });

    test('feature chef = chef requis', () {
      expect(
        FeatureRegistry.requires('compta.km_urssaf'),
        AppRole.chef,
      );
      expect(
        FeatureRegistry.requires('vehicule.entretien_alerts'),
        AppRole.chef,
      );
      expect(
        FeatureRegistry.requires('stats.heatmap_echecs'),
        AppRole.chef,
      );
      expect(
        FeatureRegistry.requires('equipe.dispatch_live'),
        AppRole.chef,
      );
    });

    test('feature chauffeur = chauffeur', () {
      expect(
        FeatureRegistry.requires('tournee.eta_dynamique'),
        AppRole.chauffeur,
      );
      expect(
        FeatureRegistry.requires('stop.memo_vocal'),
        AppRole.chauffeur,
      );
    });
  });

  group('FeatureRegistry.canSee', () {
    test('chef voit tout', () {
      for (final f in FeatureRegistry.knownFeatures) {
        expect(
          FeatureRegistry.canSee(featureKey: f, role: AppRole.chef),
          isTrue,
          reason: 'chef doit voir $f',
        );
      }
    });

    test('chauffeur ne voit pas le chef-only', () {
      expect(
        FeatureRegistry.canSee(
          featureKey: 'compta.km_urssaf',
          role: AppRole.chauffeur,
        ),
        isFalse,
      );
      expect(
        FeatureRegistry.canSee(
          featureKey: 'vehicule.entretien_alerts',
          role: AppRole.chauffeur,
        ),
        isFalse,
      );
    });

    test('chauffeur voit ses features', () {
      expect(
        FeatureRegistry.canSee(
          featureKey: 'tournee.eta_dynamique',
          role: AppRole.chauffeur,
        ),
        isTrue,
      );
      expect(
        FeatureRegistry.canSee(
          featureKey: 'inexistante',
          role: AppRole.chauffeur,
        ),
        isTrue,
        reason: 'feature inconnue = default chauffeur = visible',
      );
    });
  });

  group('AppRole', () {
    test('labels FR', () {
      expect(AppRole.chauffeur.label, 'Chauffeur');
      expect(AppRole.chef.label, 'Chef d\'équipe');
    });

    test('order : chef > chauffeur (.index)', () {
      expect(AppRole.chef.index > AppRole.chauffeur.index, isTrue);
    });
  });
}
