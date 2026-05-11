import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/address_suggestion.dart';
import '../data/geocoding_service.dart';
import '../providers/geocoding_providers.dart';
import '../providers/tile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ecran de geocodage manuel : Noah tape sur la carte pour poser un
/// pin, l'app fait un reverse geocode (BAN) pour retrouver l'adresse
/// la plus proche, et retourne une [AddressSuggestion] au caller.
///
/// Utile quand l'autocomplete d'adresse n'a rien trouve (commerce non
/// repertorie, lieu sans adresse postale precise, hangar industriel).
class PointerCarteScreen extends ConsumerStatefulWidget {
  const PointerCarteScreen({
    super.key,
    this.initialCenter,
  });

  /// Centre initial de la carte. Si null, on centre sur la France
  /// metropolitaine.
  final LatLng? initialCenter;

  @override
  ConsumerState<PointerCarteScreen> createState() =>
      _PointerCarteScreenState();
}

class _PointerCarteScreenState extends ConsumerState<PointerCarteScreen> {
  LatLng? _picked;
  AddressSuggestion? _resolved;
  bool _resolving = false;
  String? _error;

  static final _franceCenter = LatLng(46.5, 2.5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pointer sur la carte'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: widget.initialCenter ?? _franceCenter,
              initialZoom: widget.initialCenter != null ? 15 : 6,
              minZoom: 5,
              maxZoom: 19,
              onTap: (_, latlng) => _onMapTap(latlng),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.optiroute.opti_route',
                tileProvider: ref.read(cachedTileProviderInstance),
              ),
              if (_picked != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _picked!,
                      width: 36,
                      height: 36,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        color: AppColors.red,
                        size: 36,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            top: AppSpacing.x12,
            left: AppSpacing.x12,
            right: AppSpacing.x12,
            child: Material(
              color: AppColors.cream,
              borderRadius: BorderRadius.circular(AppRadius.r12),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x12),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_outlined,
                        color: AppColors.ink, size: 18),
                    const SizedBox(width: AppSpacing.x8),
                    Expanded(
                      child: Text(
                        _picked == null
                            ? 'Tape sur la carte pour poser un pin a l\'emplacement de la livraison.'
                            : 'Pin pose. Tu peux retaper pour ajuster.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.ink,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_picked != null)
            Positioned(
              bottom: AppSpacing.x12,
              left: AppSpacing.x12,
              right: AppSpacing.x12,
              child: Material(
                color: AppColors.paper,
                borderRadius: BorderRadius.circular(AppRadius.r14),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.x14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_resolving)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              ),
                              SizedBox(width: AppSpacing.x10),
                              Text(
                                'Recherche d\'adresse...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (_error != null)
                        Text(
                          _error!,
                          style: const TextStyle(
                            color: AppColors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else if (_resolved != null) ...[
                        Text(
                          _resolved!.primaryLabel,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        if (_resolved!.secondaryLabel.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _resolved!.secondaryLabel,
                              style: appMonoStyle(
                                fontSize: 11,
                                color: AppColors.textMute,
                              ),
                            ),
                          ),
                      ],
                      const SizedBox(height: AppSpacing.x10),
                      FilledButton.icon(
                        onPressed: _resolved == null
                            ? null
                            : () => Navigator.of(context).pop(_resolved),
                        icon: const Icon(Icons.check),
                        label: const Text('Utiliser cette position'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: AppColors.paper,
                          minimumSize: const Size(0, 48),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _onMapTap(LatLng latlng) async {
    setState(() {
      _picked = latlng;
      _resolved = null;
      _resolving = true;
      _error = null;
    });
    try {
      final ban = ref.read(banGeocodingServiceProvider);
      final reverse = await ban.reverseGeocode(
        lat: latlng.latitude,
        lng: latlng.longitude,
      );
      if (!mounted) return;
      setState(() {
        _resolving = false;
        if (reverse == null) {
          // BAN n'a rien trouve : on cree quand meme une AddressSuggestion
          // avec juste les coords (l'utilisateur peut renommer plus tard).
          _resolved = AddressSuggestion(
            displayName:
                'Position ${latlng.latitude.toStringAsFixed(5)}, '
                '${latlng.longitude.toStringAsFixed(5)}',
            lat: latlng.latitude,
            lon: latlng.longitude,
          );
        } else {
          _resolved = reverse;
        }
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        _error = 'Erreur reverse-geocoding : ${e.message}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resolving = false;
        // Fallback : on garde la position avec un label generique.
        _resolved = AddressSuggestion(
          displayName:
              'Position ${latlng.latitude.toStringAsFixed(5)}, '
              '${latlng.longitude.toStringAsFixed(5)}',
          lat: latlng.latitude,
          lon: latlng.longitude,
        );
      });
    }
  }
}
