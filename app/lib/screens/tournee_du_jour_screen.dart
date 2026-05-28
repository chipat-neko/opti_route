import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart' show ContentAlign;

import '../data/address_suggestion.dart';
import '../data/cloud_sync_service.dart' show TourneeMembreInfo;
import '../data/database.dart';
import '../data/supabase_service.dart';
import '../data/tournee_realtime_service.dart';
import '../theme/app_tokens.dart';
import '../providers/database_providers.dart';
import '../providers/optimization_providers.dart';
import '../providers/supabase_providers.dart';
import '../widgets/app_drawer.dart';
import '../widgets/coach_mark_helper.dart';
import '../widgets/drawer_badge_icon.dart';
import 'ajout_arret_screen.dart';
import 'ajout_arret/bordereau_scan_handler.dart';
import 'bulk_paste_screen.dart';
import 'carte_screen.dart';
import 'nearby_poi_screen.dart';
import 'scan_colis_screen.dart';
import 'tournee_du_jour/auto_push_badge.dart';
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
  // Cles cibles pour les coach marks 1er lancement (info-bulles guidees
  // pointant vers les FAB scan colis + ajouter arret).
  final GlobalKey _fabScanColisKey = GlobalKey();
  final GlobalKey _fabAjouterKey = GlobalKey();

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
      // Coach marks 1er lancement : guide vers FAB scan + FAB ajouter.
      // Idempotent : flag coach_tournee_done dans ParametresRepository.
      _maybeShowCoachMarks();
      // Bug Trello #70 : detecte si on a ete eject de cette tournee
      // pendant qu'on etait hors ligne (notre row tournee_membres a
      // ete delete par le chef). Cleanup local Drift + pop si oui.
      _maybeCheckMembershipOrCleanup();
    });
  }

  void _maybeShowCoachMarks() {
    final repo = ref.read(parametresRepositoryProvider);
    CoachMarkHelper.showIfFirstTime(
      context,
      alreadyDoneCheck: repo.getCoachTourneeDone,
      markDone: repo.setCoachTourneeDone,
      steps: [
        CoachStep(
          key: _fabScanColisKey,
          title: 'Scanner un colis',
          description:
              'Scan le code-barre de l\'etiquette pour ajouter rapidement '
              'l\'arret a ta tournee. Marche avec MESEXP, Colissimo, '
              'Chronopost.',
          align: ContentAlign.left,
        ),
        CoachStep(
          key: _fabAjouterKey,
          title: 'Ajouter un arret',
          description:
              'Ajoute un arret manuellement : tape une adresse, choisis '
              'un client du carnet ou prend une photo du bordereau.',
          align: ContentAlign.left,
        ),
      ],
    );
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

  /// Bug Trello #70 fix 2A : si le user a ete ejecte de cette tournee
  /// pendant qu'il etait hors ligne, sa row local Drift est obsolete
  /// (il n'a plus acces aux donnees Supabase mais l'app continue de les
  /// afficher). Au lancement de l'ecran tournee partagee, on verifie
  /// la liste des membres via la RPC `list_tournee_members` (SECURITY
  /// DEFINER, bypass RLS).
  ///
  /// Si je ne suis plus dans la liste :
  /// - SnackBar "Tu as ete ejecte de cette tournee"
  /// - DELETE local Drift (tournee + ses stops)
  /// - Navigator.pop pour fermer l'ecran
  ///
  /// Silent en cas d'erreur (reseau, RLS, RPC manquante) : on garde la
  /// vue actuelle, l'utilisateur peut toujours utiliser le local cache.
  Future<void> _maybeCheckMembershipOrCleanup() async {
    final cloudId = widget.tournee.cloudId;
    if (cloudId == null) return;
    final svc = SupabaseService.instance;
    if (!svc.isConfigured || svc.currentUser == null) return;
    final myUserId = svc.currentUser!.id;
    final List<TourneeMembreInfo> members;
    try {
      members = await ref
          .read(cloudSyncServiceProvider)
          .listTourneeMembers(widget.tournee.id);
    } on Object {
      return; // silent
    }
    if (members.isEmpty) return; // pas de signal fiable
    final stillMember = members.any((m) => m.userCloudId == myUserId);
    if (stillMember) return;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    // Cleanup local : tournee + stops (les FK ON DELETE CASCADE Drift
    // s'occupent des stops normalement, mais on enleve explicitement
    // pour etre sur).
    try {
      final db = ref.read(appDatabaseProvider);
      await (db.delete(db.stops)
            ..where((s) => s.tourneeId.equals(widget.tournee.id)))
          .go();
      await (db.delete(db.tournees)
            ..where((t) => t.id.equals(widget.tournee.id)))
          .go();
    } on Object {/* best-effort */}
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Tu as ete ejecte de cette tournee. Donnees locales '
            'nettoyees.'),
        backgroundColor: AppColors.amber,
        duration: Duration(seconds: 4),
      ),
    );
    navigator.pop();
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
            // Flexible + ellipsis : sans ca, sur petits ecrans /
            // densite system >100% le Text + AutoPushBadge depassent
            // l'espace AppBar restant (apres leading + 4 IconButtons
            // + PlusMenu) -> 'RIGHT OVERFLOWED BY N PIXELS' en
            // texte rouge vertical (bug Noah 2026-05-21).
            const Flexible(
              child: Text(
                'Tournee du jour',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const AutoPushBadge(),
          ],
        ),
        actions: [
          // Tri rapide local (NN) : du plus proche au plus loin
          // depuis le depart, instantane, sans cle ORS, illimite.
          // Style Spoke route planner. C'est le bouton primaire pour
          // un livreur qui veut juste un ordre intuitif rapidement.
          IconButton(
            icon: const Icon(Icons.sort_outlined),
            tooltip: 'Tri rapide : du plus proche au plus loin',
            onPressed: _onQuickSortPressed,
          ),
          // Optim avancee VROOM : routes reelles, fenetres horaires,
          // boucle minimale. Plus precise mais consomme un quota ORS
          // et peut donner un ordre contre-intuitif (loin d'abord si
          // c'est sur le chemin de retour).
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
                    ? 'Optim avancee deja faite  -  modifie un arret pour relancer'
                    : 'Optim avancee (routes reelles, 1 quota ORS)',
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
        // Carte Trello #93 : bandeau secondaire compact avec le total
        // km/min restants des stops non livres. Place sous l'AppBar pour
        // ne pas surcharger le Row title (deja fragile cote overflow,
        // cf bug Noah 2026-05-21 ligne 158-162). Hidden si tournee finie.
        bottom: _KmRestantsBanner(tourneeId: widget.tournee.id),
      ),
      body: stopsAsync.when(
        data: (stops) => Body(tournee: tournee, stops: stops),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
      floatingActionButton: Fabs(
        tournee: tournee,
        scannerColisKey: _fabScanColisKey,
        ajouterKey: _fabAjouterKey,
        onAjouter: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AjoutArretScreen(tourneeId: widget.tournee.id),
          ),
        ),
        onDemarrer: _onDemarrerPressed,
        onArreter: _onArreterPressed,
        onScannerColis: _onScannerColisPressed,
        onScanRafale: _onScanRafalePressed,
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
      case PlusAction.bulkPasteAddresses:
        _onBulkPasteAddressesPressed();
      case PlusAction.nearbyPoi:
        _onNearbyPoiPressed();
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

  /// Ouvre le scanner code-barre colis. Si le code matche un arret
  /// existant de la tournee, [ScanColisScreen] a deja incremente +1
  /// colis et on affiche un toast confirmation. Sinon on ouvre l'ecran
  /// "Nouvel arret" avec le code pre-rempli en tracking initial.
  Future<void> _onScannerColisPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final result = await Navigator.of(context).push<ScanColisResult?>(
      MaterialPageRoute(builder: (_) => const ScanColisScreen()),
    );
    if (result == null || !mounted) return;
    final matched = result.matchedStop;
    if (matched != null) {
      final nom = matched.nomClient ?? matched.adresseBrute;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.lime,
          content: Text(
            '+1 colis ajoute a $nom (${matched.nbColis + 1} au total)',
            style: const TextStyle(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    } else {
      // Pas de match : on ouvre Nouvel arret avec le code pre-rempli
      // pour que Noah complete l'adresse manuellement (ou re-scanne le
      // bordereau).
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AjoutArretScreen(
            tourneeId: widget.tournee.id,
            trackingInitial: result.trackingNumber,
          ),
        ),
      );
    }
  }

  /// Scan en rafale (carte #119) : enchaine les bordereaux sans valider
  /// entre chaque, puis ajoute tout le lot d'un coup (dedup auto). Re-tri
  /// local apres l'ajout en masse.
  Future<void> _onScanRafalePressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final summary =
        await handleBordereauScanBatch(context, ref, widget.tournee.id);
    if (summary == null || !mounted) return;
    await ref.read(localReorderServiceProvider).reorder(widget.tournee.id);
    if (!mounted) return;
    final s = summary.crees > 1 ? 's' : '';
    final doublonTxt = summary.doublons > 0
        ? ' (${summary.doublons} doublon${summary.doublons > 1 ? "s" : ""} '
            'ignore${summary.doublons > 1 ? "s" : ""})'
        : '';
    messenger.showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emerald,
        content: Text(
          '${summary.crees} arret$s ajoute$s$doublonTxt',
          style: const TextStyle(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _onOptimizePressed() => OptimTourneeActions.optimize(
        context: context,
        ref: ref,
        tournee: widget.tournee,
        setOptimizing: (v) {
          if (mounted) setState(() => _optimizing = v);
        },
      );

  Future<void> _onQuickSortPressed() => OptimTourneeActions.quickSort(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  Future<void> _onPrefetchTuilesPressed() =>
      OptimTourneeActions.prefetchTuiles(
        context: context,
        ref: ref,
        tournee: widget.tournee,
      );

  /// Ouvre l'ecran [BulkPasteScreen] qui prend un texte multiligne
  /// d'adresses (depuis Google Maps / SMS / mail / etc.) et les
  /// importe en bulk dans la tournee courante apres geocodage en
  /// parallele. Workflow inspire de la demande Noah "transferer mes
  /// favoris Google Maps".
  Future<void> _onBulkPasteAddressesPressed() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BulkPasteScreen(tourneeId: widget.tournee.id),
      ),
    );
  }

  /// Ouvre [NearbyPoiScreen] (Sprint 2B) pour chercher les commerces
  /// (pharmacie, supermarche, etc.) autour du **dernier stop pending**
  /// si la tournee a des stops geocodes, sinon autour du depot. Le user
  /// choisit une categorie + tap sur un POI -> on l'ajoute comme nouvel
  /// arret a la tournee courante.
  Future<void> _onNearbyPoiPressed() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final stops = await ref
        .read(stopsRepositoryProvider)
        .getByTournee(widget.tournee.id);
    // Centre par defaut : depot. Si la tournee a au moins un stop
    // pending geocode, on prend le dernier comme centre (plus
    // pertinent : Noah va chercher 'un truc en passant' depuis sa
    // position actuelle/prochaine).
    var centerLat = widget.tournee.pointDepartLat;
    var centerLng = widget.tournee.pointDepartLng;
    var centerLabel = 'Depot';
    final lastPending = stops.lastWhereOrNull(
      (s) => s.statutLivraison == 'a_livrer' &&
          s.lat != null &&
          s.lng != null,
    );
    if (lastPending != null) {
      centerLat = lastPending.lat!;
      centerLng = lastPending.lng!;
      centerLabel = 'Dernier arret en attente';
    }
    if (!mounted) return;
    final picked = await navigator.push<AddressSuggestion?>(
      MaterialPageRoute(
        builder: (_) => NearbyPoiScreen(
          centerLat: centerLat,
          centerLng: centerLng,
          centerLabel: centerLabel,
        ),
      ),
    );
    if (picked == null || !mounted) return;
    // Ajoute le POI comme nouveau stop dans la tournee courante.
    await ref.read(stopsRepositoryProvider).create(
          StopsCompanion.insert(
            tourneeId: widget.tournee.id,
            adresseBrute: picked.adressePostale.isEmpty
                ? (picked.poiName ?? picked.displayName)
                : picked.adressePostale,
            adresseNormalisee: Value(picked.adressePostale),
            lat: Value(picked.lat),
            lng: Value(picked.lon),
            nomClient: Value(picked.poiName),
          ),
        );
    await ref
        .read(tourneesRepositoryProvider)
        .invalidateOptimization(widget.tournee.id);
    await ref
        .read(localReorderServiceProvider)
        .reorder(widget.tournee.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${picked.poiName ?? "POI"} ajoute a la tournee'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }
}

