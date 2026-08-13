import 'package:flutter/material.dart';

import '../../../data/cloud/cloud_membres_entreprise_sync.dart'
    show EntrepriseMembreInfo;
import '../../../data/database.dart';
import '../../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Confirmations avant les actions destructrices de la section
/// « Mon entreprise » (F27).
/// ════════════════════════════════════════════════════════════════
///
/// Extraites de `entreprise_multi_tenant_section.dart`. Chaque méthode
/// se contente d'afficher l'AlertDialog et de renvoyer la réponse :
/// `true` = confirmé, `false`/`null` = annulé ou dialog fermé.
///
/// **Aucune garde de permission ici** : c'est l'UI appelante qui décide
/// si l'action est proposée (admin vs membre), et le serveur qui
/// tranche pour de bon. Ces dialogs ne font que demander « tu es sûr ».
class EntrepriseConfirmDialogs {
  EntrepriseConfirmDialogs._();

  /// Suppression définitive de l'entreprise (proposée à l'admin).
  static Future<bool?> supprimerEntreprise(
    BuildContext context,
    Entreprise e,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette entreprise ?'),
        content: Text(
          'L\'entreprise « ${e.nom} », ses entrepôts, ses employés et les '
          'invitations en cours seront supprimés définitivement. Cette '
          'action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  /// Sortie volontaire d'une entreprise (proposée aux non-admins).
  static Future<bool?> quitterEntreprise(
    BuildContext context,
    Entreprise e,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter cette entreprise ?'),
        content: Text(
          'Tu n\'auras plus accès au carnet partagé de « ${e.nom} ». Tu '
          'pourras la rejoindre à nouveau avec un code d\'invitation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
  }

  /// Révocation d'un employé : accès coupé progressivement, définitif
  /// après 30 jours (cron #363).
  static Future<bool?> revoquerMembre(
    BuildContext context,
    EntrepriseMembreInfo m,
  ) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Révoquer cet employé ?'),
        content: Text(
          '${m.email} perdra l\'accès au carnet partagé. L\'accès est '
          'coupé progressivement : définitif après 30 jours (tu peux '
          'réactiver avant).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
  }
}
