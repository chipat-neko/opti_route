import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers/location_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'stop_row_actions.dart';

/// ════════════════════════════════════════════════════════════════
/// Bandeau "tu es sur place" (carte #285).
/// ════════════════════════════════════════════════════════════════
///
/// Annonce l'arret encore a livrer le plus proche quand la position GPS
/// tombe dans le rayon de proximite (80 m par defaut, cf
/// `ProximityChecker.defaultRadiusMeters`) : "Tu es a 24 m de Mme Dupont".
/// S'il y en a plusieurs, la ligne secondaire le signale sobrement
/// ("+2 autres a proximite") sans les lister -- la liste des arrets juste
/// en dessous fait deja ce travail.
///
/// Toute la logique de selection vit dans `arretsProchesProvider`
/// (cf `providers/location_providers.dart`) : ce widget ne fait que la
/// mettre en forme. Quand le provider rend null -- tournee pas en cours,
/// pas de position, aucun arret dans le rayon -- le bandeau ne s'affiche
/// pas DU TOUT (pas de bandeau vide, ni meme son espacement).
///
/// Tap = exactement le meme geste que sur une ligne de la liste :
/// [StopRowActions.handleTap] ouvre la bottom sheet d'actions de l'arret
/// (marquer livre / echec / details / photo...). On ne duplique donc ni la
/// navigation ni la logique de validation.
class ProximiteBanner extends ConsumerWidget {
  const ProximiteBanner({super.key, required this.tourneeId});

  final int tourneeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final proches = ref.watch(arretsProchesProvider(tourneeId));
    if (proches == null) return const SizedBox.shrink();

    final p = context.palette;
    final stop = proches.plusProche;
    // L'espacement vit DANS le widget (comme AnomaliesBanner) : quand le
    // bandeau est masque, il ne laisse aucun trou dans la pile du body.
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x12),
      // Montage d'un bandeau tappable, repris tel quel de
      // AutresTourneesDuJourBanner : Container = bordure, Material =
      // fond, InkWell = geste, Padding = interieur. Le fond DOIT etre
      // porte par un Material sous l'InkWell, sinon le splash est peint
      // sur le Material du Scaffold, donc SOUS le fond opaque du
      // bandeau -> tap sans aucun retour visuel.
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(
            color: AppColors.emerald.withValues(alpha: 0.4),
          ),
        ),
        child: Material(
          color: AppColors.emerald.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.r14),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r14),
            onTap: () => StopRowActions(stop).handleTap(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x12),
              child: Row(
                children: [
                  const Icon(
                    Icons.my_location,
                    color: AppColors.emerald,
                    size: 20,
                  ),
                  const SizedBox(width: AppSpacing.x10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(text: 'Tu es a '),
                              TextSpan(
                                text: '${proches.distanceMeters} m',
                                style: appMonoStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: p.ink,
                                ),
                              ),
                              TextSpan(text: ' de ${_labelStop(stop)}'),
                            ],
                          ),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: p.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (proches.autresCount > 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '+${proches.autresCount} autre'
                              '${proches.autresCount > 1 ? "s" : ""} '
                              'a proximite',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: p.textMute,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  const Text(
                    'Ouvrir',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.emerald,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Meme regle d'affichage que `StopRow` : le nom du client s'il est
  /// renseigne, sinon le debut de l'adresse brute.
  static String _labelStop(Stop s) {
    final nom = (s.nomClient ?? '').trim();
    if (nom.isNotEmpty) return nom;
    return s.adresseBrute.split(',').first.trim();
  }
}
