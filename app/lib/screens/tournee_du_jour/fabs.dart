import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../theme/app_tokens.dart';
import 'voice_command_fab.dart';

/// ════════════════════════════════════════════════════════════════
/// Pile de FloatingActionButtons en bas a droite de l'ecran tournee
/// du jour. Le bouton du bas est "Ajouter un arret" (toujours present).
/// Au-dessus, selon le statut de la tournee :
///
///   - **'brouillon' / 'optimisee'** : "Demarrer" en lime (passe en
///     'en_cours' et enregistre `demareeLe`). Permet de demarrer
///     meme sans avoir fait l'optim ORS (cas pas de cle ORS, tournee
///     mini, ordre saisi deja correct).
///   - **'en_cours'**  : "Pause" en amber (`pauseeLe` + cumul des
///     secondes de pause).
///   - **'terminee'**  : aucun FAB supplementaire au-dessus du
///     "Ajouter un arret".
/// ════════════════════════════════════════════════════════════════
class Fabs extends StatelessWidget {
  const Fabs({
    super.key,
    required this.tournee,
    required this.onAjouter,
    required this.onDemarrer,
    required this.onScannerColis,
    required this.onScanRafale,
    this.scannerColisKey,
    this.ajouterKey,
  });

  final Tournee tournee;
  final VoidCallback onAjouter;
  final VoidCallback onDemarrer;
  final VoidCallback onScannerColis;

  /// Scan bordereaux en rafale (carte #119) : enchaine plusieurs
  /// bordereaux puis ajout en masse.
  final VoidCallback onScanRafale;
  // Keys exposes pour les coach marks contextuels (1er lancement)
  final GlobalKey? scannerColisKey;
  final GlobalKey? ajouterKey;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isBrouillon = tournee.statut == 'brouillon';
    final isOptimisee = tournee.statut == 'optimisee';
    final isEnCours = tournee.statut == 'en_cours';
    // Le bouton Demarrer s'affiche aussi en brouillon : pas besoin
    // d'optim ORS pour pouvoir demarrer (cas pas de cle ORS, tournee
    // mini, ordre saisi deja correct). Carte Trello #136.
    final showDemarrer = isBrouillon || isOptimisee;
    // Pendant la tournee (en_cours), on epure le coin bas-droite : seul le
    // micro mains-libres reste. La Pause passe dans l'app bar (a cote du
    // nom) et Scan colis / Scan bordereau / Ajouter un arret passent dans
    // le menu ⋮ (demande UI Noah 2026-06-03). Hors tournee, on garde les
    // FABs classiques (Demarrer + scans + ajout).
    if (isEnCours) {
      return VoiceCommandFab(tournee: tournee);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (showDemarrer) ...[
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
          const SizedBox(height: AppSpacing.x10),
        ],
        // Mini FAB scanner code-barre colis.
        FloatingActionButton.small(
          key: scannerColisKey,
          heroTag: 'fab-scanner-colis',
          backgroundColor: AppColors.lime,
          foregroundColor: p.ink,
          onPressed: onScannerColis,
          tooltip: 'Scanner code-barre colis',
          child: const Icon(Icons.qr_code_scanner_outlined),
        ),
        const SizedBox(height: AppSpacing.x10),
        // Scan bordereaux en rafale (carte #119).
        FloatingActionButton.small(
          heroTag: 'fab-scan-rafale',
          backgroundColor: AppColors.lime,
          foregroundColor: p.ink,
          onPressed: onScanRafale,
          tooltip: 'Scanner des bordereaux en rafale',
          child: const Icon(Icons.burst_mode_outlined),
        ),
        const SizedBox(height: AppSpacing.x10),
        FloatingActionButton.extended(
          key: ajouterKey,
          heroTag: 'fab-ajouter',
          onPressed: onAjouter,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un arret'),
        ),
      ],
    );
  }
}
