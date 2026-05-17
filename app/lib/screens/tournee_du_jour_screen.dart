import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

import '../data/database.dart';
import '../data/supabase_service.dart';
import '../data/location_service.dart';
import '../data/notifications_service.dart';
import '../data/tile_prefetch_service.dart';
import '../providers/database_providers.dart';
import '../providers/optimization_providers.dart';
import '../providers/supabase_providers.dart';
import '../providers/tile_provider.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import '../widgets/ordre_priorite_dialog.dart';
import 'ajout_arret_screen.dart';
import 'carte_screen.dart';
import 'tournee_du_jour/cloud_actions.dart';
import 'tournee_du_jour/export_actions.dart';
import 'tournee_du_jour/stops_bulk_actions.dart';
import 'parametres_screen.dart';
import 'tournee_du_jour/body.dart';
import 'tournee_du_jour/fabs.dart';
import 'tournee_du_jour/plus_menu.dart';
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
    super.dispose();
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
        title: const Text('Tournee du jour'),
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
  Future<void> _onDuplicatePlus7Pressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(tourneesRepositoryProvider);
      final targetDate =
          widget.tournee.date.add(const Duration(days: 7));
      final newId = await repo.duplicate(
        widget.tournee.id,
        targetDate: targetDate,
      );
      final newTournee = await repo.getById(newId);
      if (!mounted || newTournee == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Duplique en "${newTournee.nom}" pour la semaine prochaine',
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () {
              navigator.pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => TourneeDuJourScreen(tournee: newTournee),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

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

  Future<void> _onDemarrerPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    // Demande la permission GPS avant de basculer en mode en_cours
    // pour eviter d'afficher la card "prochain arret" sans donnees.
    try {
      final ok = await LocationService.ensurePermission();
      if (!ok) return;
    } on LocationPermissionDenied catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    if (!mounted) return;
    await ref.read(tourneesRepositoryProvider).update(
          widget.tournee.id,
          TourneesCompanion(
            statut: const Value('en_cours'),
            // Pose le timestamp de demarrage seulement s'il n'y en a
            // pas deja un (ex: reprise apres Pause -> on garde le 1er).
            demareeLe: widget.tournee.demareeLe == null
                ? Value(DateTime.now())
                : const Value.absent(),
          ),
        );
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Tournee demarree. Bonne route !'),
        backgroundColor: AppColors.emerald,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// Pause "courte" (pause dejeuner par ex) sans changer le statut de
  /// la tournee. Toggle entre pause / reprendre selon que `pauseeLe`
  /// est deja set ou non.
  ///
  /// La duree pausee s'accumule dans `pauseeSeconds` au moment du
  /// "Reprendre". Ce cumul est utilise par les stats (heures
  /// travaillees effectives) et a l'affichage chrono "Demarree il y a".
  Future<void> _onPauseShortPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(tourneesRepositoryProvider);
    final t = await repo.getById(widget.tournee.id);
    if (t == null || !mounted) return;
    if (t.pauseeLe == null) {
      await repo.pauseTournee(t.id);
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tournee en pause. Tap "Reprendre" quand tu repars.'),
          backgroundColor: AppColors.amber,
          duration: Duration(seconds: 3),
        ),
      );
    } else {
      await repo.reprendreTournee(t.id);
      if (!mounted) return;
      final pauseDuree = DateTime.now().difference(t.pauseeLe!);
      final mins = pauseDuree.inMinutes;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'C\'est reparti. Pause de ${mins}min comptee.',
          ),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _onArreterPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mettre la tournee en pause ?'),
        content: const Text(
          'La tournee repasse en mode "optimisee". Tu pourras la '
          'relancer plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mettre en pause'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(tourneesRepositoryProvider).update(
          widget.tournee.id,
          const TourneesCompanion(statut: Value('optimisee')),
        );
    // Alerte "arrets oublies" : si la tournee est mise en pause avec
    // des stops a_livrer restants, on push une notif rappel.
    final stops = await ref
        .read(stopsRepositoryProvider)
        .getByTournee(widget.tournee.id);
    final pending =
        stops.where((s) => s.statutLivraison == 'a_livrer').length;
    if (pending > 0) {
      unawaited(
        NotificationsService.instance.showPendingStopsAlert(
          tourneeId: widget.tournee.id,
          nomTournee: widget.tournee.nom,
          nbPending: pending,
        ),
      );
    }
  }

  Future<void> _onOptimizePressed() async {
    final optimizer = ref.read(optimizationServiceProvider);
    if (optimizer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cle OpenRouteService manquante. Configure-la dans les Parametres.',
          ),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ParametresScreen(),
              ),
            ),
          ),
        ),
      );
      return;
    }

    final stopsRepo = ref.read(stopsRepositoryProvider);
    final stops = await stopsRepo.getByTournee(widget.tournee.id);
    final geocoded =
        stops.where((s) => s.lat != null && s.lng != null).toList();
    if (geocoded.length < 2) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Au moins 2 arrets avec coordonnees sont necessaires.'),
        ),
      );
      return;
    }

    // 1. Si plusieurs arrets EN 1ER : demander a Noah l'ordre voulu
    //    entre eux. Idem pour EN DERNIER. VROOM ne sait pas le faire :
    //    son champ priority est un score, pas un ordre absolu.
    final firsts = geocoded
        .where((s) => s.priorite == 'obligatoire_premier')
        .toList()
      ..sort(_existingOrdrePrio);
    final lasts = geocoded
        .where((s) => s.priorite == 'obligatoire_dernier')
        .toList()
      ..sort(_existingOrdrePrio);

    if (!mounted) return;
    final firstsOrdered = await OrdrePrioriteDialog.showIfNeeded(
      context,
      titre: 'Ordre des arrets EN 1ER',
      sousTitre: 'Tu as ${firsts.length} arrets a livrer en premier. '
          'Glisse-les dans l\'ordre voulu : 1, 2, 3...',
      stops: firsts,
    );
    if (firstsOrdered == null) return; // annule
    if (!mounted) return;
    final lastsOrdered = await OrdrePrioriteDialog.showIfNeeded(
      context,
      titre: 'Ordre des arrets EN DERNIER',
      sousTitre: 'Tu as ${lasts.length} arrets a livrer en fin de tournee. '
          'Glisse-les dans l\'ordre voulu.',
      stops: lasts,
    );
    if (lastsOrdered == null) return;

    // 2. Persister `ordrePriorite` pour que le solveur (et la prochaine
    //    optimisation) le retrouvent.
    await _persistOrdrePriorite(firstsOrdered);
    await _persistOrdrePriorite(lastsOrdered);

    // Recharger les stops pour avoir les ordrePriorite a jour avant
    // d'appeler le solveur.
    final stopsRefreshed = await stopsRepo.getByTournee(widget.tournee.id);
    final geocodedRefreshed = stopsRefreshed
        .where((s) => s.lat != null && s.lng != null)
        .toList(growable: false);

    if (!mounted) return;
    setState(() => _optimizing = true);
    try {
      final result = await optimizer.optimize(
        tournee: widget.tournee,
        stops: geocodedRefreshed,
      );
      // Incremente le compteur du quota ORS pour Parametres.
      // Best-effort : si l'ecriture echoue, on ne casse pas l'optim.
      try {
        await ref
            .read(parametresRepositoryProvider)
            .incrementOrsUsed();
      } catch (_) {}

      await ref
          .read(stopsRepositoryProvider)
          .applyOptimizedOrder(result.orderedStopIds);

      // On serialise la geometry GeoJSON en string JSON pour stockage
      // SQLite. La carte la decodera en LineString a l'affichage.
      final traceJson = result.routeGeometry == null
          ? null
          : jsonEncode(result.routeGeometry);
      await ref.read(tourneesRepositoryProvider).update(
            widget.tournee.id,
            TourneesCompanion(
              statut: const Value('optimisee'),
              distanceTotaleM: Value(result.totalDistanceMeters),
              dureeTotaleS: Value(result.totalDurationSeconds),
              optimiseeLe: Value(DateTime.now()),
              traceGeojson: Value(traceJson),
            ),
          );

      if (!mounted) return;
      final km = (result.totalDistanceMeters / 1000).toStringAsFixed(1);
      final dur = _formatDuration(result.totalDurationSeconds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tournee optimisee : $km km · $dur'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'optimisation : $e')),
      );
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
  }

  /// Tri stable d'arrets par `ordrePriorite` (croissant). Null tombe a
  /// la fin -- les arrets non encore ordonnes apparaissent en queue,
  /// l'utilisateur les classera dans le dialog.
  static int _existingOrdrePrio(Stop a, Stop b) {
    final ao = a.ordrePriorite;
    final bo = b.ordrePriorite;
    if (ao == null && bo == null) return a.id.compareTo(b.id);
    if (ao == null) return 1;
    if (bo == null) return -1;
    return ao.compareTo(bo);
  }

  /// Ecrit `ordrePriorite = position dans la liste` (1-based) pour
  /// chaque stop. Permet aux prochaines optimisations de reprendre
  /// l'ordre choisi sans redemander. Batch atomique (1 round-trip
  /// SQLite au lieu de N).
  Future<void> _persistOrdrePriorite(List<int> orderedIds) async {
    if (orderedIds.isEmpty) return;
    await ref
        .read(stopsRepositoryProvider)
        .applyOrdrePriorite(orderedIds);
  }

  /// Pre-telecharge les tuiles OSM de la bbox (depot + arrets
  /// geocodes) aux zooms 13-16. Affiche d'abord une dialog de
  /// confirmation avec l'estimation taille + nb tuiles, puis une
  /// progress dialog pendant le download. Etape 4 du plan GPS.
  Future<void> _onPrefetchTuilesPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final stops =
        await ref.read(stopsRepositoryProvider).getByTournee(widget.tournee.id);
    if (!mounted) return;

    // Collecte des points : depot + arrets geocodes (lat/lng non nuls).
    final points = <LatLng>[
      LatLng(widget.tournee.pointDepartLat, widget.tournee.pointDepartLng),
      for (final s in stops)
        if (s.lat != null && s.lng != null) LatLng(s.lat!, s.lng!),
    ];
    if (points.length < 2) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Aucun arret geocode. Geolocalise d\'abord les arrets.'),
      ));
      return;
    }

    final estimate = TilePrefetchService.estimate(points: points);
    if (estimate.tiles > TilePrefetchService.maxTiles) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Zone trop large (${estimate.tiles} tuiles). Limite '
          '${TilePrefetchService.maxTiles}.',
        ),
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Telecharger pour hors-ligne ?'),
        content: Text(
          '${estimate.tiles} tuiles a telecharger '
          '(~${estimate.estimatedSizeLabel}).\n\n'
          'Les tuiles serviront a afficher la carte meme sans 4G '
          'pendant cette tournee. Operation a faire de preference '
          'en wifi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Telecharger'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final service = TilePrefetchService(ref.read(cachedTileProviderInstance));
    final progress = ValueNotifier<({int done, int total})>(
      (done: 0, total: estimate.tiles),
    );

    // Progress dialog non-bloquante (rentre dans la stack mais on la
    // pop nous-meme a la fin). Animation desactivee pour eviter le
    // flicker entre chaque update.
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Telechargement...'),
        content: ValueListenableBuilder<({int done, int total})>(
          valueListenable: progress,
          builder: (_, v, _) {
            final ratio = v.total == 0 ? 0.0 : v.done / v.total;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: ratio),
                const SizedBox(height: 12),
                Text('${v.done} / ${v.total} tuiles'),
              ],
            );
          },
        ),
      ),
    ));

    var downloaded = 0;
    String? errorMsg;
    try {
      downloaded = await service.prefetchBbox(
        points: points,
        onProgress: (done, total) {
          progress.value = (done: done, total: total);
        },
      );
    } on TilePrefetchError catch (e) {
      errorMsg = e.message;
    } catch (e) {
      errorMsg = 'Erreur : $e';
    }

    if (mounted) Navigator.of(context).pop(); // ferme la progress dialog
    progress.dispose();
    if (!mounted) return;
    if (errorMsg != null) {
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
      return;
    }
    final failed = estimate.tiles - downloaded;
    messenger.showSnackBar(SnackBar(
      content: Text(
        '$downloaded / ${estimate.tiles} tuiles en cache'
        '${failed > 0 ? ' ($failed echec(s))' : ''}',
      ),
      backgroundColor: AppColors.emerald,
    ));
  }
}

String _formatDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  if (h == 0) return '${m}min';
  return '${h}h${m.toString().padLeft(2, '0')}';
}

