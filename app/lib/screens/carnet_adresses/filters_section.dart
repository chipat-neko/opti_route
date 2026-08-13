import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/saved_destinations_repository.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/voice_input_button.dart';
import 'carnet_filters.dart';
import 'filter_chips.dart';
import 'providers.dart';

/// ════════════════════════════════════════════════════════════════
/// En-tete de filtrage du carnet : recherche + rangees de chips.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `carnet_adresses_screen.dart` (refactor F27) : ces ~200
/// lignes vivaient inline dans le `Column` du body et masquaient la
/// structure de l'ecran.
///
/// Empile, de haut en bas :
///   1. le champ de recherche (avec bouton de dictee vocale) ;
///   2. les chips couleur / favoris ([_ColorFilterRow]) ;
///   3. les chips periode d'ajout + regularite
///      ([_PeriodeRegulariteRow], carte #105) ;
///   4. le badge "X filtres actifs" + reset ([_ActiveFiltersBadge]),
///      visible seulement si au moins un filtre est pose ;
///   5. les chips de tags libres ([_TagFilterRow]), cachees si le
///      carnet n'a aucun tag.
///
/// L'etat ([CarnetFilters] + le controller de recherche) reste chez
/// l'ecran parent : cette section ne fait que l'afficher et remonter
/// les changements.
class CarnetFiltersSection extends StatelessWidget {
  const CarnetFiltersSection({
    super.key,
    required this.searchController,
    required this.onQueryChanged,
    required this.onVoiceResult,
    required this.filters,
    required this.onFiltersChanged,
  });

  final TextEditingController searchController;

  /// Texte brut du champ de recherche (non normalise).
  final ValueChanged<String> onQueryChanged;

  /// Texte reconnu par la dictee vocale.
  final ValueChanged<String> onVoiceResult;

  final CarnetFilters filters;
  final ValueChanged<CarnetFilters> onFiltersChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SearchField(
          controller: searchController,
          onChanged: onQueryChanged,
          onVoiceResult: onVoiceResult,
        ),
        _ColorFilterRow(
          selected: filters.colorTag,
          onSelected: (v) => onFiltersChanged(filters.withColorTag(v)),
        ),
        _PeriodeRegulariteRow(
          periode: filters.periode,
          onPeriode: (v) => onFiltersChanged(filters.withPeriode(v)),
          regularite: filters.regularite,
          onRegularite: (v) => onFiltersChanged(filters.withRegularite(v)),
        ),
        // Badge "X filtres actifs" + bouton reset, visible uniquement
        // si au moins 1 filtre est en place. Carte Trello #105.
        if (filters.activeCount > 0)
          _ActiveFiltersBadge(
            count: filters.activeCount,
            onReset: () => onFiltersChanged(CarnetFilters.none),
          ),
        _TagFilterRow(
          selected: filters.tag,
          onSelected: (v) => onFiltersChanged(filters.withTag(v)),
        ),
      ],
    );
  }
}

/// Champ de recherche client / adresse. Le bouton micro mains-libres
/// dicte la recherche au volant (aligne sur le pattern Spoke route
/// planner) : il ne pousse pas le texte lui-meme, il remonte le
/// resultat a l'ecran qui pilote le controller.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onVoiceResult,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onVoiceResult;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x18,
        AppSpacing.x14,
        AppSpacing.x18,
        AppSpacing.x4,
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.search),
          hintText: 'Rechercher un client / une adresse',
          suffixIcon: VoiceInputButton(
            tooltip: 'Dicter la recherche',
            onResult: onVoiceResult,
          ),
        ),
        onChanged: onChanged,
      ),
    );
  }
}

