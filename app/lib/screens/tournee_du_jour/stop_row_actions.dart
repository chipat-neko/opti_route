import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show Clipboard, ClipboardData, HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/database.dart';
import '../../data/mark_livre_service.dart';
import '../../data/preuve_photo_service.dart';
import '../../data/stop_types.dart';
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/signature_pad_dialog.dart';
import '../../widgets/snack.dart';
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
/// [Stop] qui expose 4 entry points :
///   - [handleSwipeLivre] : swipe gauche -> droite marque livre
///   - [handleTap] : ouvre la bottom sheet + dispatch l'action
///   - [markLivreRapide] : "Marquer livre" en 1 tap (boutons des
///     encarts ProchainArretCard / ProximiteBanner)
///   - [showPreviewDialog] : dialog long-press (carte #96)
///
/// Toutes les operations sont async + best-effort : on capture la
/// position GPS avec timeout 4s, on log les erreurs en SnackBar
/// humanise, et on auto-bascule la tournee en `terminee` quand tous
/// les stops ont un statut definitif. La partie base de donnees de ce
/// dernier point (capture GPS + markLivre + cloture) vit dans
/// [MarkLivreService] : ici on ne garde que le retour utilisateur.
class StopRowActions {
  const StopRowActions(this.stop);

  final Stop stop;

  Future<void> handleSwipeLivre(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(stopsRepositoryProvider);
    final markLivreService = ref.read(markLivreServiceProvider);
    final pos = await captureGpsBestEffort();
    await repo.markLivre(stop.id, position: pos);

    // La cloture est lancee AVANT la garde de montage, et volontairement
    // pas attendue tout de suite : elle ne depend pas de l'ecran, alors
    // que le retour utilisateur, lui, en depend.
    //
    // L'ordre inverse (garde puis cloture) avait un trou : swiper le
    // DERNIER arret puis fermer l'ecran dans la foulee faisait sortir
    // sur le `return`, et la tournee ne basculait jamais en 'terminee'
    // -- ni recap de fin de tournee, ni annulation des deux rappels.
    final cloture = markLivreService.syncStatutTournee(stop.tourneeId);

    if (context.mounted) {
      unawaited(HapticFeedback.mediumImpact());
      messenger.showSuccess(
        '${_primaryLine(stop)} '
        'marque ${stopActionVerbParticipe(stop.type)}',
        action: SnackBarAction(
          label: 'Photo preuve',
          textColor: AppColors.ink,
          onPressed: () => _capturerPreuve(ref, stop),
        ),
      );
    }
    await cloture;
  }

  /// "Marquer livre" en 1 tap, sans passer par la bottom sheet : le
  /// bouton des encarts `ProchainArretCard` et `ProximiteBanner`.
  ///
  /// Meme sequence que l'action `MarkLivreAction` de [handleTap]
  /// (signature facultative pendant la capture GPS, puis validation et
  /// cloture eventuelle de la tournee via [MarkLivreService]), mais avec
  /// le retour "mode livraison rapide" : SnackBar court de 2 s, sans
  /// raccourci photo preuve ni vibration -- l'utilisateur regarde
  /// l'ecran, il vient d'appuyer sur un bouton plein ecran.
  Future<void> markLivreRapide(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final markLivreService = ref.read(markLivreServiceProvider);
    await markLivreService.markLivre(
      stop,
      pendantCaptureGps: () async {
        // Signature du destinataire (facultative) -- s'ouvre tout de
        // suite, pendant que le fix GPS se prend en arriere-plan.
        if (context.mounted) {
          await captureSignatureForStop(context, ref, stop.id);
        }
      },
    );
    messenger.showSuccess(
      stop.nomClient?.isNotEmpty == true
          ? '${stop.nomClient} marque livre'
          : 'Arret marque livre',
      duration: const Duration(seconds: 2),
    );
  }

  Future<void> handleTap(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);
    final markLivreService = ref.read(markLivreServiceProvider);

