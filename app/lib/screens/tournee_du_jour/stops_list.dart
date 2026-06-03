import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/lock_ordering.dart';
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';
import 'stop_row.dart';

/// Vrai si l'arrêt a un statut définitif (livré ou échec) — il n'est plus
/// "à faire". Sert à parquer ces arrêts en bas de liste (carte #A Noah
/// 2026-06-03) pour garder le prochain arrêt visible en haut sans scroll.
bool isStopDone(Stop s) =>
    s.statutLivraison == 'livre' || s.statutLivraison == 'echec';

/// Reconstruit l'ordre COMPLET des ids après un drag dans la liste
/// affichée. [displayIds] = ids visibles (restants, + terminés si dépliés) ;
/// [hiddenDoneIds] = terminés masqués à re-append à la fin (pour persister
/// tous les ids — applyOptimizedOrder l'exige). Applique l'ajustement
/// d'index du ReorderableListView (newIndex après retrait de l'item).
/// Fonction PURE -> testable.
List<int> rebuildOrderAfterReorder({
  required List<int> displayIds,
  required List<int> hiddenDoneIds,
  required int oldIndex,
  required int newIndex,
}) {
  final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
  final moved = List<int>.of(displayIds);
  final item = moved.removeAt(oldIndex);
  moved.insert(adjusted, item);
  return [...moved, ...hiddenDoneIds];
}

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

  /// Affiche ou non les arrêts déjà traités (livré/échec). Par défaut
  /// masqués : ils sont parqués en bas derrière un bouton dépliable, pour
  /// que le prochain arrêt à faire reste en haut sans avoir à scroller.
  bool _showDone = false;

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
    //
    // En plus du reorder intra-tournee (handle drag), chaque ligne est
    // wrappee dans un LongPressDraggable pour permettre de la deplacer
    // vers une autre tournee du jour (drop sur le banner
    // AutresTourneesDuJourBanner qui sert de DragTarget). axis:vertical
    // limite le drag a la verticale pour ne pas conflicter avec le
    // Dismissible horizontal du StopRow. Delay 600ms pour ne pas
    // declencher au tap court.
    // Partition affichage (carte A Noah) : arrets restants (a_livrer) en
    // haut dans leur ordre, arrets traites (livre/echec) parques en bas et
    // MASQUES par defaut (depliables via le footer). But : le prochain
    // arret reste visible en haut, sans scroller. Display-only : on ne
    // persiste rien quand on marque livre/echec, l'ordre `ordreOptimise`
    // des restants est preserve.
    final remaining = _local.where((s) => !isStopDone(s)).toList();
    final done = _local.where(isStopDone).toList();
    final display = _showDone ? <Stop>[...remaining, ...done] : remaining;

    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: display.length,
            onReorderStart: (i) {
              _dragging = true;
              // Click selection (tic discret) au demarrage du drag : retour
              // tactile que la poignee a bien ete attrapee, important quand
              // on porte des gants l'hiver.
              HapticFeedback.selectionClick();
            },
            onReorder: (o, n) => _onReorder(o, n, display, done),
            itemBuilder: (context, i) {
              final stop = display[i];
              final estTraite = isStopDone(stop);
              final row = StopRow(
                key: ValueKey('stop-${stop.id}'),
                stop: stop,
                index: i + 1,
                dragIndex: i,
                // Arret verrouille (carte #114) OU traite : pas de poignee
                // de drag -> pas deplacable manuellement.
                showDragHandle: !stop.positionLocked && !estTraite,
                onDelete: () => _confirmDelete(context, ref, stop),
              );
              // Arret traite : parque, grise, non deplacable vers une autre
              // tournee (pas de LongPressDraggable).
              if (estTraite) {
                return KeyedSubtree(
                  key: ValueKey('done-stop-${stop.id}'),
                  child: Opacity(opacity: 0.55, child: row),
                );
              }
              return LongPressDraggable<Stop>(
                key: ValueKey('drag-stop-${stop.id}'),
                data: stop,
                axis: Axis.vertical,
                delay: const Duration(milliseconds: 600),
                hapticFeedbackOnStart: true,
                feedback: _DragFeedback(stop: stop),
                childWhenDragging: Opacity(opacity: 0.35, child: row),
                child: row,
              );
            },
          ),
          if (done.isNotEmpty)
            _DoneFooter(
              count: done.length,
              showDone: _showDone,
              onToggle: () => setState(() => _showDone = !_showDone),
            ),
        ],
      ),
    );
  }

  /// Callback du `ReorderableListView` : l'utilisateur a relache le
  /// drag entre [oldIndex] et [newIndex]. On met a jour `_local` et
  /// on persiste le nouvel ordre en base via `applyOptimizedOrder`.
  ///
  /// `newIndex > oldIndex - 1` : ajustement classique du
  /// `ReorderableListView` qui passe `newIndex` apres l'item ote.
  /// [display] = liste affichee (restants, + termines si _showDone).
  /// [hiddenDone] = termines masques (a re-append pour persister la liste
  /// COMPLETE : applyOptimizedOrder exige tous les ids, sinon collisions
  /// d'ordreOptimise).
  Future<void> _onReorder(
    int oldIndex,
    int newIndex,
    List<Stop> display,
    List<Stop> hiddenDone,
  ) async {
    final idToStop = {for (final s in _local) s.id: s};
    final fullIds = rebuildOrderAfterReorder(
      displayIds: display.map((s) => s.id).toList(growable: false),
      hiddenDoneIds:
          _showDone ? const [] : hiddenDone.map((s) => s.id).toList(),
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
    final full = [for (final id in fullIds) idToStop[id]!];
    setState(() => _local = full);
    // Confirmation de drop : pulse "moyen" pour signaler que le
    // nouvel ordre est valide et va etre persiste.
    HapticFeedback.mediumImpact();
    // Respecte les arrets verrouilles (carte #114) : meme si on a glisse
    // un autre arret par-dessus, les verrouilles regagnent leur index
    // d'origine (l'ordre courant pre-drag = widget.stops).
    final finalOrder = LockOrdering.respectLocks(
      currentOrder: widget.stops.map((s) => s.id).toList(growable: false),
      proposedOrder: full.map((s) => s.id).toList(growable: false),
      lockedIds: {
        for (final s in widget.stops)
          if (s.positionLocked) s.id,
      },
    );
    // Persister le nouvel ordre. La liste des stops du stream va etre
    // rafraichie automatiquement avec ces nouveaux ordreOptimise.
    await ref.read(stopsRepositoryProvider).applyOptimizedOrder(finalOrder);
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

/// Pied de liste dépliable : « ✓ N arrêt(s) terminé(s) — Afficher/Masquer ».
/// Permet de garder les arrêts traités hors de vue (le prochain arrêt reste
/// en haut) tout en pouvant les rouvrir d'un tap (pour relire / annuler).
class _DoneFooter extends StatelessWidget {
  const _DoneFooter({
    required this.count,
    required this.showDone,
    required this.onToggle,
  });

  final int count;
  final bool showDone;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return InkWell(
      onTap: onToggle,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x14,
          vertical: AppSpacing.x12,
        ),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: p.divider)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: 18, color: AppColors.emerald),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: Text(
                '$count arret${count > 1 ? "s" : ""} termine'
                '${count > 1 ? "s" : ""}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: p.textMute,
                ),
              ),
            ),
            Text(
              showDone ? 'Masquer' : 'Afficher',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            Icon(
              showDone ? Icons.expand_less : Icons.expand_more,
              size: 20,
              color: p.ink,
            ),
          ],
        ),
      ),
    );
  }
}

/// Aperçu visuel qui suit le doigt pendant un drag inter-tournee.
/// Card lime compacte avec icone deplacer + nom de l'arret. Volontairement
/// court (pas de tags, pas de stats) pour rester lisible meme sur petit
/// ecran. Material avec elevation pour qu'il flotte au-dessus du contenu.
class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.stop});

  final Stop stop;

  @override
  Widget build(BuildContext context) {
    final label = stop.nomClient?.isNotEmpty == true
        ? stop.nomClient!
        : stop.adresseBrute;
    return Material(
      color: Colors.transparent,
      elevation: 8,
      borderRadius: BorderRadius.circular(AppRadius.r14),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x14,
            vertical: AppSpacing.x10,
          ),
          decoration: BoxDecoration(
            color: AppColors.lime,
            borderRadius: BorderRadius.circular(AppRadius.r14),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.swap_horiz,
                color: AppColors.ink,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.x8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
