import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/database.dart';
import 'package:opti_route/data/heatmap_service.dart';

Stop _stop({required double? lat, required double? lng, int id = 1}) {
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
    statutLivraison: 'livre',
    positionLocked: false,
    creeLe: now,
    updatedAt: now,
  );
}

void main() {
  group('HeatmapService.aggregate', () {
    test('2 arrets dans la meme cellule -> 1 cellule, count 2', () {
      final cells = HeatmapService.aggregate([
        _stop(lat: 48.4470, lng: 1.4890, id: 1),
        _stop(lat: 48.4472, lng: 1.4895, id: 2),
      ]);
      expect(cells.length, 1);
      expect(cells.first.count, 2);
    });

    test('arrets eloignes -> cellules distinctes', () {
      final cells = HeatmapService.aggregate([
        _stop(lat: 48.44, lng: 1.48, id: 1),
        _stop(lat: 48.90, lng: 2.30, id: 2),
      ]);
      expect(cells.length, 2);
      expect(cells.every((c) => c.count == 1), isTrue);
    });

    test('arrets sans coords ignores', () {
      final cells = HeatmapService.aggregate([
        _stop(lat: null, lng: null, id: 1),
        _stop(lat: 48.44, lng: 1.48, id: 2),
      ]);
      expect(cells.length, 1);
      expect(cells.single.count, 1);
    });

    test('liste vide -> aucune cellule, maxCount 0', () {
      expect(HeatmapService.aggregate(const []), isEmpty);
      expect(HeatmapService.maxCount(const []), 0);
    });

    test('centre de cellule reste dans la maille (~0.01 deg)', () {
      final cells = HeatmapService.aggregate([_stop(lat: 48.447, lng: 1.489)]);
      final c = cells.single;
      expect((c.lat - 48.447).abs() < 0.01, isTrue);
      expect((c.lng - 1.489).abs() < 0.01, isTrue);
    });

    test('maxCount = plus grand compte', () {
      final cells = HeatmapService.aggregate([
        _stop(lat: 48.44, lng: 1.48, id: 1),
        _stop(lat: 48.441, lng: 1.481, id: 2),
        _stop(lat: 48.442, lng: 1.482, id: 3),
        _stop(lat: 48.90, lng: 2.30, id: 4),
      ]);
      expect(HeatmapService.maxCount(cells), 3);
    });
  });
}
