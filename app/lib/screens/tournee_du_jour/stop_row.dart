import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/eta_calculator.dart';
import '../../data/location_service.dart';
import '../../data/notifications_service.dart';
import '../../data/preuve_photo_service.dart';
import '../../data/stops_repository.dart';
import '../../data/tournees_repository.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/stop_action_sheet.dart';
import '../ajout_arret_screen.dart';

/// Ligne d'arret dans la liste de la tournee du jour. Affiche numero,
/// nom client / adresse, tags (priorite, GPS manquant, nb colis,
/// fenetre horaire), avatar coequipier, badge ETA, poignee de drag.
///
/// Tap = ouvre la bottom sheet d'actions (marquer livre / echec /
/// details / photo). Swipe gauche = supprime (via callback parent).
class StopRow extends ConsumerWidget {
  const StopRow({
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
              IndexChip(
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
              // Avatar du coequipier affecte (uniquement si != Noah).
              if (stop.coequipierId != null)
                CoequipierAvatar(coequipierId: stop.coequipierId!),
              // ETA estimee (uniquement pour les stops a_livrer).
              if (!isLivre && !isEchec)
                EtaBadge(tourneeId: stop.tourneeId, stopId: stop.id),
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
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                '${_primaryLine(stop)} en echec : ${_humanRaison(r)}'),
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
      case TakePreuvePhotoAction():
        await _capturerPreuve(ref, stop.id);
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
      out.add(const StopTag(
        label: 'GPS manquant',
        bg: AppColors.amber,
        fg: AppColors.ink,
      ));
    }
    if (s.nbColis > 1) {
      out.add(StopTag(
        label: '${s.nbColis} colis',
        bg: p.creamSoft,
        fg: p.ink,
      ));
    }
    if (s.fenetreDebut != null || s.fenetreFin != null) {
      final start = s.fenetreDebut ?? '--:--';
      final end = s.fenetreFin ?? '--:--';
      out.add(StopTag(
        label: '$start -> $end',
        bg: const Color(0x33F2A341),
        fg: const Color(0xFF7A4F0E),
        mono: true,
      ));
    }
    return out;
  }

  Widget? _priorityTag(String priorite) {
    return switch (priorite) {
      'obligatoire_premier' => const StopTag(
          label: 'En 1er',
          bg: AppColors.lime,
          fg: AppColors.ink,
        ),
      'obligatoire_dernier' => const StopTag(
          label: 'En dernier',
          bg: AppColors.lime,
          fg: AppColors.ink,
        ),
      'eviter_si_possible' => StopTag(
          label: 'Eviter',
          bg: AppColors.amber.withValues(alpha: 0.25),
          fg: const Color(0xFF7A4F0E),
        ),
      _ => null,
    };
  }
}

/// Chip carre avec le numero d'ordre du stop. Couleur de fond selon
/// statut (vert = livre, rouge = echec, ink = priorite figue, paper
/// par defaut).
class IndexChip extends StatelessWidget {
  const IndexChip({
    super.key,
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

/// Tag (pilule colore) affichant un label court. Utilise pour les
/// priorites, le nombre de colis, les fenetres horaires, etc.
class StopTag extends StatelessWidget {
  const StopTag({
    super.key,
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

/// Mini avatar circulaire du coequipier affecte a un arret.
/// Resolution non-bloquante : si le coequipier n'est pas dans
/// `coequipiersByIdProvider` (archive ou supprime), on affiche `?`.
class CoequipierAvatar extends ConsumerWidget {
  const CoequipierAvatar({super.key, required this.coequipierId});

  final int coequipierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final byId = ref.watch(coequipiersByIdProvider);
    final c = byId[coequipierId];
    final color = c == null
        ? context.palette.creamSoft
        : colorFromTag(c.colorTag, defaultColor: AppColors.lime);
    final label = c == null ? '?' : _avatarInitials(c.nom);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.x6),
      child: Tooltip(
        message: c?.nom ?? 'Coequipier inconnu',
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.ink.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ),
      ),
    );
  }

  static String _avatarInitials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

/// Badge "ETA HH:MM" affiche en regard du nom du client. Watche le
/// provider `etasParStopProvider` et n'affiche rien tant que le calcul
/// n'a pas emis ou si l'ETA n'est pas disponible pour ce stop.
class EtaBadge extends ConsumerWidget {
  const EtaBadge({
    super.key,
    required this.tourneeId,
    required this.stopId,
  });

  final int tourneeId;
  final int stopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final etas = ref.watch(etasParStopProvider(tourneeId)).asData?.value;
    final eta = etas?[stopId];
    if (eta == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.x6),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x6,
          vertical: 3,
        ),
        decoration: BoxDecoration(
          color: p.inkLine.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Text(
          EtaCalculator.formatEtaHHmm(eta),
          style: appMonoStyle(
            fontSize: 10,
            color: p.textMute,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
