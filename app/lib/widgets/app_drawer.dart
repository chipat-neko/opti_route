import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/database_providers.dart';
import '../screens/carnet_adresses_screen.dart';
import '../screens/parametres_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/tableau_bord_equipe_screen.dart';
import '../screens/tournees_list_screen.dart';
import '../theme/app_tokens.dart';

/// Drawer applicatif commun.
///
/// Architecture hybride choisie avec Noah : la home est la **tournee
/// du jour** ; l'historique reste accessible mais cache derriere le
/// menu hamburger.
class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasEnCours = ref.watch(hasTourneeEnCoursProvider);
    final tourneesAujourdhui = ref.watch(tourneesDuJourProvider);
    final p = context.palette;
    return Drawer(
      backgroundColor: p.cream,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x22,
                AppSpacing.x28,
                AppSpacing.x22,
                AppSpacing.x12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'opti_route',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x4),
                  Text(
                    tourneesAujourdhui.isEmpty
                        ? 'Aucune tournee aujourd\'hui'
                        : tourneesAujourdhui.length == 1
                            ? '1 tournee aujourd\'hui'
                            : '${tourneesAujourdhui.length} tournees '
                                'aujourd\'hui',
                    style: TextStyle(
                      fontSize: 12,
                      color: p.textMute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.today_outlined),
                  if (hasEnCours)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.lime,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: p.cream,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: const Text('Tournee du jour'),
              subtitle: hasEnCours
                  ? Text(
                      'En cours',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.emerald,
                      ),
                    )
                  : null,
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historique des tournees'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TourneesListScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_outline),
              title: const Text('Carnet d\'adresses'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CarnetAdressesScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined),
              title: const Text('Statistiques'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const StatsScreen(),
                  ),
                );
              },
            ),
            // Mode chef d'equipe : ajoute "Tableau de bord equipe"
            // dans le drawer. Cache pour les livreurs solos pour eviter
            // de polluer la navigation avec des features non utilisees.
            Consumer(
              builder: (context, ref, _) {
                final modeChef =
                    ref.watch(modeChefProvider).asData?.value ?? false;
                if (!modeChef) return const SizedBox.shrink();
                return ListTile(
                  leading: const Icon(Icons.dashboard_outlined),
                  title: const Text('Tableau de bord equipe'),
                  subtitle: const Text(
                    'Vue agregee toutes tournees du jour',
                    style: TextStyle(fontSize: 11),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const TableauBordEquipeScreen(),
                      ),
                    );
                  },
                );
              },
            ),
            const Spacer(),
            const Divider(height: 1),
            // Lien externe vers le site vitrine (presentation, FAQ,
            // changelog, ROI). Ouvert dans le navigateur systeme via
            // url_launcher car le webview embarque n'a pas vraiment de
            // valeur (le user verrait juste l'app dans une app).
            ListTile(
              leading: const Icon(Icons.public_outlined),
              title: const Text('Voir le site'),
              subtitle: const Text(
                'Presentation, FAQ, changelog',
                style: TextStyle(fontSize: 12),
              ),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: () {
                launchUrl(
                  Uri.parse('https://chipat-neko.github.io/opti_route/site/'),
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.tune_outlined),
              title: const Text('Parametres'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const ParametresScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
