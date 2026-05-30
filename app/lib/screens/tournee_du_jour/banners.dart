import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/anomaly_detection_service.dart';
import '../../data/database.dart';
import '../../data/eta_calculator.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Petit bandeau qui affiche une estimation du cout carburant pour la
/// tournee, base sur le param `coutCarburantLitre` x `consoLitresPar100Km`
/// x la distance totale calculee par ORS. Discret : juste une ligne
/// avec une icone pompe a essence et le montant en EUR.
class CoutCarburantBanner extends ConsumerWidget {
  const CoutCarburantBanner({super.key, required this.distanceMeters});

  final int distanceMeters;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final async = ref.watch(coutCarburantProvider(distanceMeters));
    final value = async.asData?.value;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        children: [
          Icon(Icons.local_gas_station_outlined, size: 16, color: p.textMute),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              'Cout carburant estime',
              style: TextStyle(fontSize: 12.5, color: p.textMute),
            ),
          ),
          Text(
            value == null ? '...' : _formatEur(value),
            style: appMonoStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }

  static String _formatEur(double eur) {
    // Format FR : virgule decimale, symbole EUR a droite, 2 decimales.
    final cents = (eur * 100).round();
    final entier = cents ~/ 100;
    final dec = (cents % 100).toString().padLeft(2, '0');
    return '$entier,$dec EUR';
  }
}

/// Bandeau ink "Itineraire optimise" affiche quand la tournee a deja
/// ete optimisee (presence de `optimiseeLe`). Affiche l'heure du calcul
/// + un badge OK lime pour rassurer l'utilisateur que tout est OK.
class OptimisedBanner extends StatelessWidget {
  const OptimisedBanner({super.key, required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final timeLabel = tournee.optimiseeLe == null
        ? null
        : DateFormat('HH:mm', 'fr').format(tournee.optimiseeLe!);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: p.ink,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.lime,
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.bolt, color: p.ink, size: 18),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Itineraire optimise',
                  style: TextStyle(
                    color: p.paper,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (timeLabel != null)
                  Text(
                    'Calcule a $timeLabel',
                    style: TextStyle(
                      color: p.paper.withValues(alpha: 0.65),
                      fontSize: 11.5,
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.lime.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.r6),
              border: Border.all(
                color: AppColors.lime.withValues(alpha: 0.4),
              ),
            ),
            child: Text(
              'OK',
              style: appMonoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.lime,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau d'alertes anomalies de la tournee en cours (carte #122).
/// Calcule les anomalies via [AnomalyDetectionService] (taux d'echec
/// eleve, inactivite > 2h, tournee a cloturer) et les affiche, une par
/// ligne, coloree selon la gravite. Masque (SizedBox.shrink) si aucune.
class AnomaliesBanner extends StatelessWidget {
  const AnomaliesBanner({
    super.key,
    required this.tournee,
    required this.stops,
  });

  final Tournee tournee;
  final List<Stop> stops;

  @override
  Widget build(BuildContext context) {
    final anomalies = AnomalyDetectionService.detect(
      tournee: tournee,
      stops: stops,
      now: DateTime.now(),
    );
    if (anomalies.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final a in anomalies)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.x8),
            child: _AnomalieRow(anomalie: a),
          ),
      ],
    );
  }
}

class _AnomalieRow extends StatelessWidget {
  const _AnomalieRow({required this.anomalie});

  final Anomalie anomalie;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (color, icon) = switch (anomalie.severite) {
      AnomalieSeverite.critique => (AppColors.red, Icons.error_outline),
      AnomalieSeverite.attention =>
        (AppColors.amber, Icons.warning_amber_outlined),
      AnomalieSeverite.info => (AppColors.emerald, Icons.info_outline),
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              anomalie.message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                color: p.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip "Fin ~HH:MM" affiche en haut de la tournee du jour quand la
/// tournee est demarree et qu'il reste des stops a livrer (carte #276).
/// Se recalibre a chaque validation via [endOfTourProvider] (qui depend
/// de [etasParStopProvider]). Auto-masque si pas d'estimation.
class EndOfTourChip extends ConsumerWidget {
  const EndOfTourChip({super.key, required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tournee.statut != 'en_cours') return const SizedBox.shrink();
    final p = context.palette;
    final end = ref.watch(endOfTourProvider(tournee.id)).asData?.value;
    if (end == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        children: [
          Icon(Icons.flag_outlined, size: 16, color: p.textMute),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              'Fin estimee de tournee',
              style: TextStyle(fontSize: 12.5, color: p.textMute),
            ),
          ),
          Text(
            '~${EtaCalculator.formatEtaHHmm(end)}',
            style: appMonoStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
