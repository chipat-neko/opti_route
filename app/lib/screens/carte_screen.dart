import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/database.dart';
import '../data/location_service.dart';
import '../providers/database_providers.dart';
import '../providers/tile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'carte/markers.dart';
import 'carte/overlays.dart';

/// Affichage carte de la tournee : pin du depart + un pin par arret
/// (avec coordonnees) + auto-fit sur l'ensemble. Tap sur un pin
/// d'arret -> bottom sheet d'info.
class CarteScreen extends ConsumerStatefulWidget {
  const CarteScreen({super.key, required this.tournee});

  final Tournee tournee;

  @override
  ConsumerState<CarteScreen> createState() => _CarteScreenState();
}

class _CarteScreenState extends ConsumerState<CarteScreen> {
  final _mapController = MapController();
  CameraFit? _currentFit;
  bool _fullscreen = false;
  // Filtres statut : par defaut tout visible. Tap sur un chip toggle.
  bool _showALivrer = true;
  bool _showLivre = true;
  bool _showEchec = true;

  @override
  void dispose() {
    // Restore les barres systeme au cas ou l'utilisateur quitte
    // l'ecran en plein ecran.
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    SystemChrome.setEnabledSystemUIMode(
      _fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
    );
  }

  /// Vrai si un stop passe les filtres statut courants. Sert a masquer
  /// dynamiquement les markers sur la carte sans toucher au repo.
  bool _passesStatusFilter(Stop s) {
    return switch (s.statutLivraison) {
      'livre' => _showLivre,
      'echec' => _showEchec,
      _ => _showALivrer,
    };
  }

