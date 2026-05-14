import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/database.dart';
import '../data/location_service.dart';
import '../providers/database_providers.dart';
import '../providers/optimization_providers.dart';
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
class NavigationScreen extends ConsumerStatefulWidget {
  const NavigationScreen({super.key, required this.stop});

  /// Le stop a atteindre. Doit avoir `lat != null && lng != null`,
  /// sinon le caller (StopActionSheet) ne doit pas pousser cet ecran.
  final Stop stop;

  @override
  ConsumerState<NavigationScreen> createState() => _NavigationScreenState();
}

/// Etat de la permission GPS au montage du screen. Determine quel
/// widget afficher (loader / erreur / carte).
enum _PermissionState {
  /// On est en train de demander la permission a l'utilisateur.
  asking,

  /// Permission accordee, on peut lancer le stream GPS.
  granted,

  /// Permission refusee (definitivement ou GPS systeme off). On
  /// affiche un message explicite avec un bouton "Ouvrir parametres".
  denied,
}

class _NavigationScreenState extends ConsumerState<NavigationScreen> {
  final MapController _mapController = MapController();

  _PermissionState _permissionState = _PermissionState.asking;
  String? _permissionError;

  /// Position one-shot recuperee au mount, avant que le stream emette
  /// sa 1ere valeur. Permet d'afficher la carte immediatement au lieu
  /// d'attendre 5-30 sec le 1er emit du stream.
  Position? _fallbackPosition;

  /// Vrai si le stream n'a rien emis depuis 30 sec (pas de signal GPS).
  /// Bascule l'UI vers un message explicite "vérifie le GPS systeme"
  /// au lieu du loader infini.
  bool _gpsTimedOut = false;
  Timer? _gpsTimeoutTimer;

  /// Premier centrage automatique sur la position au 1er emit du stream.
  bool _hasCenteredOnce = false;

  /// Toggle "auto-follow" : si true, la carte recentrera a chaque
  /// nouvelle position GPS. Par defaut ON, desactive automatiquement
  /// si l'utilisateur drag/zoom.
  bool _autoFollow = true;

  /// Polyline routière (qui suit les rues) recuperee via l'API ORS
  /// Directions une fois qu'on a une 1ere position GPS. Null tant que
  /// l'appel n'a pas reussi -- dans ce cas on affiche la ligne droite
  /// haversine en fallback. Etape 2 du plan GPS (cf
  /// docs/plan-gps-integre.md).
  List<LatLng>? _routePolyline;
  bool _routeFetchInFlight = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Sequence d'init :
  /// 1. Demande la permission GPS (peut throw [LocationPermissionDenied])
  /// 2. Recupere une position one-shot pour afficher la carte
  ///    immediatement (la 1ere emit du stream peut prendre 30 sec)
  /// 3. Demarre le timer de timeout 30 sec (au cas ou le GPS n'emette
  ///    rien -- ex: phone en intérieur, mode avion)
  Future<void> _bootstrap() async {
    try {
      final ok = await LocationService.ensurePermission();
      if (!mounted) return;
      if (!ok) {
        setState(() {
          _permissionState = _PermissionState.denied;
          _permissionError =
              'Permission GPS non accordee. Active-la pour utiliser le suivi.';
        });
        return;
      }
      setState(() => _permissionState = _PermissionState.granted);

      // Fallback one-shot : valeur initiale immediate. Si l'utilisateur
      // est en intérieur ou en mode avion, ca peut throw mais on
      // l'ignore (le stream prendra le relais).
      try {
        final pos = await LocationService.currentPosition();
        if (mounted) setState(() => _fallbackPosition = pos);
        // Lance le fetch ORS Directions des qu'on a une 1ere position.
        // Si l'API rate (quota, timeout, no internet), on garde la
        // ligne droite haversine en fallback (degradation gracieuse).
        unawaited(_fetchRoutePolyline(pos));
      } catch (_) {/* swallow, on attend le stream */}

      // Timer de timeout : si rien n'a emis apres 30 sec, on affiche
      // un message explicite au lieu du loader infini.
      _gpsTimeoutTimer = Timer(const Duration(seconds: 30), () {
        if (mounted && !_hasCenteredOnce) {
          setState(() => _gpsTimedOut = true);
        }
      });
    } on LocationPermissionDenied catch (e) {
      if (!mounted) return;
      setState(() {
        _permissionState = _PermissionState.denied;
        _permissionError = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _permissionState = _PermissionState.denied;
        _permissionError = 'Erreur GPS : $e';
      });
    }
  }

