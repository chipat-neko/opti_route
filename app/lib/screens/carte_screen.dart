import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../providers/tile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

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
    final stopsGeoreferenced =
        stops.where((s) => s.lat != null && s.lng != null).toList();

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
                    borderColor: AppColors.paper,
                    borderStrokeWidth: 1.5,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                _DepotMarker.build(depot, widget.tournee),
                for (var i = 0; i < stopsGeoreferenced.length; i++)
                  _StopMarker.build(
                    stop: stopsGeoreferenced[i],
                    index: i + 1,
                    onTap: () => _showStopInfo(stopsGeoreferenced[i], i + 1),
                  ),
              ],
            ),
          ],
        ),
        if (stopsGeoreferenced.isEmpty) const _EmptyOverlay(),
        Positioned(
          right: AppSpacing.x16,
          bottom: AppSpacing.x18,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'fullscreen',
                backgroundColor: AppColors.paper,
                foregroundColor: AppColors.ink,
                elevation: 4,
                onPressed: _toggleFullscreen,
                child: Icon(_fullscreen
                    ? Icons.fullscreen_exit
                    : Icons.fullscreen),
              ),
              const SizedBox(height: AppSpacing.x8),
              FloatingActionButton.small(
                heroTag: 'recentrer',
                backgroundColor: AppColors.paper,
                foregroundColor: AppColors.ink,
                elevation: 4,
                onPressed: () {
                  final fit = _currentFit;
                  if (fit != null) _mapController.fitCamera(fit);
                },
                child: const Icon(Icons.fit_screen_outlined),
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
                backgroundColor: AppColors.paper,
                foregroundColor: AppColors.ink,
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
      return [
        for (final c in decoded)
          if (c is List && c.length >= 2)
            LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()),
      ];
    } catch (_) {
      return const [];
    }
  }

  void _showStopInfo(Stop stop, int index) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.paper,
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
                    color: AppColors.inkLine,
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
                      color: AppColors.paper,
                      border: Border.all(color: AppColors.ink, width: 1.5),
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
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.3,
                            ),
                          )
                        else
                          Text(
                            stop.adresseBrute.split(',').first.trim(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.ink,
                              letterSpacing: -0.3,
                            ),
                          ),
                        const SizedBox(height: AppSpacing.x4),
                        Text(
                          stop.adresseBrute,
                          style: appMonoStyle(
                            fontSize: 12,
                            color: AppColors.textMute,
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
                    color: AppColors.creamSoft,
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                  ),
                  child: Text(
                    stop.notes!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.ink,
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
                  _InfoChip(
                    icon: Icons.inventory_2_outlined,
                    label: '${stop.nbColis} colis',
                  ),
                  if (stop.fenetreDebut != null || stop.fenetreFin != null)
                    _InfoChip(
                      icon: Icons.access_time,
                      label:
                          '${stop.fenetreDebut ?? '—'} → ${stop.fenetreFin ?? '—'}',
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

class _EmptyOverlay extends StatelessWidget {
  const _EmptyOverlay();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: AppSpacing.x16,
      right: AppSpacing.x16,
      bottom: AppSpacing.x18,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.paper,
          borderRadius: BorderRadius.circular(AppRadius.r16),
          boxShadow: AppShadows.card,
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.textMute),
            SizedBox(width: AppSpacing.x10),
            Expanded(
              child: Text(
                'Aucun arret avec coordonnees a afficher.',
                style: TextStyle(fontSize: 13, color: AppColors.ink),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DepotMarker {
  static Marker build(LatLng latLng, Tournee tournee) {
    return Marker(
      point: latLng,
      width: 48,
      height: 48,
      alignment: Alignment.center,
      child: _PinShell(
        bg: AppColors.lime,
        border: AppColors.ink,
        child: const Icon(
          Icons.warehouse_outlined,
          size: 22,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

class _StopMarker {
  static Marker build({
    required Stop stop,
    required int index,
    required VoidCallback onTap,
  }) {
    final (bg, fg, label) = _styleForStop(stop, index);
    return Marker(
      point: LatLng(stop.lat!, stop.lng!),
      width: 40,
      height: 40,
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: onTap,
        child: _PinShell(
          bg: bg,
          border: AppColors.ink,
          child: Center(
            child: label is Widget
                ? label
                : Text(
                    label as String,
                    style: appMonoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: fg,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  static (Color, Color, Object) _styleForStop(Stop stop, int index) {
    return switch (stop.statutLivraison) {
      'livre' => (
          AppColors.emerald,
          AppColors.paper,
          const Icon(Icons.check, color: AppColors.paper, size: 18),
        ),
      'echec' => (
          AppColors.red,
          AppColors.paper,
          const Text(
            '!',
            style: TextStyle(
              color: AppColors.paper,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
        ),
      _ => (AppColors.paper, AppColors.ink, '$index'),
    };
  }
}

class _PinShell extends StatelessWidget {
  const _PinShell({
    required this.bg,
    required this.border,
    required this.child,
  });

  final Color bg;
  final Color border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border, width: 1.5),
        boxShadow: AppShadows.fab,
      ),
      child: Center(child: child),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    this.mono = false,
  });

  final IconData icon;
  final String label;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x10,
        vertical: AppSpacing.x6,
      ),
      decoration: BoxDecoration(
        color: AppColors.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.ink),
          const SizedBox(width: AppSpacing.x6),
          Text(
            label,
            style: mono
                ? appMonoStyle(fontSize: 12, fontWeight: FontWeight.w700)
                : const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
          ),
        ],
      ),
    );
  }
}
