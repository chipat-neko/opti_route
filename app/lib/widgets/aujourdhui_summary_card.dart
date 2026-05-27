import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Carte "Aujourd'hui" affichee en haut de l'ecran principal quand la
/// journee a deja eu de l'activite mais qu'il n'y a plus de tournee
/// active. Montre en un coup d'oeil : compteur colis livres, progress
/// bar, tournees terminees / total, premiere / derniere livraison.
///
/// Self-hiding : si aucune tournee planifiee aujourd'hui, retourne un
/// `SizedBox.shrink()` (zero regression visuelle pour le user qui n'a
/// rien commence). Carte Trello #100.
class AujourdhuiSummaryCard extends ConsumerWidget {
  const AujourdhuiSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(aujourdhuiResumeProvider);
    return async.when(
      data: (resume) {
        if (resume.isEmpty) return const SizedBox.shrink();
        return _Body(resume: resume);
      },
      // Pas de loader visible : on n'occupe la place qu'une fois pret
      // (sinon flash de progress sur le HomeScreen au demarrage).
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.resume});

  final AujourdhuiResume resume;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct = (resume.avancement * 100).round();
    final km = (resume.distanceMeters / 1000).toStringAsFixed(1);
    final dureeStr = _formatDuration(resume.durationSeconds);
    final horaires = _formatHoraires(
      resume.premierLivreLe,
      resume.dernierLivreLe,
    );

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
          Row(
            children: [
              Text(
                'AUJOURD\'HUI',
                style: appMonoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: p.textMute,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              if (horaires != null)
                Text(
                  horaires,
                  style: appMonoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: p.textMute,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          _BigNumber(value: '${resume.nbColisLivres}'),
          const SizedBox(height: AppSpacing.x12),
          if (resume.nbArretsTotaux > 0) ...[
            _ProgressBar(value: resume.avancement),
            const SizedBox(height: AppSpacing.x8),
            Text(
              '${resume.nbLivres + resume.nbEchecs}/${resume.nbArretsTotaux} arrets traites · $pct%',
              style: TextStyle(fontSize: 12, color: p.textMute),
            ),
            const SizedBox(height: AppSpacing.x12),
          ],
          Row(
            children: [
              Expanded(
                child: _SmallStat(
                  label: 'Tournees',
                  value:
                      '${resume.nbTourneesTerminees}/${resume.nbTournees}',
                  hint: _tourneesHint(resume),
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _SmallStat(
                  label: 'Echecs',
                  value: '${resume.nbEchecs}',
                  hint: resume.nbEchecs == 0
                      ? 'aucun echec'
                      : '${(resume.tauxReussite * 100).round()}% reussite',
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _SmallStat(
                  label: 'Distance',
                  value: km,
                  unit: 'km',
                ),
              ),
              const _StatDivider(),
              Expanded(
                child: _SmallStat(
                  label: 'Duree',
                  value: dureeStr,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _tourneesHint(AujourdhuiResume r) {
    if (r.nbTourneesEnCours > 0) return '${r.nbTourneesEnCours} en cours';
    if (r.nbTourneesTerminees == r.nbTournees) return 'toutes terminees';
    final brouillons = r.nbTournees - r.nbTourneesTerminees;
    return '$brouillons en attente';
  }

  static String? _formatHoraires(DateTime? premier, DateTime? dernier) {
    if (premier == null || dernier == null) return null;
    String hhmm(DateTime d) =>
        '${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
    if (premier == dernier) return hhmm(premier);
    return '${hhmm(premier)} - ${hhmm(dernier)}';
  }

  static String _formatDuration(int seconds) {
    if (seconds == 0) return ' - ';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}

class _BigNumber extends StatelessWidget {
  const _BigNumber({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            value,
            style: appMonoStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              'colis livres',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.r6),
      child: LinearProgressIndicator(
        value: value,
        minHeight: 6,
        backgroundColor: p.creamSoft,
        valueColor: const AlwaysStoppedAnimation(AppColors.emerald),
      ),
    );
  }
}

class _SmallStat extends StatelessWidget {
  const _SmallStat({
    required this.label,
    required this.value,
    this.unit,
    this.hint,
  });

  final String label;
  final String value;
  final String? unit;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: appMonoStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: p.textMute,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 2),
          RichText(
            text: TextSpan(
              style: appMonoStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.ink,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(text: value),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textMute,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: TextStyle(fontSize: 10, color: p.textMute),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: context.palette.divider);
}
