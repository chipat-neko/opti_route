import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/supabase_service.dart';
import '../providers/database_providers.dart';
import '../providers/supabase_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/snack.dart';

/// ════════════════════════════════════════════════════════════════
/// Écran « Diagnostic » — récap technique factuel pour le support.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche UNIQUEMENT des données réelles déjà présentes dans l'app
/// (version, état cloud, rôle, nb entreprises/entrepôts). Aucune donnée
/// inventée, aucune action destructrice. Bouton « Copier » pour que
/// l'utilisateur colle son récap dans un message de support (le support
/// sait alors version + état sans deviner).
///
/// Ne montre PAS de données sensibles (pas d'email complet, pas de token) :
/// l'email est masqué partiellement (RGPD + capture d'écran).
class DiagnosticScreen extends ConsumerWidget {
  const DiagnosticScreen({super.key});

  /// Masque le milieu d'un email : lucas@gmail.com -> l***@gmail.com.
  static String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return '—';
    final at = email.indexOf('@');
    if (at <= 1) return '***${at >= 0 ? email.substring(at) : ''}';
    return '${email[0]}***${email.substring(at)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final user = ref.watch(cloudUserProvider).asData?.value;
    final role = ref.watch(monRoleProvider).asData?.value;
    final entreprises =
        ref.watch(mesEntreprisesProvider).asData?.value ?? const [];
    final cloudConfigure = SupabaseService.instance.isConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text('Diagnostic')),
      body: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snap) {
          final version = snap.hasData
              ? '${snap.data!.version}+${snap.data!.buildNumber}'
              : '…';
          final lignes = <(String, String)>[
            ('Version', version),
            ('Cloud configuré', cloudConfigure ? 'oui' : 'non'),
            ('Connecté', user != null ? 'oui' : 'non'),
            ('Compte', _maskEmail(user?.email)),
            (
              'Rôle',
              role == null
                  ? (user == null ? 'non connecté' : 'solo / aucune entreprise')
                  : role.isAdminEntreprise
                      ? 'chef d\'entreprise'
                      : role.isChefEntrepot
                          ? 'chef d\'entrepôt'
                          : 'chauffeur'
            ),
            ('Entreprises (local)', '${entreprises.length}'),
          ];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.x16),
            children: [
              Text(
                'Infos techniques utiles si tu contactes le support. '
                'Aucune donnée sensible n\'est affichée (email masqué).',
                style:
                    TextStyle(fontSize: 13, color: p.textMute, height: 1.5),
              ),
              const SizedBox(height: AppSpacing.x16),
              Container(
                padding: const EdgeInsets.all(AppSpacing.x14),
                decoration: BoxDecoration(
                  color: p.creamSoft,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                ),
                child: Column(
                  children: [
                    for (final l in lignes) _ligne(context, l.$1, l.$2),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
              FilledButton.icon(
                onPressed: () {
                  final txt = lignes.map((l) => '${l.$1} : ${l.$2}').join('\n');
                  Clipboard.setData(
                      ClipboardData(text: 'opti_route diagnostic\n$txt'));
                  context.showSuccess('Diagnostic copié');
                },
                icon: const Icon(Icons.copy_outlined, size: 18),
                label: const Text('Copier le diagnostic'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _ligne(BuildContext context, String cle, String valeur) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(cle,
                style: TextStyle(fontSize: 13, color: p.textMute)),
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(valeur,
                style:
                    TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.ink)),
          ),
        ],
      ),
    );
  }
}
