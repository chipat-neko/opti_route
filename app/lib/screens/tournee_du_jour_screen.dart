import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../data/cloud_auto_push_service.dart';
import '../data/database.dart';
import '../data/supabase_service.dart';
import '../data/tournee_realtime_service.dart';
import '../theme/app_tokens.dart';
import '../providers/database_providers.dart';
import '../providers/optimization_providers.dart';
import '../providers/supabase_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import 'ajout_arret_screen.dart';
import 'carte_screen.dart';
import 'tournee_du_jour/body.dart';
import 'tournee_du_jour/cloud_actions.dart';
import 'tournee_du_jour/export_actions.dart';
import 'tournee_du_jour/fabs.dart';
import 'tournee_du_jour/lifecycle_actions.dart';
import 'tournee_du_jour/optim_actions.dart';
import 'tournee_du_jour/plus_menu.dart';
import 'tournee_du_jour/stops_bulk_actions.dart';
import 'tournee_form_screen.dart';

class TourneeDuJourScreen extends ConsumerStatefulWidget {
  const TourneeDuJourScreen({super.key, required this.tournee});

  final Tournee tournee;

  @override
  ConsumerState<TourneeDuJourScreen> createState() =>
      _TourneeDuJourScreenState();
}

class _TourneeDuJourScreenState extends ConsumerState<TourneeDuJourScreen> {
  bool _optimizing = false;
  StreamSubscription<PresenceDelta>? _presenceDeltaSub;

