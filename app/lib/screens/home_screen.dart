import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import 'tournee_du_jour_screen.dart';
import 'tournee_form_screen.dart';

/// Routeur principal qui choisit entre l'ecran "tournee du jour" si
/// une tournee active existe, sinon un empty state qui invite a en
/// creer une.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentTourneeProvider);

    return current.when(
      data: (tournee) =>
          tournee == null ? const _NoTourTodayScreen() : TourneeDuJourScreen(tournee: tournee),
      loading: () => const _LoadingScaffold(),
      error: (err, _) => _ErrorScaffold(error: '$err'),
    );
  }
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ErrorScaffold extends StatelessWidget {
  const _ErrorScaffold({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x22),
          child: Text('Erreur de chargement : $error'),
        ),
      ),
    );
  }
}

class _NoTourTodayScreen extends StatelessWidget {
  const _NoTourTodayScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerBadgeIcon(),
        title: const Text('Aujourd\'hui'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  color: AppColors.creamSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_shipping_outlined,
                  size: 44,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x18),
              Text(
                'Pas de tournee aujourd\'hui',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.x8),
              const Text(
                'Cree-la maintenant pour commencer a ajouter tes arrets.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textMute,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.x22),
              FilledButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const TourneeFormScreen(),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Creer ma tournee'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
