import 'package:flutter/material.dart';

import '../../../data/plan.dart';
import '../../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Pastilles affichées en tête de la carte entreprise (F27).
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `entreprise_multi_tenant_section.dart` :
///   - BadgePlan : plan/abonnement de l'entreprise (#381-A)
///   - BadgeAdmin : « Admin » si l'utilisateur courant est le créateur
///
/// Purement informatif : **aucune** de ces pastilles ne conditionne un
/// droit. Les gardes de permission restent à côté des actions qu'elles
/// protègent (et le serveur re-vérifie via RLS).

/// Badge informatif du plan/abonnement de l'entreprise (#381-A). Affiche
/// le libellé court (Free / Tier 1 / ...). Aucune limite appliquée ici.
class BadgePlan extends StatelessWidget {
  const BadgePlan(this.code, {super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final plan = Plan.fromCode(code);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.x8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        plan.badge,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      ),
    );
  }
}

/// Petit badge « Admin » affiché sur les entreprises dont l'utilisateur
/// courant est le créateur.
class BadgeAdmin extends StatelessWidget {
  const BadgeAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.x8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Admin',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.emerald,
        ),
      ),
    );
  }
}
