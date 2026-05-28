import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/chef_carte_service.dart';
import '../../data/chef_presence_service.dart';
import '../../data/cloud_error_humanizer.dart';
import '../../data/tournee_realtime_service.dart' show LivePosition;
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';

/// Panneau "carte" du logiciel chef (epopee #88, [#88·3]).
///
/// Affiche une carte OSM avec les depots + arrets geolocalises de la
/// journee (donnees locales), colories par statut de livraison. La
/// couche "positions live des chauffeurs" (multi-tournees Realtime)
/// viendra se greffer ici une fois le cloud temps reel valide sur
/// device -- un bandeau l'indique. Source : [equipeCarteJourProvider].
class ChefLiveMapPanel extends ConsumerWidget {
  const ChefLiveMapPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(equipeCarteJourProvider);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  'Carte du jour',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              _Tag(label: '[#88·3]'),
            ],
          ),
          const Divider(height: AppSpacing.x22),
          Expanded(
            child: async.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text(
                  humanizeAnyError(e),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: p.textMute),
                ),
              ),
              data: (carte) => carte.isEmpty
                  ? Center(
                      child: Text(
                        'Aucune adresse geolocalisee aujourd\'hui',
                        textAlign: TextAlign.center,
                        style:
                            TextStyle(fontSize: 13, color: p.textFaint),
                      ),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.r12),
                      child: _Carte(carte: carte),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Carte extends ConsumerWidget {
  const _Carte({required this.carte});

  final ChefCarteJour carte;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    // Positions live des chauffeurs (carte #174). Vide si cloud off /
    // pas connecte / aucune tournee partagee en cours.
    final live = ref.watch(equipePresenceProvider).asData?.value ??
        const <String, LivePosition>{};
    final now = DateTime.now();
    final points = [
      for (final pt in carte.points) LatLng(pt.lat, pt.lng),
    ];
    // Fit bounds si >= 2 points, sinon centre sur l'unique point.
    final hasBounds = points.length >= 2;
    return Stack(
      children: [
        FlutterMap(
          options: MapOptions(
            initialCameraFit: hasBounds
                ? CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(40),
                  )
                : null,
            initialCenter: hasBounds ? const LatLng(0, 0) : points.first,
            initialZoom: hasBounds ? 11 : 14,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'fr.optiroute.app',
            ),
            MarkerLayer(
              markers: [
                for (final pt in carte.points)
                  Marker(
                    point: LatLng(pt.lat, pt.lng),
                    width: 30,
                    height: 30,
                    child: _Pin(point: pt),
                  ),
              ],
            ),
            // Couche live : 1 marker par chauffeur qui broadcast sa
            // position (carte #174).
            if (live.isNotEmpty)
              MarkerLayer(
                markers: [
                  for (final pos in live.values)
                    Marker(
                      point: LatLng(pos.lat, pos.lng),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      child: _DriverPin(
                        freshness: freshnessOf(now.difference(pos.timestamp)),
                      ),
                    ),
                ],
              ),
          ],
        ),
        // Bandeau : nb de chauffeurs en direct, ou note "a venir".
        Positioned(
          left: AppSpacing.x8,
          right: AppSpacing.x8,
          top: AppSpacing.x8,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x10,
              vertical: AppSpacing.x6,
            ),
            decoration: BoxDecoration(
              color: p.paper.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppRadius.r8),
              boxShadow: AppShadows.card,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.my_location_outlined,
                    size: 14,
                    color: live.isEmpty ? p.textMute : AppColors.emerald),
                const SizedBox(width: AppSpacing.x6),
                Expanded(
                  child: Text(
                    live.isEmpty
                        ? 'Positions live des chauffeurs : actives des '
                            'qu\'un livreur est en tournee partagee'
                        : '${live.length} chauffeur'
                            '${live.length > 1 ? "s" : ""} en direct',
                    style: TextStyle(
                      fontSize: 10,
                      color: live.isEmpty ? p.textMute : p.ink,
                      fontWeight:
                          live.isEmpty ? FontWeight.w400 : FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.point});

  final ChefCartePoint point;

  @override
  Widget build(BuildContext context) {
    if (point.type == ChefPointType.depot) {
      return const Icon(Icons.home_outlined, size: 26, color: AppColors.ink);
    }
    final color = switch (point.statut) {
      'livre' => AppColors.emerald,
      'echec' => AppColors.red,
      _ => AppColors.lime,
    };
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.paper, width: 2),
        boxShadow: AppShadows.fab,
      ),
    );
  }
}

/// Marker d'un chauffeur en direct (carte #174). Couleur selon la
/// fraicheur de la derniere position : emerald < 60s, amber < 300s,
/// gris attenue au-dela.
class _DriverPin extends StatelessWidget {
  const _DriverPin({required this.freshness});

  final LiveFreshness freshness;

  @override
  Widget build(BuildContext context) {
    final color = switch (freshness) {
      LiveFreshness.fresh => AppColors.emerald,
      LiveFreshness.recent => AppColors.amber,
      LiveFreshness.stale => AppColors.textFaint,
    };
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.paper, width: 2),
        boxShadow: AppShadows.fab,
      ),
      alignment: Alignment.center,
      child: const Icon(Icons.directions_car,
          size: 18, color: AppColors.paper),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: p.textMute,
        ),
      ),
    );
  }
}
