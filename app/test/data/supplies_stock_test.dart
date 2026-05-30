import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/supplies_stock.dart';

void main() {
  group('SupplyItem (#331)', () {
    test('alertLevel 0-3', () {
      expect(
        const SupplyItem(id: 'a', name: 'X', currentQty: 10, minQty: 5)
            .alertLevel,
        0,
      );
      expect(
        const SupplyItem(id: 'a', name: 'X', currentQty: 5, minQty: 5)
            .alertLevel,
        1,
      );
      expect(
        const SupplyItem(id: 'a', name: 'X', currentQty: 2, minQty: 5)
            .alertLevel,
        2,
      );
      expect(
        const SupplyItem(id: 'a', name: 'X', currentQty: 0, minQty: 5)
            .alertLevel,
        3,
      );
    });
  });
  group('SuppliesStock.needAttention (#331)', () {
    test('filtre isLow + tri descendant', () {
      final out = SuppliesStock.needAttention(const [
        SupplyItem(id: 'a', name: 'OK', currentQty: 10, minQty: 5),
        SupplyItem(id: 'b', name: 'Urgent', currentQty: 0, minQty: 5),
        SupplyItem(id: 'c', name: 'Bas', currentQty: 3, minQty: 5),
      ]);
      expect(out.map((i) => i.id), ['b', 'c']);
    });
  });
}
