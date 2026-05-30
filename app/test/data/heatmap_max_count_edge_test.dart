import 'package:flutter_test/flutter_test.dart';
import 'package:opti_route/data/heatmap_service.dart';

// Complete heatmap_service_edge_test : cas de maxCount sur liste vide
// + multiples cellules avec meme count.
void main() {
  group('HeatmapService.maxCount — cas degeneres', () {
    test('liste vide : retourne 0 (pas de crash sur empty.first)', () {
      expect(HeatmapService.maxCount(const []), 0);
    });

    test('cellules multiples avec meme count : retourne ce count', () {
      const cells = [
        HeatCell(lat: 0, lng: 0, count: 5),
        HeatCell(lat: 1, lng: 1, count: 5),
        HeatCell(lat: 2, lng: 2, count: 5),
      ];
      expect(HeatmapService.maxCount(cells), 5);
    });

    test('1 seule cellule : retourne son count', () {
      const cells = [HeatCell(lat: 0, lng: 0, count: 42)];
      expect(HeatmapService.maxCount(cells), 42);
    });

    test('100 cellules : pas de probleme de perf, max correct', () {
      final cells = List.generate(
        100,
        (i) => HeatCell(lat: i / 10, lng: i / 10, count: i),
      );
      expect(HeatmapService.maxCount(cells), 99);
    });
  });
}
