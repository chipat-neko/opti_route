import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'role_gated.dart';
import 'snack.dart';

/// ════════════════════════════════════════════════════════════════
/// PointageCard - carte #279.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche le toggle "Commencer / Terminer le service" + cumul des
/// heures travaillees aujourd'hui + cette semaine (lundi -> dimanche).
///
/// Pointage MANUEL pour le MVP : Noah tap au demarrage de sa journee
/// et au retour au depot. Pas de pause auto GPS encore.
///
/// Sert au cumul d'heures (paie a la tache, suivi amplitude) et
/// foundation pour le futur "colis / heure" cote stats (#279 v2).
class PointageCard extends ConsumerStatefulWidget {
  const PointageCard({super.key});

  @override
  ConsumerState<PointageCard> createState() => _PointageCardState();
}

class _PointageCardState extends ConsumerState<PointageCard> {
  Duration _today = Duration.zero;
  Duration _week = Duration.zero;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Charge les cumuls au 1er affichage. Re-charge a chaque changement
    // de session (via le listener Riverpod ci-dessous).
    Future.microtask(_refreshTotals);
  }

  Future<void> _refreshTotals() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final repo = ref.read(workSessionsRepositoryProvider);
    final now = DateTime.now();
    final today = await repo.durationForDay(now, now: now);
    final weekStart = _startOfWeek(now);
    final weekEnd = weekStart.add(const Duration(days: 7));
    final week = await repo.durationForRange(
      from: weekStart,
      to: weekEnd,
      now: now,
    );
    if (!mounted) return;
    setState(() {
      _today = today;
      _week = week;
      _loading = false;
    });
  }

  static DateTime _startOfWeek(DateTime now) {
    // Lundi = 1, Dimanche = 7 (DateTime.weekday).
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  Future<void> _toggle(WorkSession? current) async {
    final repo = ref.read(workSessionsRepositoryProvider);
    if (current == null) {
      await repo.startSession();
      if (mounted) context.showSuccess('Service demarre. Bonne tournee !');
    } else {
      await repo.endCurrentSession();
      if (mounted) context.showInfo('Service termine.');
    }
    await _refreshTotals();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final asyncCurrent = ref.watch(currentWorkSessionProvider);
    // Refresh des totaux des qu'une session change d'etat.
    ref.listen<AsyncValue<WorkSession?>>(currentWorkSessionProvider, (_, _) {
      _refreshTotals();
    });
    final current = asyncCurrent.asData?.value;
    final isOpen = current != null;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isOpen ? Icons.timer : Icons.timer_outlined,
                size: 20,
                color: isOpen ? AppColors.emerald : p.textMute,
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  'Pointage',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              if (isOpen)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.emerald.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                  ),
                  child: Text(
                    'EN SERVICE',
                    style: appMonoStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: 'Aujourd\'hui',
                  value: _fmt(_today),
                  loading: _loading,
                ),
              ),
              // Cumul Semaine = chef-only (le chauffeur n'a pas besoin
              // de voir ce niveau de stat ; gestion paie). Carte split
              // chauffeur/chef 2026-05-30 -> registry `pointage.cumul_semaine`.
              const RoleGated(
                featureKey: 'pointage.cumul_semaine',
                child: SizedBox(width: AppSpacing.x12),
              ),
              RoleGated(
                featureKey: 'pointage.cumul_semaine',
                child: Expanded(
                  child: _StatTile(
                    label: 'Semaine',
                    value: _fmt(_week),
                    loading: _loading,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _toggle(current),
              icon: Icon(isOpen ? Icons.stop_circle : Icons.play_circle),
              label: Text(
                isOpen ? 'Terminer le service' : 'Commencer le service',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOpen ? AppColors.red : AppColors.lime,
                foregroundColor: isOpen ? AppColors.cream : p.ink,
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.x12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.loading,
  });

  final String label;
  final String value;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x10),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              color: p.textMute,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            loading ? '...' : value,
            style: appMonoStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