    final action = await StopActionSheet.show(context, stop);
    if (action == null) return;
    var statutChange = false;
    switch (action) {
      case MarkLivreAction():
        // Capture GPS lancee en ARRIERE-PLAN : elle tourne PENDANT que
        // l'utilisateur signe. Avant, on attendait le fix GPS
        // (LocationAccuracy.high, jusqu'a 4s, lent en interieur) AVANT
        // d'ouvrir le canva -> grosse latence d'ouverture. Maintenant le
        // pad s'affiche instantanement et le GPS a le temps de se capturer
        // pendant la signature. Retour Noah dev2 2026-06-03.
        final gpsFuture = captureGpsBestEffort();
        // Signature du destinataire juste apres le "livre" (facultative :
        // l'utilisateur peut passer). Demande Noah 2026-06-03.
        if (context.mounted) {
          await captureSignatureForStop(context, ref, stop.id);
        }
        await repo.markLivre(stop.id, position: await gpsFuture);
        statutChange = true;
        // Vibration courte de confirmation : terrain gants l'hiver,
        // Noah ne regarde pas toujours l'ecran apres avoir tape.
        unawaited(HapticFeedback.mediumImpact());
        messenger.showSuccess(
          '${_primaryLine(stop)} '
          'marque ${stopActionVerbParticipe(stop.type)}',
          action: SnackBarAction(
            label: 'Photo preuve',
            textColor: AppColors.ink,
            onPressed: () => _capturerPreuve(ref, stop),
          ),
        );
      case MarkEchecAction(raison: final r):
        final pos = await captureGpsBestEffort();
        await repo.markEchec(stop.id, r, position: pos);
        statutChange = true;
        // Vibration plus marquee qu'un livre OK : signal "attention,
        // statut negatif".
        unawaited(HapticFeedback.heavyImpact());
        messenger.showError(
          '${_primaryLine(stop)} '
          '${stop.type == kStopTypeRamasse ? "pas ramasse" : "en echec"} '
          ': ${_humanRaison(r)}',
          action: SnackBarAction(
            label: 'Photo preuve',
            textColor: AppColors.paper,
            onPressed: () => _capturerPreuve(ref, stop),
          ),
        );
      case MarkAaLivrerAction():
        await repo.markAaLivrer(stop.id);
        statutChange = true;
        unawaited(HapticFeedback.lightImpact());
      case TakePreuvePhotoAction():
        await _capturerPreuve(ref, stop);
      case ViewPreuvePhotoAction():
        final path = stop.preuvePhotoPath;
        if (path == null) return;
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => PreuvePhotoViewerScreen(photoPath: path),
          ),
        );
      case ViewSignatureAction():
        final path = stop.signaturePath;
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
        messenger.showSuccess(
          'Adresse copiee',
          duration: const Duration(seconds: 2),
        );
      case ShareAdresseAction():
        final adresse = stop.adresseNormalisee ?? stop.adresseBrute;
        await SharePlus.instance.share(
          ShareParams(text: adresse, subject: 'Adresse de livraison'),
        );
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
          messenger.showWarning(
            'Adresse pas encore geocodee, Street View indisponible',
            duration: const Duration(seconds: 3),
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
        messenger.showSuccess(
          '${_primaryLine(stop)} converti en '
          '${newType == kStopTypeRamasse ? "ramasse" : "livraison"}',
          duration: const Duration(seconds: 2),
        );
      case ToggleLockPositionAction(locked: final locked):
        await repo.setPositionLocked(stop.id, locked);
        unawaited(HapticFeedback.lightImpact());
        messenger.showSuccess(
          locked
              ? '${_primaryLine(stop)} verrouille a cette position'
              : '${_primaryLine(stop)} deverrouille',
          duration: const Duration(seconds: 2),
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
        messenger.showSuccess(
          '${_primaryLine(stop)} deplace vers une autre tournee',
          duration: const Duration(seconds: 3),
        );
    }

    if (statutChange) {
      await markLivreService.syncStatutTournee(stop.tourneeId);
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

  static String _humanRaison(String? r) {
    return switch (r) {
      'absent' => 'absent',
      'refuse' => 'refuse',
      'adresse_fausse' => 'adresse fausse',
      'autre' => 'autre',
      _ => 'sans raison',
    };
  }

  /// Lance la camera pour capturer une photo preuve, puis attache le
  /// chemin au stop. Best-effort : si l'utilisateur annule ou que la
  /// permission camera est refusee, on ne fait rien.
  Future<void> _capturerPreuve(WidgetRef ref, Stop stop) async {
    final path = await PreuvePhotoService().capturer(
      stopId: stop.id,
      watermark: _composeWatermark(stop),
    );
    if (path == null) return;
    await ref.read(stopsRepositoryProvider).setPreuvePhoto(stop.id, path);
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

  /// Compose le filigrane incrusté sur la photo preuve (carte #397) :
  /// 1re ligne = nom client / adresse ; 2e ligne = date/heure locale +
  /// coordonnées GPS de l'arrêt (si géocodé). Vérifiable en cas de litige.
  String _composeWatermark(Stop s) {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    final dt = '${two(now.day)}/${two(now.month)}/${now.year} '
        '${two(now.hour)}:${two(now.minute)}';
    final gps = (s.lat != null && s.lng != null)
        ? '${s.lat!.toStringAsFixed(5)}, ${s.lng!.toStringAsFixed(5)}'
        : '';
    final ligne2 = gps.isEmpty ? dt : '$dt  -  $gps';
    return '${_primaryLine(s)}\n$ligne2';
  }
}
