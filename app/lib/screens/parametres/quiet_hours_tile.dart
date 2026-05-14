import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/parametres_repository.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Tile "Ne pas deranger" (quiet hours) de la section Notifications.
/// ════════════════════════════════════════════════════════════════
///
/// L'utilisateur configure 2 horaires HH:mm (debut + fin) pendant
/// lesquels toutes les notifications immediate de l'app
/// (showBackupSuccess, showEndOfRouteSummary, showPendingStopsAlert)
/// sont skipped silencieusement (cf [NotificationsService._isQuietHours]).
///
/// **Pourquoi un tile dedie** : depuis le refactor 2026-05-14 de
/// parametres_screen.dart (1522 lignes → fichiers thematiques),
/// chaque section vit dans son propre fichier pour faciliter le
/// hot reload et la maintenance.

class QuietHoursTile extends ConsumerWidget {
  const QuietHoursTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final repo = ref.watch(parametresRepositoryProvider);
    final start = ref.watch(quietStartProvider).asData?.value;
    final end = ref.watch(quietEndProvider).asData?.value;
    final enabled = start != null && end != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.do_not_disturb_on_outlined),
      title: const Text('Ne pas deranger'),
      subtitle: Text(
        enabled
            ? 'Notifs muettes de $start a $end'
            : 'Pas de creneau silencieux configure',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmallTimeBtn(
            label: start ?? 'Debut',
            isPlaceholder: start == null,
            onTap: () async {
              final parsed = ParametresRepository.parseHHmm(start);
              final picked = await showTimePicker(
                context: context,
                initialTime: parsed == null
                    ? const TimeOfDay(hour: 12, minute: 0)
                    : TimeOfDay(hour: parsed.hour, minute: parsed.minute),
              );
              if (picked != null) {
                final h = picked.hour.toString().padLeft(2, '0');
                final m = picked.minute.toString().padLeft(2, '0');
                await repo.setQuietHoursStart('$h:$m');
              }
            },
            onClear: start == null ? null : () => repo.clearQuietHoursStart(),
            color: p,
          ),
          const SizedBox(width: 6),
          Text('→', style: TextStyle(color: p.textMute)),
          const SizedBox(width: 6),
          _SmallTimeBtn(
            label: end ?? 'Fin',
            isPlaceholder: end == null,
            onTap: () async {
              final parsed = ParametresRepository.parseHHmm(end);
              final picked = await showTimePicker(
                context: context,
                initialTime: parsed == null
                    ? const TimeOfDay(hour: 14, minute: 0)
                    : TimeOfDay(hour: parsed.hour, minute: parsed.minute),
              );
              if (picked != null) {
                final h = picked.hour.toString().padLeft(2, '0');
                final m = picked.minute.toString().padLeft(2, '0');
                await repo.setQuietHoursEnd('$h:$m');
              }
            },
            onClear: end == null ? null : () => repo.clearQuietHoursEnd(),
            color: p,
          ),
        ],
      ),
    );
  }
}

class _SmallTimeBtn extends StatelessWidget {
  const _SmallTimeBtn({
    required this.label,
    required this.isPlaceholder,
    required this.onTap,
    required this.onClear,
    required this.color,
  });
  final String label;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final AppPalette color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r8),
      onTap: onTap,
      onLongPress: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.creamSoft,
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isPlaceholder ? color.textMute : color.ink,
          ),
        ),
      ),
    );
  }
}

/// Stream du quiet_hours_start (HH:mm ou null si non configure).
final quietStartProvider = StreamProvider<String?>((ref) {
  return ref.watch(parametresRepositoryProvider).watchQuietHoursStart();
});

/// Stream du quiet_hours_end (HH:mm ou null si non configure).
final quietEndProvider = StreamProvider<String?>((ref) {
  return ref.watch(parametresRepositoryProvider).watchQuietHoursEnd();
});
