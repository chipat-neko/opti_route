import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import 'chef_live_map_panel.dart';
import 'chef_stats_panel.dart';
import 'chef_tournees_panel.dart';

/// Largeur minimale (en px logiques) au-dela de laquelle on bascule en
/// disposition "grand ecran" multi-panneaux. En dessous, les panneaux
/// s'empilent verticalement (l'ecran reste utilisable sur tablette /
/// fenetre etroite, meme si la cible est l'ordinateur du chef).
const double kChefWideBreakpoint = 1000;

/// Fondation du logiciel "vue d'ensemble chef" (epopee #88, sous-carte
/// [#88·1]).
///
/// Cet ecran est le **shell** : il pose la mise en page responsive
/// grand ecran (3 panneaux cote a cote) qui accueillera, dans les
/// sous-cartes suivantes, les vrais contenus :
/// - [#88·2] liste des tournees en cours de tous les chauffeurs
/// - [#88·3] carte GPS live multi-chauffeurs
/// - [#88·4] dashboard stats du jour
///
/// Pour l'instant chaque panneau affiche un placeholder. Le shell est
/// concu pour le web (deja deploye) et le desktop Windows (cible a
/// activer en [#88·5]) : sur un grand ecran, les 3 panneaux s'affichent
/// en colonnes ; sur un ecran etroit ils s'empilent.
class ChefDashboardShell extends StatelessWidget {
  const ChefDashboardShell({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.cream,
      appBar: AppBar(
        title: const Text('Mode chef — Vue d\'ensemble'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(20),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.x16,
              bottom: AppSpacing.x8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Beta — fondation (epopee #88)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: p.textMute,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= kChefWideBreakpoint;
            return wide
                ? const _WideLayout()
                : const _NarrowLayout();
          },
        ),
      ),
    );
  }
}

/// Disposition grand ecran : 3 panneaux cote a cote.
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: const [
          Expanded(flex: 3, child: _TourneesPanel()),
          SizedBox(width: AppSpacing.x16),
          Expanded(flex: 4, child: _CartePanel()),
          SizedBox(width: AppSpacing.x16),
          Expanded(flex: 3, child: _StatsPanel()),
        ],
      ),
    );
  }
}

/// Disposition etroite (tablette / fenetre reduite / mobile) : les
/// panneaux s'empilent et defilent.
class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: p.creamSoft,
              borderRadius: BorderRadius.circular(AppRadius.r12),
            ),
            child: Row(
              children: [
                Icon(Icons.desktop_windows_outlined,
                    size: 18, color: p.textMute),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: Text(
                    'Optimise pour grand ecran (PC / navigateur). '
                    'Elargis la fenetre pour la vue en colonnes.',
                    style: TextStyle(fontSize: 12, color: p.textMute),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          const SizedBox(height: 280, child: _TourneesPanel()),
          const SizedBox(height: AppSpacing.x16),
          const SizedBox(height: 280, child: _CartePanel()),
          const SizedBox(height: AppSpacing.x16),
          const SizedBox(height: 280, child: _StatsPanel()),
        ],
      ),
    );
  }
}

/// Panneau "tournees en cours" — branche sur le vrai contenu ([#88·2]).
class _TourneesPanel extends StatelessWidget {
  const _TourneesPanel();

  @override
  Widget build(BuildContext context) {
    return const ChefTourneesPanel();
  }
}

/// Panneau "carte" — branche sur le vrai contenu ([#88·3]).
class _CartePanel extends StatelessWidget {
  const _CartePanel();

  @override
  Widget build(BuildContext context) {
    return const ChefLiveMapPanel();
  }
}

/// Panneau "stats du jour" — branche sur le vrai contenu ([#88·4]).
class _StatsPanel extends StatelessWidget {
  const _StatsPanel();

  @override
  Widget build(BuildContext context) {
    return const ChefStatsPanel();
  }
}

