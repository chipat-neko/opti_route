import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import 'parametres_widgets.dart';
import 'quiet_hours_tile.dart';

/// ════════════════════════════════════════════════════════════════
/// Sections "Apparence" + "Accessibilite & confort" des Parametres.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `parametres_screen.dart` (1109 lignes, refactor #3). Ces
/// 2 sections etaient des candidats naturels car elles ne dependent
/// que de providers Riverpod (themeMode, themePreset, densiteUi,
/// contrasteEleve, veilleReminder) -- pas d'etat local du screen state.
///
/// Inclut le [QuietHoursTile] dans la section Accessibilite car le
/// "Ne pas deranger" est un confort plus qu'une securite.

class ApparenceSection extends ConsumerWidget {
  const ApparenceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ParametresSectionTitle('Apparence'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Mode sombre pour la conduite de nuit. "Auto" suit les '
          'reglages Android.',
          style: TextStyle(
            fontSize: 12.5,
            color: p.textMute,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        Consumer(
          builder: (context, ref, _) {
            final mode = ref.watch(themeModeProvider).asData?.value ??
                ThemeMode.system;
            return Wrap(
              spacing: AppSpacing.x8,
              children: [
                ThemeChip(
                  label: 'Auto',
                  value: ThemeMode.system,
                  groupValue: mode,
                ),
                ThemeChip(
                  label: 'Clair',
                  value: ThemeMode.light,
                  groupValue: mode,
                ),
                ThemeChip(
                  label: 'Sombre',
                  value: ThemeMode.dark,
                  groupValue: mode,
                ),
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.x18),
        Text(
          'Palette de couleurs',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          'Change l\'ambiance des surfaces. Les couleurs metier '
          '(vert = livre, rouge = echec) restent identiques.',
          style: TextStyle(
            fontSize: 12.5,
            color: p.textMute,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        Consumer(
          builder: (context, ref, _) {
            final preset = ref.watch(themePresetProvider).asData?.value ??
                AppThemePreset.lime;
            return Column(
              children: [
                for (final pp in AppThemePreset.all)
                  PaletteTile(
                    preset: pp,
                    selected: pp.name == preset.name,
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class AccessibiliteSection extends ConsumerWidget {
  const AccessibiliteSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const ParametresSectionTitle('Accessibilite & confort'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Adapte l\'interface pour la conduite ou les conditions '
          'difficiles (soleil, vibrations).',
          style: TextStyle(
            fontSize: 12.5,
            color: p.textMute,
            height: 1.4,
          ),
        ),
        const SizedBox(height: AppSpacing.x12),
        Consumer(
          builder: (context, ref, _) {
            final repo = ref.watch(parametresRepositoryProvider);
            final densite = ref.watch(densiteUiProvider).asData?.value ??
                'normal';
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: densite == 'large',
              title: const Text('Mode XL (conduite)'),
              subtitle: const Text(
                'Polices +15%, cibles tactiles agrandies',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (v) async {
                await repo.setDensiteUi(v ? 'large' : 'normal');
              },
            );
          },
        ),
        Consumer(
          builder: (context, ref, _) {
            final repo = ref.watch(parametresRepositoryProvider);
            final contraste = ref
                    .watch(contrasteEleveProvider)
                    .asData
                    ?.value ??
                false;
            return SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: contraste,
              title: const Text('Contraste eleve'),
              subtitle: const Text(
                'Bordures et textes renforces pour lire en plein soleil',
                style: TextStyle(fontSize: 12),
              ),
              onChanged: (v) async {
                await repo.setContrasteEleve(v);
              },
            );
          },
        ),
        Consumer(
          builder: (context, ref, _) {
            final repo = ref.watch(parametresRepositoryProvider);
            final hhmm = ref
                .watch(veilleReminderHHmmProvider)
                .asData
                ?.value;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.bedtime_outlined),
              title: const Text('Rappel veille auto'),
              subtitle: Text(
                hhmm == null
                    ? 'Desactive — programme un rappel la veille de '
                        'chaque tournee'
                    : 'Active a $hhmm la veille de chaque tournee',
                style: const TextStyle(fontSize: 12),
              ),
              trailing: hhmm == null
                  ? const Icon(Icons.add)
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(hhmm,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                            )),
                        IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () =>
                              repo.clearVeilleReminderHHmm(),
                        ),
                      ],
                    ),
              onTap: () async {
                final initial = hhmm == null
                    ? const TimeOfDay(hour: 21, minute: 0)
                    : TimeOfDay(
                        hour: int.parse(hhmm.split(':')[0]),
                        minute: int.parse(hhmm.split(':')[1]),
                      );
                final picked = await showTimePicker(
                  context: context,
                  initialTime: initial,
                );
                if (picked != null) {
                  final h = picked.hour.toString().padLeft(2, '0');
                  final m = picked.minute.toString().padLeft(2, '0');
                  await repo.setVeilleReminderHHmm('$h:$m');
                }
              },
            );
          },
        ),
        // Mode "Ne pas deranger" : 2 TimePickers cote a cote pour
        // configurer le creneau silencieux. Pendant ce creneau, les
        // notifs immediates (fin de tournee, arrets oublies) sont
        // silencieusement skip. Les rappels planifies par l'user
        // (veille de tournee) restent prioritaires car explicites.
        const QuietHoursTile(),
      ],
    );
  }
}
