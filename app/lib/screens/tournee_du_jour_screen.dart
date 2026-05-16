import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../data/cloud_sync_service.dart';
import '../data/database.dart';
import '../data/location_service.dart';
import '../data/navigation_service.dart';
import '../data/notifications_service.dart';
import '../data/tile_prefetch_service.dart';
import '../data/tournee_pdf_service.dart';
import '../data/tournee_text_share_service.dart';
import '../providers/geocoding_providers.dart';
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
      case PlusAction.delete:
        _confirmDeleteTournee();
    }
  }

  Future<void> _onPushCloudPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    final service = ref.read(cloudSyncServiceProvider);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Sync en cours...'),
        duration: Duration(seconds: 10),
      ),
    );
    try {
      await service.pushTournee(widget.tournee.id);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tournee synchronisee au cloud'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } on CloudSyncException catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
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

