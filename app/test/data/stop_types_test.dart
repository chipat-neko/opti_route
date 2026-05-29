import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/stop_types.dart';

// Verrouille les constantes + helpers d'affichage du type d'arret
// (livraison / ramasse). Pur, aucun impact prod.
void main() {
  group('constantes', () {
    test('kStopTypeLivraison = "livraison"', () {
      expect(kStopTypeLivraison, 'livraison');
    });
    test('kStopTypeRamasse = "ramasse"', () {
      expect(kStopTypeRamasse, 'ramasse');
    });
    test('kStopTypeValues contient les 2 types dans l\'ordre', () {
      expect(kStopTypeValues, [kStopTypeLivraison, kStopTypeRamasse]);
    });
  });

  group('stopActionVerbInfinitif', () {
    test('ramasse -> "ramasse"', () {
      expect(stopActionVerbInfinitif(kStopTypeRamasse), 'ramasse');
    });
    test('livraison -> "livre" (defaut)', () {
      expect(stopActionVerbInfinitif(kStopTypeLivraison), 'livre');
    });
    test('valeur inconnue -> "livre" (fallback)', () {
      expect(stopActionVerbInfinitif('inconnu'), 'livre');
    });
  });

  group('stopActionVerbParticipe', () {
    test('ramasse -> "ramasse"', () {
      expect(stopActionVerbParticipe(kStopTypeRamasse), 'ramasse');
    });
    test('livraison -> "livre"', () {
      expect(stopActionVerbParticipe(kStopTypeLivraison), 'livre');
    });
  });

  group('stopTypeLabelUpper', () {
    test('ramasse -> "RAMASSE"', () {
      expect(stopTypeLabelUpper(kStopTypeRamasse), 'RAMASSE');
    });
    test('livraison -> "LIVRAISON"', () {
      expect(stopTypeLabelUpper(kStopTypeLivraison), 'LIVRAISON');
    });
  });

  group('stopTypeLabel', () {
    test('ramasse -> "Ramasse"', () {
      expect(stopTypeLabel(kStopTypeRamasse), 'Ramasse');
    });
    test('livraison -> "Livraison"', () {
      expect(stopTypeLabel(kStopTypeLivraison), 'Livraison');
    });
  });
}
