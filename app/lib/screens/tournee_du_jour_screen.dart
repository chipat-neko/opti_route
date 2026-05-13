import 'dart:async';
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
import '../data/tournee_pdf_service.dart';
import '../data/tournee_text_share_service.dart';
import '../providers/geocoding_providers.dart';
import '../providers/database_providers.dart';
import '../providers/location_providers.dart';
import '../providers/optimization_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import '../widgets/ordre_priorite_dialog.dart';
import 'ajout_arret_screen.dart';
import 'carte_screen.dart';
import 'parametres_screen.dart';
import 'tournee_du_jour/banners.dart';
import 'tournee_du_jour/progress_banner.dart';
import 'tournee_du_jour/stat_row.dart';
import 'tournee_du_jour/stop_row.dart';
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
    // Bouton grisé tant que `optimiseeLe != null` : la tournée est déjà
    // optimisée et rien n'a changé depuis. Toute modif structurelle
    // (add/edit/delete arret, point de depart change) appelle
    // `invalidateOptimization` qui remet `optimiseeLe = null` et
    // ré-active le bouton.
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
              if (value == 'export_pdf_co') _onExportPdfPerCoequipierPressed();
              if (value == 'share_text') _onShareTextPressed();
              if (value == 'share_to_coequipier') {
                _onShareToCoequipierPressed();
              }
              if (value == 'assign_rest') _onAssignRestPressed();
              if (value == 'pause_short') _onPauseShortPressed();
              if (value == 'batch_livre') _onBatchLivrePressed();
              if (value == 'retry_geocode') _onRetryGeocodePressed();
              if (value == 'undo_last') _onUndoLastStatusPressed();
              if (value == 'duplicate_plus7') _onDuplicatePlus7Pressed();
            },
            itemBuilder: (_) => [
              if (widget.tournee.statut == 'en_cours')
                PopupMenuItem(
                  value: 'pause_short',
                  child: ListTile(
                    leading: Icon(
                      widget.tournee.pauseeLe == null
                          ? Icons.pause_circle_outline
                          : Icons.play_circle_outline,
                      color: AppColors.amber,
                    ),
                    title: Text(
                      widget.tournee.pauseeLe == null
                          ? 'Pause courte (pause dejeuner)'
                          : 'Reprendre la tournee',
                    ),
                    subtitle: const Text(
                      'Met le chrono en pause sans arreter la tournee',
                      style: TextStyle(fontSize: 11),
                    ),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
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
              const PopupMenuItem(
                value: 'share_to_coequipier',
                child: ListTile(
                  leading: Icon(Icons.groups_outlined),
                  title: Text('Partager a un coequipier'),
                  subtitle: Text(
                    'Envoie seulement ses arrets affectes',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'assign_rest',
                child: ListTile(
                  leading: Icon(Icons.assignment_ind_outlined),
                  title: Text('Affecter le reste a...'),
                  subtitle: Text(
                    'Bulk : tous les arrets non affectes a un coequipier',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf_outlined),
                  title: Text('Exporter en PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_pdf_co',
                child: ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Exporter PDF par coequipier'),
                  subtitle: Text(
                    'Fiche individuelle (un PDF par personne)',
                    style: TextStyle(fontSize: 11),
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
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
      // et basculer sur l'empty state  -  pas besoin de pop manuellement.
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
      // Profil entreprise (optionnel) : ajoute un footer "nom + SIRET +
      // slogan" en bas de chaque page du PDF.
      final paramsRepo = ref.read(parametresRepositoryProvider);
      final entrepriseNom = await paramsRepo.getEntrepriseNom();
      final entrepriseSiret = await paramsRepo.getEntrepriseSiret();
      final entrepriseSlogan = await paramsRepo.getEntrepriseSlogan();
      await service.exportAndShare(
        tournee: widget.tournee,
        stops: stops,
        coutCarburantEur: cout,
        entrepriseNom: entrepriseNom,
        entrepriseSiret: entrepriseSiret,
        entrepriseSlogan: entrepriseSlogan,
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'export PDF : $e')),
      );
    }
  }

  /// Export un PDF par coequipier present dans la tournee (Moi + chaque
  /// affecte). Genere N fichiers et lance N partages successifs. Le
  /// chef peut ainsi envoyer une fiche dediee a chaque livreur.
  Future<void> _onExportPdfPerCoequipierPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stops =
          await ref.read(stopsRepositoryProvider).getByTournee(widget.tournee.id);
      // Set des cles : null + ids presents
      final keys = <int?>{};
      for (final s in stops) {
        keys.add(s.coequipierId);
      }
      if (keys.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Aucun arret a exporter.')),
        );
        return;
      }
      if (keys.length == 1) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Tous les arrets ont la meme affectation. Utilise '
              '"Exporter en PDF" classique.',
            ),
          ),
        );
        return;
      }

      // Resolution noms coequipiers
      final coRepo = ref.read(coequipiersRepositoryProvider);
      final coequipiers = await coRepo.getAllActifs();
      final byId = {for (final c in coequipiers) c.id: c};

      final paramsRepo = ref.read(parametresRepositoryProvider);
      final entrepriseNom = await paramsRepo.getEntrepriseNom();
      final entrepriseSiret = await paramsRepo.getEntrepriseSiret();
      final entrepriseSlogan = await paramsRepo.getEntrepriseSlogan();
      double? cout;
      if (widget.tournee.distanceTotaleM != null &&
          widget.tournee.distanceTotaleM! > 0) {
        cout = await paramsRepo.estimerCoutCarburant(
          distanceMeters: widget.tournee.distanceTotaleM!,
        );
      }

      final service = TourneePdfService();
      for (final key in keys) {
        final nom = key == null ? 'Moi' : (byId[key]?.nom ?? 'Coequipier #$key');
        await service.exportForCoequipier(
          tournee: widget.tournee,
          allStops: stops,
          coequipierIdOrNull: key,
          coequipierNom: nom,
          coutCarburantEur: cout,
          entrepriseNom: entrepriseNom,
          entrepriseSiret: entrepriseSiret,
          entrepriseSlogan: entrepriseSlogan,
        );
      }
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${keys.length} PDF generes (1 par coequipier).',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'export PDF equipe : $e')),
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
        // Auto-reorder local : maintenant que les stops ont des coords,
        // ils peuvent participer au nearest-neighbor.
        await ref
            .read(localReorderServiceProvider)
            .reorder(widget.tournee.id);
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

  /// Affiche un selecteur de coequipier, puis genere un text-share
  /// filtre sur ses arrets affectes. Si le coequipier a un numero, on
  /// pre-remplit l'intent vers WhatsApp / SMS via url_launcher.
  Future<void> _onShareToCoequipierPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final p = context.palette;
    final coequipiers =
        await ref.read(coequipiersRepositoryProvider).getAllActifs();
    if (!mounted) return;
    if (coequipiers.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun coequipier. Ajoute-en dans Parametres > Mon equipe.',
          ),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<Coequipier>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x18,
            vertical: AppSpacing.x14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Partager a',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              for (final c in coequipiers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorFromTag(
                      c.colorTag,
                      defaultColor: AppColors.creamSoft,
                    ),
                    child: Text(
                      _coequipierInitials(c.nom),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  title: Text(c.nom),
                  subtitle: c.telephone != null && c.telephone!.isNotEmpty
                      ? Text(c.telephone!)
                      : null,
                  onTap: () => Navigator.of(context).pop(c),
                ),
            ],
          ),
        ),
      ),
    );

    if (picked == null || !mounted) return;

    try {
      final allStops = await ref
          .read(stopsRepositoryProvider)
          .getByTournee(widget.tournee.id);
      final stopsLui =
          allStops.where((s) => s.coequipierId == picked.id).toList();
      if (stopsLui.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Aucun arret affecte a ${picked.nom}. Affecte-lui des '
              'arrets depuis la bottom sheet d\'un arret.',
            ),
          ),
        );
        return;
      }

      final service = TourneeTextShareService(
        parametres: ref.read(parametresRepositoryProvider),
      );
      final text = await service.formatPlainText(
        tournee: widget.tournee,
        stops: stopsLui,
      );
      final preamble =
          'Tes arrets pour ${widget.tournee.nom} (${stopsLui.length}) :\n\n';

      // Si le coequipier a un telephone, on tente WhatsApp d'abord
      // (le scheme `whatsapp://` ouvre l'app si installee), puis SMS.
      // Sinon fallback share natif (Share.share).
      final tel = picked.telephone?.replaceAll(RegExp(r'\D'), '');
      if (tel != null && tel.isNotEmpty) {
        final waUri = Uri.parse(
          'https://wa.me/33${tel.startsWith('0') ? tel.substring(1) : tel}'
          '?text=${Uri.encodeComponent(preamble + text)}',
        );
        final ok = await NavigationService.tryLaunch(waUri);
        if (!ok) {
          // Fallback SMS
          final smsUri = Uri.parse(
            'sms:${picked.telephone}'
            '?body=${Uri.encodeComponent(preamble + text)}',
          );
          await NavigationService.tryLaunch(smsUri);
        }
      } else {
        // Pas de tel : share natif
        await service.shareAsText(
          tournee: widget.tournee,
          stops: stopsLui,
        );
      }
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur au partage : $e')),
      );
    }
  }

  static String _coequipierInitials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  /// Affectation en masse : tous les stops non encore affectes (Moi)
  /// passent au coequipier choisi. Le cas d'usage typique chef d'equipe :
  /// "je m'occupe des 5 premiers, le reste va a Lucas".
  Future<void> _onAssignRestPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final p = context.palette;
    final coequipiers =
        await ref.read(coequipiersRepositoryProvider).getAllActifs();
    if (!mounted) return;
    if (coequipiers.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun coequipier. Ajoute-en dans Parametres > Mon equipe.',
          ),
        ),
      );
      return;
    }
    final stops = await ref
        .read(stopsRepositoryProvider)
        .getByTournee(widget.tournee.id);
    final reste =
        stops.where((s) => s.coequipierId == null).toList(growable: false);
    if (reste.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Tous les arrets ont deja un coequipier affecte.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;
    final picked = await showModalBottomSheet<Coequipier>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x18,
            vertical: AppSpacing.x14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Affecter ${reste.length} arret${reste.length > 1 ? "s" : ""} non affecte${reste.length > 1 ? "s" : ""} a',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              for (final c in coequipiers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorFromTag(
                      c.colorTag,
                      defaultColor: AppColors.creamSoft,
                    ),
                    child: Text(
                      _coequipierInitials(c.nom),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  title: Text(c.nom),
                  onTap: () => Navigator.of(context).pop(c),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked == null || !mounted) return;
    await ref
        .read(stopsRepositoryProvider)
        .setCoequipierForUnassigned(widget.tournee.id, picked.id);
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${reste.length} arret${reste.length > 1 ? "s" : ""} affecte${reste.length > 1 ? "s" : ""} a ${picked.nom}',
        ),
        backgroundColor: AppColors.emerald,
      ),
    );
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
        StatRow(
          arretsCount: stops.length,
          colisTotal: stops.fold<int>(0, (sum, s) => sum + s.nbColis),
          distanceMeters: tournee.distanceTotaleM,
          durationSeconds: tournee.dureeTotaleS,
        ),
        if (tournee.distanceTotaleM != null &&
            tournee.distanceTotaleM! > 0) ...[
          const SizedBox(height: AppSpacing.x8),
          CoutCarburantBanner(distanceMeters: tournee.distanceTotaleM!),
        ],
        if (tournee.statut == 'optimisee') ...[
          const SizedBox(height: AppSpacing.x12),
          OptimisedBanner(tournee: tournee),
        ],
        if (stops.any((s) =>
            s.statutLivraison == 'livre' || s.statutLivraison == 'echec')) ...[
          const SizedBox(height: AppSpacing.x12),
          ProgressBanner(
            stops: stops,
            tourneeTerminee: tournee.statut == 'terminee',
            demareeLe: tournee.demareeLe,
            isEnPause: tournee.pauseeLe != null,
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
      // Auto-reorder local apres suppression d'un stop.
      await ref
          .read(localReorderServiceProvider)
          .reorder(stop.tourneeId);
    }
  }
}

/// Chip de filtre coequipier dans la _StopsSection. Le fond utilise
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