  @override
  void initState() {
    super.initState();
    // Auto-push de la tournee active vers Supabase (sous-jalon 2.D-2).
    // Le service watche les changements (Tournees row + Stops) et push
    // silencieusement apres 5s de debounce. No-op si user pas connecte.
    // Stop dans dispose().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(cloudAutoPushServiceProvider)
          .watchTournee(widget.tournee.id);
      // Jalon 3.A : si la tournee est partagee (cloudId set + plusieurs
      // membres), s'abonner au Realtime channel pour recevoir les events
      // live des autres devices. No-op si tournee perso pure.
      _maybeSubscribeRealtime();
      // Jalon 3.E : ecoute les delta presence pour afficher des
      // SnackBar "X a rejoint / quitte la tournee".
      _maybeListenPresenceDeltas();
    });
  }

  @override
  void dispose() {
    // Arrete le watch auto-push pour ne pas continuer a push apres que
    // l'ecran est ferme (le user va peut-etre ouvrir une autre tournee
    // qui declenchera son propre watchTournee).
    ref.read(cloudAutoPushServiceProvider).stop();
    // Jalon 3.A : desabonne le channel Realtime de cette tournee.
    ref.read(tourneeRealtimeServiceProvider).unsubscribe();
    // Jalon 3.C : arrete le push GPS live.
    ref.read(livePresenceServiceProvider).stop();
    // Jalon 3.E : cancel la subscription au stream presence delta.
    _presenceDeltaSub?.cancel();
    super.dispose();
  }

  /// Jalon 3.E : ecoute les delta presence du channel actif et affiche
  /// un SnackBar in-app a chaque join/leave d'un autre coequipier.
  /// Volontairement basique : pas de nom (round-trip RPC trop lourd
  /// par event), juste "Un coequipier" — le user peut consulter la
  /// section Coequipiers pour le detail.
  void _maybeListenPresenceDeltas() {
    final realtime = ref.read(tourneeRealtimeServiceProvider);
    _presenceDeltaSub =
        realtime.presenceDeltaStream.listen((delta) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            delta.isJoin
                ? 'Un coequipier vient de rejoindre cette tournee'
                : 'Un coequipier vient de quitter cette tournee',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  /// Subscribe au channel Realtime de la tournee si elle a un cloudId
  /// (= deja pushee au cloud). Best-effort : si pas configure / pas
  /// auth / cloudId null, on skip silencieusement.
  ///
  /// Jalon 3.C : si la tournee est `en_cours` au moment du subscribe,
  /// on demarre aussi le push GPS live pour que le chef voie le
  /// livreur bouger sur la carte. Auto-stop dans dispose.
  Future<void> _maybeSubscribeRealtime() async {
    final cloudId = widget.tournee.cloudId;
    if (cloudId == null) return;
    final svc = SupabaseService.instance;
    if (!svc.isConfigured || svc.currentUser == null) return;
    try {
      await ref
          .read(tourneeRealtimeServiceProvider)
          .subscribeTournee(Supabase.instance.client, cloudId);
      // Demarre le push GPS si tournee active (statut en_cours). Pour
      // les tournees brouillon/optimisee/terminee, pas la peine de
      // brûler la batterie pour push une position figee.
      if (widget.tournee.statut == 'en_cours') {
        await ref.read(livePresenceServiceProvider).start();
      }
    } on Object {/* best-effort */}
  }

  @override
  Widget build(BuildContext context) {
    final stopsAsync = ref.watch(stopsByTourneeProvider(widget.tournee.id));
    final optimizer = ref.watch(optimizationServiceProvider);
    // Watch la tournee depuis la DB pour que l'UI se rafraichisse
    // automatiquement quand on appelle `repo.update(statut: ...)`
    // depuis _onDemarrerPressed / _onPauseShortPressed / _onArreterPressed.
    // Sans ca, `widget.tournee` reste fige a la valeur du constructeur
    // et l'UI ne reagit pas aux changements de statut / pauseeLe /
    // demareeLe (bug observe sur la checklist 2026-05-14).
    final tournee =
        ref.watch(tourneeByIdProvider(widget.tournee.id)).asData?.value ??
            widget.tournee;
    // Bouton grisé tant que `optimiseeLe != null` : la tournée est déjà
    // optimisée et rien n'a changé depuis. Toute modif structurelle
    // (add/edit/delete arret, point de depart change) appelle
    // `invalidateOptimization` qui remet `optimiseeLe = null` et
    // ré-active le bouton.
    final dejaOptimisee = tournee.optimiseeLe != null;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerBadgeIcon(),
        title: Row(
          children: [
            const Text('Tournee du jour'),
            const SizedBox(width: 8),
            const _AutoPushBadge(),
          ],
        ),
        actions: [
          IconButton(
            icon: _optimizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bolt_outlined),
            tooltip: optimizer == null
                ? 'Configure ta cle ORS dans les Parametres'
                : dejaOptimisee
                    ? 'Tournee deja optimisee  -  modifie un arret pour relancer'
                    : 'Optimiser la tournee',
            onPressed: (_optimizing || dejaOptimisee)
                ? null
                : _onOptimizePressed,
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Voir sur la carte',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CarteScreen(tournee: tournee),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier la tournee',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TourneeFormScreen(initial: tournee),
              ),
            ),
          ),
          PlusMenu(
            tournee: tournee,
            onAction: _onPlusAction,
          ),
        ],
      ),
      body: stopsAsync.when(
        data: (stops) => Body(tournee: tournee, stops: stops),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
      floatingActionButton: Fabs(
        tournee: tournee,
        onAjouter: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AjoutArretScreen(tourneeId: widget.tournee.id),
          ),
        ),
        onDemarrer: _onDemarrerPressed,
        onArreter: _onArreterPressed,
      ),
    );
  }

  /// Dispatch des actions du menu "Plus" vers les bonnes methodes. Le
  /// menu vit dans [PlusMenu] et remonte juste un enum, le mapping
  /// vers les `Future<void>` (qui ont besoin du state + ref + context)
  /// reste ici.
  void _onPlusAction(PlusAction action) {
    switch (action) {
      case PlusAction.pauseShort:
        _onPauseShortPressed();
      case PlusAction.batchLivre:
        _onBatchLivrePressed();
      case PlusAction.undoLast:
        _onUndoLastStatusPressed();
      case PlusAction.retryGeocode:
        _onRetryGeocodePressed();
      case PlusAction.duplicatePlus7:
        _onDuplicatePlus7Pressed();
      case PlusAction.shareText:
        _onShareTextPressed();
      case PlusAction.shareToCoequipier:
        _onShareToCoequipierPressed();
      case PlusAction.assignRest:
        _onAssignRestPressed();
      case PlusAction.exportPdf:
        _onExportPdfPressed();
      case PlusAction.exportPdfCo:
        _onExportPdfPerCoequipierPressed();
      case PlusAction.prefetchTuiles:
        _onPrefetchTuilesPressed();
      case PlusAction.pushCloud:
        _onPushCloudPressed();
      case PlusAction.inviteEquipier:
        _onInviteEquipierPressed();
      case PlusAction.leaveEquipe:
        _onLeaveEquipePressed();
      case PlusAction.delete:
        _confirmDeleteTournee();
    }
  }

  // Handlers cloud delegues a [CloudTourneeActions] (refactor 2026-05-17).
  Future<void> _onPushCloudPressed() => CloudTourneeActions.push(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onInviteEquipierPressed() => CloudTourneeActions.invite(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onLeaveEquipePressed() => CloudTourneeActions.leave(
        context: context,
        ref: ref,
        tournee: widget.tournee,
        onSuccess: () => Navigator.of(context).pop(),
      );

  Future<void> _confirmDeleteTournee() => CloudTourneeActions.confirmAndDelete(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  /// Action "Tout marquer livre" : valide d'un coup tous les arrets
  /// restants en statut 'a_livrer'. Utile pour les depots d'entreprise
  /// ou on livre 10 colis en une fois, ou pour cloturer rapidement une
  /// tournee terminee qu'on a oublie de marquer.
  Future<void> _onBatchLivrePressed() => StopsBulkActions.batchLivre(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onExportPdfPressed() => ExportTourneeActions.exportPdf(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onExportPdfPerCoequipierPressed() =>
      ExportTourneeActions.exportPdfPerCoequipier(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  /// Duplique la tournee courante a la meme date + 7 jours. Reset le
  /// statut + statuts arrets (via `duplicate` qui le fait deja). Affiche
  /// une confirmation et propose de basculer dessus.
  Future<void> _onDuplicatePlus7Pressed() =>
      OptimTourneeActions.duplicatePlus7(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onUndoLastStatusPressed() =>
      StopsBulkActions.undoLastStatus(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onRetryGeocodePressed() => StopsBulkActions.retryGeocode(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onShareTextPressed() => ExportTourneeActions.shareText(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  /// Affiche un selecteur de coequipier, puis genere un text-share
  /// filtre sur ses arrets affectes. Si le coequipier a un numero, on
  /// pre-remplit l'intent vers WhatsApp / SMS via url_launcher.
  Future<void> _onShareToCoequipierPressed() =>
      ExportTourneeActions.shareToCoequipier(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onAssignRestPressed() => StopsBulkActions.assignRest(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onDemarrerPressed() => LifecycleTourneeActions.demarrer(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onPauseShortPressed() => LifecycleTourneeActions.pauseShort(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onArreterPressed() => LifecycleTourneeActions.arreter(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onOptimizePressed() => OptimTourneeActions.optimize(
        context: context,
        ref: ref,
        tournee: widget.tournee,
        setOptimizing: (v) {
          if (mounted) setState(() => _optimizing = v);
        },
      );

  Future<void> _onPrefetchTuilesPressed() =>
      OptimTourneeActions.prefetchTuiles(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );
}

/// Petit indicateur discret dans l'AppBar qui montre l'etat de
/// l'auto-push :
/// - idle : invisible (SizedBox.shrink)
/// - pending : icone ⟳ statique amber (debounce 5s en cours)
/// - pushing : icone ⟳ tournant emerald (HTTP en cours)
///
/// Sert a rassurer Noah que ses modifs sont en cours de sauvegarde
/// cloud sans pollution visuelle quand rien ne se passe.
class _AutoPushBadge extends ConsumerWidget {
  const _AutoPushBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(cloudAutoPushServiceProvider);
    return StreamBuilder<AutoPushState>(
      stream: service.stateStream,
      initialData: service.currentState,
      builder: (context, snap) {
        final state = snap.data ?? AutoPushState.idle;
        switch (state) {
          case AutoPushState.idle:
            return const SizedBox.shrink();
          case AutoPushState.pending:
            return Tooltip(
              message: 'Sauvegarde cloud dans 5s...',
              child: Icon(
                Icons.cloud_sync_outlined,
                size: 16,
                color: AppColors.amber.withValues(alpha: 0.7),
              ),
            );
          case AutoPushState.pushing:
            return const Tooltip(
              message: 'Sauvegarde cloud en cours...',
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.emerald,
                ),
              ),
            );
        }
      },
    );
  }
}

