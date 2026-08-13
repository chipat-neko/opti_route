import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/cloud/cloud_membres_entreprise_sync.dart'
    show EntrepriseMembreInfo;
import '../../../data/cloud_error_humanizer.dart';
import '../../../providers/supabase_providers.dart';
import '../../../theme/app_tokens.dart';
import 'info_ligne.dart';

/// ════════════════════════════════════════════════════════════════
/// Liste des membres / employés d'une entreprise (carte #366, F27).
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `entreprise_multi_tenant_section.dart`. Lit
/// `entrepriseMembresProvider` (Supabase, RLS) et affiche pour chaque
/// membre son nom, son rôle, son entrepôt et son statut (actif /
/// révoqué J-n / expiré).
///
/// **Gardes de permission** (identiques à avant le découpage) :
///   - « Inviter un employé » n'est proposé que si [isAdmin] ;
///   - le bouton « Révoquer » n'apparaît que si [isAdmin] **et** que le
///     membre est `actif` **et** que son rôle n'est pas
///     `admin_entreprise` : la garde couvre donc *tous* les admins, pas
///     seulement soi-même (le commentaire d'origine, conservé plus bas,
///     dit « pas sur soi-même » — il est plus permissif que le code).
///
/// Ces gardes sont uniquement de l'affichage : la révocation réelle est
/// re-vérifiée côté serveur.
class MembresList extends ConsumerWidget {
  const MembresList({
    super.key,
    required this.entrepriseId,
    required this.isAdmin,
    required this.busy,
    required this.onInviterMembre,
    required this.onRevoquerMembre,
  });

  /// `cloudId` de l'entreprise dont on liste les membres.
  final String entrepriseId;

  /// Vrai si l'utilisateur courant est le créateur de l'entreprise.
  final bool isAdmin;

  /// Une action cloud est déjà en cours -> boutons désactivés.
  final bool busy;

  final VoidCallback onInviterMembre;
  final void Function(EntrepriseMembreInfo membre) onRevoquerMembre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(entrepriseMembresProvider(entrepriseId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.groups_outlined, size: 18, color: p.ink),
            const SizedBox(width: AppSpacing.x8),
            Text('Employés',
                style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.x8),
            child: LinearProgressIndicator(),
          ),
          error: (err, _) => InfoLigne(
              icon: Icons.error_outline, texte: humanizeCloudError(err)),
          data: (membres) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (membres.isEmpty)
                  Text('Aucun employé pour l\'instant.',
                      style: TextStyle(fontSize: 12.5, color: p.textMute))
                else
                  for (final m in membres)
                    _MembreRow(
                      membre: m,
                      isAdmin: isAdmin,
                      busy: busy,
                      onRevoquer: () => onRevoquerMembre(m),
                    ),
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.x8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: busy ? null : onInviterMembre,
                      icon: const Icon(Icons.person_add_alt_1_outlined,
                          size: 18),
                      label: const Text('Inviter un employé'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Une ligne de membre : nom, « rôle · entrepôt », pastille de statut
/// et (admin seulement) le bouton « Révoquer ».
class _MembreRow extends StatelessWidget {
  const _MembreRow({
    required this.membre,
    required this.isAdmin,
    required this.busy,
    required this.onRevoquer,
  });

  final EntrepriseMembreInfo membre;
  final bool isAdmin;
  final bool busy;
  final VoidCallback onRevoquer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final jours = membre.joursAvantExpiration;
    final (statutLabel, statutColor) = switch (membre.statut) {
      'actif' => ('actif', AppColors.emerald),
      'revoque' => (
          jours == null ? 'révoqué' : 'révoqué · J-$jours',
          AppColors.amber
        ),
      _ => ('expiré', AppColors.red),
    };
    final roleLabel = switch (membre.role) {
      'admin_entreprise' => 'Admin',
      'chef_entrepot' => 'Chef entrepôt',
      'membre' => 'Membre',
      _ => membre.role,
    };
    final sousTitre = [
      roleLabel,
      if (membre.entrepotNom != null) membre.entrepotNom!,
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: p.textMute),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(membre.nomAffiche,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: p.ink, fontWeight: FontWeight.w600)),
                Text(sousTitre,
                    style: TextStyle(fontSize: 12, color: p.textMute)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x8, vertical: 2),
            decoration: BoxDecoration(
              color: statutColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(statutLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statutColor)),
          ),
          // Révoquer : admin uniquement, pas sur soi-même, pas sur un
          // membre déjà révoqué/expiré.
          if (isAdmin &&
              membre.statut == 'actif' &&
              membre.role != 'admin_entreprise')
            IconButton(
              tooltip: 'Révoquer',
              icon: const Icon(Icons.person_remove_outlined, size: 20),
              onPressed: busy ? null : onRevoquer,
            ),
        ],
      ),
    );
  }
}
