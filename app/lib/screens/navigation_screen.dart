import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/database.dart';
import '../data/location_service.dart';
import '../providers/tile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Navigation interne plein ecran : suivi GPS live + destination.
/// ════════════════════════════════════════════════════════════════
///
/// PoC Etape 1 du plan GPS turn-by-turn integre (cf
/// `docs/plan-gps-integre.md`). Affiche :
/// - Carte OSM plein ecran centree sur la position GPS courante
/// - Marker bleu "ma position" mis a jour en temps reel via
///   [LocationService.positionStream]
/// - Marker destination (le [Stop] cible)
/// - Polyline ligne droite entre les 2 (haversine, pas un vrai
///   itineraire routier -- ca viendra en Etape 2 via ORS directions)
/// - Bandeau supérieur avec la distance restante en temps reel
///
/// **But** : eviter au livreur de switcher entre opti_route et
/// Maps/Waze pendant la tournee. Il peut voir ou il en est sans
/// quitter l'app. Le bouton "Maps/Waze" classique reste dispo pour
/// les utilisateurs qui preferent une vraie nav turn-by-turn.
///
/// **Limitations PoC** :
/// - Ligne droite (pas d'itineraire routier). Vraie nav viendra en
///   Etape 2 quand on integrera les `directions.steps` de l'API ORS.
/// - Pas de voix. Etape 3 quand on ajoutera flutter_tts.
/// - Pas de re-routing si l'utilisateur s'eloigne.
class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key, required this.stop});

  /// Le stop a atteindre. Doit avoir `lat != null && lng != null`,
  /// sinon le caller (StopActionSheet) ne doit pas pousser cet ecran.
  final Stop stop;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  final MapController _mapController = MapController();

  /// Vrai apres le 1er emit du stream GPS. Permet de centrer la map
  /// automatiquement la 1ere fois (puis l'utilisateur peut faire un
  /// pinch-zoom et on ne re-centre plus tant qu'il n'a pas demande).
  bool _hasCenteredOnce = false;

  /// Toggle "auto-follow" : si true, la carte recentrera a chaque
  /// nouvelle position GPS. Par defaut OFF apres le 1er centrage pour
  /// laisser l'utilisateur explorer librement.
  bool _autoFollow = true;

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final destination = LatLng(widget.stop.lat!, widget.stop.lng!);

    return Scaffold(
      backgroundColor: p.cream,
      body: StreamBuilder<Position>(
        stream: LocationService.positionStream(distanceFilterMeters: 10),
        builder: (context, snapshot) {
          final pos = snapshot.data;
          // Tant qu'on n'a pas de position GPS, on affiche un loader
          // centre. Cas typique : 1-3 secondes au cold open de
          // l'ecran, le temps que le GPS chip s'allume et triangule.
          if (pos == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: p.ink),
                  const SizedBox(height: AppSpacing.x14),
                  Text(
                    'Recherche du signal GPS...',
                    style: TextStyle(color: p.ink, fontSize: 14),
                  ),
                ],
              ),
            );
          }

          final me = LatLng(pos.latitude, pos.longitude);
          final distanceM = LocationService.distanceMeters(
            fromLat: pos.latitude,
            fromLng: pos.longitude,
            toLat: widget.stop.lat!,
            toLng: widget.stop.lng!,
          );

          // Premier centrage automatique sur la position courante au
          // 1er emit du stream. Apres, on respecte le toggle _autoFollow.
          if (!_hasCenteredOnce) {
            _hasCenteredOnce = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(me, 16);
            });
          } else if (_autoFollow) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _mapController.move(me, _mapController.camera.zoom);
            });
          }

          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: me,
                  initialZoom: 16,
                  minZoom: 4,
                  maxZoom: 19,
                  // Si l'utilisateur touche la carte (drag/zoom), on
                  // desactive l'auto-follow pour qu'il puisse explorer
                  // sans etre re-centre constamment.
                  onPositionChanged: (_, hasGesture) {
                    if (hasGesture && _autoFollow) {
                      setState(() => _autoFollow = false);
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.optiroute.opti_route',
                    tileProvider: ref.read(cachedTileProviderInstance),
                  ),
                  // Ligne droite position -> destination. C'est PAS un
                  // itineraire routier, juste une indication visuelle
                  // de direction. Phase B remplacera par les
                  // directions.steps de l'API ORS.
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: [me, destination],
                        strokeWidth: 4,
                        color: AppColors.emerald,
                        pattern: StrokePattern.dashed(
                          segments: const [10, 6],
                        ),
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      // Position courante (cercle bleu avec halo).
                      Marker(
                        point: me,
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E88E5),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: AppShadows.fab,
                          ),
                        ),
                      ),
                      // Destination (pin lime avec icone flag).
                      Marker(
                        point: destination,
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.lime,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.ink, width: 1.5),
                            boxShadow: AppShadows.fab,
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.flag,
                            color: AppColors.ink,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Bandeau supérieur : nom client + distance restante en
              // temps reel. Tap sur la fleche back retourne a l'ecran
              // precedent (la tournee_du_jour generalement).
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x14,
                      vertical: AppSpacing.x10,
                    ),
                    decoration: BoxDecoration(
                      color: p.paper,
                      borderRadius: BorderRadius.circular(AppRadius.r14),
                      boxShadow: AppShadows.card,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                          tooltip: 'Retour',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.x8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.stop.nomClient?.trim().isNotEmpty ==
                                        true
                                    ? widget.stop.nomClient!
                                    : (widget.stop.adresseNormalisee ??
                                        widget.stop.adresseBrute),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: p.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _formatDistance(distanceM),
                                style: appMonoStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.emerald,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Toggle auto-follow (loupe avec cible).
                        IconButton(
                          icon: Icon(
                            _autoFollow
                                ? Icons.gps_fixed
                                : Icons.gps_not_fixed,
                            color: _autoFollow ? AppColors.emerald : p.textMute,
                          ),
                          onPressed: () {
                            setState(() => _autoFollow = !_autoFollow);
                            if (_autoFollow) {
                              _mapController.move(me, 16);
                            }
                          },
                          tooltip: _autoFollow
                              ? 'Auto-suivi actif'
                              : 'Centrer sur ma position',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // FAB "J'y suis" en bas a droite : retour vers l'ecran
              // precedent avec un signal `true` pour que le caller
              // puisse declencher la bottom sheet de validation.
              Positioned(
                right: AppSpacing.x18,
                bottom: AppSpacing.x18,
                child: FloatingActionButton.extended(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('J\'y suis'),
                  backgroundColor: AppColors.lime,
                  foregroundColor: AppColors.ink,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Distance "X m" ou "X.Y km" selon le seuil, en mono pour
  /// alignement vertical avec d'autres mesures.
  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m restants';
    final km = (meters / 1000).toStringAsFixed(1);
    return '$km km restants';
  }
}
