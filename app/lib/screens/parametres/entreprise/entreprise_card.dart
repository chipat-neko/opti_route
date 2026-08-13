import 'package:flutter/material.dart';

import '../../../data/cloud/cloud_membres_entreprise_sync.dart'
    show EntrepriseMembreInfo;
import '../../../data/database.dart';
import '../../../theme/app_tokens.dart';
import '../../liste_employes_screen.dart';
import 'entrepots_list.dart';
import 'entreprise_badges.dart';
import 'membres_list.dart';

/// ════════════════════════════════════════════════════════════════
/// Carte d'une entreprise dans la section « Mon entreprise » (F27).
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `entreprise_multi_tenant_section.dart`. Empile, pour une
/// entreprise du miroir local :
///   1. l'en-tête (nom, badges plan/admin, menu Supprimer / Quitter) ;
///   2. le SIRET s'il est renseigné ;
///   3. la liste des entrepôts ([EntrepotsList]) ;
///   4. la liste des employés ([MembresList]) ;
///   5. l'accès à l'écran « Liste des employés » (admin seulement).
///
/// **Permissions** : `isAdmin` est calculé ici, comme avant le
/// découpage, par `entreprise.createdBy == userId` — c'est la seule
/// source de vérité côté UI et elle est passée telle quelle aux sous-
/// listes. Le menu « … » propose « Supprimer l'entreprise » à l'admin
/// et « Quitter l'entreprise » aux autres (jamais les deux).
///
/// Ce widget ne fait aucun appel cloud : il remonte les intentions au
/// parent via les callbacks, qui gèrent l'état `busy` et les erreurs.
class EntrepriseCard extends StatelessWidget {
  const EntrepriseCard({
    super.key,
    required this.entreprise,
    required this.userId,
    required this.busy,
    required this.onSupprimer,
    required this.onQuitter,
    required this.onAjouterEntrepot,
    required this.onInviterMembre,
    required this.onRevoquerMembre,
  });

  final Entreprise entreprise;

  /// Id du compte cloud connecté, comparé à `entreprise.createdBy`
  /// pour déterminer si l'utilisateur est admin de cette entreprise.
  final String userId;

  /// Une action cloud est déjà en cours -> boutons/menu désactivés.
  final bool busy;

  final VoidCallback onSupprimer;
  final VoidCallback onQuitter;
  final VoidCallback onAjouterEntrepot;
  final VoidCallback onInviterMembre;
  final void Function(EntrepriseMembreInfo membre) onRevoquerMembre;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isAdmin = entreprise.createdBy == userId;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x12),
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.business, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  entreprise.nom,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              // Badge du plan/abonnement (#381-A) : informatif uniquement,
              // aucune limite appliquee a ce stade.
              BadgePlan(entreprise.plan),
              const SizedBox(width: AppSpacing.x4),
              if (isAdmin) const BadgeAdmin(),
              // Menu sortie : Supprimer (admin) ou Quitter (membre).
              PopupMenuButton<String>(
                tooltip: 'Options',
                enabled: !busy,
                icon: Icon(Icons.more_vert, size: 20, color: p.textMute),
                onSelected: (v) {
                  if (v == 'delete') onSupprimer();
                  if (v == 'leave') onQuitter();
                },
                itemBuilder: (_) => [
                  if (isAdmin)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer l\'entreprise'),
                    )
                  else
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Quitter l\'entreprise'),
                    ),
                ],
              ),
            ],
          ),
          if (entreprise.siret != null) ...[
            const SizedBox(height: AppSpacing.x4),
            Text('SIRET ${entreprise.siret}',
                style: TextStyle(fontSize: 12, color: p.textMute)),
          ],
          const Divider(height: AppSpacing.x22),
          EntrepotsList(
            entrepriseId: entreprise.cloudId,
            isAdmin: isAdmin,
            busy: busy,
            onAjouterEntrepot: onAjouterEntrepot,
          ),
          const Divider(height: AppSpacing.x22),
          MembresList(
            entrepriseId: entreprise.cloudId,
            isAdmin: isAdmin,
            busy: busy,
            onInviterMembre: onInviterMembre,
            onRevoquerMembre: onRevoquerMembre,
          ),
          // Admin : accès à l'écran "Liste des employés" organisé par
          // entrepôt (chefs / chauffeurs) avec mutation (#361).
          if (isAdmin) ...[
            const SizedBox(height: AppSpacing.x10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: busy
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ListeEmployesScreen(
                              entrepriseId: entreprise.cloudId,
                              titre: 'Employés — ${entreprise.nom}',
                              peutMuter: true,
                            ),
                          ),
                        ),
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Liste des employés (par entrepôt)'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
