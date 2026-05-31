import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud_error_humanizer.dart';
import '../providers/database_providers.dart';
import '../providers/supabase_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/snack.dart';

/// ════════════════════════════════════════════════════════════════
/// Écran « Qui es-tu ? » au 1er démarrage (carte #373, spec #372).
/// ════════════════════════════════════════════════════════════════
///
/// Épopée multi-tenant #361. S'affiche une fois (après le walkthrough
/// d'onboarding, avant le contenu) tant que `profil_type` n'est pas
/// posé — y compris pour les utilisateurs existants au 1er update qui
/// embarque cet écran (décision Noah : ré-afficher une fois).
///
/// 4 profils :
///  1. **Je travaille seul** → `solo` → accès total (comportement
///     actuel, gratuit). Branche pleinement fonctionnelle.
///  2. **Je rejoins une équipe / chef d'entrepôt** → `employe` : saisie
///     du **code à 6 chiffres** fourni par le chef → RPC
///     `accept_entreprise_invitation` (#366). Fonctionnel.
///  3. **Je suis chef d'entreprise** → `chef_entreprise` + mode chef →
///     crée son entreprise dans Paramètres > Mon entreprise (#364).
///
/// UI simple/fonctionnelle (refonte UX globale plus tard, cf préférence
/// Noah). Aucune donnée locale touchée : cet écran ne pose qu'un flag
/// (sauf « rejoindre » qui crée l'adhésion cloud puis pull).
class ProfilChoiceScreen extends ConsumerStatefulWidget {
  const ProfilChoiceScreen({super.key});

  @override
  ConsumerState<ProfilChoiceScreen> createState() =>
      _ProfilChoiceScreenState();
}

class _ProfilChoiceScreenState extends ConsumerState<ProfilChoiceScreen> {
  bool _busy = false;

  Future<void> _choisirSolo() async {
    await ref.read(parametresRepositoryProvider).setProfilType('solo');
    // Le routeur (HomeScreen) rebascule automatiquement via le stream.
  }

  Future<void> _choisirChefEntreprise() async {
    final repo = ref.read(parametresRepositoryProvider);
    await repo.setProfilType('chef_entreprise');
    // Active la vue chef -> débloque le tableau de bord + la section
    // « Mon entreprise » des Paramètres.
    await repo.setModeChef(true);
    if (mounted) {
      context.showInfo(
        'Crée ton entreprise dans Paramètres → Mon entreprise.',
        duration: const Duration(seconds: 5),
      );
    }
  }

  /// Profils « rejoindre une équipe » / « chef d'entrepôt » : saisie du
  /// code à 6 chiffres. Nécessite d'être connecté au cloud (sinon on
  /// invite à se connecter d'abord).
  Future<void> _choisirRejoindre() async {
    final user = ref.read(cloudUserProvider).asData?.value;
    if (user == null) {
      // Pose quand même le profil (l'employé rejoindra après connexion).
      await ref.read(parametresRepositoryProvider).setProfilType('employe');
      if (mounted) {
        context.showInfo(
          'Connecte ton compte cloud (Paramètres → Compte cloud), '
          'puis saisis le code de ton chef.',
          duration: const Duration(seconds: 6),
        );
      }
      return;
    }
    // Capture le messenger AVANT tout await (BuildContext across async gap).
    final messenger = ScaffoldMessenger.of(context);
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _CodeDialog(),
    );
    if (code == null) return;
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final sync = ref.read(cloudSyncServiceProvider);
      await sync.acceptEntrepriseInvitationByCode(code);
      // Récupère l'entreprise + entrepôts + carnet partagé rejoints.
      await sync.pullMesEntreprises();
      await ref
          .read(parametresRepositoryProvider)
          .setProfilType('employe');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Bienvenue dans l\'équipe ! Accès accordé.'),
          backgroundColor: AppColors.emerald,
        ),
      );
      // Le routeur rebascule via le stream profilType.
    } catch (e) {
      if (mounted) setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(humanizeCloudError(e)),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.cream,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.x22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.x18),
                  const Icon(Icons.waving_hand_outlined,
                      size: 56, color: AppColors.lime),
                  const SizedBox(height: AppSpacing.x16),
                  Text(
                    'Qui es-tu ?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: AppSpacing.x8),
                  Text(
                    'Choisis comment tu utilises opti_route. Tu pourras '
                    'changer plus tard dans les Paramètres. Tes données '
                    '(carnet, tournées) sont conservées quel que soit '
                    'ton choix.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 13, color: p.textMute, height: 1.4),
                  ),
                  const SizedBox(height: AppSpacing.x22),
                  _ProfilCard(
                    icon: Icons.person_outline,
                    title: 'Je travaille seul',
                    subtitle: 'Accès complet à l\'app, gratuit. Tout reste '
                        'sur ton téléphone.',
                    onTap: _busy ? null : _choisirSolo,
                  ),
                  const SizedBox(height: AppSpacing.x12),
                  _ProfilCard(
                    icon: Icons.groups_outlined,
                    title: 'Je rejoins une équipe',
                    subtitle: 'Ton chef t\'a donné un code. Saisis-le pour '
                        'accéder au carnet partagé.',
                    onTap: _busy ? null : _choisirRejoindre,
                  ),
                  const SizedBox(height: AppSpacing.x12),
                  _ProfilCard(
                    icon: Icons.business_outlined,
                    title: 'Je suis chef d\'entreprise',
                    subtitle:
                        'Tu crées ton entreprise et invites tes employés.',
                    onTap: _busy ? null : _choisirChefEntreprise,
                  ),
                ],
              ),
            ),
            if (_busy)
              const ColoredBox(
                color: Color(0x55000000),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfilCard extends StatelessWidget {
  const _ProfilCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Material(
      color: p.paper,
      borderRadius: BorderRadius.circular(AppRadius.r16),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: p.creamSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: p.ink),
              ),
              const SizedBox(width: AppSpacing.x14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.ink)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style:
                            TextStyle(fontSize: 12.5, color: p.textMute)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: p.textMute),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog de saisie du code d'invitation à 6 chiffres (#373 → RPC #366).
class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState?.validate() ?? false) {
      Navigator.of(context).pop(_ctrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rejoindre une équipe'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Saisis le code à 6 chiffres que ton chef t\'a donné.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.x12),
            TextFormField(
              controller: _ctrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 6),
              decoration: const InputDecoration(
                hintText: '123456',
                counterText: '',
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (!RegExp(r'^[0-9]{6}$').hasMatch(s)) {
                  return 'Le code doit faire 6 chiffres';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _valider, child: const Text('Rejoindre')),
      ],
    );
  }
}
