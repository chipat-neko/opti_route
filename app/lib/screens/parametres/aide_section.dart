import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../onboarding_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Aide" — relancer l'onboarding et reactiver les astuces.
/// ════════════════════════════════════════════════════════════════
///
/// Expose 2 points d'entree :
///
/// 1. **Revoir le tutoriel** : pousse [OnboardingScreen] en mode
///    `replayMode: true` (les 6 pages onboarding, sans toucher au
///    flag onboarding_done ni a la cle ORS).
///
/// 2. **Reactiver les astuces** : reset les 4 flags `coach_*_done`
///    dans ParametresRepository pour que les info-bulles contextuelles
///    reapparaissent a la prochaine ouverture de chaque ecran
///    (Tournee du jour, Scan, Parametres, Carnet). Utile si Noah a
///    cliqué "Passer" sans regarder, ou si un nouveau coequipier
///    prend le telephone.
class AideSection extends ConsumerWidget {
  const AideSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.menu_book_outlined),
          title: const Text('Revoir le tutoriel'),
          subtitle: const Text(
            'Reaffiche les 6 pages de l\'onboarding (mode chef, scan, '
            'palettes, securite, GPS, cle ORS)',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => const OnboardingScreen(replayMode: true),
              ),
            );
          },
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.tips_and_updates_outlined),
          title: const Text('Reactiver les astuces'),
          subtitle: const Text(
            'Les info-bulles guidees reapparaitront a la prochaine '
            'ouverture de chaque ecran (Tournee, Scan, Parametres, Carnet)',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.refresh),
          onTap: () async {
            await ref
                .read(parametresRepositoryProvider)
                .resetAllCoachMarks();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Astuces reactivees. Reouvre les ecrans '
                    'pour les revoir.'),
              ),
            );
          },
        ),
      ],
    );
  }
}