/// Chips de filtre par couleur / favoris : un mini scroll horizontal
/// pour ne pas pousser la liste vers le bas.
class _ColorFilterRow extends StatelessWidget {
  const _ColorFilterRow({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x18,
        ),
        scrollDirection: Axis.horizontal,
        children: [
          ColorFilterChip(
            label: 'Tous',
            selected: selected == null,
            onSelected: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          ColorFilterChip(
            label: 'Favoris',
            selected: selected == 'favoris',
            color: AppColors.amber,
            onSelected: () => onSelected('favoris'),
          ),
          const SizedBox(width: 8),
          for (final (tag, color) in colorTagOptions) ...[
            ColorFilterChip(
              label: tag,
              selected: selected == tag,
              color: color,
              onSelected: () => onSelected(tag),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Periode d'ajout + regularite (carte Trello #105). Compacte : 1
/// SizedBox 36, 5 chips max (Tous / 30j / 6 mois / 1 an / reguliers /
/// uniques). Les 2 chips de regularite se deselectionnent au 2e tap,
/// pas celles de periode (qui ont leur propre chip "toutes").
class _PeriodeRegulariteRow extends StatelessWidget {
  const _PeriodeRegulariteRow({
    required this.periode,
    required this.onPeriode,
    required this.regularite,
    required this.onRegularite,
  });

  final String? periode;
  final ValueChanged<String?> onPeriode;
  final String? regularite;
  final ValueChanged<String?> onRegularite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x18,
        ),
        scrollDirection: Axis.horizontal,
        children: [
          TagFilterChip(
            label: 'periode: toutes',
            selected: periode == null,
            onSelected: () => onPeriode(null),
          ),
          const SizedBox(width: 8),
          TagFilterChip(
            label: '30 jours',
            selected: periode == '30d',
            onSelected: () => onPeriode('30d'),
          ),
          const SizedBox(width: 8),
          TagFilterChip(
            label: '6 mois',
            selected: periode == '6m',
            onSelected: () => onPeriode('6m'),
          ),
          const SizedBox(width: 8),
          TagFilterChip(
            label: '1 an',
            selected: periode == '1y',
            onSelected: () => onPeriode('1y'),
          ),
          const SizedBox(width: 16),
          TagFilterChip(
            label: 'clients reguliers (>=5)',
            selected: regularite == 'reguliers',
            onSelected: () => onRegularite(
                regularite == 'reguliers' ? null : 'reguliers'),
          ),
          const SizedBox(width: 8),
          TagFilterChip(
            label: 'jamais reutilises',
            selected: regularite == 'uniques',
            onSelected: () =>
                onRegularite(regularite == 'uniques' ? null : 'uniques'),
          ),
        ],
      ),
    );
  }
}

/// Ligne "N filtres actifs" + bouton "Reinitialiser". Carte Trello
/// #105.
class _ActiveFiltersBadge extends StatelessWidget {
  const _ActiveFiltersBadge({required this.count, required this.onReset});

  final int count;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x18,
        AppSpacing.x4,
        AppSpacing.x18,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_alt,
            size: 14,
            color: context.palette.textMute,
          ),
          const SizedBox(width: 4),
          Text(
            '$count filtre${count > 1 ? "s" : ""} actif${count > 1 ? "s" : ""}',
            style: TextStyle(
              fontSize: 11,
              color: context.palette.textMute,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh, size: 14),
            label: const Text(
              'Reinitialiser',
              style: TextStyle(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x8,
              ),
              minimumSize: const Size(0, 28),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chips de tags libres : uniquement ceux presents dans le carnet.
/// Cachee si aucun tag. Watch elle-meme le carnet (la liste des tags
/// se derive du contenu, elle n'a pas a remonter jusqu'a l'ecran).
class _TagFilterRow extends ConsumerWidget {
  const _TagFilterRow({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEntries =
        ref.watch(carnetStreamProvider).asData?.value ?? const [];
    final allTags = <String>{};
    for (final e in allEntries) {
      allTags.addAll(
        SavedDestinationsRepository.parseTags(e.tagsJson),
      );
    }
    if (allTags.isEmpty) return const SizedBox.shrink();
    final sorted = allTags.toList()..sort();
    return SizedBox(
      height: 36,
      child: ListView(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x18,
        ),
        scrollDirection: Axis.horizontal,
        children: [
          TagFilterChip(
            label: 'tag: tous',
            selected: selected == null,
            onSelected: () => onSelected(null),
          ),
          const SizedBox(width: 8),
          for (final t in sorted) ...[
            TagFilterChip(
              label: t,
              selected: selected == t,
              onSelected: () => onSelected(t),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
