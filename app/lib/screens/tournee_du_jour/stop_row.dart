import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/stop_types.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'known_client_badge.dart';
import 'stop_row_actions.dart';
import 'stop_row_visuals.dart';

// Re-exports pour les callers historiques de stop_row.dart qui
// importent IndexChip / StopTag / CoequipierAvatar / EtaBadge /
// SegmentBadge depuis ce fichier (carte Trello #150 : extraction
// des sous-widgets visuels dans stop_row_visuals.dart).
export 'stop_row_visuals.dart' show IndexChip, StopTag, CoequipierAvatar, EtaBadge, SegmentBadge;

/// Ligne d'arret dans la liste de la tournee du jour. Affiche numero,
/// nom client / adresse, tags (priorite, GPS manquant, nb colis,
/// fenetre horaire), avatar coequipier, badge ETA, poignee de drag.
///
/// Tap = ouvre la bottom sheet d'actions (marquer livre / echec /
/// details / photo). Long-press = dialog preview (carte #96). Swipe
/// gauche = supprime (via callback parent). Swipe droite = marque
/// livre directement.
///
/// La logique des 15 actions du sealed [StopAction] est extraite
/// dans `stop_row_actions.dart` ([StopRowActions]), les widgets
/// visuels dans `stop_row_visuals.dart` (carte Trello #150).
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
    final actions = StopRowActions(stop);
    return Dismissible(
      key: ValueKey('stop-${stop.id}'),
      // Si l'arret est deja livre, on n'autorise que le swipe vers la
      // gauche (suppression). Sinon on autorise les 2 sens :
      // - gauche -> droite (startToEnd) : marquer livre, vert
      // - droite -> gauche (endToStart) : supprimer, rouge
      direction: isLivre
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      // background = visible quand swipe gauche -> droite (startToEnd).
      // Vert "Marquer livre" avec icone check, aligne a gauche.
      background: Container(
        color: AppColors.emerald.withValues(alpha: 0.18),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x22),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.check_circle_outline, color: AppColors.emerald),
            SizedBox(width: AppSpacing.x8),
            Text(
              'Livre',
              style: TextStyle(
                color: AppColors.emerald,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      // secondaryBackground = visible quand swipe droite -> gauche
      // (endToStart). Rouge "Supprimer" avec icone delete, aligne a droite.
      secondaryBackground: Container(
        color: AppColors.red.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x22),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe gauche -> droite : marque livre + capture GPS + haptic +
          // SnackBar. Retourne false pour ne pas dismiss le widget (le
          // refresh de la liste vient du watch Drift).
          await actions.handleSwipeLivre(context, ref);
          return false;
        }
        // Swipe droite -> gauche : delegue au parent qui ouvre la
        // confirmation de suppression.
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: () => actions.handleTap(context, ref),
        onLongPress: () => actions.showPreviewDialog(context, ref),
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            _primaryLine(stop),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isLivre ? p.textMute : p.ink,
                              decoration: isLivre
                                  ? TextDecoration.lineThrough
                                  : null,
                              decorationColor: p.textMute,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Carte Trello #94 : badge discret si le client
                        // est deja dans le carnet (>= 2 livraisons, ou
                        // favori). Aide Noah a reconnaitre les habitues.
                        KnownClientBadge(stopId: stop.id),
                      ],
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
                    // Segment km + duree (style Spoke) : "8 km · 15 min
                    // depuis precedent". Affiche seulement sur les
                    // stops a_livrer (info utile = ce qui reste a
                    // faire, pas le passe).
                    if (!isLivre && !isEchec)
                      SegmentBadge(
                        tourneeId: stop.tourneeId,
                        stopId: stop.id,
                      ),
                    if (isEchec) ...[
                      const SizedBox(height: 4),
                      Text(
                        // Pour un ramasse echoue : "Pas ramasse : raison".
                        // Pour une livraison echouee : "Echec : raison".
                        '${stop.type == kStopTypeRamasse ? "Pas ramasse" : "Echec"} '
                        ': ${_humanRaison(stop.raisonEchec)}',
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
                    padding: const EdgeInsets.symmetric(
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

  // Duplique [StopRowActions._humanRaison] : utilise ici pour le label
  // affiche directement dans la row quand statutLivraison='echec'.
  String _humanRaison(String? r) {
    return switch (r) {
      'absent' => 'absent',
      'refuse' => 'refuse',
      'adresse_fausse' => 'adresse fausse',
      'autre' => 'autre',
      _ => 'sans raison',
    };
  }

  List<Widget> _buildTags(Stop s, AppPalette p) {
    final out = <Widget>[];
    // Tag ramasse en premier : forte distinction visuelle (orange amber)
    // car le geste est inverse de la livraison classique.
    if (s.type == kStopTypeRamasse) {
      out.add(const StopTag(
        label: 'RAMASSE',
        bg: AppColors.amber,
        fg: AppColors.ink,
      ));
    }
    final priority = _priorityTag(s.priorite, p);
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
        fg: p.ink,
        mono: true,
      ));
    }
    return out;
  }

  /// p: palette context-aware passee par le caller (build context).
  /// Necessaire pour le tag "Eviter" qui a un fond amber translucide
  /// laissant passer la couleur de la card par transparence -> le fg
  /// doit s'inverser en mode dark, sinon texte noir invisible sur
  /// fond sombre (bug audit 2026-05-21).
  Widget? _priorityTag(String priorite, AppPalette p) {
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
          fg: p.ink,
        ),
      _ => null,
    };
  }
}