  /// Demande la permission GPS si necessaire, recupere la position
  /// courante et anime la carte dessus. Snackbar en cas d'echec
  /// (permission refusee, GPS off, timeout). Pas de pin permanent
  /// "moi ici" -- juste un recentrage one-shot.
  Future<void> _centerOnMe() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final ok = await LocationService.ensurePermission();
      if (!ok || !mounted) return;
      final pos = await LocationService.currentPosition();
      if (!mounted) return;
      _mapController.move(LatLng(pos.latitude, pos.longitude), 16);
    } on LocationPermissionDenied catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Position GPS indisponible : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopsAsync = ref.watch(stopsByTourneeProvider(widget.tournee.id));

    return Scaffold(
      appBar: _fullscreen
          ? null
          : AppBar(
              title: const Text('Carte'),
            ),
      body: stopsAsync.when(
        data: _buildMap,
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
    );
  }

  Widget _buildMap(List<Stop> stops) {
    final p = context.palette;
    final stopsGeoreferenced = stops
        .where((s) => s.lat != null && s.lng != null)
        .where(_passesStatusFilter)
        .toList();

    final depot = LatLng(
      widget.tournee.pointDepartLat,
      widget.tournee.pointDepartLng,
    );

    final allPoints = <LatLng>[
      depot,
      for (final s in stopsGeoreferenced) LatLng(s.lat!, s.lng!),
    ];

    final tracePoints = _decodeTrace(widget.tournee.traceGeojson);

    _currentFit = allPoints.length > 1
        ? CameraFit.bounds(
            bounds: LatLngBounds.fromPoints(allPoints),
            padding: const EdgeInsets.all(48),
          )
        : CameraFit.coordinates(
            coordinates: allPoints,
            padding: const EdgeInsets.all(48),
            maxZoom: 14,
          );

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCameraFit: _currentFit,
            minZoom: 2,
            maxZoom: 18,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.optiroute.opti_route',
              tileProvider: ref.read(cachedTileProviderInstance),
            ),
            if (tracePoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: tracePoints,
                    strokeWidth: 5,
                    color: AppColors.emerald,
                    borderColor: p.paper,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                buildDepotMarker(depot, widget.tournee),
                for (var i = 0; i < stopsGeoreferenced.length; i++)
                  buildStopMarker(
                    stop: stopsGeoreferenced[i],
                    index: i + 1,
                    onTap: () => _showStopInfo(stopsGeoreferenced[i], i + 1),
                  ),
              ],
            ),
          ],
        ),
        if (stopsGeoreferenced.isEmpty &&
            (_showALivrer && _showLivre && _showEchec))
          const EmptyOverlay(),
        // Row de filtres statut, superposee en haut. SafeArea pour
        // eviter de passer sous le notch.
        Positioned(
          top: AppSpacing.x6,
          left: AppSpacing.x12,
          right: AppSpacing.x12,
          child: SafeArea(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  MapFilterChip(
                    label: 'A livrer',
                    color: AppColors.lime,
                    selected: _showALivrer,
                    onTap: () => setState(() => _showALivrer = !_showALivrer),
                  ),
                  const SizedBox(width: AppSpacing.x6),
                  MapFilterChip(
                    label: 'Livre',
                    color: AppColors.emerald,
                    selected: _showLivre,
                    onTap: () => setState(() => _showLivre = !_showLivre),
                  ),
                  const SizedBox(width: AppSpacing.x6),
                  MapFilterChip(
                    label: 'Echec',
                    color: AppColors.red,
                    selected: _showEchec,
                    onTap: () => setState(() => _showEchec = !_showEchec),
                  ),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: AppSpacing.x16,
          bottom: AppSpacing.x18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'fullscreen',
                backgroundColor: p.paper,
                foregroundColor: p.ink,
                elevation: 4,
                onPressed: _toggleFullscreen,
                child: Icon(_fullscreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen),
              ),
              const SizedBox(height: AppSpacing.x8),
              FloatingActionButton.small(
                heroTag: 'recentrer',
                backgroundColor: p.paper,
                foregroundColor: p.ink,
                elevation: 4,
                onPressed: () {
                  final fit = _currentFit;
                  if (fit != null) _mapController.fitCamera(fit);
                },
                child: const Icon(Icons.fit_screen_outlined),
              ),
              const SizedBox(height: AppSpacing.x8),
              FloatingActionButton.small(
                heroTag: 'me-here',
                backgroundColor: p.paper,
                foregroundColor: p.ink,
                elevation: 4,
                onPressed: _centerOnMe,
                tooltip: 'Centrer sur ma position',
                child: const Icon(Icons.my_location),
              ),
            ],
          ),
        ),
        if (_fullscreen)
          // Bouton "retour" flottant en haut a gauche puisqu'on a
          // masque l'AppBar. Utilise SafeArea pour rester sous le
          // notch / barre statut si elle revient.
          Positioned(
            top: AppSpacing.x12,
            left: AppSpacing.x12,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'back-fullscreen',
                backgroundColor: p.paper,
                foregroundColor: p.ink,
                elevation: 4,
                onPressed: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back),
              ),
            ),
          ),
      ],
    );
  }

  /// Decode la trace stockee dans `Tournee.traceGeojson` (string JSON
  /// d'une liste de [lng, lat]) en liste de LatLng utilisable par
  /// `PolylineLayer`. Retourne une liste vide si rien a tracer
  /// (tournee non encore optimisee, ou le fournisseur n'a pas renvoye
  /// de geometry).
  static List<LatLng> _decodeTrace(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <LatLng>[];
      for (final c in decoded) {
        if (c is! List || c.length < 2) continue;
        // Cast defensif : trace persistee avant le fix 2026-05-15
        // pouvait contenir des coords null dans des cas edge (ORS
        // glitch en zone marine). Skip plutot que crasher.
        final lng = (c[0] as num?)?.toDouble();
        final lat = (c[1] as num?)?.toDouble();
        if (lng == null || lat == null) continue;
        out.add(LatLng(lat, lng));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  void _showStopInfo(Stop stop, int index) {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.paper,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.r28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x22,
            AppSpacing.x18,
            AppSpacing.x22,
            AppSpacing.x22,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: p.inkLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: p.paper,
                      border: Border.all(color: p.ink, width: 1.5),
                      borderRadius: BorderRadius.circular(AppRadius.r10),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$index',
                      style: appMonoStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (stop.nomClient != null &&
                            stop.nomClient!.isNotEmpty)
                          Text(
                            stop.nomClient!,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.ink,
                              letterSpacing: -0.3,
                            ),
                          )
                        else
                          Text(
                            stop.adresseBrute.split(',').first.trim(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: p.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.x4),
                        Text(
                          stop.adresseBrute,
                          style: appMonoStyle(
                            fontSize: 12,
                            color: p.textMute,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (stop.notes != null && stop.notes!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.x14),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.x12),
                  decoration: BoxDecoration(
                    color: p.creamSoft,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Text(
                    stop.notes!,
                    style: TextStyle(
                      fontSize: 13,
                      color: p.ink,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.x18),
              Wrap(
                spacing: AppSpacing.x8,
                runSpacing: AppSpacing.x8,
                children: [
                  InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${stop.nbColis} colis',
                  ),
                  if (stop.fenetreDebut != null || stop.fenetreFin != null)
                    InfoChip(
                      icon: Icons.access_time,
                      label:
                          '${stop.fenetreDebut ?? ' - '} -> ${stop.fenetreFin ?? ' - '}',
                      mono: true,
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
