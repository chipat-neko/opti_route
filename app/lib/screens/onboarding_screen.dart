import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import 'onboarding/pages.dart';

/// Walkthrough du premier lancement. Cinq pages :
///   1. Bienvenue (presentation rapide)
///   2. Concept tournee + carnet
///   3. Scan bordereau (MESEXP / Colissimo / Chronopost)
///   4. Mode chef d'equipe + facturation (vagues recentes)
///   5. Saisie de la cle OpenRouteService (avec lien externe pour la
///      creer gratuitement)
///
/// La cle ORS n'est pas obligatoire : l'app fonctionne sans, mais le
/// bouton "Optimiser" est grise tant qu'on n'a pas saisi la cle.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  /// PageController qui orchestre la navigation entre les 5 pages.
  /// Permet l'animation `nextPage` / `previousPage` declenchees par les
  /// boutons en bas de l'ecran (precedent / suivant).
  final _pageController = PageController();

  /// Controller du champ de saisie de la cle ORS sur la derniere page.
  /// La valeur est persistee dans `parametres.ors_api_key` a la fin
  /// du walkthrough (cf. `_finish`).
  final _orsKeyCtrl = TextEditingController();

  /// Index de la page courante (0..4). Mis a jour via
  /// `PageView.onPageChanged`. Sert a :
  /// - choisir entre "Passer" (page 0) et "Precedent" (pages 1+)
  /// - choisir entre "Suivant" (pages 0..3) et "Commencer" (page 4)
  /// - colorer le bon indicateur "dot" en bas.
  int _currentPage = 0;

  /// True pendant la persistance finale (le user a tape "Commencer").
  /// Bloque les boutons pour eviter un double-tap qui declencherait
  /// 2 appels concurrents a `setOnboardingDone`.
  bool _saving = false;

  @override
  void dispose() {
    _pageController.dispose();
    _orsKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.cream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  const PageBienvenue(),
                  const PageConcept(),
                  const PageScan(),
                  const PageChefEquipe(),
                  PageOrsKey(controller: _orsKeyCtrl),
                ],
              ),
            ),
            Indicators(currentPage: _currentPage, total: 5),
            const SizedBox(height: AppSpacing.x18),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x18,
              ),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _saving
                          ? null
                          : () => _pageController.previousPage(
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOut,
                              ),
                      child: const Text('Precedent'),
                    )
                  else
                    TextButton(
                      onPressed: _saving ? null : _skip,
                      child: const Text('Passer'),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving
                        ? null
                        : (_currentPage < 4
                            ? () => _pageController.nextPage(
                                  duration:
                                      const Duration(milliseconds: 250),
                                  curve: Curves.easeOut,
                                )
                            : _finish),
                    icon: _saving
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.lime,
                            ),
                          )
                        : Icon(
                            _currentPage < 4
                                ? Icons.arrow_forward
                                : Icons.check,
                          ),
                    label: Text(
                      _currentPage < 4 ? 'Suivant' : 'Commencer',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x18),
          ],
        ),
      ),
    );
  }

  /// Bouton "Passer" sur la 1re page : marque l'onboarding comme
  /// termine SANS saisir de cle ORS. L'utilisateur pourra la coller
  /// plus tard via Parametres > Optimisation. Le HomeScreen watch le
  /// flag onboarding_done et bascule automatiquement vers le contenu
  /// normal des qu'il est mis a true.
  Future<void> _skip() async {
    setState(() => _saving = true);
    await ref.read(parametresRepositoryProvider).setOnboardingDone();
  }

  /// Bouton "Commencer" sur la derniere page : sauvegarde la cle ORS
  /// si l'utilisateur l'a saisie, puis marque l'onboarding comme
  /// termine. Si le champ est vide, on ne touche pas a la cle ORS
  /// (l'utilisateur peut decider de la saisir plus tard).
  Future<void> _finish() async {
    setState(() => _saving = true);
    final repo = ref.read(parametresRepositoryProvider);
    final orsKey = _orsKeyCtrl.text.trim();
    if (orsKey.isNotEmpty) {
      await repo.setOrsApiKey(orsKey);
    }
    await repo.setOnboardingDone();
  }
}
