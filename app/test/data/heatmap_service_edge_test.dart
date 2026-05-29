import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/heatmap_service.dart';

Stop _stop({required double lat, required double lng, int id = 1}) {
  final now = DateTime(2026, 5, 29);
  return Stop(
    id: id,
    tourneeId: 1,
    adresseBrute: 'A$id',
    type: 'livraison',
    lat: lat,
    lng: lng,
    nbColis: 1,
    priorite: 'flexible',
    dureeArretMin: 2,
    statutLivraison: 'a_livrer',
    positionLocked: false,
    creeLe: now,
    updatedAt: now,
  );
}

// Complete heatmap_service_test : seuils de cellDeg, hemisphere sud,
// passage de l'equateur, agregation massive.
void main() {
  group('HeatmapService.aggregate (cas-limites)', () {
    test('cellDeg = 0 -> liste vide', () {
      expect(
        HeatmapService.aggregate([_stop(lat: 48, lng: 1)], cellDeg: 0),
        isEmpty,
      );
    });

    test('cellDeg negatif -> liste vide', () {
      expect(
        HeatmapService.aggregate([_stop(lat: 48, lng: 1)], cellDeg: -0.1),
        isEmpty,
      );
    });

    test('cellDeg 0.1 (grossier) groupe les points proches', () {
      final cells = HeatmapService.aggregate(
        [
          _stop(lat: 48.05, lng: 1.05, id: 1),
          _stop(lat: 48.09, lng: 1.01, id: 2),
        ],
        cellDeg: 0.1,
      );
      expect(cells.length, 1);
      expect(cells.first.count, 2);
    });

    test('coords hemisphere sud traitees', () {
      final cells = HeatmapService.aggregate([
        _stop(lat: -33.86, lng: 151.21, id: 1), // Sydney
      ]);
      expect(cells.length, 1);
      expect(cells.first.lat, lessThan(0));
    });

    test('a cheval sur l\'equateur : cellules distinctes (floor change)', () {
      final cells = HeatmapService.aggregate([
        _stop(lat: 0.005, lng: 0, id: 1),
        _stop(lat: -0.005, lng: 0, id: 2),
      ]);
      expect(cells.length, 2);
    });

    test('50 stops dans la meme cellule -> count = 50', () {
      final stops = List.generate(
        50,
        (i) => _stop(lat: 48.4400 + i * 0.00005, lng: 1.4800, id: i),
      );
      final cells = HeatmapService.aggregate(stops);
      expect(cells.length, 1);
      expect(cells.first.count, 50);
    });
  });

  group('HeatmapService.maxCount (cas-limites)', () {
    test('counts mixtes -> max', () {
      const cells = [
        HeatCell(lat: 0, lng: 0, count: 3),
        HeatCell(lat: 1, lng: 1, count: 8),
        HeatCell(lat: 2, lng: 2, count: 1),
      ];
      expect(HeatmapService.maxCount(cells), 8);
    });

    test('cellule avec count 0 -> 0', () {
      const cells = [HeatCell(lat: 0, lng: 0, count: 0)];
      expect(HeatmapService.maxCount(cells), 0);
    });
  });
}
