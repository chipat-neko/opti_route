import 'package:flutter/material.dart';

import '../onboarding_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Aide" — relancer l'onboarding et acceder aux tutoriels.
/// ════════════════════════════════════════════════════════════════
///
/// Expose un point d'entree pour revoir le walkthrough des 6 pages
/// d'onboarding. Pratique si Noah a oublie comment utiliser une feature
/// (mode chef, scan, 4 palettes, PIN/biometrie, etc.) -- toutes sont
/// recapitulees dans l'onboarding.
///
/// L'onboarding pousse en mode `replayMode: true` ne touche PAS au
/// flag `onboarding_done` ni a la cle ORS deja en place : juste
/// `Navigator.pop` quand le user clique "Fermer".
///
/// Phase 2 (carte Backlog dediee) : ajout d'un toggle "Astuces" qui
/// reactivera les coach marks contextuels au prochain demarrage de
/// chaque ecran (Tournee, Scan, Carnet).
class AideSection extends StatelessWidget {
  const AideSection({super.key});

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}
