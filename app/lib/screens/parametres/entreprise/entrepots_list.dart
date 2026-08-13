import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/cloud_error_humanizer.dart';
import '../../../data/database.dart';
import '../../../providers/database_providers.dart';
import '../../../theme/app_tokens.dart';
import 'info_ligne.dart';

/// ════════════════════════════════════════════════════════════════
/// Liste des entrepôts d'une entreprise (bloc de la carte, F27).
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `entreprise_multi_tenant_section.dart`. Lit le miroir
/// local Drift via `entrepotsParEntrepriseProvider` (aucun SQL direct
/// dans l'écran) et affiche :
///   - un état vide « Aucun entrepôt pour l'instant. » ;
///   - une ligne par entrepôt (nom + adresse optionnelle) ;
///   - le bouton « Ajouter un entrepôt » **réservé à l'admin**.
///
/// [isAdmin] est la même garde qu'avant le découpage : elle vient du
/// `entreprise.createdBy == userId` calculé par la carte parente. Côté
/// serveur, la RLS re-vérifie de toute façon la création d'entrepôt.
class EntrepotsList extends ConsumerWidget {
  const EntrepotsList({
    super.key,
    required this.entrepriseId,
    required this.isAdmin,
    required this.busy,
    required this.onAjouterEntrepot,
  });

  /// `cloudId` de l'entreprise dont on liste les entrepôts.
  final String entrepriseId;

  /// Vrai si l'utilisateur courant est le créateur de l'entreprise :
  /// seul lui voit le bouton « Ajouter un entrepôt ».
  final bool isAdmin;

  /// Une action cloud est déjà en cours -> bouton désactivé.
  final bool busy;

  final VoidCallback onAjouterEntrepot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(entrepotsParEntrepriseProvider(entrepriseId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) =>
          InfoLigne(icon: Icons.error_outline, texte: humanizeCloudError(e)),
      data: (entrepots) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entrepots.isEmpty)
              Text(
                'Aucun entrepôt pour l\'instant.',
                style: TextStyle(fontSize: 12.5, color: p.textMute),
              )
            else
              for (final ent in entrepots) _EntrepotRow(ent),
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.x8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: busy ? null : onAjouterEntrepot,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un entrepôt'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Une ligne d'entrepôt : icône, nom en gras, adresse en dessous si
/// elle est renseignée. Purement informatif (pas d'action).
class _EntrepotRow extends StatelessWidget {
  const _EntrepotRow(this.entrepot);

  final Entrepot entrepot;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Icon(Icons.warehouse_outlined, size: 18, color: p.textMute),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(entrepot.nom,
                    style:
                        TextStyle(color: p.ink, fontWeight: FontWeight.w600)),
                if (entrepot.adresse != null)
                  Text(entrepot.adresse!,
                      style: TextStyle(fontSize: 12, color: p.textMute)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
