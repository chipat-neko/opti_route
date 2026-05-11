import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart' show Position;
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/location_service.dart';
import '../data/navigation_service.dart';
import '../data/notifications_service.dart';
import '../data/stops_repository.dart';
import '../data/tournee_pdf_service.dart';
import '../data/tournee_text_share_service.dart';
import '../providers/geocoding_providers.dart';
import '../data/tournees_repository.dart';
import '../providers/database_providers.dart';
import '../providers/location_providers.dart';
import '../providers/optimization_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import '../widgets/ordre_priorite_dialog.dart';
import '../widgets/stop_action_sheet.dart';
import 'ajout_arret_screen.dart';
import 'carte_screen.dart';
import 'parametres_screen.dart';
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
  Widget build(BuildContext context) {
    final stopsAsync = ref.watch(stopsByTourneeProvider(widget.tournee.id));
    final optimizer = ref.watch(optimizationServiceProvider);
    // Bouton grisÃ© tant que `optimiseeLe != null` : la tournÃ©e est dÃ©jÃ 
    // optimisÃ©e et rien n'a changÃ© depuis. Toute modif structurelle
    // (add/edit/delete arret, point de depart change) appelle
    // `invalidateOptimization` qui remet `optimiseeLe = null` et
    // rÃ©-active le bouton.
    final dejaOptimisee = widget.tournee.optimiseeLe != null;

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
                    ? 'Tournee deja optimisee â€” modifie un arret pour relancer'
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
                builder: (_) => CarteScreen(tournee: widget.tournee),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier la tournee',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TourneeFormScreen(initial: widget.tournee),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Plus',
            onSelected: (value) {
              if (value == 'delete') _confirmDeleteTournee();
              if (value == 'export_pdf') _onExportPdfPressed();
              if (value == 'share_text') _onShareTextPressed();
              if (value == 'batch_livre') _onBatchLivrePressed();
              if (value == 'retry_geocode') _onRetryGeocodePressed();
              if (value == 'undo_last') _onUndoLastStatusPressed();
              if (value == 'duplicate_plus7') _onDuplicatePlus7Pressed();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'batch_livre',
                child: ListTile(
                  leading: Icon(Icons.done_all, color: AppColors.emerald),
                  title: Text('Tout marquer livre'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'undo_last',
                child: ListTile(
                  leading: Icon(Icons.undo, color: AppColors.amber),
                  title: Text('Annuler dernier statut'),
                  subtitle: Text(
                    'Le dernier arret valide/echec',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'retry_geocode',
                child: ListTile(
                  leading: Icon(Icons.gps_fixed),
                  title: Text('Geolocaliser hors-ligne'),
                  subtitle: Text(
                    'Re-tente le GPS pour les arrets sans coords',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'duplicate_plus7',
                child: ListTile(
                  leading: Icon(Icons.copy_outlined),
                  title: Text('Refaire dans 7 jours'),
                  subtitle: Text(
                    'Duplique a la meme heure semaine prochaine',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'share_text',
                child: ListTile(
                  leading: Icon(Icons.share_outlined),
                  title: Text('Partager en texte'),
                  subtitle: Text(
                    'WhatsApp, SMS, mail...',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'export_pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Exporter en PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.red),
                  title: Text('Supprimer la tournee'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: stopsAsync.when(
        data: (stops) => _Body(tournee: widget.tournee, stops: stops),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
      floatingActionButton: _Fabs(
        tournee: widget.tournee,
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

  Future<void> _confirmDeleteTournee() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette tournee ?'),
        content: Text(
          '"${widget.tournee.nom}" et tous ses arrets seront supprimes '
          'definitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red.withValues(alpha: 0.15),
              foregroundColor: AppColors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(tourneesRepositoryProvider).delete(widget.tournee.id);
      if (!mounted) return;
      // Le HomeScreen va detecter qu'il n'y a plus de tournee du jour
      // et basculer sur l'empty state â€” pas besoin de pop manuellement.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }

  /// Action "Tout marquer livre" : valide d'un coup tous les arrets
  /// restants en statut 'a_livrer'. Utile pour les depots d'entreprise
  /// ou on livre 10 colis en une fois, ou pour cloturer rapidement une
  /// tournee terminee qu'on a oublie de marquer.
  Future<void> _onBatchLivrePressed() async {
    final stopsRepo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);
    final all = await stopsRepo.getByTournee(widget.tournee.id);
    final pending =
        all.where((s) => s.statutLivraison == 'a_livrer').toList();
    if (!mounted) return;
    if (pending.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucun arret en attente de livraison'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tout marquer livre ?'),
        content: Text(
          '${pending.length} arret(s) en attente vont etre marques comme '
          'livres. Tu pourras revenir en arriere arret par arret depuis la '
          'bottom sheet si besoin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: context.palette.paper,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tout livrer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Capture GPS une fois pour tout le batch (best-effort).
    ({double lat, double lng})? pos;
    try {
      final ok = await LocationService.ensurePermission();
      if (ok) {
        final p = await LocationService.currentPosition()
            .timeout(const Duration(seconds: 4));
        pos = (lat: p.latitude, lng: p.longitude);
      }
    } catch (_) {}

    for (final s in pending) {
      await stopsRepo.markLivre(s.id, position: pos);
    }
    // Bascule auto en 'terminee' (tous les arrets valides maintenant).
    final refreshed = await stopsRepo.getByTournee(widget.tournee.id);
    final tousValides = refreshed.every(
      (s) => s.statutLivraison == 'livre' || s.statutLivraison == 'echec',
    );
    if (tousValides) {
      await tourneesRepo.update(
        widget.tournee.id,
        const TourneesCompanion(statut: Value('terminee')),
      );
      // Tournee finie : on annule le rappel local s'il y en avait un
      // (inutile de reveiller Noah le lendemain pour une tournee deja
      // terminee).
      await NotificationsService.instance
          .cancelTourneeRappel(widget.tournee.id);
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${pending.length} arret(s) marques livres'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  Future<void> _onExportPdfPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stops =
          await ref.read(stopsRepositoryProvider).getByTournee(widget.tournee.id);
      final service = TourneePdfService();
      // Calcule le cout carburant pour l'inclure dans le PDF si la
      // tournee a une distance.
      double? cout;
      if (widget.tournee.distanceTotaleM != null &&
          widget.tournee.distanceTotaleM! > 0) {
        cout = await ref
            .read(parametresRepositoryProvider)
            .estimerCoutCarburant(
              distanceMeters: widget.tournee.distanceTotaleM!,
            );
      }
      await service.exportAndShare(
        tournee: widget.tournee,
        stops: stops,
        coutCarburantEur: cout,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'export PDF : $e')),
      );
    }
  }

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

  /// Annule le dernier statut (livre ou echec) pose dans cette tournee.
  /// Retrouve le stop via `getLastTransitionedStop` puis le repasse en
  /// 'a_livrer'. Snackbar de confirmation avec un bouton de re-annule.
  Future<void> _onUndoLastStatusPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final repo = ref.read(stopsRepositoryProvider);
      final last = await repo.getLastTransitionedStop(widget.tournee.id);
      if (!mounted) return;
      if (last == null) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Aucun statut a annuler dans cette tournee.'),
          ),
        );
        return;
      }
      await repo.revertStatus(last.id);
      if (!mounted) return;
      final label = last.nomClient?.trim().isNotEmpty == true
          ? last.nomClient!.trim()
          : last.adresseBrute.split(',').first.trim();
      messenger.showSnackBar(
        SnackBar(
          content: Text('"$label" est repasse en "A livrer"'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  /// Lance le re-geocodage des arrets sans coords (mode hors-ligne).
  /// Affiche un dialog de progression simple, puis un bilan en snackbar.
  Future<void> _onRetryGeocodePressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    // Dialog "loading" non dismissible
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            SizedBox(
              height: 18,
              width: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppSpacing.x14),
            Expanded(child: Text('Geolocalisation en cours...')),
          ],
        ),
      ),
    );
    try {
      final svc = ref.read(stopsGeocodeRetryServiceProvider);
      final res = await svc.retryFor(widget.tournee.id);
      navigator.pop(); // ferme le loader
      if (!mounted) return;
      if (res.totalCandidats == 0) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Aucun arret sans GPS a geolocaliser.'),
          ),
        );
        return;
      }
      // Si on a resolu au moins 1 stop, l'optim est invalidee : le
      // bouton "Optimiser" redevient cliquable.
      if (res.resolved.isNotEmpty) {
        await ref
            .read(tourneesRepositoryProvider)
            .invalidateOptimization(widget.tournee.id);
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            res.unresolved.isEmpty
                ? '${res.resolved.length} arret(s) geolocalise(s)'
                : '${res.resolved.length} resolu(s), '
                    '${res.unresolved.length} echec(s) - '
                    'verifie l\'adresse manuellement',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      navigator.pop();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  /// Partage la tournee sous forme de texte court via le selecteur natif
  /// Android (WhatsApp, SMS, mail, etc.). Utilise les arrets dans leur
  /// ordre actuel (optimise si l'optim a tourne, sinon ordre de saisie).
  Future<void> _onShareTextPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stops = await ref
          .read(stopsRepositoryProvider)
          .getByTournee(widget.tournee.id);
      final service = TourneeTextShareService(
        parametres: ref.read(parametresRepositoryProvider),
      );
      await service.shareAsText(
        tournee: widget.tournee,
        stops: stops,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur au partage : $e')),
      );
    }
  }

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
          content: Text('Tournee optimisee : $km km Â· $dur'),
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
  /// l'ordre choisi sans redemander.
  Future<void> _persistOrdrePriorite(List<int> orderedIds) async {
    if (orderedIds.isEmpty) return;
    final repo = ref.read(stopsRepositoryProvider);
    for (var i = 0; i < orderedIds.length; i++) {
      await repo.update(
        orderedIds[i],
        StopsCompanion(ordrePriorite: Value(i + 1)),
      );
    }
  }
}

String _formatDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  if (h == 0) return '${m}min';
  return '${h}h${m.toString().padLeft(2, '0')}';
}

class _Body extends StatelessWidget {
  const _Body({required this.tournee, required this.stops});

  final Tournee tournee;
  final List<Stop> stops;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x18,
        AppSpacing.x8,
        AppSpacing.x18,
        AppSpacing.x18,
      ),
      children: [
        _Header(tournee: tournee),
        _AutresTourneesDuJourBanner(currentTourneeId: tournee.id),
        const SizedBox(height: AppSpacing.x16),
        _StatRow(
          arretsCount: stops.length,
          colisTotal: stops.fold<int>(0, (sum, s) => sum + s.nbColis),
          distanceMeters: tournee.distanceTotaleM,
          durationSeconds: tournee.dureeTotaleS,
        ),
        if (tournee.distanceTotaleM != null &&
            tournee.distanceTotaleM! > 0) ...[
          const SizedBox(height: AppSpacing.x8),
          _CoutCarburantBanner(distanceMeters: tournee.distanceTotaleM!),
        ],
        if (tournee.statut == 'optimisee') ...[
          const SizedBox(height: AppSpacing.x12),
          _OptimisedBanner(tournee: tournee),
        ],
        if (stops.any((s) =>
            s.statutLivraison == 'livre' || s.statutLivraison == 'echec')) ...[
          const SizedBox(height: AppSpacing.x12),
          _ProgressBanner(
            stops: stops,
            tourneeTerminee: tournee.statut == 'terminee',
            demareeLe: tournee.demareeLe,
          ),
        ],
        if (tournee.statut == 'en_cours') ...[
          const SizedBox(height: AppSpacing.x12),
          _ProchainArretCard(stops: stops),
        ],
        const SizedBox(height: AppSpacing.x18),
        if (stops.isEmpty)
          const _StopsPlaceholder()
        else
          _StopsSection(stops: stops),
      ],
    );
  }
}

/// Section "Liste des arrets" avec un champ de recherche au-dessus
/// (utile pour les grosses tournees, 15+ arrets). Quand la query est
/// vide : liste complete + drag-and-drop actif. Quand on cherche : on
/// affiche uniquement les arrets qui matchent (par nom client / adresse
/// / notes, normalisation des accents) et le drag est desactive
/// puisque l'ordre n'a pas de sens sur un sous-ensemble.
class _StopsSection extends ConsumerStatefulWidget {
  const _StopsSection({required this.stops});

  final List<Stop> stops;

  @override
  ConsumerState<_StopsSection> createState() => _StopsSectionState();
}

class _StopsSectionState extends ConsumerState<_StopsSection> {
  String _query = '';

  /// Filtre par statut applique en plus de la recherche texte :
  /// 'tout' / 'a_livrer' / 'livre' / 'echec'.
  String _statutFilter = 'tout';

  /// Mode "tri par distance GPS" : remplace l'ordre optimise par
  /// la proximite a ma position actuelle. Utile quand je devie de
  /// l'itineraire ou pour decider du prochain arret le plus proche.
  bool _sortByDistance = false;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasQuery = _query.trim().isNotEmpty;
    final hasStatutFilter = _statutFilter != 'tout';
    var filtered = widget.stops;
    if (hasStatutFilter) {
      filtered = filtered
          .where((s) => s.statutLivraison == _statutFilter)
          .toList();
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
    final isFiltered = hasQuery || hasStatutFilter || _sortByDistance;

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
                    color: _sortByDistance
                        ? p.ink
                        : p.textMute,
                  ),
                  selectedColor: AppColors.lime,
                  backgroundColor: p.paper,
                  side: BorderSide(
                    color: _sortByDistance
                        ? AppColors.lime
                        : p.inkLine,
                  ),
                  labelStyle: TextStyle(
                    color: p.ink,
                    fontWeight: _sortByDistance
                        ? FontWeight.w700
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
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
          _StopsList(stops: filtered, reorderable: !isFiltered),
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
      'Ã ': 'a', 'Ã¢': 'a', 'Ã¤': 'a', 'Ã¡': 'a', 'Ã£': 'a',
      'Ã§': 'c',
      'Ã¨': 'e', 'Ã©': 'e', 'Ãª': 'e', 'Ã«': 'e',
      'Ã®': 'i', 'Ã¯': 'i', 'Ã­': 'i', 'Ã¬': 'i',
      'Ã´': 'o', 'Ã¶': 'o', 'Ã³': 'o', 'Ãµ': 'o',
      'Ã¹': 'u', 'Ã»': 'u', 'Ã¼': 'u', 'Ãº': 'u',
      'Ã¿': 'y', 'Ã½': 'y',
      'Ã±': 'n',
      'Å“': 'oe', 'Ã¦': 'ae',
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

/// Bandeau cliquable qui apparait quand le livreur a plusieurs
/// tournees datees d'aujourd'hui (typiquement matin/aprem ou plusieurs
/// secteurs). Tap -> bottom sheet listant les autres tournees du jour
/// avec leur statut, tap sur l'une -> switch vers cette tournee.
class _AutresTourneesDuJourBanner extends ConsumerWidget {
  const _AutresTourneesDuJourBanner({required this.currentTourneeId});

  final int currentTourneeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final all = ref.watch(tourneesDuJourProvider);
    final autres = all.where((t) => t.id != currentTourneeId).toList();
    if (autres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x10),
      child: Material(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r10),
          onTap: () => _showSwitcher(context, autres),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x12,
              vertical: AppSpacing.x10,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: p.ink,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: Text(
                    autres.length == 1
                        ? '1 autre tournee aujourd\'hui'
                        : '${autres.length} autres tournees aujourd\'hui',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: p.textMute,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showSwitcher(
    BuildContext context,
    List<Tournee> autres,
  ) async {
    final p = context.palette;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x18,
            AppSpacing.x14,
            AppSpacing.x18,
            AppSpacing.x18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: p.inkLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Autres tournees du jour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              for (final t in autres) ...[
                Material(
                  color: p.paper,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => TourneeDuJourScreen(tournee: t),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.nom,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _statutLabel(t.statut),
                                  style: appMonoStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _statutColor(t.statut),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: p.textMute,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _statutLabel(String s) => switch (s) {
        'brouillon' => 'BROUILLON',
        'optimisee' => 'OPTIMISEE',
        'en_cours' => 'EN COURS',
        'terminee' => 'TERMINEE',
        _ => s.toUpperCase(),
      };

  static Color _statutColor(String s) => switch (s) {
        'en_cours' => AppColors.emerald,
        'terminee' => AppColors.emerald,
        'optimisee' => AppColors.ink,
        _ => AppColors.textMute,
      };
}

class _Header extends StatelessWidget {
  const _Header({required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dateLabel = DateFormat('EEEE d MMMM', 'fr')
        .format(tournee.date)
        .toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: appMonoStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: p.textMute,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          tournee.nom,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: p.ink,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          'Depart : ${tournee.pointDepartLabel}',
          style: TextStyle(
            fontSize: 13,
            color: p.textMute,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.arretsCount,
    required this.colisTotal,
    this.distanceMeters,
    this.durationSeconds,
  });

  final int arretsCount;
  final int colisTotal;
  final int? distanceMeters;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasDistance = distanceMeters != null && distanceMeters! > 0;
    final hasDuration = durationSeconds != null && durationSeconds! > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Row(
        children: [
          _StatTile(label: 'Arrets', value: '$arretsCount'),
          const _StatDivider(),
          _StatTile(label: 'Colis', value: '$colisTotal'),
          const _StatDivider(),
          _StatTile(
            label: 'Distance',
            value: hasDistance
                ? (distanceMeters! / 1000).toStringAsFixed(1)
                : 'â€”',
            unit: hasDistance ? 'km' : null,
          ),
          const _StatDivider(),
          _StatTile(
            label: 'Duree',
            value: hasDuration ? _formatDuration(durationSeconds!) : 'â€”',
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: context.palette.divider);
}

/// Petit bandeau qui affiche une estimation du cout carburant pour la
/// tournee, base sur le param `coutCarburantLitre` x `consoLitresPar100Km`
/// x la distance totale calculee par ORS. Discret : juste une ligne
/// avec une icone pompe a essence et le montant en EUR.
class _CoutCarburantBanner extends ConsumerWidget {
  const _CoutCarburantBanner({required this.distanceMeters});

  final int distanceMeters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(coutCarburantProvider(distanceMeters));
    final value = async.asData?.value;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        children: [
          Icon(Icons.local_gas_station_outlined, size: 16, color: p.textMute),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              'Cout carburant estime',
              style: TextStyle(fontSize: 12.5, color: p.textMute),
            ),
          ),
          Text(
            value == null ? '...' : _formatEur(value),
            style: appMonoStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatEur(double eur) {
    // Format FR : virgule decimale, symbole EUR a droite, 2 decimales.
    final cents = (eur * 100).round();
    final entier = cents ~/ 100;
    final dec = (cents % 100).toString().padLeft(2, '0');
    return '$entier,$dec EUR';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: appMonoStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(text: value),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: TextStyle(
                        fontSize: 13,
                        color: p.textMute,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: p.textMute,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptimisedBanner extends StatelessWidget {
  const _OptimisedBanner({required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final timeLabel = tournee.optimiseeLe == null
        ? null
        : DateFormat('HH:mm', 'fr').format(tournee.optimiseeLe!);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.bolt, color: p.ink, size: 18),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Itineraire optimise',
                  style: TextStyle(
                    color: p.paper,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (timeLabel != null)
                  Text(
                    'Calcule a $timeLabel',
                    style: TextStyle(
                      color: p.paper.withValues(alpha: 0.65),
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.r6),
              border: Border.all(
                color: AppColors.lime.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'OK',
              style: appMonoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.lime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card "Prochain arret" affichee en haut de l'ecran pendant que la
/// tournee est en cours. Met en avant le 1er arret encore "a livrer"
/// dans l'ordre optimise, avec :
/// - Distance vol d'oiseau live depuis la position GPS du chauffeur.
/// - Boutons rapides Maps / Waze.
/// - Tap sur la card -> bottom sheet d'action (livre / echec / details).
class _ProchainArretCard extends ConsumerWidget {
  const _ProchainArretCard({required this.stops});

  final List<Stop> stops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    Stop? candidat;
    for (final s in stops) {
      if (s.statutLivraison == 'a_livrer' &&
          s.lat != null &&
          s.lng != null) {
        candidat = s;
        break;
      }
    }
    if (candidat == null) {
      // Tous valides ou pas de coords : on n'affiche rien (le
      // _ProgressBanner / la liste suffisent).
      return const SizedBox.shrink();
    }
    // Promotion non-null : variable `final` apres l'early return.
    final prochain = candidat;
    final lat = prochain.lat!;
    final lng = prochain.lng!;

    final positionAsync = ref.watch(currentPositionProvider);
    final distanceLabel = positionAsync.maybeWhen(
      data: (pos) {
        if (pos == null) return null;
        final m = LocationService.distanceMeters(
          fromLat: pos.latitude,
          fromLng: pos.longitude,
          toLat: lat,
          toLng: lng,
        );
        return _formatDistanceMeters(m);
      },
      orElse: () => null,
    );

    final nom = (prochain.nomClient ?? '').trim();
    final hasNom = nom.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                ),
                child: Text(
                  'PROCHAIN',
                  style: appMonoStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (distanceLabel != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      color: AppColors.lime,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distanceLabel,
                      style: appMonoStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lime,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          if (hasNom)
            Text(
              nom,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: p.paper,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasNom) const SizedBox(height: 2),
          Text(
            prochain.adresseNormalisee ?? prochain.adresseBrute,
            style: TextStyle(
              fontSize: hasNom ? 13 : 16,
              color: p.paper.withValues(alpha: hasNom ? 0.7 : 1),
              fontWeight: hasNom ? FontWeight.w500 : FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.paper,
                    foregroundColor: p.ink,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => NavigationService.launchGoogleMaps(
                    lat: lat,
                    lng: lng,
                  ),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text(
                    'Maps',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.paper,
                    foregroundColor: p.ink,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => NavigationService.launchWaze(
                    lat: lat,
                    lng: lng,
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text(
                    'Waze',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
          // Bouton "Livre" gros et direct : mode livraison rapide ;
          // pas besoin d'ouvrir la bottom sheet pour valider l'arret.
          // Capture la position GPS comme preuve et passe au prochain.
          const SizedBox(height: AppSpacing.x10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
              foregroundColor: p.paper,
              minimumSize: const Size(double.infinity, 48),
            ),
            onPressed: () => _markLivreFromCard(context, ref, prochain),
            icon: const Icon(Icons.check_circle, size: 20),
            label: const Text(
              'Marquer livre',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _markLivreFromCard(
    BuildContext context,
    WidgetRef ref,
    Stop stop,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    // Capture GPS best-effort en parallele du markLivre (4 s max).
    ({double lat, double lng})? pos;
    try {
      final ok = await LocationService.ensurePermission();
      if (ok) {
        final p = await LocationService.currentPosition()
            .timeout(const Duration(seconds: 4));
        pos = (lat: p.latitude, lng: p.longitude);
      }
    } catch (_) {/* best-effort */}

    await ref.read(stopsRepositoryProvider).markLivre(stop.id, position: pos);

    // Bascule auto en 'terminee' si tous les arrets ont un statut.
    // Meme logique que _TourneeDuJourScreenState._maybeFinishTournee
    // (qu'on duplique ici car cette methode est static).
    final stopsRepo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);
    final allStops = await stopsRepo.getByTournee(stop.tourneeId);
    final tousValides = allStops.isNotEmpty &&
        allStops.every((s) =>
            s.statutLivraison == 'livre' || s.statutLivraison == 'echec');
    if (tousValides) {
      await tourneesRepo.update(
        stop.tourneeId,
        const TourneesCompanion(statut: Value('terminee')),
      );
      // Bascule automatique vers terminee : on annule le rappel s'il
      // y en avait un.
      await NotificationsService.instance
          .cancelTourneeRappel(stop.tourneeId);
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          stop.nomClient?.isNotEmpty == true
              ? '${stop.nomClient} marque livre'
              : 'Arret marque livre',
        ),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  static String _formatDistanceMeters(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }
}

/// Pile de FloatingActionButtons en bas a droite. Le bouton du bas est
/// 'Ajouter un arret' (toujours present). Au-dessus, selon le statut
/// de la tournee :
/// - 'optimisee' : 'Demarrer' (vert lime).
/// - 'en_cours'  : 'Pause' (amber).
/// - autres : aucun bouton supplementaire.
class _Fabs extends StatelessWidget {
  const _Fabs({
    required this.tournee,
    required this.onAjouter,
    required this.onDemarrer,
    required this.onArreter,
  });

  final Tournee tournee;
  final VoidCallback onAjouter;
  final VoidCallback onDemarrer;
  final VoidCallback onArreter;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isOptimisee = tournee.statut == 'optimisee';
    final isEnCours = tournee.statut == 'en_cours';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isOptimisee)
          FloatingActionButton.extended(
            heroTag: 'fab-demarrer',
            backgroundColor: AppColors.lime,
            foregroundColor: p.ink,
            onPressed: onDemarrer,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Demarrer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        if (isEnCours)
          FloatingActionButton.extended(
            heroTag: 'fab-arreter',
            backgroundColor: AppColors.amber,
            foregroundColor: p.ink,
            onPressed: onArreter,
            icon: const Icon(Icons.pause_rounded),
            label: const Text(
              'Pause',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        if (isOptimisee || isEnCours) const SizedBox(height: AppSpacing.x10),
        FloatingActionButton.extended(
          heroTag: 'fab-ajouter',
          onPressed: onAjouter,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un arret'),
        ),
      ],
    );
  }
}

/// Bandeau de progression / bilan qui s'affiche des qu'au moins un
/// arret a un statut definitif. Quand toute la tournee est terminee,
/// passe en mode "Tournee terminee" avec un fond vert.
class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({
    required this.stops,
    required this.tourneeTerminee,
    this.demareeLe,
  });

  final List<Stop> stops;
  final bool tourneeTerminee;

  /// Timestamp du tap "Demarrer" pour calculer le temps ecoule depuis.
  /// Null = tournee jamais demarree (pas d'affichage dans le bandeau).
  final DateTime? demareeLe;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final livres =
        stops.where((s) => s.statutLivraison == 'livre').length;
    final echecs = stops.where((s) => s.statutLivraison == 'echec').length;
    final total = stops.length;
    final restants = total - livres - echecs;
    final colisLivres = stops
        .where((s) => s.statutLivraison == 'livre')
        .fold<int>(0, (sum, s) => sum + s.nbColis);
    final colisTotal = stops.fold<int>(0, (sum, s) => sum + s.nbColis);

    final bg = tourneeTerminee ? AppColors.emerald : p.paper;
    final fg = tourneeTerminee ? p.paper : p.ink;
    final mute = tourneeTerminee
        ? p.paper.withValues(alpha: 0.75)
        : p.textMute;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: tourneeTerminee
            ? null
            : Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tourneeTerminee
                    ? Icons.flag
                    : Icons.local_shipping_outlined,
                color: fg,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tourneeTerminee
                          ? 'Tournee terminee'
                          : 'Avancement : $livres / $total',
                      style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (demareeLe != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          'Demarree il y a ${_formatElapsed(demareeLe!)}',
                          style: appMonoStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: mute,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (colisTotal > 0)
                Text(
                  '$colisLivres / $colisTotal colis',
                  style: appMonoStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tourneeTerminee ? AppColors.lime : AppColors.emerald,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          // Barre de progression simple : 3 segments empiles.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (livres > 0)
                    Expanded(
                      flex: livres,
                      child: Container(
                        color: tourneeTerminee
                            ? AppColors.lime
                            : AppColors.emerald,
                      ),
                    ),
                  if (echecs > 0)
                    Expanded(flex: echecs, child: Container(color: AppColors.red)),
                  if (restants > 0)
                    Expanded(
                      flex: restants,
                      child: Container(
                        color: tourneeTerminee
                            ? p.paper.withValues(alpha: 0.2)
                            : p.creamSoft,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Wrap(
            spacing: AppSpacing.x14,
            runSpacing: AppSpacing.x4,
            children: [
              _ProgressStat(
                icon: Icons.check_circle,
                color: tourneeTerminee ? AppColors.lime : AppColors.emerald,
                label: '$livres livres',
                fg: fg,
                mute: mute,
              ),
              _ProgressStat(
                icon: Icons.cancel,
                color: AppColors.red,
                label: '$echecs echecs',
                fg: fg,
                mute: mute,
              ),
              if (!tourneeTerminee)
                _ProgressStat(
                  icon: Icons.schedule,
                  color: AppColors.amber,
                  label: '$restants a livrer',
                  fg: fg,
                  mute: mute,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Formate la duree ecoulee depuis [start] sous forme courte :
  /// "8 min", "1h32", "2j 4h". Pas de secondes, on rafraichit la
  /// minute pres au prochain rebuild.
  static String _formatElapsed(DateTime start) {
    final d = DateTime.now().difference(start);
    if (d.inMinutes < 1) return 'moins d\'une min';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inDays < 1) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return '${h}h${m.toString().padLeft(2, '0')}';
    }
    final j = d.inDays;
    final h = d.inHours % 24;
    return '${j}j ${h}h';
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.fg,
    required this.mute,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Color fg;
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StopsPlaceholder extends StatelessWidget {
  const _StopsPlaceholder();

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

class _StopsList extends ConsumerStatefulWidget {
  const _StopsList({required this.stops, this.reorderable = true});

  final List<Stop> stops;

  /// Quand `false` (typiquement pendant une recherche), le drag-and-drop
  /// est desactive : la poignee `drag_handle` est masquee et la liste
  /// utilise un simple `ListView` au lieu de `ReorderableListView`.
  /// L'ordre n'a pas de sens sur une liste filtree.
  final bool reorderable;

  @override
  ConsumerState<_StopsList> createState() => _StopsListState();
}

class _StopsListState extends ConsumerState<_StopsList> {
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
  void didUpdateWidget(_StopsList oldWidget) {
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
      // est un simple ListView ; chaque _StopRow recoit `showDragHandle:
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
              _StopRow(
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
          return _StopRow(
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
      await ref.read(stopsRepositoryProvider).delete(stop.id);
      await ref
          .read(tourneesRepositoryProvider)
          .invalidateOptimization(stop.tourneeId);
    }
  }
}

class _StopRow extends ConsumerWidget {
  const _StopRow({
    super.key,
    required this.stop,
    required this.index,
    required this.dragIndex,
    required this.onDelete,
    this.showDragHandle = true,
  });

  final Stop stop;
  final int index;
  /// Index dans la `ReorderableListView` parent. Utilise pour wrapper
  /// la poignee de drag (icone `drag_handle`) dans un
  /// `ReorderableDragStartListener` qui demarre le drag uniquement
  /// quand on tape sur cette poignee (et pas sur le reste de la card,
  /// qui ouvre la bottom sheet).
  final int dragIndex;
  final VoidCallback onDelete;

  /// Mis a false pendant une recherche (la liste est filtree, l'ordre
  /// n'a pas de sens) : on cache la poignee de drag.
  final bool showDragHandle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tags = _buildTags(stop, p);
    final isLivre = stop.statutLivraison == 'livre';
    final isEchec = stop.statutLivraison == 'echec';
    return Dismissible(
      key: ValueKey('stop-${stop.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.red.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x22),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: () => _onTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x14,
            vertical: AppSpacing.x14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IndexChip(
                index: index,
                priorite: stop.priorite,
                statut: stop.statutLivraison,
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _primaryLine(stop),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isLivre ? p.textMute : p.ink,
                        decoration:
                            isLivre ? TextDecoration.lineThrough : null,
                        decorationColor: p.textMute,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_secondaryLine(stop) != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _secondaryLine(stop)!,
                        style: appMonoStyle(
                          fontSize: 11,
                          color: p.textMute,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isEchec) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Echec : ${_humanRaison(stop.raisonEchec)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x8),
                      Wrap(
                        spacing: AppSpacing.x6,
                        runSpacing: AppSpacing.x4,
                        children: tags,
                      ),
                    ],
                  ],
                ),
              ),
              if (showDragHandle)
                ReorderableDragStartListener(
                  index: dragIndex,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.x6,
                      vertical: AppSpacing.x10,
                    ),
                    child: Icon(
                      Icons.drag_handle,
                      color: p.textFaint,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);

    final action = await StopActionSheet.show(context, stop);
    if (action == null) return;
    var statutChange = false;
    switch (action) {
      case MarkLivreAction():
        final pos = await _captureGpsPosition();
        await repo.markLivre(stop.id, position: pos);
        statutChange = true;
        messenger.showSnackBar(
          SnackBar(
            content: Text('${_primaryLine(stop)} marque livre'),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
          ),
        );
      case MarkEchecAction(raison: final r):
        final pos = await _captureGpsPosition();
        await repo.markEchec(stop.id, r, position: pos);
        statutChange = true;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                '${_primaryLine(stop)} en echec : ${_humanRaison(r)}'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      case MarkAaLivrerAction():
        await repo.markAaLivrer(stop.id);
        statutChange = true;
      case OpenDetailsAction():
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => AjoutArretScreen(
              tourneeId: stop.tourneeId,
              initial: stop,
            ),
          ),
        );
    }

    if (statutChange) {
      await _maybeFinishTournee(repo, tourneesRepo, stop.tourneeId);
    }
  }

  /// Verifie si tous les arrets ont un statut definitif (livre / echec)
  /// et bascule la tournee en 'terminee' le cas echeant. Si on annule
  /// un statut, on revient a 'optimisee' / 'en_cours'.
  Future<void> _maybeFinishTournee(
    StopsRepository stopsRepo,
    TourneesRepository tourneesRepo,
    int tourneeId,
  ) async {
    final stops = await stopsRepo.getByTournee(tourneeId);
    if (stops.isEmpty) return;
    final tournee = await tourneesRepo.getById(tourneeId);
    if (tournee == null) return;
    final tousValides = stops.every(
      (s) => s.statutLivraison == 'livre' || s.statutLivraison == 'echec',
    );
    final wasTerminee = tournee.statut == 'terminee';
    if (tousValides && !wasTerminee) {
      await tourneesRepo.update(
        tourneeId,
        const TourneesCompanion(statut: Value('terminee')),
      );
    } else if (!tousValides && wasTerminee) {
      // L'utilisateur a annule un statut deja pose. On retire la
      // marque "terminee" pour qu'il finisse la tournee.
      await tourneesRepo.update(
        tourneeId,
        const TourneesCompanion(statut: Value('optimisee')),
      );
    }
  }

  static String _humanRaison(String? r) {
    return switch (r) {
      'absent' => 'absent',
      'refuse' => 'refuse',
      'adresse_fausse' => 'adresse fausse',
      'autre' => 'autre',
      _ => 'sans raison',
    };
  }

  /// Best-effort : retourne la position GPS actuelle pour servir de
  /// preuve de passage. Si la permission n'a pas ete accordee ou si
  /// le GPS est down (offline, batterie faible, indoors), retourne
  /// null -- on stocke quand meme le statut sans coords.
  ///
  /// Timeout court (4 s) : on ne veut pas bloquer l'UX pendant que
  /// Noah enchaine les "Marquer livre" en sortant des voitures.
  static Future<({double lat, double lng})?> _captureGpsPosition() async {
    try {
      final ok = await LocationService.ensurePermission();
      if (!ok) return null;
      final pos = await LocationService.currentPosition()
          .timeout(const Duration(seconds: 4));
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return null;
    }
  }

  String _primaryLine(Stop s) {
    if (s.nomClient != null && s.nomClient!.isNotEmpty) {
      return s.nomClient!;
    }
    return s.adresseBrute.split(',').first.trim();
  }

  String? _secondaryLine(Stop s) {
    if (s.nomClient != null && s.nomClient!.isNotEmpty) {
      return s.adresseBrute.split(',').take(2).join(',').trim();
    }
    if (s.notes != null && s.notes!.isNotEmpty) return s.notes;
    return null;
  }

  List<Widget> _buildTags(Stop s, AppPalette p) {
    final out = <Widget>[];
    final priority = _priorityTag(s.priorite);
    if (priority != null) out.add(priority);
    // Stop sans coordonnees (mode hors-ligne, geocodage echoue) : tag
    // amber bien visible "GPS manquant" pour rappeler que cet arret ne
    // sera pas pris en compte dans l'optimisation.
    if (s.lat == null || s.lng == null) {
      out.add(const _Tag(
        label: 'GPS manquant',
        bg: AppColors.amber,
        fg: AppColors.ink,
      ));
    }
    if (s.nbColis > 1) {
      out.add(_Tag(
        label: '${s.nbColis} colis',
        bg: p.creamSoft,
        fg: p.ink,
      ));
    }
    if (s.fenetreDebut != null || s.fenetreFin != null) {
      final start = s.fenetreDebut ?? '--:--';
      final end = s.fenetreFin ?? '--:--';
      out.add(_Tag(
        label: '$start â†’ $end',
        bg: const Color(0x33F2A341),
        fg: const Color(0xFF7A4F0E),
        mono: true,
      ));
    }
    return out;
  }

  Widget? _priorityTag(String priorite) {
    return switch (priorite) {
      'obligatoire_premier' => const _Tag(
          label: 'En 1er',
          bg: AppColors.lime,
          fg: AppColors.ink,
        ),
      'obligatoire_dernier' => const _Tag(
          label: 'En dernier',
          bg: AppColors.lime,
          fg: AppColors.ink,
        ),
      'eviter_si_possible' => _Tag(
          label: 'Eviter',
          bg: AppColors.amber.withValues(alpha: 0.25),
          fg: const Color(0xFF7A4F0E),
        ),
      _ => null,
    };
  }
}

class _IndexChip extends StatelessWidget {
  const _IndexChip({
    required this.index,
    required this.priorite,
    this.statut = 'a_livrer',
  });

  final int index;
  final String priorite;
  final String statut;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (statut == 'livre') {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.emerald,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.check, color: p.paper, size: 20),
      );
    }
    if (statut == 'echec') {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.red,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.close, color: p.paper, size: 20),
      );
    }
    final isActive =
        priorite == 'obligatoire_premier' || priorite == 'obligatoire_dernier';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? p.ink : p.paper,
        border: Border.all(color: p.ink, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: appMonoStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.lime : p.ink,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.bg,
    required this.fg,
    this.mono = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final style = mono
        ? appMonoStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)
        : TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.4,
          );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label.toUpperCase(),
        style: style,
      ),
    );
  }
}