/// Extension utilitaire (manque sur Iterable Dart) pour trouver le
/// dernier element correspondant a un predicat, ou null si rien.
extension _IterableLastWhereOrNull<E> on Iterable<E> {
  E? lastWhereOrNull(bool Function(E) test) {
    E? found;
    for (final e in this) {
      if (test(e)) found = e;
    }
    return found;
  }
}

// _AutoPushBadge -> extrait dans tournee_du_jour/auto_push_badge.dart
// (refactor 2026-05-21 : public AutoPushBadge reutilisable).

/// Bandeau secondaire sous l'AppBar tournee : "12,4 km · 1h05 restants
/// (8 arrets)". Compact, 24px de haut. Carte Trello #93.
///
/// Cache si :
/// - tournee terminee (tous les stops livres / echec)
/// - aucun segment calcule (tournee vide / pas encore optimisee)
///
/// Implementer PreferredSizeWidget pour pouvoir etre passe en `bottom`
/// de l'AppBar.
class _KmRestantsBanner extends ConsumerWidget
    implements PreferredSizeWidget {
  const _KmRestantsBanner({required this.tourneeId});

  final int tourneeId;

  @override
  Size get preferredSize => const Size.fromHeight(24);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final resumeAsync = ref.watch(distanceRestanteProvider(tourneeId));
    final resume = resumeAsync.asData?.value;
    if (resume == null) return const SizedBox(height: 24);
    final km = (resume.meters / 1000).toStringAsFixed(1);
    final mins = resume.duration.inMinutes;
    final dureeLabel = mins < 60
        ? '$mins min'
        : '${mins ~/ 60}h${(mins % 60).toString().padLeft(2, '0')}';
    return SizedBox(
      height: 24,
      child: Container(
        alignment: Alignment.center,
        color: p.cream,
        child: Text(
          '$km km · $dureeLabel restants (${resume.countStops} arrets)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: p.textMute,
          ),
        ),
      ),
    );
  }
}

