import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/eta_calculator.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets visuels reutilises par [StopRow] dans la tournee du jour.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `stop_row.dart` (carte Trello #150) :
///   - IndexChip : pastille numerotee a gauche, couleur selon statut
///   - StopTag : pilule colore pour priorite / GPS / colis / fenetre
///   - CoequipierAvatar : avatar circulaire 26px avec initiales
///   - EtaBadge : heure d'arrivee estimee (HH:MM)
///   - SegmentBadge : distance + duree depuis le stop precedent
///   - PreviewRow : ligne icone + texte du dialog preview (long-press)

/// Chip carre avec le numero d'ordre du stop. Couleur de fond selon
/// statut (vert = livre, rouge = echec, ink = priorite figee, paper
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
    final parts = nom
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
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

/// Badge "8 km · 15 min" affiche en bas du primaire d'un StopRow.
/// Indique la distance + duree estimee du segment PRECEDENT (depuis
/// le stop precedent OU depuis le depot pour le 1er stop pending).
///
/// Inspire de Spoke route planner ("15 min, 8 km jusqu'au prochain
/// arret"). Aide Noah a savoir d'un coup d'oeil si c'est juste a cote
/// ou loin sans avoir a calculer.
///
/// Pas affiche si le stop est deja livre/echec OU si pas de coords.
class SegmentBadge extends ConsumerWidget {
  const SegmentBadge({
    super.key,
    required this.tourneeId,
    required this.stopId,
  });

  final int tourneeId;
  final int stopId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final segments =
        ref.watch(segmentsParStopProvider(tourneeId)).asData?.value;
    final seg = segments?[stopId];
    if (seg == null) return const SizedBox.shrink();
    final origin = seg.fromDepot ? 'depart' : 'precedent';
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Icon(
            Icons.straighten,
            size: 11,
            color: p.textMute,
          ),
          const SizedBox(width: 3),
          // Flexible + ellipsis : sans ca, sur les longs segments
          // ('13 km · 1h05 depuis precedent') le Text depassait
          // a droite et Flutter affichait 'RIGHT OVERFLOWED BY N
          // PIXELS' en texte rouge vertical (vu sur Xiaomi Noah
          // 2026-05-21 : bande rouge qui traverse l'ecran).
          Flexible(
            child: Text(
              '${seg.distanceLabel} · ${seg.durationLabel} depuis $origin',
              style: appMonoStyle(
                fontSize: 10,
                color: p.textMute,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne icone + texte du dialog preview (carte Trello #96). Utilise
/// pour les infos cles d'un stop (adresse, colis, fenetre, notes).
class PreviewRow extends StatelessWidget {
  const PreviewRow({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: p.textMute),
        const SizedBox(width: AppSpacing.x8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: p.ink, height: 1.35),
          ),
        ),
      ],
    );
  }
}
