import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Position;

import '../../data/database.dart';
import '../../data/location_service.dart';
import '../../providers/database_providers.dart';
import '../../providers/location_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'stops_list.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Liste des arrets" : chips de filtre + champ recherche +
/// liste reorderable.
/// ════════════════════════════════════════════════════════════════
///
/// Pile complete affichee sous les bandeaux ProgressBanner et
/// ProchainArretCard dans l'ecran tournee du jour :
///
/// 1. Chips de **filtre par statut** ("Tout / A livrer / Livres /
///    Echecs") avec compteur. Visible des qu'au moins un arret est
///    livre ou en echec (sinon pas de sens).
/// 2. Toggle **"Par distance"** : remplace l'ordre optimise par la
///    proximite GPS a ma position actuelle. Utile quand on devie de
///    l'itineraire ou pour decider du prochain arret le plus proche.
/// 3. Row de **filtres coequipier** ("Tous / Moi / Lucas / ...") :
///    visible uniquement si au moins un stop est affecte (mode equipe).
/// 4. Champ **recherche** (>= 5 stops sinon cache) : filtre par nom
///    client / adresse / notes avec normalisation des accents.
/// 5. La [StopsList] avec les stops filtres. Le drag-and-drop est
///    desactive si un filtre est actif (l'ordre n'a pas de sens sur
///    un sous-ensemble).
class StopsSection extends ConsumerStatefulWidget {
  const StopsSection({super.key, required this.stops});

  final List<Stop> stops;

  @override
  ConsumerState<StopsSection> createState() => _StopsSectionState();
}

class _StopsSectionState extends ConsumerState<StopsSection> {
  String _query = '';

  /// Filtre par statut applique en plus de la recherche texte :
  /// 'tout' / 'a_livrer' / 'livre' / 'echec'.
  String _statutFilter = 'tout';

  /// Mode "tri par distance GPS" : remplace l'ordre optimise par
  /// la proximite a ma position actuelle. Utile quand je devie de
  /// l'itineraire ou pour decider du prochain arret le plus proche.
  bool _sortByDistance = false;

