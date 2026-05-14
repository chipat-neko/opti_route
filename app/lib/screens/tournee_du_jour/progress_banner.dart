import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Bandeau de progression de la tournee (livres / echecs / a livrer).
/// Affiche :
/// - le titre "Avancement N/M" ou "Tournee terminee"
/// - le temps ecoule depuis le demarrage (si non-pause)
/// - un badge "EN PAUSE" si la tournee est en pause
/// - une barre de progression 3 segments (livres / echecs / restants)
/// - le compteur colis livres / total
/// - 3 stat-rows (livres / echecs / a livrer) avec icones colorees
class ProgressBanner extends StatelessWidget {
  const ProgressBanner({
    super.key,
    required this.stops,
    required this.tourneeTerminee,
    this.demareeLe,
    this.isEnPause = false,
  });

  final List<Stop> stops;
  final bool tourneeTerminee;

  /// Timestamp du tap "Demarrer" pour calculer le temps ecoule depuis.
  /// Null = tournee jamais demarree (pas d'affichage dans le bandeau).
  final DateTime? demareeLe;

  /// Si vrai, affiche un badge "EN PAUSE" et masque le compteur de
  /// temps ecoule (pour eviter de croire que le chrono court).
  final bool isEnPause;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final livres =
        stops.where((s) => s.statutLivraison == 'livre').length;
    final echecs = stops.where((s) => s.statutLivraison == 'echec').length;
    final total = stops.length;
    final restants = total - livres - echecs;
    final colisLivres = stops
        .where((s) => s.statutLivraison == 'livre')
        .fold<int>(0, (sum, s) => sum + s.nbColis);
    final colisTotal = stops.fold<int>(0, (sum, s) => sum + s.nbColis);

    final bg = tourneeTerminee ? AppColors.emerald : p.paper;
    final fg = tourneeTerminee ? p.paper : p.ink;
    final mute = tourneeTerminee
        ? p.paper.withValues(alpha: 0.75)
        : p.textMute;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: tourneeTerminee
            ? null
            : Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                tourneeTerminee
                    ? Icons.flag
                    : Icons.local_shipping_outlined,
                color: fg,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tourneeTerminee
                          ? 'Tournee terminee'
                          : 'Avancement : $livres / $total',
                      style: TextStyle(
                        color: fg,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (demareeLe != null && !isEnPause)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          'Demarree il y a ${_formatElapsed(demareeLe!)}',
                          style: appMonoStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: mute,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isEnPause)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.amber,
                    borderRadius: BorderRadius.circular(AppRadius.r8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.pause_circle_filled,
                        size: 14,
                        color: AppColors.ink,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'EN PAUSE',
                        style: appMonoStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                )
              else if (colisTotal > 0)
                Text(
                  '$colisLivres / $colisTotal colis',
                  style: appMonoStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: tourneeTerminee ? AppColors.lime : AppColors.emerald,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          // Barre de progression simple : 3 segments empiles.
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (livres > 0)
                    Expanded(
                      flex: livres,
                      child: Container(
                        color: tourneeTerminee
                            ? AppColors.lime
                            : AppColors.emerald,
                      ),
                    ),
                  if (echecs > 0)
                    Expanded(flex: echecs, child: Container(color: AppColors.red)),
                  if (restants > 0)
                    Expanded(
                      flex: restants,
                      child: Container(
                        color: tourneeTerminee
                            ? p.paper.withValues(alpha: 0.2)
                            : p.creamSoft,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Wrap(
            spacing: AppSpacing.x14,
            runSpacing: AppSpacing.x4,
            children: [
              _ProgressStat(
                icon: Icons.check_circle,
                color: tourneeTerminee ? AppColors.lime : AppColors.emerald,
                label: '$livres livres',
                fg: fg,
                mute: mute,
              ),
              _ProgressStat(
                icon: Icons.cancel,
                color: AppColors.red,
                label: '$echecs echecs',
                fg: fg,
                mute: mute,
              ),
              if (!tourneeTerminee)
                _ProgressStat(
                  icon: Icons.schedule,
                  color: AppColors.amber,
                  label: '$restants a livrer',
                  fg: fg,
                  mute: mute,
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Formate la duree ecoulee depuis [start] sous forme courte :
  /// "8 min", "1h32", "2j 4h". Pas de secondes, on rafraichit la
  /// minute pres au prochain rebuild.
  static String _formatElapsed(DateTime start) {
    final d = DateTime.now().difference(start);
    if (d.inMinutes < 1) return 'moins d\'une min';
    if (d.inHours < 1) return '${d.inMinutes} min';
    if (d.inDays < 1) {
      final h = d.inHours;
      final m = d.inMinutes % 60;
      return '${h}h${m.toString().padLeft(2, '0')}';
    }
    final j = d.inDays;
    final h = d.inHours % 24;
    return '${j}j ${h}h';
  }
}

class _ProgressStat extends StatelessWidget {
  const _ProgressStat({
    required this.icon,
    required this.color,
    required this.label,
    required this.fg,
    required this.mute,
  });

  final IconData icon;
  final Color color;
  final String label;
  final Color fg;
  // ignore: unused_field
  final Color mute;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
