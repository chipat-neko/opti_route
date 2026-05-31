import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau_ml/classifier.dart';
import 'package:opti_route/data/bordereau_ml/features.dart';

void main() {
  group('computeFeatures (parite Python)', () {
    test('ligne vide -> 0 partout (sauf rel/block params)', () {
      final f = computeFeatures(
        text: '',
        relY: 0.5,
        relX: 0.5,
        blockHeight: 30,
        blockWidth: 200,
      );
      expect(f.length, 20);
      expect(f[0], 0.0); // length
      expect(f[1], 0.0); // n_words
      expect(f[9], 0.0); // n_digits
      expect(f[16], 0.5); // rel_y
      expect(f[17], 0.5); // rel_x
      expect(f[18], 30.0); // block_height
    });

    test('TEL : "Tel 06 12 34 56 78"', () {
      final f = computeFeatures(
        text: 'Tel 06 12 34 56 78',
        relY: 0.5,
        relX: 0.5,
        blockHeight: 20,
        blockWidth: 150,
      );
      // has_tel_kw (index 11) = 1
      expect(f[11], 1.0);
      // has_phone (index 12) = 1
      expect(f[12], 1.0);
      // has_digit (index 5) = 1
      expect(f[5], 1.0);
      // n_digits (index 9) = 10
      expect(f[9], 10.0);
    });

    test('CP_VILLE : "75001 PARIS"', () {
      final f = computeFeatures(
        text: '75001 PARIS',
        relY: 0.5,
        relX: 0.5,
        blockHeight: 25,
        blockWidth: 180,
      );
      // has_cp5 (index 10) = 1
      expect(f[10], 1.0);
      // pct_upper (index 2) doit etre eleve (PARIS = MAJ)
      expect(f[2], greaterThan(0.9));
    });

    test('RUE : "12 rue de la Paix"', () {
      final f = computeFeatures(
        text: '12 rue de la Paix',
        relY: 0.5,
        relX: 0.5,
        blockHeight: 25,
        blockWidth: 200,
      );
      // has_rue_kw (index 13) = 1
      expect(f[13], 1.0);
      // starts_digit (index 7) = 1
      expect(f[7], 1.0);
    });

    test('PARASITE : "DESTINATAIRE"', () {
      final f = computeFeatures(
        text: 'DESTINATAIRE',
        relY: 0.1,
        relX: 0.1,
        blockHeight: 20,
        blockWidth: 120,
      );
      // has_parasite_kw (index 15) = 1
      expect(f[15], 1.0);
      // pct_upper (index 2) = 1.0
      expect(f[2], 1.0);
    });
  });

  group('BordereauMlClassifier (loading)', () {
    // Le load() depend d'un asset bundle qui n'est pas dispo en VM
    // sans test bundle dedie. On verifie juste que les API ne crashent
    // pas et que classify() retourne null tant que pas charge.
    test('isLoaded = false avant load()', () {
      final clf = BordereauMlClassifier.instance;
      // Singleton donc on ne sait pas si un autre test l'a charge.
      // En revanche, classify avec mauvais feature count doit retourner
      // null sans crash.
      if (!clf.isLoaded) {
        final r = clf.classify(
          text: 'foo',
          relY: 0.5,
          relX: 0.5,
          blockHeight: 20,
          blockWidth: 100,
        );
        expect(r, isNull);
      }
    });

    test('BordereauClass.isLowConfidence seuil 0.70', () {
      const a = BordereauClass('NOM_CLIENT', 0.65);
      const b = BordereauClass('NOM_CLIENT', 0.75);
      expect(a.isLowConfidence, isTrue);
      expect(b.isLowConfidence, isFalse);
    });

    test('BordereauClass.toString', () {
      const a = BordereauClass('TEL', 0.95);
      expect(a.toString(), 'TEL (95%)');
    });
  });
}
