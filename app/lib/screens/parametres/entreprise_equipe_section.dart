import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import '../coequipiers_screen.dart';
import 'entreprise_form.dart';
import 'parametres_widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Entreprise & equipe" + "Mon equipe".
/// ════════════════════════════════════════════════════════════════
///
/// Trois blocs :
///   - Formulaire des infos entreprise (raison sociale, SIRET, etc.)
///   - SwitchListTile "Mode chef d'equipe" -> active la vue tableau
///     de bord equipe + affectation en masse
///   - ListTile "Coequipiers" -> pousse [CoequipiersScreen]
class EntrepriseEquipeSection extends ConsumerWidget {
  const EntrepriseEquipeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final repo = ref.watch(parametresRepositoryProvider);
    final modeChef = ref.watch(modeChefProvider).asData?.value ?? false;
    final coequipiers =
        ref.watch(coequipiersAllProvider).asData?.value ?? const [];
    final nbActifs = coequipiers.where((c) => c.actif).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Entreprise & equipe'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Si tu es chef d\'equipe ou si tu factures sous une raison '
          'sociale, renseigne tes infos pour personnaliser tes exports.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x12),
        const EntrepriseForm(),
        const SizedBox(height: AppSpacing.x14),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: modeChef,
          title: const Text('Mode chef d\'equipe'),
          subtitle: const Text(
            'Active le tableau de bord equipe + affectation en masse',
            style: TextStyle(fontSize: 12),
          ),
          onChanged: (v) async {
            await repo.setModeChef(v);
          },
        ),
        const SizedBox(height: AppSpacing.x18),
        const ParametresSectionTitle('Mon equipe'),
        const SizedBox(height: AppSpacing.x10),
        ListTile(
          leading: const Icon(Icons.groups_outlined),
          title: const Text('Coequipiers'),
          subtitle: Text(
            coequipiers.isEmpty
                ? 'Aucun coequipier — ajoute tes aidants pour '
                    'tracker qui livre quoi'
                : '$nbActifs actif${nbActifs > 1 ? "s" : ""}'
                    '${coequipiers.length > nbActifs ? " · ${coequipiers.length - nbActifs} archive${coequipiers.length - nbActifs > 1 ? "s" : ""}" : ""}',
            style: const TextStyle(fontSize: 12),
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const CoequipiersScreen(),
            ),
          ),
        ),
      ],
    );
  }
}
