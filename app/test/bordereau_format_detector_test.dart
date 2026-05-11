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

    test('bordereau papier MESEXP standard -> mesexp', () {
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

    test('etiquette colis France Alliance variante A -> colis', () {
      // Photo de reference MVIMG_063125 : "DE MATOS ANTONIO".
      expect(
        detector.detect(const [
          'Transports France Alliance',
          'Centre Livreur',
          'Eure et Loir Acheminement',
          '28630 - GELLAINVILLE',
          'EXP: UNIKALO',
          'RECEP.:',
          '28146356',
          'UM: 1/1',
          'Destinataire :',
          'DE MATOS ANTONIO',
          '1 RUE DE L\'ABREUVOIRE',
          'FR - 28240 - LA LOUPE',
          'PRODUIT: MESEXP',
        ]),
        BordereauFormat.colis,
      );
    });

    test('etiquette colis variante B (FA56 PNEUS sans tirets) -> colis', () {
      // Photo de reference MVIMG_063202 : "AUTODISTRIBUTION MORIZE LOIRET".
      expect(
        detector.detect(const [
          'FA56 PNEUS',
          'AUTODISTRIBUTION MORIZE LOIRET',
          'AVENUE DES PRES',
          'MARGON',
          'FR 28400 ARCISSES',
          'COLIS 1/1',
          'FRANCE ALLIANCE 56',
        ]),
        BordereauFormat.colis,
      );
    });

    test('papier MESEXP (Lieu de livraison + Total colis) > colis', () {
      // Bordereau papier complet : score MESEXP doit l\'emporter meme
      // si "Transports France Alliance" apparait en filigrane.
      expect(
        detector.detect(const [
          'MESEXP Messagerie Express',
          'Destinataire',
          'CLIENT',
          'Lieu de livraison',
          '28000 CHARTRES',
          'Total colis : 2',
          'Contact destinataire',
          'Lettre de voiture',
        ]),
        BordereauFormat.mesexp,
      );
    });

    test('etiquette colis (France Alliance + FR-CP-VILLE) > papier', () {
      // Memes mots "Destinataire" et "PRODUIT: MESEXP" mais le contexte
      // est clairement une etiquette compacte.
      expect(
        detector.detect(const [
          'Transports France Alliance',
          'Centre Livreur',
          'Destinataire :',
          'ETS J.P. FRANCE',
          'FR - 28480 - THIRON GARDAIS',
          'PRODUIT: MESEXP',
          'UM: 1/1',
        ]),
        BordereauFormat.colis,
      );
    });
  });
}
