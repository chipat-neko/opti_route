import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:opti_route/data/tile_prefetch_service.dart';

// Complete tile_prefetch_service_test : boundaries estimatedSizeLabel,
// classes TileXYZ / TilePrefetchEstimate / TilePrefetchError,
// limites minZoom/maxZoom.
void main() {
  group('TileXYZ', () {
    test('expose z, x, y', () {
      const t = TileXYZ(13, 100, 200);
      expect(t.z, 13);
      expect(t.x, 100);
      expect(t.y, 200);
    });
  });

  group('TilePrefetchEstimate.estimatedSizeLabel — boundaries', () {
    test('0 bytes -> "0 KB"', () {
      const e = TilePrefetchEstimate(tiles: 0, estimatedBytes: 0);
      expect(e.estimatedSizeLabel, '0 KB');
    });

    test('512 KB -> "512 KB"', () {
      const e = TilePrefetchEstimate(tiles: 26, estimatedBytes: 512 * 1024);
      expect(e.estimatedSizeLabel, '512 KB');
    });

    test('1 MB pile (1024*1024) -> "1.0 MB" (bascule)', () {
      const e = TilePrefetchEstimate(tiles: 52, estimatedBytes: 1024 * 1024);
      expect(e.estimatedSizeLabel, '1.0 MB');
    });

    test('1023 KB juste avant 1 MB -> "1023 KB"', () {
      const e = TilePrefetchEstimate(
          tiles: 52, estimatedBytes: 1023 * 1024);
      expect(e.estimatedSizeLabel, '1023 KB');
    });

    test('2.5 MB -> "2.5 MB"', () {
      const e = TilePrefetchEstimate(
        tiles: 128,
        estimatedBytes: 2 * 1024 * 1024 + 512 * 1024,
      );
      expect(e.estimatedSizeLabel, '2.5 MB');
    });
  });

  group('TilePrefetchService.estimate — calcul bytes', () {
    test('estimatedBytes = tiles * 20 * 1024 (heuristique)', () {
      final e = TilePrefetchService.estimate(
        points: const [LatLng(48.5, 1.5)],
        minZoom: 13,
        maxZoom: 13,
      );
      expect(e.estimatedBytes, e.tiles * 20 * 1024);
    });

    test('liste vide : tiles=0, bytes=0', () {
      final e = TilePrefetchService.estimate(
        points: const [],
      );
      expect(e.tiles, 0);
      expect(e.estimatedBytes, 0);
    });
  });

  group('TilePrefetchService.estimate — limites de zoom', () {
    test('minZoom == maxZoom : 1 niveau seulement', () {
      // 1 point au zoom 14 = 1 tuile
      final e = TilePrefetchService.estimate(
        points: const [LatLng(48.5, 1.5)],
        minZoom: 14,
        maxZoom: 14,
      );
      expect(e.tiles, 1);
    });

    test('minZoom > maxZoom : aucune tuile (loop ne tourne pas)', () {
      final e = TilePrefetchService.estimate(
        points: const [LatLng(48.5, 1.5)],
        minZoom: 16,
        maxZoom: 13,
      );
      expect(e.tiles, 0);
    });
  });

  group('TilePrefetchService.estimate — bbox multi-quadrant', () {
    test('points dans les 2 hemispheres : bbox englobe l\'equateur', () {
      // 1 point nord (48,1) + 1 point sud (-33,151) : bbox enorme
      // mais pas de crash, et le nb de tuiles est borne.
      final e = TilePrefetchService.estimate(
        points: const [LatLng(48.0, 1.0), LatLng(-33.0, 151.0)],
        minZoom: 1,
        maxZoom: 3,
      );
      expect(e.tiles, greaterThan(0));
    });

    test('points proches : 1 tuile par zoom (4 zooms = 4 tuiles)', () {
      // Tous dans le meme carre de tuile au zoom 13.
      final e = TilePrefetchService.estimate(
        points: const [
          LatLng(48.5, 1.5),
          LatLng(48.5001, 1.5001),
        ],
        minZoom: 13,
        maxZoom: 16,
      );
      expect(e.tiles, greaterThanOrEqualTo(4));
      expect(e.tiles, lessThanOrEqualTo(16),
          reason: 'au pire 4 tuiles par zoom (carre 2x2 en bord)');
    });
  });

  group('TilePrefetchError', () {
    test('expose message + toString', () {
      final e = TilePrefetchError('zone trop large');
      expect(e.message, 'zone trop large');
      expect(e.toString(), 'zone trop large');
    });
  });
}
