import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_tokens.dart';
import '../widgets/pointage_card.dart';
import 'parametres/parametres_categories.dart';
import 'parametres/parametres_widgets.dart';

/// Écran « Paramètres » — refonte #401.
///
/// Désormais un HUB : la carte Pointage (usage quotidien) en haut, puis une
/// liste de CATÉGORIES. Chaque catégorie ouvre un écran focalisé
/// (`parametres_categories.dart`) qui réutilise les widgets de section
/// existants. But : un écran lisible et ergonomique sur mobile, au lieu
/// d'un seul long défilement de ~18 sections.
class ParametresScreen extends ConsumerWidget {
  const ParametresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x16),
        children: [
          // Pointage = action quotidienne (début/fin de service + cumul),
          // pas un réglage -> reste accessible directement, en tête.
          const ParametresSectionTitle('Temps de travail'),
          const SizedBox(height: AppSpacing.x10),
          const PointageCard(),
          const SizedBox(height: AppSpacing.x22),
          const ParametresSectionTitle('Réglages'),
          const SizedBox(height: AppSpacing.x10),
          ..._categories.map((c) => _CategoryTile(category: c)),
        ],
      ),
    );
  }
}

/// Description d'une catégorie du hub (icône + titre + sous-titre + écran).
class _Category {
  const _Category({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.builder,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final WidgetBuilder builder;
}

const _categories = <_Category>[
  _Category(
    icon: Icons.route_outlined,
    title: 'Tournée & carburant',
    subtitle: 'Géocodage, clé ORS, défauts de tournée, prix carburant',
    builder: _buildTournee,
  ),
  _Category(
    icon: Icons.palette_outlined,
    title: 'Apparence & notifications',
    subtitle: 'Thème jour/nuit, accessibilité, alertes',
    builder: _buildApparence,
  ),
  _Category(
    icon: Icons.groups_outlined,
    title: 'Compte & équipe',
    subtitle: 'Compte cloud, entreprise, entrepôts, coéquipiers',
    builder: _buildCompte,
  ),
  _Category(
    icon: Icons.save_outlined,
    title: 'Données & stockage',
    subtitle: 'Sauvegardes, restauration, OCR, cache',
    builder: _buildDonnees,
  ),
  _Category(
    icon: Icons.lock_outline,
    title: 'Sécurité',
    subtitle: 'Verrou par code PIN et biométrie',
    builder: _buildSecurite,
  ),
  _Category(
    icon: Icons.info_outline,
    title: 'Application & aide',
    subtitle: 'Version, mise à jour, FAQ, diagnostic, mentions légales',
    builder: _buildApplication,
  ),
];

// Builders top-level (fonctions const-compatibles pour la liste ci-dessus).
Widget _buildTournee(BuildContext _) => const TourneeParamsScreen();
Widget _buildApparence(BuildContext _) => const ApparenceParamsScreen();
Widget _buildCompte(BuildContext _) => const CompteEquipeParamsScreen();
Widget _buildDonnees(BuildContext _) => const DonneesParamsScreen();
Widget _buildSecurite(BuildContext _) => const SecuriteParamsScreen();
Widget _buildApplication(BuildContext _) => const ApplicationParamsScreen();

/// Tuile de catégorie dans le hub : carte cliquable icône + texte + chevron.
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.category});

  final _Category category;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x10),
      child: Material(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: category.builder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x16,
              vertical: AppSpacing.x14,
            ),
            child: Row(
              children: [
                Icon(category.icon, color: AppColors.emerald),
                const SizedBox(width: AppSpacing.x16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        category.subtitle,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: p.textMute,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.x8),
                Icon(Icons.chevron_right, color: p.textFaint),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
