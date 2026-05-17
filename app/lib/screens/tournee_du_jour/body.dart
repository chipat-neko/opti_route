import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../theme/app_tokens.dart';
import '../cloud/coequipiers_section.dart';
import 'autres_tournees_banner.dart';
import 'banners.dart';
import 'header.dart';
import 'prochain_arret_card.dart';
import 'progress_banner.dart';
import 'stat_row.dart';
import 'stops_list.dart';
import 'stops_section.dart';

/// ════════════════════════════════════════════════════════════════
/// Body principal de [TourneeDuJourScreen].
/// ════════════════════════════════════════════════════════════════
///
/// Empile dans un ListView les sous-widgets thematiques :
/// Header, AutresTourneesDuJourBanner, StatRow, CoutCarburantBanner,
/// OptimisedBanner, ProgressBanner, ProchainArretCard, StopsSection.
///
/// Extrait de `tournee_du_jour_screen.dart` pour symetrie avec les
/// autres widgets du dossier `tournee_du_jour/`. Pure stateless :
/// l'etat de la tournee + ses stops sont passes en parametre par
/// l'ecran parent qui les watch via Riverpod.
class Body extends StatelessWidget {
  const Body({
    super.key,
    required this.tournee,
    required this.stops,
  });

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
        Header(tournee: tournee),
        // Jalon 3.B : section coequipiers (visible seulement si la
        // tournee est partagee = au moins 1 member en plus du owner).
        // Auto-masquee sinon via SizedBox.shrink interne.
        CoequipiersSection(tournee: tournee),
        AutresTourneesDuJourBanner(currentTourneeId: tournee.id),
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
          ProchainArretCard(stops: stops),
        ],
        const SizedBox(height: AppSpacing.x18),
        if (stops.isEmpty)
          const StopsPlaceholder()
        else
          StopsSection(stops: stops),
      ],
    );
  }
}
