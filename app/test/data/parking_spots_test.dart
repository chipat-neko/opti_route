import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/parking_spots.dart';

void main() {
  group('ParkingSpotsHelper.findNearby (#330)', () {
    final spots = [
      const ParkingSpot(id: 'a', lat: 48.0001, lng: 1.0, label: 'A'),
      const ParkingSpot(id: 'b', lat: 48.0010, lng: 1.0, label: 'B'),
      const ParkingSpot(id: 'c', lat: 49.0, lng: 1.0, label: 'Loin'),
    ];

    test('aucun match < 50m', () {
      expect(
        ParkingSpotsHelper.findNearby(
          centerLat: 50,
          centerLng: 1,
          spots: spots,
        ),
        isEmpty,
      );
    });

    test('A à 11m -> trouve, trie distance', () {
      final r = ParkingSpotsHelper.findNearby(
        centerLat: 48,
        centerLng: 1,
        spots: spots,
        radiusMeters: 200,
      );
      expect(r, hasLength(2));
      expect(r.first.spot.id, 'a');
      expect(r.last.spot.id, 'b');
    });
  });
}
