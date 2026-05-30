import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_tokens.dart';
import '../widgets/pointage_card.dart';
import '../widgets/role_gated.dart';
import '../widgets/update_check_card.dart';
import 'backups_list_screen.dart';
import 'mentions_legales_screen.dart';
import 'parametres/aide_section.dart';
import 'parametres/apparence_accessibilite_section.dart';
import 'parametres/carburant_section.dart';
import 'parametres/cache_section.dart';
import 'parametres/cloud_section.dart';
import 'parametres/donnees_section.dart';
import 'parametres/entreprise_equipe_section.dart';
import 'parametres/notifications_section.dart';
import 'parametres/ocr_stats_tile.dart';
import 'parametres/ors_section.dart';
import 'parametres/parametres_widgets.dart';
import 'parametres/securite_section.dart';
import 'parametres/tournee_defaults_section.dart';

/// Ecran "Parametres" : ossature ListView qui chaine toutes les
/// sections autonomes du dossier `lib/screens/parametres/`. Aucune
/// logique metier ici, chaque section gere son state et ses appels
/// au repository. Voir carte Trello #151 pour l'historique de
/// l'extraction (fichier passe de 1076 a ~150 lignes).
class ParametresScreen extends ConsumerWidget {
  const ParametresScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: const [
          // Carte #279 : pointage debut/fin de service + cumul jour/semaine.
          ParametresSectionTitle('Temps de travail'),
          SizedBox(height: AppSpacing.x10),
          PointageCard(),
          _Sep(),
          // Carte #update_checker : verification + lancement MAJ MSIX
          // Windows (gatée chef car le workflow build/install est chef).
          RoleGated(
            featureKey: 'app.update_checker',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ParametresSectionTitle('Mise à jour'),
                SizedBox(height: AppSpacing.x10),
                UpdateCheckCard(),
                _Sep(),
              ],
            ),
          ),
          ParametresSectionTitle('Geocodage'),
          SizedBox(height: AppSpacing.x10),
          StatusCard(
            highlight: true,
            icon: Icons.verified_outlined,
            title: 'Geocodage 3 sources',
            subtitle:
                'BAN (cadastre officiel) · Recherche-Entreprises '
                '(SIRENE/INSEE) · Photon/OSM (enseignes & marques). '
                'Aucune cle, aucune limite stricte.',
          ),
          _Sep(),
          OrsSection(),
          _Sep(),
          TourneeDefaultsSection(),
          _Sep(),
          CarburantSection(),
          _Sep(),
          CacheSection(),
          _Sep(),
          NotificationsSection(),
          _Sep(),
          ApparenceSection(),
          _Sep(),
          AccessibiliteSection(),
          _Sep(),
          EntrepriseEquipeSection(),
          _Sep(),
          _CloudSectionBlock(),
          _Sep(),
          _SecuriteSectionBlock(),
          _Sep(),
          _DonneesSectionBlock(),
          _Sep(),
          _AboutSectionBlock(),
        ],
      ),
    );
  }
}

/// Separateur reutilise entre chaque section : marge + Divider + marge.
class _Sep extends StatelessWidget {
  const _Sep();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: AppSpacing.x28),
        Divider(),
        SizedBox(height: AppSpacing.x18),
      ],
    );
  }
}

/// Bloc "Compte cloud" : titre + intro + section.
class _CloudSectionBlock extends StatelessWidget {
  const _CloudSectionBlock();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Compte cloud'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Phase 2 (en construction) : connecte un compte pour '
          'synchroniser entre tes appareils et partager les tournees '
          'avec tes coequipiers en temps reel. Pour l\'instant le '
          'mode local-only reste l\'autorite.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x12),
        const CloudSection(),
      ],
    );
  }
}

/// Bloc "Securite" : titre + intro + section.
class _SecuriteSectionBlock extends StatelessWidget {
  const _SecuriteSectionBlock();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Securite'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Verrouille l\'app avec un code a 4 chiffres (et la biometrie '
          'si ton phone le supporte). Protege le carnet clients, les '
          'codes interphones et les photos preuves si tu perds ton '
          'telephone.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x12),
        const SecuriteSection(),
      ],
    );
  }
}

/// Bloc "Donnees" : sauvegarde / restauration / OCR stats / liste backups.
class _DonneesSectionBlock extends StatelessWidget {
  const _DonneesSectionBlock();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Donnees'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Sauvegarde complete de l\'app dans un zip portable '
          '(DB SQLite + photos preuves). Conserve sur Drive ou clef '
          'USB pour retrouver tes donnees en cas de perte du phone.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x10),
        const BackupTile(),
        const RestoreTile(),
        const AutoBackupTile(),
        const OcrStatsTile(),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.folder_open_outlined),
          title: const Text('Mes backups'),
          subtitle: const Text(
            'Voir, partager ou supprimer les .zip auto-generes',
            style: TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const BackupsListScreen(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Bloc "A propos" : aide + mentions legales.
class _AboutSectionBlock extends StatelessWidget {
  const _AboutSectionBlock();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('A propos'),
        const SizedBox(height: AppSpacing.x10),
        const AideSection(),
        ListTile(
          leading: const Icon(Icons.policy_outlined),
          title: const Text('Mentions legales'),
          subtitle: const Text(
            'Confidentialite + conditions d\'utilisation',
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
