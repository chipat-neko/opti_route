import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/bordereau/format_detector.dart';

void main() {
  group('BordereauFormatDetector.detect', () {
    const detector = BordereauFormatDetector();

    test('lignes vides -> unknown', () {
      expect(detector.detect(const []), BordereauFormat.unknown);
    });

    test('aucun marqueur reconnu -> unknown', () {
      expect(
        detector.detect(const [
          'Texte aleatoire sans marqueur',
          'Une autre ligne',
        ]),
        BordereauFormat.unknown,
      );
    });

    test('bordereau MESEXP standard -> mesexp', () {
      expect(
        detector.detect(const [
          'Regime MESEXP - Messagerie Express',
          'Destinataire',
          'HYDRO ALUMINIUM EXTRUSION SERVICES',
          'Lieu de livraison',
          '28110 LUCE',
          'Total colis : 1',
        ]),
        BordereauFormat.mesexp,
      );
    });

    test('MESEXP avec marqueurs secondaires uniquement -> mesexp', () {
      // Si "MESEXP" est mal lu par l'OCR mais qu'on a les marqueurs
      // secondaires, on doit quand meme detecter.
      expect(
        detector.detect(const [
          'Destinataire',
          'CLIENT XYZ',
          'Lieu de livraison',
          '28000 CHARTRES',
          'Total colis : 2',
          'Contact destinataire',
        ]),
        BordereauFormat.mesexp,
      );
    });

    test('tolerance OCR "desinataire" (sans le t) -> mesexp', () {
      expect(
        detector.detect(const [
          'Desinataire',
          'CLIENT',
          'Lieu livraison',
          '75000 PARIS',
        ]),
        BordereauFormat.mesexp,
      );
    });

    test('marqueurs colis -> colis', () {
      expect(
        detector.detect(const [
          'Tracking : 1Z999AA1234567890',
          'Suivi colis',
          'Reference colis 42',
        ]),
        BordereauFormat.colis,
      );
    });

    test('mix MESEXP fort + colis faible -> mesexp gagne', () {
      // Heuristique : on prend le score le plus eleve.
      expect(
        detector.detect(const [
          'MESEXP Messagerie Express',
          'Destinataire',
          'CLIENT',
          'Lieu de livraison',
          '75000 PARIS',
          'Suivi colis 42', // 1 marqueur colis
        ]),
        BordereauFormat.mesexp,
      );
    });
  });
}