  @override
  void dispose() {
    _gpsTimeoutTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Recupere la polyline routière (qui suit les rues) entre la
  /// position courante et le stop cible. Etape 2 du plan GPS. Lance
  /// 1 fois au boot ; si l'API rate, on garde la ligne droite.
  ///
  /// Le profil ORS (voiture / camion) est lu depuis la tournee du stop
  /// pour respecter le choix de l'utilisateur. Si pas de cle ORS
  /// configuree, le provider retourne null et on retombe sur le
  /// fallback ligne droite.
  Future<void> _fetchRoutePolyline(Position pos) async {
    if (_routeFetchInFlight || _routePolyline != null) return;
    _routeFetchInFlight = true;
    try {
      final route = ref.read(routeServiceProvider);
      if (route == null) return; // pas de cle ORS -> fallback haversine

      // Lit la tournee parent pour recuperer le profil (driving-car
      // par defaut, driving-hgv pour camion lourd). Best-effort : si
      // la tournee n'existe pas, on utilise le profil par defaut.
      String profil = 'driving-car';
      bool eviterPeages = false;
      try {
        final tournee = await ref
            .read(tourneesRepositoryProvider)
            .getById(widget.stop.tourneeId);
        if (tournee != null) {
          profil = tournee.profilOrs;
          eviterPeages = tournee.eviterPeages;
        }
      } catch (_) {/* defaults OK */}

      final polyline = await route.fetchRoute(
        from: LatLng(pos.latitude, pos.longitude),
        to: LatLng(widget.stop.lat!, widget.stop.lng!),
        profil: profil,
        eviterPeages: eviterPeages,
      );
      if (!mounted) return;
      if (polyline != null && polyline.isNotEmpty) {
        setState(() => _routePolyline = polyline);
      }
    } finally {
      _routeFetchInFlight = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      backgroundColor: p.cream,
      body: switch (_permissionState) {
        _PermissionState.asking => _buildLoading(
            p,
            'Verification des permissions GPS...',
          ),
        _PermissionState.denied => _buildPermissionError(p),
        _PermissionState.granted => _buildMap(p),
      },
    );
  }

  Widget _buildLoading(AppPalette p, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: p.ink),
          const SizedBox(height: AppSpacing.x14),
          Text(message, style: TextStyle(color: p.ink, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPermissionError(AppPalette p) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x22),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Spacer(),
            Icon(Icons.location_disabled, size: 56, color: AppColors.red),
            const SizedBox(height: AppSpacing.x14),
            Text(
              'GPS indisponible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.x10),
            Text(
              _permissionError ?? 'Permission de localisation non accordee.',
              style: TextStyle(color: p.textMute, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.x22),
            FilledButton.icon(
              onPressed: () async {
                await Geolocator.openAppSettings();
                // Apres retour des Settings, retenter automatiquement.
                if (mounted) {
                  setState(() {
                    _permissionState = _PermissionState.asking;
                    _permissionError = null;
                  });
                  _bootstrap();
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Ouvrir les parametres'),
            ),
            const SizedBox(height: AppSpacing.x10),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _permissionState = _PermissionState.asking;
                  _permissionError = null;
                });
                _bootstrap();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  Widget _buildMap(AppPalette p) {
    final destination = LatLng(widget.stop.lat!, widget.stop.lng!);

    return StreamBuilder<Position>(
      stream: LocationService.positionStream(distanceFilterMeters: 10),
      builder: (context, snapshot) {
        // Position prioritaire : stream (live), sinon fallback (one-shot
        // au boot), sinon null (loader).
        final pos = snapshot.data ?? _fallbackPosition;

        if (pos == null) {
          if (_gpsTimedOut) {
            return _buildGpsTimeout(p);
          }
          return _buildLoading(p, 'Recherche du signal GPS...');
        }

        // Annule le timeout des qu'on a une 1ere position.
        _gpsTimeoutTimer?.cancel();

        final me = LatLng(pos.latitude, pos.longitude);
        final distanceM = LocationService.distanceMeters(
          fromLat: pos.latitude,
          fromLng: pos.longitude,
          toLat: widget.stop.lat!,
          toLng: widget.stop.lng!,
        );

        // Premier centrage automatique sur la position courante.
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
                PolylineLayer(
                  polylines: [
                    // Si l'API ORS a renvoye la route routière, on
                    // l'affiche en trait plein emerald (qui suit les
                    // rues). Sinon fallback ligne droite pointillee
                    // pour rester visible meme sans cle ORS.
                    if (_routePolyline != null &&
                        _routePolyline!.length >= 2)
                      Polyline(
                        points: _routePolyline!,
                        strokeWidth: 5,
                        color: AppColors.emerald,
                      )
                    else
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
            // Bandeau supérieur
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
            // FAB "J'y suis"
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
    );
  }

  Widget _buildGpsTimeout(AppPalette p) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x22),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const Spacer(),
            Icon(Icons.gps_off, size: 56, color: AppColors.amber),
            const SizedBox(height: AppSpacing.x14),
            Text(
              'Signal GPS faible',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x10),
            Text(
              'Aucune position GPS recue apres 30 sec. Verifie que :\n\n'
              '• Le GPS systeme est active (icone GPS dans la barre de notif)\n'
              '• Tu n\'es pas en intérieur sans signal\n'
              '• Le mode avion est desactive\n'
              '• La permission "Pendant l\'utilisation" est OK dans les Reglages',
              style: TextStyle(color: p.textMute, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.x22),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  _gpsTimedOut = false;
                  _hasCenteredOnce = false;
                });
                _gpsTimeoutTimer?.cancel();
                _gpsTimeoutTimer = Timer(const Duration(seconds: 30), () {
                  if (mounted && !_hasCenteredOnce) {
                    setState(() => _gpsTimedOut = true);
                  }
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reessayer'),
            ),
            const Spacer(flex: 2),
          ],
        ),
      ),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()} m restants';
    final km = (meters / 1000).toStringAsFixed(1);
    return '$km km restants';
  }
}
