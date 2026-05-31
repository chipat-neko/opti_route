import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import 'carnet_migration_wizard.dart';

/// Banner persistant proposant de partager le carnet local avec
/// l'entreprise (carte #365, épopée multi-tenant #361).
///
/// Ne s'affiche **que si les 3 conditions** sont réunies :
///   1. l'utilisateur a au moins une entreprise (sinon rien à partager) ;
///   2. il reste des adresses privées dans le carnet ;
///   3. le wizard n'a pas déjà été marqué terminé.
///
/// Sinon → `SizedBox.shrink()` (invisible). Tap → ouvre le wizard
/// plein-écran sur la 1re entreprise de l'utilisateur.
class CarnetMigrationBanner extends ConsumerWidget {
  const CarnetMigrationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entreprises = ref.watch(mesEntreprisesProvider).asData?.value;
    final done = ref.watch(carnetMigrationDoneProvider).asData?.value ?? false;
    final nbPrivees =
        ref.watch(carnetPriveesCountProvider).asData?.value ?? 0;

    if (entreprises == null || entreprises.isEmpty) {
      return const SizedBox.shrink();
    }
    if (done || nbPrivees == 0) return const SizedBox.shrink();

    final p = context.palette;
    final entreprise = entreprises.first;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        0,
        AppSpacing.x16,
        AppSpacing.x8,
      ),
      child: Material(
        color: AppColors.lime.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r12),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => CarnetMigrationWizard(entreprise: entreprise),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x12),
            child: Row(
              children: [
                Icon(Icons.cloud_sync_outlined, color: p.ink, size: 22),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Partager ton carnet avec ${entreprise.nom} ?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: p.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Tu as $nbPrivees adresse${nbPrivees > 1 ? "s" : ""} '
                        'locale${nbPrivees > 1 ? "s" : ""}. Choisis '
                        'lesquelles partager avec tes employés.',
                        style: TextStyle(fontSize: 12, color: p.textMute),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: p.textMute),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
