import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

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
  final _pageController = PageController();
  final _orsKeyCtrl = TextEditingController();
  int _currentPage = 0;
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
                  _PageBienvenue(),
                  _PageConcept(),
                  const _PageScan(),
                  const _PageChefEquipe(),
                  _PageOrsKey(controller: _orsKeyCtrl),
                ],
              ),
            ),
            _Indicators(currentPage: _currentPage, total: 5),
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

  Future<void> _skip() async {
    setState(() => _saving = true);
    await ref.read(parametresRepositoryProvider).setOnboardingDone();
    // Pas besoin de pop : HomeScreen watch le stream du flag et
    // rebuild automatiquement vers le contenu normal.
  }

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

class _PageBienvenue extends StatelessWidget {
  const _PageBienvenue();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x22,
        vertical: AppSpacing.x28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(AppRadius.r22),
            ),
            child: Icon(
              Icons.local_shipping_outlined,
              size: 40,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x22),
          Text(
            'Bienvenue dans\nopti_route',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: p.ink,
              height: 1.1,
              letterSpacing: -0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          Text(
            'Optimisation de tournees de livraison, '
            'gratuit et sans carte de credit.',
            style: TextStyle(
              fontSize: 15,
              color: p.textMute,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x22),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.emeraldSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(f.$1,
                        size: 16, color: AppColors.emerald),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 13.5,
                        color: p.ink,
                        height: 1.4,
                      ),
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

  static const _features = <(IconData, String)>[
    (
      Icons.bolt_outlined,
      'Optimise l\'ordre de tes arrets pour livrer en moins de temps.',
    ),
    (
      Icons.gps_fixed,
      'Mode tournee en cours avec GPS live et boutons rapides Maps / Waze.',
    ),
    (
      Icons.bookmark_outline,
      'Carnet d\'adresses local : tes clients deja livres remontent automatiquement.',
    ),
    (
      Icons.verified_outlined,
      'Tout reste sur ton telephone. Aucune CB, aucun compte.',
    ),
  ];
}

class _PageConcept extends StatelessWidget {
  const _PageConcept();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x22,
        vertical: AppSpacing.x28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comment ca marche',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x22),
          ..._steps.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: p.ink,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: appMonoStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.lime,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.value.$1,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: p.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              entry.value.$2,
                              style: TextStyle(
                                fontSize: 13,
                                color: p.textMute,
                                height: 1.4,
                              ),
                            ),
                          ],
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

  static const _steps = <(String, String)>[
    (
      'Cree une tournee',
      'Donne-lui un nom, une date, et le point de depart (ton entrepot ou ta maison).',
    ),
    (
      'Ajoute tes arrets',
      'Tape l\'adresse, scan un bordereau, ou pointe sur la carte. Marque les priorites EN 1ER / EN DERNIER.',
    ),
    (
      'Optimise',
      'L\'app calcule l\'ordre le plus rapide en respectant tes contraintes.',
    ),
    (
      'Demarre la tournee',
      'GPS live + Maps/Waze sur chaque arret. Marque livre / echec au fur et a mesure.',
    ),
  ];
}

class _PageScan extends StatelessWidget {
  const _PageScan();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x22,
        vertical: AppSpacing.x28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(AppRadius.r22),
            ),
            child: Icon(
              Icons.document_scanner_outlined,
              size: 38,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x22),
          Text(
            'Scan bordereau',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          Text(
            'Pointe ton phone sur un bordereau de livraison : l\'OCR '
            'reconnait les noms + adresses et les ajoute a la tournee. '
            'Trois formats reconnus :',
            style: TextStyle(
              fontSize: 14,
              color: p.textMute,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x18),
          ..._formats.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldSoft,
                      borderRadius: BorderRadius.circular(AppRadius.r6),
                    ),
                    child: Text(
                      f.$1,
                      style: appMonoStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.emerald,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x10),
                  Expanded(
                    child: Text(
                      f.$2,
                      style: TextStyle(
                        fontSize: 13,
                        color: p.ink,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Accessible depuis le menu Plus -> "Scanner un bordereau" '
            'pendant la creation d\'une tournee.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  static const _formats = <(String, String)>[
    ('MESEXP', 'Format generique francais (tableau Destinataire / Lieu / Total colis).'),
    ('COLISSIMO', 'Etiquettes La Poste avec tracking 6A/6L/8L/9N.'),
    ('CHRONOPOST', 'Etiquettes Chronopost avec tracking XR/XE...FR.'),
  ];
}

class _PageChefEquipe extends StatelessWidget {
  const _PageChefEquipe();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x22,
        vertical: AppSpacing.x28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.emerald,
              borderRadius: BorderRadius.circular(AppRadius.r22),
            ),
            child: const Icon(
              Icons.groups_outlined,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.x22),
          Text(
            'Mode equipe & facturation',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          Text(
            'Tu es chef d\'equipe ou tu factures sous une raison '
            'sociale ? L\'app inclut tout ce qu\'il faut :',
            style: TextStyle(
              fontSize: 14,
              color: p.textMute,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x18),
          ..._features.map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.x12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.emeraldSoft,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(f.$1, size: 16, color: AppColors.emerald),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.$2,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f.$3,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: p.textMute,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Activable plus tard dans Parametres -> Mode chef d\'equipe.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static const _features = <(IconData, String, String)>[
    (
      Icons.assignment_ind_outlined,
      'Affectation des arrets',
      'Distribue chaque livraison a un coequipier depuis la bottom sheet.',
    ),
    (
      Icons.share_outlined,
      'Partage cible',
      'WhatsApp/SMS direct au bon coequipier avec son lot d\'arrets.',
    ),
    (
      Icons.picture_as_pdf_outlined,
      'PDF par coequipier',
      'Genere un PDF separe pour chaque membre de l\'equipe.',
    ),
    (
      Icons.euro_outlined,
      'Recap de facturation',
      'Tarif au km / au colis / a l\'arret + cout carburant = marge brute.',
    ),
  ];
}

class _PageOrsKey extends StatelessWidget {
  const _PageOrsKey({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x22,
        vertical: AppSpacing.x28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: p.creamSoft,
              borderRadius: BorderRadius.circular(AppRadius.r22),
            ),
            child: Icon(
              Icons.bolt_outlined,
              size: 40,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x22),
          Text(
            'Cle OpenRouteService',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          Text(
            'Pour activer l\'optimisation de tournees, il faut une cle '
            'gratuite OpenRouteService. 500 optimisations par jour, '
            'aucune carte de credit demandee.',
            style: TextStyle(
              fontSize: 14,
              color: p.textMute,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          OutlinedButton.icon(
            onPressed: () => launchUrl(
              Uri.parse('https://openrouteservice.org/dev/#/signup'),
              mode: LaunchMode.externalApplication,
            ),
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Creer un compte gratuit'),
          ),
          const SizedBox(height: AppSpacing.x18),
          TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Cle API ORS',
              hintText: 'Environ 40 caracteres',
              helperText: 'Tu peux la coller plus tard depuis Parametres.',
              helperMaxLines: 2,
            ),
            autocorrect: false,
            enableSuggestions: false,
          ),
        ],
      ),
    );
  }
}

class _Indicators extends StatelessWidget {
  const _Indicators({required this.currentPage, required this.total});

  final int currentPage;
  final int total;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: i == currentPage ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == currentPage ? p.ink : p.inkLine,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}
