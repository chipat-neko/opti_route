import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:opti_route/data/tile_prefetch_service.dart';

/// Tests des fonctions PURES de [TilePrefetchService] (estimation de
/// la bbox et conversion lat/lng -> tile indices). Le download HTTP
/// reel n'est pas couvert ici (necessite un mock CachedTileProvider
/// et un fake HTTP client).
void main() {
  group('TilePrefetchService.estimate', () {
    test('liste vide -> 0 tuiles, 0 bytes', () {
      final e = TilePrefetchService.estimate(points: []);
      expect(e.tiles, 0);
      expect(e.estimatedBytes, 0);
      expect(e.estimatedSizeLabel, '0 KB');
    });

    test('1 point a Paris au zoom 13 -> 1 tuile', () {
      final e = TilePrefetchService.estimate(
        points: [const LatLng(48.8566, 2.3522)],
        minZoom: 13,
        maxZoom: 13,
      );
      // 1 point genere une bbox degeneree (lat=lat, lng=lng), donc 1 tuile.
      expect(e.tiles, 1);
      expect(e.estimatedBytes, 20 * 1024);
      expect(e.estimatedSizeLabel, '20 KB');
    });

    test('1 point sur zooms 13-16 -> 4 tuiles (1 par zoom)', () {
      final e = TilePrefetchService.estimate(
        points: [const LatLng(48.8566, 2.3522)],
        minZoom: 13,
        maxZoom: 16,
      );
      expect(e.tiles, 4);
    });

    test('2 points distants : plus de tuiles au zoom le plus eleve', () {
      // Paris + Marseille : ~ 660 km. Au zoom 16, la bbox couvre
      // une enorme surface en tuiles.
      final e = TilePrefetchService.estimate(
        points: [
          const LatLng(48.8566, 2.3522), // Paris
          const LatLng(43.2965, 5.3698), // Marseille
        ],
        minZoom: 10,
        maxZoom: 10,
      );
      // Au zoom 10, chaque tuile = ~ 38 km de cote. Distance Paris-Marseille
      // ~ 660 km, donc on attend une grille de plusieurs tuiles. La verification
      // exacte depend de la formule slippy map. On verifie juste > 1.
      expect(e.tiles, greaterThan(1));
    });

    test('estimatedSizeLabel : < 1 MB en KB, >= 1 MB en MB', () {
      const small = TilePrefetchEstimate(tiles: 10, estimatedBytes: 200 * 1024);
      expect(small.estimatedSizeLabel, '200 KB');
      const large = TilePrefetchEstimate(
        tiles: 100,
        estimatedBytes: 2 * 1024 * 1024,
      );
      expect(large.estimatedSizeLabel, '2.0 MB');
    });
  });

  group('TilePrefetchService.maxTiles', () {
    test('plafond expose pour reutilisation', () {
      // On veut que maxTiles soit > 0 et raisonnable (entre 1000 et 10000).
      expect(TilePrefetchService.maxTiles, greaterThan(1000));
      expect(TilePrefetchService.maxTiles, lessThan(10000));
    });
  });
}