  /// Filtre coequipier : null = tous, 0 = Moi (coequipierId null),
  /// >0 = id d'un coequipier specifique. Visible uniquement si au
  /// moins un stop a un `coequipierId != null` (mode equipe actif).
  int? _coequipierFilter;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasQuery = _query.trim().isNotEmpty;
    final hasStatutFilter = _statutFilter != 'tout';
    final hasCoFilter = _coequipierFilter != null;
    var filtered = widget.stops;
    if (hasStatutFilter) {
      filtered = filtered
          .where((s) => s.statutLivraison == _statutFilter)
          .toList();
    }
    if (hasCoFilter) {
      // 0 = Moi (coequipierId null), >0 = id specifique
      filtered = filtered.where((s) {
        if (_coequipierFilter == 0) return s.coequipierId == null;
        return s.coequipierId == _coequipierFilter;
      }).toList();
    }
    if (hasQuery) {
      filtered = _filter(filtered, _query);
    }
    if (_sortByDistance) {
      final pos = ref.watch(currentPositionProvider).asData?.value;
      if (pos != null) {
        filtered = List.of(filtered)
          ..sort((a, b) {
            final da = _distanceFromPos(pos, a);
            final db = _distanceFromPos(pos, b);
            return da.compareTo(db);
          });
      }
    }
    final isFiltered =
        hasQuery || hasStatutFilter || hasCoFilter || _sortByDistance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Chips de filtre par statut : visible des qu'au moins un
        // arret est livre ou en echec (sinon Tout = tous, ca sert
        // a rien).
        if (widget.stops.any((s) =>
            s.statutLivraison == 'livre' || s.statutLivraison == 'echec')) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _StatutFilterChip(
                  label: 'Tout',
                  value: 'tout',
                  groupValue: _statutFilter,
                  count: widget.stops.length,
                  onSelected: (v) => setState(() => _statutFilter = v),
                ),
                const SizedBox(width: AppSpacing.x6),
                _StatutFilterChip(
                  label: 'A livrer',
                  value: 'a_livrer',
                  groupValue: _statutFilter,
                  count: widget.stops
                      .where((s) => s.statutLivraison == 'a_livrer')
                      .length,
                  onSelected: (v) => setState(() => _statutFilter = v),
                ),
                const SizedBox(width: AppSpacing.x6),
                _StatutFilterChip(
                  label: 'Livres',
                  value: 'livre',
                  groupValue: _statutFilter,
                  count: widget.stops
                      .where((s) => s.statutLivraison == 'livre')
                      .length,
                  onSelected: (v) => setState(() => _statutFilter = v),
                ),
                const SizedBox(width: AppSpacing.x6),
                _StatutFilterChip(
                  label: 'Echecs',
                  value: 'echec',
                  groupValue: _statutFilter,
                  count: widget.stops
                      .where((s) => s.statutLivraison == 'echec')
                      .length,
                  onSelected: (v) => setState(() => _statutFilter = v),
                ),
                const SizedBox(width: AppSpacing.x12),
                // Toggle "tri par distance GPS" : remplace l'ordre
                // optimise par la proximite GPS. Utile en cours de
                // tournee quand on devie de l'itineraire.
                FilterChip(
                  label: const Text('Par distance'),
                  selected: _sortByDistance,
                  onSelected: (v) => setState(() => _sortByDistance = v),
                  avatar: Icon(
                    Icons.my_location,
                    size: 14,
                    color: _sortByDistance ? p.ink : p.textMute,
                  ),
                  selectedColor: AppColors.lime,
                  backgroundColor: p.paper,
                  side: BorderSide(
                    color: _sortByDistance ? AppColors.lime : p.inkLine,
                  ),
                  labelStyle: TextStyle(
                    color: p.ink,
                    fontWeight:
                        _sortByDistance ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
        ],
        // Row de filtres coequipier : visible UNIQUEMENT si au moins
        // un stop est affecte a un coequipier (mode equipe actif sur
        // cette tournee). On expose "Moi" + un chip par coequipier
        // present dans la tournee.
        if (widget.stops.any((s) => s.coequipierId != null)) ...[
          Consumer(
            builder: (context, ref, _) {
              final byId = ref.watch(coequipiersByIdProvider);
              // Set des ids presents dans cette tournee (sans null).
              final usedIds = <int>{};
              var hasMoi = false;
              for (final s in widget.stops) {
                if (s.coequipierId == null) {
                  hasMoi = true;
                } else {
                  usedIds.add(s.coequipierId!);
                }
              }
              return SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _CoFilterChip(
                      label: 'Tous',
                      selected: _coequipierFilter == null,
                      color: p.ink,
                      onSelected: () =>
                          setState(() => _coequipierFilter = null),
                    ),
                    const SizedBox(width: AppSpacing.x6),
                    if (hasMoi)
                      _CoFilterChip(
                        label: 'Moi',
                        selected: _coequipierFilter == 0,
                        color: AppColors.lime,
                        onSelected: () =>
                            setState(() => _coequipierFilter = 0),
                      ),
                    if (hasMoi) const SizedBox(width: AppSpacing.x6),
                    for (final id in usedIds) ...[
                      _CoFilterChip(
                        label: byId[id]?.nom ?? '#$id',
                        selected: _coequipierFilter == id,
                        color: byId[id] == null
                            ? p.inkLine
                            : colorFromTag(
                                byId[id]!.colorTag,
                                defaultColor: AppColors.creamSoft,
                              ),
                        onSelected: () =>
                            setState(() => _coequipierFilter = id),
                      ),
                      const SizedBox(width: AppSpacing.x6),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.x10),
        ],
        // N'afficher le champ de recherche que si la liste est assez
        // longue pour en valoir la peine.
        if (widget.stops.length >= 5) ...[
          TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search, size: 20),
              hintText: 'Filtrer par nom, rue, notes...',
              isDense: true,
              suffixIcon: hasQuery
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () => setState(() => _query = ''),
                    )
                  : null,
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          if (isFiltered) ...[
            const SizedBox(height: AppSpacing.x6),
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
              child: Text(
                filtered.isEmpty
                    ? 'Aucun arret ne correspond'
                    : '${filtered.length} / ${widget.stops.length} arret(s)',
                style: appMonoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.textMute,
                ),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.x10),
        ],
        if (filtered.isEmpty && isFiltered)
          Container(
            padding: const EdgeInsets.all(AppSpacing.x22),
            decoration: BoxDecoration(
              color: p.paper,
              borderRadius: BorderRadius.circular(AppRadius.r18),
              border: Border.all(color: p.divider),
            ),
            child: Text(
              'Aucun arret ne correspond.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textMute),
            ),
          )
        else
          StopsList(stops: filtered, reorderable: !isFiltered),
      ],
    );
  }

  /// Distance vol d'oiseau entre la position GPS et l'arret (Geolocator
  /// haversine). Stops sans coords -> infini (relegues a la fin).
  static double _distanceFromPos(Position pos, Stop s) {
    if (s.lat == null || s.lng == null) return double.infinity;
    return LocationService.distanceMeters(
      fromLat: pos.latitude,
      fromLng: pos.longitude,
      toLat: s.lat!,
      toLng: s.lng!,
    );
  }

  static List<Stop> _filter(List<Stop> stops, String query) {
    final norm = _normalize(query.trim());
    if (norm.isEmpty) return stops;
    return stops.where((s) {
      final hay = _normalize([
        s.nomClient ?? '',
        s.adresseBrute,
        s.adresseNormalisee ?? '',
        s.notes ?? '',
      ].join(' '));
      return hay.contains(norm);
    }).toList();
  }

  static String _normalize(String s) {
    final lower = s.toLowerCase();
    const map = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
      'ç': 'c',
      'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i', 'ì': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ÿ': 'y', 'ý': 'y',
      'ñ': 'n',
      'Å“': 'oe', 'æ': 'ae',
    };
    final buf = StringBuffer();
    for (final ch in lower.split('')) {
      buf.write(map[ch] ?? ch);
    }
    return buf.toString();
  }
}

/// Chip de filtre par statut au-dessus de la liste des arrets.
/// Affiche le compteur a cote du label : "A livrer (12)".
class _StatutFilterChip extends StatelessWidget {
  const _StatutFilterChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.count,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String groupValue;
  final int count;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = value == groupValue;
    return ChoiceChip(
      label: Text('$label ($count)'),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.lime,
      backgroundColor: p.paper,
      side: BorderSide(
        color: selected ? AppColors.lime : p.inkLine,
      ),
      labelStyle: TextStyle(
        color: p.ink,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Chip de filtre coequipier dans la StopsSection. Le fond utilise
/// la couleur d'avatar du coequipier quand selectionne, pour donner
/// un repere visuel immediat.
class _CoFilterChip extends StatelessWidget {
  const _CoFilterChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r22),
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: selected ? color : p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r22),
          border: Border.all(
            color: selected ? Colors.transparent : p.inkLine,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected ? AppColors.ink : p.ink,
          ),
        ),
      ),
    );
  }
}
