import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/tournee_pdf_widgets.dart';

// Tests des helpers TOP-LEVEL pures de tournee_pdf_widgets :
// formatPdfDuration, statutLabel, inferStatut. Pas de rendu PDF.
void main() {
  group('formatPdfDuration', () {
    test('0s -> "0min"', () {
      expect(formatPdfDuration(0), '0min');
    });

    test('< 1h : juste minutes "Xmin"', () {
      expect(formatPdfDuration(60 * 30), '30min');
      expect(formatPdfDuration(60 * 5), '5min');
    });

    test('exactement 1h pile : "1h00" (zero-pad minutes)', () {
      expect(formatPdfDuration(3600), '1h00');
    });

    test('1h05 : "1h05" (zero-pad)', () {
      expect(formatPdfDuration(3600 + 5 * 60), '1h05');
    });

    test('2h30 : "2h30"', () {
      expect(formatPdfDuration(2 * 3600 + 30 * 60), '2h30');
    });

    test('8h00 (journee standard livreur)', () {
      expect(formatPdfDuration(8 * 3600), '8h00');
    });

    test('59min : pas encore "1h"', () {
      expect(formatPdfDuration(59 * 60), '59min');
    });
  });

  group('statutLabel', () {
    test('a_livrer -> "A livrer"', () {
      expect(statutLabel('a_livrer'), 'A livrer');
    });

    test('livre -> "LIVRE" (majuscule pour ressortir)', () {
      expect(statutLabel('livre'), 'LIVRE');
    });

    test('echec -> "ECHEC" (majuscule)', () {
      expect(statutLabel('echec'), 'ECHEC');
    });

    test('brouillon / optimisee / en_cours / terminee : capitalize', () {
      expect(statutLabel('brouillon'), 'Brouillon');
      expect(statutLabel('optimisee'), 'Optimisee');
      expect(statutLabel('en_cours'), 'En cours');
      expect(statutLabel('terminee'), 'Terminee');
    });

    test('statut inconnu : retourne tel quel (fallback)', () {
      expect(statutLabel('xyz_unknown'), 'xyz_unknown');
    });

    test('chaine vide : retourne vide', () {
      expect(statutLabel(''), '');
    });
  });

  group('inferStatut', () {
    test('total 0 -> "brouillon"', () {
      expect(inferStatut(0, 0, 0), 'brouillon');
    });

    test('tout traite -> "terminee"', () {
      expect(inferStatut(5, 4, 1), 'terminee');
      expect(inferStatut(3, 3, 0), 'terminee');
      expect(inferStatut(2, 0, 2), 'terminee');
    });

    test('partiellement traite -> "en_cours"', () {
      expect(inferStatut(5, 2, 1), 'en_cours');
      expect(inferStatut(10, 5, 0), 'en_cours');
      expect(inferStatut(10, 0, 5), 'en_cours');
    });

    test('rien de traite mais total > 0 -> "optimisee"', () {
      expect(inferStatut(5, 0, 0), 'optimisee');
    });
  });
}
