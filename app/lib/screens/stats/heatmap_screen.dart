import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/heatmap_service.dart';
import '../../providers/database_providers.dart';
import '../../providers/tile_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Cellules de heatmap (zones livrees) agregees depuis TOUS les arrets
/// geocodes de l'historique. autoDispose : recalcule a l'ouverture de
/// l'ecran, libere en sortie. Carte #98.
final heatmapCellsProvider =
    FutureProvider.autoDispose<List<HeatCell>>((ref) async {
  final stops = await ref.read(stopsRepositoryProvider).getAllGeocoded();
  return HeatmapService.aggregate(stops);
});

/// Carte de densite des livraisons (carte #98) : "voici les zones que je
/// couvre". Chaque cellule de grille (~1 km) devient un cercle colore
/// (jaune = peu, rouge = beaucoup) ; les cercles translucides qui se
/// chevauchent donnent un effet heatmap, sans dependance tierce.
class HeatmapScreen extends ConsumerWidget {
  const HeatmapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cellsAsync = ref.watch(heatmapCellsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Zones les plus livrees')),
      body: cellsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x22),
            child: Text('Erreur : ${humanizeAnyError(e)}'),
          ),
        ),
        data: (cells) =>
            cells.isEmpty ? const _EmptyState() : _HeatMap(cells: cells),
      ),
    );
  }
}

class _HeatMap extends ConsumerWidget {
  const _HeatMap({required this.cells});

  final List<HeatCell> cells;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = [for (final c in cells) LatLng(c.lat, c.lng)];
    final maxCount = HeatmapService.maxCount(cells);
    final totalStops = cells.fold<int>(0, (sum, c) => sum + c.count);

    final fit = points.length > 1
        ? CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(points),
            padding: const EdgeInsets.all(56),
          )
        : CameraFit.coordinates(
            coordinates: points,
            padding: const EdgeInsets.all(56),
            maxZoom: 13,
          );

    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCameraFit: fit,
            minZoom: 2,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.optiroute.opti_route',
              tileProvider: ref.read(cachedTileProviderInstance),
            ),
            CircleLayer(
              circles: [
                for (final c in cells)
                  CircleMarker(
                    point: LatLng(c.lat, c.lng),
                    // Rayon en metres ~ demi-cellule : les cercles se
                    // chevauchent legerement -> effet heatmap continu.
                    radius: 650,
                    useRadiusInMeter: true,
                    color: _colorFor(c.count, maxCount).withValues(alpha: 0.45),
                    borderStrokeWidth: 0,
                    borderColor: Colors.transparent,
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          left: AppSpacing.x14,
          right: AppSpacing.x14,
          bottom: AppSpacing.x14,
          child: _Legend(
            zones: cells.length,
            totalStops: totalStops,
            maxCount: maxCount,
          ),
        ),
      ],
    );
  }

  /// Jaune (peu) -> orange -> rouge (beaucoup), normalise sur le max.
  /// Plancher a 0.15 pour qu'une cellule isolee reste visible.
  static Color _colorFor(int count, int maxCount) {
    final ratio = maxCount <= 1 ? 1.0 : (count / maxCount).clamp(0.15, 1.0);
    return Color.lerp(AppColors.amber, AppColors.red, ratio) ?? AppColors.red;
  }
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.zones,
    required this.totalStops,
    required this.maxCount,
  });

  final int zones;
  final int totalStops;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: p.divider),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$totalStops arrets livres · $zones zones',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          Row(
            children: [
              Text('Moins',
                  style: TextStyle(fontSize: 11, color: p.textMute)),
              const SizedBox(width: AppSpacing.x6),
              Expanded(
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    gradient: const LinearGradient(
                      colors: [AppColors.amber, AppColors.red],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x6),
              Text('Plus (jusqu\'a $maxCount)',
                  style: TextStyle(fontSize: 11, color: p.textMute)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Carte CTA affichee dans l'ecran Stats -> ouvre la [HeatmapScreen]
/// (carte #98).
class HeatmapCard extends StatelessWidget {
  const HeatmapCard({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r18),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const HeatmapScreen()),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.creamSoft,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.local_fire_department_outlined,
                    color: p.ink,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CARTE DES ZONES',
                        style: appMonoStyle(
                          fontSize: 10.5,
                          letterSpacing: 0.6,
                          fontWeight: FontWeight.w800,
                          color: p.textMute,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Heatmap des livraisons',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Visualise les zones que tu couvres le plus',
                        style: TextStyle(fontSize: 11.5, color: p.textMute),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: p.textMute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 48, color: p.textMute),
            const SizedBox(height: AppSpacing.x14),
            Text(
              'Aucune zone a afficher',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              'La carte se remplit au fil de tes livraisons geolocalisees.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.textMute, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }
}
