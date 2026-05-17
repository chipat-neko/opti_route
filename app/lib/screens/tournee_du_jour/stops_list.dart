import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';
import 'stop_row.dart';

/// ════════════════════════════════════════════════════════════════
/// Placeholder affiche quand la tournee n'a aucun arret.
/// ════════════════════════════════════════════════════════════════
///
/// Card cream avec une icone "add_road" + message d'invitation a
/// taper sur le FAB "Ajouter un arret". Sert d'empty state amical
/// quand on cree une tournee vide ou qu'on supprime tous ses stops.
class StopsPlaceholder extends StatelessWidget {
  const StopsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x22),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: p.creamSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_road_outlined,
              color: p.ink,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Text(
            'Pas encore d\'arrets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Tape sur "Ajouter un arret" pour commencer a remplir ta tournee.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: p.textMute,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// ════════════════════════════════════════════════════════════════
/// Liste reorderable des arrets de la tournee.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche les stops dans des [StopRow], avec deux modes selon le
/// flag `reorderable` :
///
///   - **reorderable = true** (mode normal) : `ReorderableListView` ;
///     l'utilisateur peut drag-and-drop chaque ligne pour reordonner
///     manuellement. Le nouvel ordre est persiste via
///     `StopsRepository.applyOptimizedOrder`.
///
///   - **reorderable = false** (mode recherche/filtre) : simple
///     `ListView` ; la poignee drag est masquee (l'ordre n'a pas
///     de sens sur une liste filtree).
///
/// Le widget garde une copie locale `_local` des stops pendant le
/// drag (pour eviter les conflits avec le stream Drift qui pourrait
/// emettre pendant l'interaction). On resync uniquement quand
/// `_dragging == false`.
class StopsList extends ConsumerStatefulWidget {
  const StopsList({
    super.key,
    required this.stops,
    this.reorderable = true,
  });

  final List<Stop> stops;

  /// Quand `false` (typiquement pendant une recherche), le drag-and-drop
  /// est desactive : la poignee `drag_handle` est masquee et la liste
  /// utilise un simple `ListView` au lieu de `ReorderableListView`.
  /// L'ordre n'a pas de sens sur une liste filtree.
  final bool reorderable;

  @override
  ConsumerState<StopsList> createState() => _StopsListState();
}

class _StopsListState extends ConsumerState<StopsList> {
  /// Copie locale des stops, manipulee pendant le drag-and-drop. Quand
  /// le stream Drift emet une nouvelle liste, on resync (sauf si on est
  /// en plein milieu d'un drag, auquel cas on attend la fin).
  late List<Stop> _local;
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _local = List.of(widget.stops);
  }

  @override
  void didUpdateWidget(StopsList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragging) {
      _local = List.of(widget.stops);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (!widget.reorderable) {
      // Mode lecture seule (typiquement pendant une recherche). La liste
      // est un simple ListView ; chaque StopRow recoit `showDragHandle:
      // false` pour cacher la poignee qui n'a pas de sens ici.
      return Container(
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r18),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            for (var i = 0; i < widget.stops.length; i++)
              StopRow(
                key: ValueKey('stop-${widget.stops[i].id}'),
                stop: widget.stops[i],
                index: i + 1,
                dragIndex: i,
                showDragHandle: false,
                onDelete: () => _confirmDelete(context, ref, widget.stops[i]),
              ),
          ],
        ),
      );
    }
    // Mode normal : drag-and-drop active. `buildDefaultDragHandles:
    // false` car on positionne nous-meme le `ReorderableDragStartListener`
    // sur la poignee `drag_handle` dans `StopRow` (pour eviter que le
    // tap sur la card declenche un drag).
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      clipBehavior: Clip.antiAlias,
      child: ReorderableListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        buildDefaultDragHandles: false,
        itemCount: _local.length,
        onReorderStart: (_) => _dragging = true,
        onReorder: _onReorder,
        itemBuilder: (context, i) {
          final stop = _local[i];
          return StopRow(
            key: ValueKey('stop-${stop.id}'),
            stop: stop,
            index: i + 1,
            dragIndex: i,
            onDelete: () => _confirmDelete(context, ref, stop),
          );
        },
      ),
    );
  }

  /// Callback du `ReorderableListView` : l'utilisateur a relache le
  /// drag entre [oldIndex] et [newIndex]. On met a jour `_local` et
  /// on persiste le nouvel ordre en base via `applyOptimizedOrder`.
  ///
  /// `newIndex > oldIndex - 1` : ajustement classique du
  /// `ReorderableListView` qui passe `newIndex` apres l'item ote.
  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    setState(() {
      final item = _local.removeAt(oldIndex);
      _local.insert(adjusted, item);
    });
    // Persister le nouvel ordre. La liste des stops du stream va etre
    // rafraichie automatiquement avec ces nouveaux ordreOptimise.
    await ref
        .read(stopsRepositoryProvider)
        .applyOptimizedOrder(_local.map((s) => s.id).toList());
    _dragging = false;
  }

  /// Affiche un dialog de confirmation et supprime le stop si OK.
  /// Apres suppression : invalide l'optimisation VROOM (qui ne
  /// correspond plus a la nouvelle liste) et re-calcule l'ordre
  /// nearest-neighbor local pour les stops restants.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Stop stop,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet arret ?'),
        content: Text(
          stop.nomClient != null && stop.nomClient!.isNotEmpty
              ? '${stop.nomClient} - ${stop.adresseBrute}'
              : stop.adresseBrute,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      // Jalon 2.F : propagation cloud (best-effort) + local
      await ref
          .read(cloudSyncServiceProvider)
          .deleteStopWithCloudCleanup(stop.id);
      await ref
          .read(tourneesRepositoryProvider)
          .invalidateOptimization(stop.tourneeId);
      // Auto-reorder local apres suppression d'un stop.
      await ref
          .read(localReorderServiceProvider)
          .reorder(stop.tourneeId);
    }
  }
}
