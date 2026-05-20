import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/address_suggestion.dart';
import '../data/overpass_poi_service.dart';
import '../providers/poi_providers.dart';
import '../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Recherche de commerces / POI a proximite d'un point GPS.
/// ════════════════════════════════════════════════════════════════
///
/// Inspire de Spoke route planner : Noah cherche "pharmacie" /
/// "supermarche" autour de son depot OU autour du dernier stop.
/// On affiche des chips categories + une liste triee par distance,
/// avec un tap qui retourne le POI selectionne au caller.
///
/// Usage typique : push avec `Navigator.push<AddressSuggestion?>`.
/// La valeur retournee est l'AddressSuggestion choisie (ou null si
/// l'utilisateur annule).
class NearbyPoiScreen extends ConsumerStatefulWidget {
  const NearbyPoiScreen({
    super.key,
    required this.centerLat,
    required this.centerLng,
    this.centerLabel,
  });

  /// Coords du centre de recherche (en general : depot OU dernier
  /// stop de la tournee).
  final double centerLat;
  final double centerLng;

  /// Label affiche en haut ('Depot' / 'Dernier arret' / etc.).
  final String? centerLabel;

  @override
  ConsumerState<NearbyPoiScreen> createState() => _NearbyPoiScreenState();
}

class _NearbyPoiScreenState extends ConsumerState<NearbyPoiScreen> {
  String? _selectedCategory;
  Future<List<AddressSuggestion>>? _search;
  int _radius = 1500;

  static const _radiusOptions = [500, 1000, 1500, 3000, 5000];

  void _selectCategory(String key) {
    setState(() {
      _selectedCategory = key;
      final svc = ref.read(overpassPoiServiceProvider);
      _search = svc.searchNearby(
        categoryKey: key,
        centerLat: widget.centerLat,
        centerLng: widget.centerLng,
        radiusMeters: _radius,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Commerces a proximite'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x18,
                AppSpacing.x12,
                AppSpacing.x18,
                AppSpacing.x6,
              ),
              child: Row(
                children: [
                  Icon(Icons.my_location, size: 16, color: p.textMute),
                  const SizedBox(width: AppSpacing.x6),
                  Expanded(
                    child: Text(
                      'Centre : ${widget.centerLabel ?? "position actuelle"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textMute,
                      ),
                    ),
                  ),
                  _RadiusDropdown(
                    value: _radius,
                    options: _radiusOptions,
                    onChanged: (v) {
                      setState(() => _radius = v);
                      if (_selectedCategory != null) {
                        _selectCategory(_selectedCategory!);
                      }
                    },
                  ),
                ],
              ),
            ),
            // Chips categories scrollables horizontalement
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x14,
                ),
                children: [
                  for (final entry in OverpassPoiService.categories.entries)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x4,
                        vertical: AppSpacing.x10,
                      ),
                      child: _CategoryChip(
                        label: entry.value.label,
                        iconName: entry.value.iconName,
                        selected: _selectedCategory == entry.key,
                        onTap: () => _selectCategory(entry.key),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _search == null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.x22),
                        child: Text(
                          'Choisis une categorie pour voir les commerces '
                          'autour de toi (rayon $_radius m).',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: p.textMute,
                            height: 1.4,
                          ),
                        ),
                      ),
                    )
                  : FutureBuilder<List<AddressSuggestion>>(
                      future: _search,
                      builder: (_, snapshot) {
                        if (snapshot.connectionState !=
                            ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.x22),
                              child: Text(
                                'Erreur Overpass : ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: AppColors.red,
                                ),
                              ),
                            ),
                          );
                        }
                        final results = snapshot.data ?? const [];
                        if (results.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.x22),
                              child: Text(
                                'Aucun commerce trouve dans un rayon de '
                                '$_radius m. Augmente le rayon ou change '
                                'de categorie.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: p.textMute,
                                ),
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final s = results[i];
                            return _PoiTile(
                              suggestion: s,
                              onTap: () =>
                                  Navigator.of(context).pop(s),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.iconName,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String iconName;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_iconFromName(iconName), size: 16),
          const SizedBox(width: AppSpacing.x6),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.lime,
      backgroundColor: p.paper,
      labelStyle: TextStyle(
        color: p.ink,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'local_pharmacy':
        return Icons.local_pharmacy;
      case 'bakery_dining':
        return Icons.bakery_dining;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'restaurant':
        return Icons.restaurant;
      case 'local_cafe':
        return Icons.local_cafe;
      case 'local_gas_station':
        return Icons.local_gas_station;
      case 'atm':
        return Icons.atm;
      case 'local_post_office':
        return Icons.local_post_office;
      case 'local_parking':
        return Icons.local_parking;
      case 'wc':
        return Icons.wc;
      default:
        return Icons.place;
    }
  }
}

class _PoiTile extends StatelessWidget {
  const _PoiTile({required this.suggestion, required this.onTap});

  final AddressSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = suggestion.poiName ?? suggestion.displayName;
    final addr = suggestion.adressePostale;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: p.creamSoft,
        foregroundColor: p.ink,
        child: const Icon(Icons.store_outlined, size: 18),
      ),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: addr.isEmpty
          ? null
          : Text(
              addr,
              style: TextStyle(fontSize: 12, color: p.textMute),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: const Icon(Icons.add_circle_outline),
      onTap: onTap,
    );
  }
}

class _RadiusDropdown extends StatelessWidget {
  const _RadiusDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final int value;
  final List<int> options;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<int>(
      value: value,
      isDense: true,
      underline: const SizedBox.shrink(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      items: [
        for (final r in options)
          DropdownMenuItem(
            value: r,
            child: Text(r < 1000 ? '$r m' : '${r ~/ 1000} km'),
          ),
      ],
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
