import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/database.dart';
import '../../data/location_service.dart';
import '../../data/notifications_service.dart';
import '../../data/preuve_photo_service.dart';
import '../../data/stop_types.dart';
import '../../data/stops_repository.dart';
import '../../data/tournees_repository.dart';
import '../../data/tracking_codes_repository.dart';
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/stop_action_sheet.dart';
import '../ajout_arret_screen.dart';
import '../preuve_photo_viewer_screen.dart';
import 'stop_row_visuals.dart';

/// ════════════════════════════════════════════════════════════════
/// Dispatcher des actions disponibles sur un [StopRow].
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `stop_row.dart` (carte Trello #150). Concentre les
/// 15 actions du sealed [StopAction] + le swipe livre + le dialog
/// preview (long-press). Pas d'etat -- juste un wrapper autour d'un
/// [Stop] qui expose 3 entry points :
///   - [handleSwipeLivre] : swipe gauche -> droite marque livre
///   - [handleTap] : ouvre la bottom sheet + dispatch l'action
///   - [showPreviewDialog] : dialog long-press (carte #96)
///
/// Toutes les operations sont async + best-effort : on capture la
/// position GPS avec timeout 4s, on log les erreurs en SnackBar
/// humanise, et on auto-bascule la tournee en `terminee` quand tous
/// les stops ont un statut definitif.
class StopRowActions {
  const StopRowActions(this.stop);

  final Stop stop;

  Future<void> handleSwipeLivre(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);
    final pos = await _captureGpsPosition();
    await repo.markLivre(stop.id, position: pos);
    if (!context.mounted) return;
    unawaited(HapticFeedback.mediumImpact());
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${_primaryLine(stop)} '
          'marque ${stopActionVerbParticipe(stop.type)}',
        ),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Photo preuve',
          textColor: AppColors.ink,
          onPressed: () => _capturerPreuve(ref, stop.id),
        ),
      ),
    );
    await _maybeFinishTournee(repo, tourneesRepo, stop.tourneeId);
  }

  Future<void> handleTap(BuildContext context, WidgetRef ref) async {
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
        // Vibration courte de confirmation : terrain gants l'hiver,
        // Noah ne regarde pas toujours l'ecran apres avoir tape.
        unawaited(HapticFeedback.mediumImpact());
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_primaryLine(stop)} '
              'marque ${stopActionVerbParticipe(stop.type)}',
            ),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Photo preuve',
              textColor: AppColors.ink,
              onPressed: () => _capturerPreuve(ref, stop.id),
            ),
          ),
        );
      case MarkEchecAction(raison: final r):
        final pos = await _captureGpsPosition();
        await repo.markEchec(stop.id, r, position: pos);
        statutChange = true;
        // Vibration plus marquee qu'un livre OK : signal "attention,
        // statut negatif".
        unawaited(HapticFeedback.heavyImpact());
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_primaryLine(stop)} '
              '${stop.type == kStopTypeRamasse ? "pas ramasse" : "en echec"} '
              ': ${_humanRaison(r)}',
            ),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Photo preuve',
              textColor: AppColors.paper,
              onPressed: () => _capturerPreuve(ref, stop.id),
            ),
          ),
        );
      case MarkAaLivrerAction():
        await repo.markAaLivrer(stop.id);
        statutChange = true;
        unawaited(HapticFeedback.lightImpact());
      case TakePreuvePhotoAction():
        await _capturerPreuve(ref, stop.id);
      case ViewPreuvePhotoAction():
        final path = stop.preuvePhotoPath;
        if (path == null) return;
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => PreuvePhotoViewerScreen(photoPath: path),
          ),
        );
      case CopyAdresseAction():
        final adresse = stop.adresseNormalisee ?? stop.adresseBrute;
        await Clipboard.setData(ClipboardData(text: adresse));
        unawaited(HapticFeedback.lightImpact());
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Adresse copiee'),
            backgroundColor: AppColors.emerald,
            duration: Duration(seconds: 2),
          ),
        );
      case ShareAdresseAction():
        final adresse = stop.adresseNormalisee ?? stop.adresseBrute;
        await SharePlus.instance.share(
          ShareParams(text: adresse, subject: 'Adresse de livraison'),
        );
      case GenerateTrackingLinkAction():
        final trackingRepo = ref.read(trackingCodesRepositoryProvider);
        try {
          final tc = await trackingRepo.generateForStop(stop.id);
          final url = TrackingCodesRepository.buildUrl(tc.code);
          // Carte #81 : pousse le code au cloud pour que l'Edge Function
          // `track` puisse resoudre le lien. Best-effort silencieux (no-op
          // si pas connecte / stop pas encore sync / function pas deployee).
          try {
            await ref
                .read(cloudSyncServiceProvider)
                .pushTrackingCode(tc.code, stop.id);
          } on Object {/* offline / stop pas sync : lien local quand meme */}
          await Clipboard.setData(ClipboardData(text: url));
          unawaited(HapticFeedback.lightImpact());
          messenger.showSnackBar(
            SnackBar(
              content: Text('Lien tracking copie : $url'),
              backgroundColor: AppColors.emerald,
              duration: const Duration(seconds: 4),
            ),
          );
        } catch (e) {
          messenger.showSnackBar(
            SnackBar(
              content:
                  Text('Generation lien echouee : ${humanizeAnyError(e)}'),
              backgroundColor: AppColors.red,
            ),
          );
        }
      case OpenInMapsAction():
        final adresse = stop.adresseNormalisee ?? stop.adresseBrute;
        final uri = Uri.parse(
          'https://www.google.com/maps/search/?api=1'
          '&query=${Uri.encodeComponent(adresse)}',
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      case OpenStreetviewAction():
        final lat = stop.lat;
        final lng = stop.lng;
        if (lat == null || lng == null) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text(
                'Adresse pas encore geocodee, Street View indisponible',
              ),
              backgroundColor: AppColors.amber,
              duration: Duration(seconds: 3),
            ),
          );
          return;
        }
        final uri = Uri.parse(
          'https://www.google.com/maps/@?api=1'
          '&map_action=pano&viewpoint=$lat,$lng',
        );
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      case OpenDetailsAction():
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => AjoutArretScreen(
              tourneeId: stop.tourneeId,
              initial: stop,
            ),
          ),
        );
      case ConvertTypeAction(newType: final newType):
        await repo.setType(stop.id, newType);
        unawaited(HapticFeedback.lightImpact());
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              '${_primaryLine(stop)} converti en '
              '${newType == kStopTypeRamasse ? "ramasse" : "livraison"}',
            ),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
          ),
        );
      case ToggleLockPositionAction(locked: final locked):
        await repo.setPositionLocked(stop.id, locked);
        unawaited(HapticFeedback.lightImpact());
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              locked
                  ? '${_primaryLine(stop)} verrouille a cette position'
                  : '${_primaryLine(stop)} deverrouille',
            ),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
          ),
        );
      case MoveToTourneeAction(targetTourneeId: final targetId):
        // Deplace le stop vers la tournee choisie. On invalide
        // l'optim VROOM des 2 tournees (source + dest), puis on
        // relance l'auto-reorder local sur les 2.
        final sourceTourneeId = stop.tourneeId;
        await repo.moveToTournee(stop.id, targetId);
        await tourneesRepo.invalidateOptimization(sourceTourneeId);
        await tourneesRepo.invalidateOptimization(targetId);
        await ref.read(localReorderServiceProvider).reorder(sourceTourneeId);
        await ref.read(localReorderServiceProvider).reorder(targetId);
        unawaited(HapticFeedback.mediumImpact());
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                '${_primaryLine(stop)} deplace vers une autre tournee'),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 3),
          ),
        );
    }

    if (statutChange) {
      await _maybeFinishTournee(repo, tourneesRepo, stop.tourneeId);
    }
  }

  /// Carte Trello #96 : preview rapide d'un stop sans engager d'action.
  /// Long-press sur la row -> dialog modal compact avec nom, adresse,
  /// nb colis, fenetre horaire, notes. Boutons :
  /// - "Fermer" : juste pop
  /// - "Actions" : pop puis ouvre la bottom sheet d'actions classique
  ///
  /// Use case : verifier les notes (code interphone) ou l'horaire
  /// fenetre avant de descendre du vehicule, sans risquer de valider
  /// un statut par erreur.
  Future<void> showPreviewDialog(
      BuildContext context, WidgetRef ref) async {
    unawaited(HapticFeedback.lightImpact());
    final p = context.palette;
    final adresse = stop.adresseNormalisee ?? stop.adresseBrute;
    final nom = stop.nomClient?.trim();
    final fenetreDebut = stop.fenetreDebut;
    final fenetreFin = stop.fenetreFin;
    final notes = stop.notes?.trim();
    final ouvrirActions = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: p.paper,
        title: Text(
          (nom != null && nom.isNotEmpty) ? nom : _primaryLine(stop),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PreviewRow(icon: Icons.place_outlined, text: adresse),
            const SizedBox(height: AppSpacing.x8),
            PreviewRow(
              icon: Icons.inventory_2_outlined,
              text: '${stop.nbColis} colis '
                  '(${stop.type == kStopTypeRamasse ? "ramasse" : "livraison"})',
            ),
            if (fenetreDebut != null && fenetreFin != null) ...[
              const SizedBox(height: AppSpacing.x8),
              PreviewRow(
                icon: Icons.schedule_outlined,
                text: 'Fenetre $fenetreDebut - $fenetreFin',
              ),
            ],
            if (notes != null && notes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x8),
              PreviewRow(icon: Icons.notes_outlined, text: notes),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Fermer'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Actions'),
          ),
        ],
      ),
    );
    if (ouvrirActions == true && context.mounted) {
      await handleTap(context, ref);
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
      // Notif post-tournee : recap livres / echecs / duree.
      final nbLivres = stops.where((s) => s.statutLivraison == 'livre').length;
      final nbEchecs = stops.where((s) => s.statutLivraison == 'echec').length;
      final dureeMin = (tournee.dureeTotaleS ?? 0) ~/ 60;
      unawaited(
        NotificationsService.instance.showEndOfRouteSummary(
          tourneeId: tourneeId,
          nomTournee: tournee.nom,
          nbLivres: nbLivres,
          nbEchecs: nbEchecs,
          dureeTotaleMin: dureeMin,
        ),
      );
      // Si un rappel matin etait programme et toujours pendant, on
      // l'annule (la tournee est faite).
      unawaited(NotificationsService.instance.cancelTourneeRappel(tourneeId));
      // Idem pour le rappel "tournee non terminee >8h" (#121).
      unawaited(NotificationsService.instance
          .cancelTourneeNonTermineeReminder(tourneeId));
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

  /// Lance la camera pour capturer une photo preuve, puis attache le
  /// chemin au stop. Best-effort : si l'utilisateur annule ou que la
  /// permission camera est refusee, on ne fait rien.
  Future<void> _capturerPreuve(WidgetRef ref, int stopId) async {
    final path = await PreuvePhotoService().capturer(stopId: stopId);
    if (path == null) return;
    await ref.read(stopsRepositoryProvider).setPreuvePhoto(stopId, path);
    // Bypass du debounce 5s : si Noah ferme l'ecran tournee dans la
    // foulee (typique apres validation livraison via SnackBar), le
    // dispose appelle cloudAutoPushService.stop() qui cancel le timer
    // sans push. Le flush() pousse maintenant pour ne pas perdre la
    // photo cote cloud (bug Trello #69). No-op si pas connecte ou
    // si rien en attente.
    await ref.read(cloudAutoPushServiceProvider).flush();
  }

  String _primaryLine(Stop s) {
    if (s.nomClient != null && s.nomClient!.isNotEmpty) {
      return s.nomClient!;
    }
    return s.adresseBrute.split(',').first.trim();
  }
}
