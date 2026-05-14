import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Pile de FloatingActionButtons en bas a droite de l'ecran tournee
/// du jour. Le bouton du bas est "Ajouter un arret" (toujours present).
/// Au-dessus, selon le statut de la tournee :
///
///   - **'optimisee'** : "Demarrer" en lime (passe en 'en_cours' et
///     enregistre `demareeLe`).
///   - **'en_cours'**  : "Pause" en amber (`pauseeLe` + cumul des
///     secondes de pause).
///   - **brouillon / terminee** : aucun FAB supplementaire au-dessus
///     du "Ajouter un arret".
/// ════════════════════════════════════════════════════════════════
class Fabs extends StatelessWidget {
  const Fabs({
    super.key,
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
