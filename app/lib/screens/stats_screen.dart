import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import 'stats/coequipiers_stats_card.dart';
import 'stats/export_facturation_cards.dart';
import 'stats/jours_semaine_card.dart';
import 'stats/motivation_card.dart';
import 'stats/stats_card.dart';
import 'stats/top_clients_card.dart';
import 'stats/top_raisons_echec_card.dart';

/// ════════════════════════════════════════════════════════════════
/// Ecran "Statistiques cumulatives" — point d'entree.
/// ════════════════════════════════════════════════════════════════
///
/// Accessible depuis le drawer. Affiche un empilement de cards :
///
///   1. [MotivationCard]         : compteurs annuels + badges
///   2. [StatsCard] x 3          : 7j / 30j / 365j
///   3. [JoursSemaineCard]       : barchart colis par jour (30j)
///   4. [TopClientsCard]         : top 5 du carnet
///   5. [CoequipiersStatsCard]   : stats par coequipier (30j)
///   6. [TopRaisonsEchecCard]    : top raisons d'echec (30j)
///   7. [FacturationCard]        : CTA vers FacturationScreen
///   8. [ExportCsvCard]          : export CSV 365j + share natif
///
/// Pull-to-refresh : invalide tous les providers stats pour relancer
/// les calculs depuis Drift (utile apres avoir ajoute / supprime
/// des tournees recemment).
///
/// Chaque card est dans son propre fichier sous `lib/screens/stats/`
/// pour faciliter la maintenance.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiques'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Invalide tous les providers stats pour relancer les calculs
          // (Drift est en watch mais certains providers sont futures).
          ref.invalidate(statsBundleProvider);
          ref.invalidate(statsProvider);
          ref.invalidate(colisParJourProvider);
          ref.invalidate(coutCarburantCumuleProvider);
          // Petit delai pour laisser tourner les futures + animer le
          // spinner Material du RefreshIndicator.
          await Future<void>.delayed(const Duration(milliseconds: 400));
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x18),
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [
            MotivationCard(),
            SizedBox(height: AppSpacing.x14),
            StatsCard(label: '7 DERNIERS JOURS', days: 7),
            SizedBox(height: AppSpacing.x14),
            StatsCard(label: '30 DERNIERS JOURS', days: 30),
            SizedBox(height: AppSpacing.x14),
            StatsCard(label: 'DEPUIS 1 AN', days: 365),
            SizedBox(height: AppSpacing.x14),
            JoursSemaineCard(),
            SizedBox(height: AppSpacing.x14),
            TopClientsCard(),
            SizedBox(height: AppSpacing.x14),
            CoequipiersStatsCard(),
            SizedBox(height: AppSpacing.x14),
            TopRaisonsEchecCard(),
            SizedBox(height: AppSpacing.x14),
            FacturationCard(),
            SizedBox(height: AppSpacing.x14),
            ExportCsvCard(),
          ],
        ),
      ),
    );
  }
}
