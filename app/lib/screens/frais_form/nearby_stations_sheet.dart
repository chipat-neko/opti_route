import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/fuel_price_service.dart';
import '../../data/navigation_service.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// BottomSheet "Stations Diesel proches" (carte Trello #39 V4).
/// ════════════════════════════════════════════════════════════════
///
/// Fetch les N stations Diesel les plus proches via le provider
/// `nearbyDieselStationsProvider` (data.gouv.fr ODSql, rayon 10 km
/// par defaut). Pour chaque station : nom + adresse + prix + distance
/// + bouton "Itineraire" (lance Maps via NavigationService).
///
/// Tap sur la card -> `Navigator.pop(station)` qui rend la station
/// selectionnee au caller. Le caller (FraisFormScreen) chaine ensuite
/// le dialog "Combien de litres ?" pour calculer le montant final.
///
/// Coordonnees arrondies a 0.01 deg (~1 km) pour stabiliser le cache
/// du provider entre micro-deplacements GPS.
class NearbyStationsSheet extends ConsumerWidget {
  const NearbyStationsSheet({
    super.key,
    required this.lat,
    required this.lng,
  });

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final coords = (
      (lat * 100).round() / 100,
      (lng * 100).round() / 100,
    );
    final async = ref.watch(nearbyDieselStationsProvider(coords));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x18,
          AppSpacing.x18,
          AppSpacing.x18,
          AppSpacing.x10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.local_gas_station_outlined,
                    color: AppColors.emerald),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: Text(
                    'Stations Diesel proches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Rafraichir',
                  onPressed: () =>
                      ref.invalidate(nearbyDieselStationsProvider(coords)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              'Tap sur une station pour pre-remplir le libelle + montant '
              '(estim 50L de plein). Source data.gouv.fr.',
              style: TextStyle(
                fontSize: 11.5,
                color: p.textMute,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.x12),
            async.when(
              data: (stations) {
                if (stations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.x22,
                    ),
                    child: Center(
                      child: Text(
                        'Aucune station trouvee dans un rayon de 10 km '
                        '(reseau down ou zone isolee).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: p.textMute,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final st in stations) _StationTile(station: st),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.x22),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.x18,
                ),
                child: Text(
                  'Erreur de chargement : $e',
                  style: const TextStyle(color: AppColors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({required this.station});

  final FuelStation station;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final priceFr = station.dieselPriceEur.toStringAsFixed(3);
    final distFr = station.distanceKm < 1
        ? '${(station.distanceKm * 1000).round()} m'
        : '${station.distanceKm.toStringAsFixed(1)} km';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: () => Navigator.of(context).pop(station),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.displayLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${station.codePostal} ${station.ville} · $distFr',
                      style: TextStyle(fontSize: 11, color: p.textMute),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$priceFr EUR',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.directions, size: 18),
                    tooltip: 'Itineraire',
                    onPressed: () => NavigationService.launchGoogleMaps(
                      lat: station.lat,
                      lng: station.lng,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
