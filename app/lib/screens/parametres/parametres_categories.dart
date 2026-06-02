import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';
import '../../widgets/role_gated.dart';
import '../../widgets/update_check_card.dart';
import '../../widgets/version_tile.dart';
import '../backups_list_screen.dart';
import '../mentions_legales_screen.dart';
import 'aide_section.dart';
import 'apparence_accessibilite_section.dart';
import 'carburant_section.dart';
import 'cache_section.dart';
import 'cloud_section.dart';
import 'donnees_section.dart';
import 'entreprise_equipe_section.dart';
import 'entreprise_multi_tenant_section.dart';
import 'notifications_section.dart';
import 'ocr_stats_tile.dart';
import 'ors_section.dart';
import 'parametres_widgets.dart';
import 'securite_section.dart';
import 'tournee_defaults_section.dart';

/// ════════════════════════════════════════════════════════════════
/// Écrans-détail des catégories de Paramètres (refonte #401).
/// ════════════════════════════════════════════════════════════════
///
/// L'écran Paramètres est désormais un HUB (liste de catégories). Chaque
/// catégorie ouvre un de ces écrans focalisés, qui RÉUTILISENT les
/// widgets de section existants (`lib/screens/parametres/*_section.dart`)
/// sans réécrire aucune logique métier — chaque section gère son propre
/// state et ses appels repository, exactement comme avant. Seule la
/// PRÉSENTATION change (regroupement + navigation à 1 niveau), pour un
/// écran plus lisible et ergonomique sur mobile.

/// Scaffold commun à toutes les catégories : AppBar avec le titre + un
/// ListView paddé. Évite de répéter la même ossature 6 fois.
class _CategoryScaffold extends StatelessWidget {
  const _CategoryScaffold({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: children,
      ),
    );
  }
}

/// Séparateur entre 2 sections d'un même écran-détail (marge + Divider).
class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: AppSpacing.x22),
        Divider(),
        SizedBox(height: AppSpacing.x16),
      ],
    );
  }
}

/// Petit texte d'intro gris sous un titre de section.
class _Intro extends StatelessWidget {
  const _Intro(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x12),
      child: Text(
        text,
        style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 1. Tournée & carburant
// ─────────────────────────────────────────────────────────────────
class TourneeParamsScreen extends StatelessWidget {
  const TourneeParamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryScaffold(
      title: 'Tournée & carburant',
      children: [
        ParametresSectionTitle('Géocodage'),
        SizedBox(height: AppSpacing.x10),
        StatusCard(
          highlight: true,
          icon: Icons.verified_outlined,
          title: 'Géocodage 3 sources',
          subtitle: 'BAN (cadastre officiel) · Recherche-Entreprises '
              '(SIRENE/INSEE) · Photon/OSM (enseignes & marques). '
              'Aucune clé, aucune limite stricte.',
        ),
        _Sep(),
        OrsSection(),
        _Sep(),
        TourneeDefaultsSection(),
        _Sep(),
        CarburantSection(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 2. Apparence & notifications
// ─────────────────────────────────────────────────────────────────
class ApparenceParamsScreen extends StatelessWidget {
  const ApparenceParamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryScaffold(
      title: 'Apparence & notifications',
      children: [
        ApparenceSection(),
        _Sep(),
        AccessibiliteSection(),
        _Sep(),
        NotificationsSection(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 3. Compte & équipe
// ─────────────────────────────────────────────────────────────────
class CompteEquipeParamsScreen extends StatelessWidget {
  const CompteEquipeParamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryScaffold(
      title: 'Compte & équipe',
      children: [
        ParametresSectionTitle('Compte cloud'),
        SizedBox(height: AppSpacing.x10),
        _Intro(
          'Connecte un compte pour synchroniser entre tes appareils et '
          'partager les tournées avec ton équipe. Sans compte, le mode '
          'local-only reste l\'autorité (tout reste sur ce téléphone).',
        ),
        CloudSection(),
        _Sep(),
        EntrepriseEquipeSection(),
        _Sep(),
        EntrepriseMultiTenantSection(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 4. Données & stockage
// ─────────────────────────────────────────────────────────────────
class DonneesParamsScreen extends StatelessWidget {
  const DonneesParamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CategoryScaffold(
      title: 'Données & stockage',
      children: [
        const ParametresSectionTitle('Sauvegarde'),
        const SizedBox(height: AppSpacing.x10),
        const _Intro(
          'Sauvegarde complète de l\'app dans un zip portable (base SQLite '
          '+ photos preuves). Conserve-le sur Drive ou clé USB pour '
          'retrouver tes données en cas de perte du téléphone.',
        ),
        const BackupTile(),
        const RestoreTile(),
        const AutoBackupTile(),
        const OcrStatsTile(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_open_outlined),
          title: const Text('Mes backups'),
          subtitle: const Text(
            'Voir, partager ou supprimer les .zip auto-générés',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BackupsListScreen(),
            ),
          ),
        ),
        const _Sep(),
        const CacheSection(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 5. Sécurité
// ─────────────────────────────────────────────────────────────────
class SecuriteParamsScreen extends StatelessWidget {
  const SecuriteParamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _CategoryScaffold(
      title: 'Sécurité',
      children: [
        _Intro(
          'Verrouille l\'app avec un code à 4 chiffres (et la biométrie si '
          'ton téléphone le supporte). Protège le carnet clients, les codes '
          'interphones et les photos preuves si tu perds ton téléphone.',
        ),
        SecuriteSection(),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 6. Application & aide
// ─────────────────────────────────────────────────────────────────
class ApplicationParamsScreen extends StatelessWidget {
  const ApplicationParamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return _CategoryScaffold(
      title: 'Application & aide',
      children: [
        const VersionTile(),
        const RoleGated(
          featureKey: 'app.update_checker',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: AppSpacing.x10),
              UpdateCheckCard(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        const Divider(),
        const SizedBox(height: AppSpacing.x8),
        const AideSection(),
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('Mentions légales'),
          subtitle: const Text(
            'Confidentialité + conditions d\'utilisation',
            style: TextStyle(fontSize: 12),
          ),
          contentPadding: EdgeInsets.zero,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const MentionsLegalesScreen(),
            ),
          ),
        ),
      ],
    );
  }
}
