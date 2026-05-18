import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import 'onboarding_screen.dart';
import 'tournee_du_jour_screen.dart';
import 'tournee_form_screen.dart';
import 'unified_search_screen.dart';

/// Routeur principal qui choisit entre :
/// - l'OnboardingScreen si l'utilisateur n'a pas encore fini le
///   walkthrough du premier lancement,
/// - l'ecran "tournee du jour" si une tournee active existe,
/// - sinon un empty state qui invite a en creer une.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingDone = ref.watch(onboardingDoneStreamProvider);
    final current = ref.watch(currentTourneeProvider);

    // Tant qu'on n'a pas charge l'etat de l'onboarding, on patiente.
    if (onboardingDone.isLoading) return const _LoadingScaffold();
    // Si le flag n'est pas pose -> walkthrough.
    if (onboardingDone.value != true) {
      return const OnboardingScreen();
    }

    return current.when(
      data: (tournee) =>
          tournee == null ? const _NoTourTodayScreen() : TourneeDuJourScreen(tournee: tournee),
      loading: () => const _LoadingScaffold(),
      error: (err, st) => _ErrorScaffold(error: '$err', stack: '$st'),
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
  const _ErrorScaffold({required this.error, this.stack});

  final String error;
  final String? stack;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Erreur')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.x22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Erreur de chargement : $error'),
              if (stack != null) ...[
                const SizedBox(height: AppSpacing.x18),
                const Text(
                  'Stack trace (pour debug) :',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
                SelectableText(
                  stack!,
                  style: const TextStyle(
                    fontFamily: 'JetBrainsMono',
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _NoTourTodayScreen extends StatelessWidget {
  const _NoTourTodayScreen();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerBadgeIcon(),
        title: const Text('Aujourd\'hui'),
        actions: [
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Rechercher tournees, arrets, clients',
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute<void>(
                  builder: (_) => const UnifiedSearchScreen(),
                ),
              ),
            ),
          ),
        ],
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
                decoration: BoxDecoration(
                  color: p.creamSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: 44,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x18),
              Text(
                'Pas de tournee aujourd\'hui',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                'Cree-la maintenant pour commencer a ajouter tes arrets.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: p.textMute,
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
