import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/end_of_day_depot.dart';

void main() {
  const depotLat = 48.4470;
  const depotLng = 1.4890;
  const depotLabel = 'Depot Chartres';

  group('EndOfDayDepot.proposeNextDayDepot (#314)', () {
    test('pas de endOfDay -> depot normal', () {
      final p = EndOfDayDepot.proposeNextDayDepot(
        normalDepotLat: depotLat,
        normalDepotLng: depotLng,
        normalDepotLabel: depotLabel,
      );
      expect(p.lat, depotLat);
      expect(p.label, depotLabel);
      expect(p.isFromYesterday, isFalse);
    });

    test('endOfDay < 8km -> depot normal', () {
      final p = EndOfDayDepot.proposeNextDayDepot(
        normalDepotLat: depotLat,
        normalDepotLng: depotLng,
        normalDepotLabel: depotLabel,
        endOfDayLat: 48.450,
        endOfDayLng: 1.490,
      );
      expect(p.label, depotLabel);
      expect(p.savedKm, 0);
    });

    test('endOfDay 30km (Chateaudun) -> propose hier soir + savedKm', () {
      const chatLat = 48.0729; // Chateaudun
      const chatLng = 1.3271;
      final p = EndOfDayDepot.proposeNextDayDepot(
        normalDepotLat: depotLat,
        normalDepotLng: depotLng,
        normalDepotLabel: depotLabel,
        endOfDayLat: chatLat,
        endOfDayLng: chatLng,
      );
      expect(p.lat, chatLat);
      expect(p.isFromYesterday, isTrue);
      expect(p.savedKm, greaterThan(40),
          reason: 'distance ~43 km Chartres-Chateaudun');
      expect(p.savedKm, lessThan(120));
    });
  });
}
