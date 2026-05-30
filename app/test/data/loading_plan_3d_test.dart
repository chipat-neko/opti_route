import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/loading_plan_3d.dart';

void main() {
  group('LoadingPlan3D.compute (#332)', () {
    test('vide -> vide', () {
      expect(LoadingPlan3D.compute(const []), isEmpty);
    });

    test('fragile -> niveau haut', () {
      final out = LoadingPlan3D.compute([
        const LoadingItem(stopId: 1, deliveryOrder: 1, fragile: true),
      ]);
      expect(out.first.level, LoadingLevel.top);
    });

    test('lourd -> niveau bas', () {
      final out = LoadingPlan3D.compute([
        const LoadingItem(stopId: 1, deliveryOrder: 1, heavy: true),
      ]);
      expect(out.first.level, LoadingLevel.bottom);
    });

    test('zone selon ordre livraison', () {
      // 9 items, deliveryOrder 1 (1/9=0.11 front), 5 (5/9=0.55 middle),
      // 9 (9/9=1.0 back).
      final items = List<LoadingItem>.generate(
        9,
        (i) => LoadingItem(stopId: i + 1, deliveryOrder: i + 1),
      );
      final out = LoadingPlan3D.compute(items);
      expect(out[0].zone, LoadingZone.front);
      expect(out[4].zone, LoadingZone.middle);
      expect(out[8].zone, LoadingZone.back);
    });
  });
}
