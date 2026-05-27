import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

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

/// Panneau "tournees en cours" — placeholder, contenu en [#88·2].
class _TourneesPanel extends StatelessWidget {
  const _TourneesPanel();

  @override
  Widget build(BuildContext context) {
    return const _ChefPanel(
      icon: Icons.route_outlined,
      title: 'Tournees en cours',
      sousCarte: '[#88·2]',
      description: 'Liste temps reel de tous les chauffeurs + progression',
    );
  }
}

/// Panneau "carte live" — placeholder, contenu en [#88·3].
class _CartePanel extends StatelessWidget {
  const _CartePanel();

  @override
  Widget build(BuildContext context) {
    return const _ChefPanel(
      icon: Icons.map_outlined,
      title: 'Carte live',
      sousCarte: '[#88·3]',
      description: 'Positions GPS des chauffeurs en temps reel',
    );
  }
}

/// Panneau "stats du jour" — placeholder, contenu en [#88·4].
class _StatsPanel extends StatelessWidget {
  const _StatsPanel();

  @override
  Widget build(BuildContext context) {
    return const _ChefPanel(
      icon: Icons.insights_outlined,
      title: 'Stats du jour',
      sousCarte: '[#88·4]',
      description: '% livres, retards, alertes de la journee',
    );
  }
}

/// Carte "panneau" generique du shell chef : un conteneur paper avec
/// un en-tete (icone + titre + tag sous-carte) et un placeholder
/// "a venir" centre.
class _ChefPanel extends StatelessWidget {
  const _ChefPanel({
    required this.icon,
    required this.title,
    required this.sousCarte,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String sousCarte;
  final String description;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              _SousCarteTag(label: sousCarte),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            description,
            style: TextStyle(fontSize: 12, color: p.textMute),
          ),
          const Divider(height: AppSpacing.x22),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.hourglass_empty,
                      size: 28, color: p.textFaint),
                  const SizedBox(height: AppSpacing.x8),
                  Text(
                    'A venir',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.textFaint,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Petit tag arrondi affichant la sous-carte Trello d'origine du
/// panneau (ex `[#88·2]`).
class _SousCarteTag extends StatelessWidget {
  const _SousCarteTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: p.textMute,
        ),
      ),
    );
  }
}
