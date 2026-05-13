import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Carte "Colis par jour" — barchart hebdomadaire.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche la repartition des colis livres par jour de semaine
/// (lundi..dimanche) sur les 30 derniers jours, sous forme d'un
/// petit barchart "ASCII" horizontal (proportionnel au max).
///
/// Aide a reperer les jours charges -> potentiellement bouger une
/// tournee recurrente vers un jour plus calme.
class JoursSemaineCard extends ConsumerWidget {
  const JoursSemaineCard({super.key});

  /// Map index DateTime.weekday (1=lundi..7=dimanche) -> label FR.
  /// L'index 0 n'est jamais utilise (le 1er jour est lundi=1).
  static const _jourLabels = [
    null,
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(colisParJourProvider(30));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'COLIS PAR JOUR (30 J)',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          async.when(
            data: (map) {
              if (map.isEmpty) {
                return Text(
                  'Aucun colis livre cette periode.',
                  style: TextStyle(color: p.textMute),
                );
              }
              // Determine la valeur max pour calculer le ratio
              // des barres (toutes proportionnelles au max).
              final maxVal = map.values.fold<int>(
                0,
                (m, v) => v > m ? v : m,
              );
              return Column(
                children: [
                  for (var wd = 1; wd <= 7; wd++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: _BarRow(
                        label: _jourLabels[wd]!,
                        value: map[wd] ?? 0,
                        max: maxVal,
                      ),
                    ),
                ],
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.x18),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text(
              'Erreur : $e',
              style: const TextStyle(color: AppColors.red),
            ),
          ),
        ],
      ),
    );
  }
}

/// Une barre horizontale du barchart : label a gauche (largeur fixe
/// 72 px), barre proportionnelle au milieu (fond cream + remplissage
/// lime), valeur en mono a droite.
class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.value,
    required this.max,
  });

  final String label;
  final int value;
  final int max;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ratio = max == 0 ? 0.0 : value / max;
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.ink,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: p.creamSoft,
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: ratio,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(AppRadius.r6),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.x10),
        SizedBox(
          width: 28,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: appMonoStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ),
      ],
    );
  }
}
