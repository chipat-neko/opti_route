import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/screens/stats/stats_card.dart';

// Verrouille le formatage EUR (virgule decimale + suffixe " EUR") utilise
// dans la card facturation. Pur, aucun changement de prod.
void main() {
  group('StatsCard.formatEur', () {
    test('virgule decimale + suffixe " EUR"', () {
      expect(StatsCard.formatEur(12.34), '12,34 EUR');
    });

    test('zero', () {
      expect(StatsCard.formatEur(0), '0,00 EUR');
    });

    test('decimale unique padding zero ("0,50")', () {
      expect(StatsCard.formatEur(0.5), '0,50 EUR');
    });

    test('grand montant', () {
      expect(StatsCard.formatEur(1234.56), '1234,56 EUR');
    });

    test('partie entiere uniquement', () {
      expect(StatsCard.formatEur(42), '42,00 EUR');
    });

    test('arrondi a 2 decimales : 0.004 -> 0,00', () {
      expect(StatsCard.formatEur(0.004), '0,00 EUR');
    });

    test('arrondi a 2 decimales : 0.005 -> 0,01 (half away from zero)', () {
      expect(StatsCard.formatEur(0.005), '0,01 EUR');
    });
  });
}
