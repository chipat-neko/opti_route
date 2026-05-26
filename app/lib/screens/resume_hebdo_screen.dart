import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/resume_hebdo_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ecran "Resume hebdo" (carte Trello #101). Accessible depuis le
/// drawer principal sous le titre "Resume de la semaine".
///
/// Affiche pour la semaine selectionnee :
///   - Total stops livres / programmes + colis
///   - Tournees realisees (compteur + liste)
///   - Comparatif vs semaine precedente
///   - Top 3 clients
///   - Coequipier le plus actif (si mode equipe)
///   - Alertes (taux echec eleve, tournees a probleme)
///
/// Navigation entre semaines : 2 boutons "<" et ">" dans l'AppBar
/// pour reculer / avancer. La semaine courante est mise en valeur.
class ResumeHebdoScreen extends ConsumerStatefulWidget {
  const ResumeHebdoScreen({super.key});

  @override
  ConsumerState<ResumeHebdoScreen> createState() =>
      _ResumeHebdoScreenState();
}

class _ResumeHebdoScreenState extends ConsumerState<ResumeHebdoScreen> {
  /// Semaine actuellement affichee, identifiee par son lundi 00:00.
  /// Null = semaine en cours (computed dans le provider).
  DateTime? _referenceWeek;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final async = ref.watch(resumeHebdoProvider(_referenceWeek));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume de la semaine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            tooltip: 'Semaine precedente',
            onPressed: () => _shiftWeek(-7),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            tooltip: 'Semaine suivante',
            onPressed: _canGoForward() ? () => _shiftWeek(7) : null,
          ),
        ],
      ),
      body: async.when(
        data: (r) => _Body(resume: r),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x22),
            child: Text(
              'Erreur de chargement : $e',
              style: TextStyle(color: p.textMute),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  void _shiftWeek(int days) {
    final base = _referenceWeek ??
        ResumeHebdoService.weekStart(DateTime.now());
    setState(() => _referenceWeek = base.add(Duration(days: days)));
  }

  /// Empeche d'aller plus loin que la semaine en cours (pas de sens
  /// d'afficher la semaine prochaine, qui n'a pas encore eu lieu).
  bool _canGoForward() {
    if (_referenceWeek == null) return false;
    final currentWeekStart = ResumeHebdoService.weekStart(DateTime.now());
    return _referenceWeek!.isBefore(currentWeekStart);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.resume});

  final ResumeHebdo resume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final fmt = DateFormat('d MMM', 'fr');
    final periode =
        '${fmt.format(resume.semaineDebut)} - ${fmt.format(resume.semaineFin)}';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x18),
      children: [
        // Bandeau semaine
        Text(
          periode.toUpperCase(),
          style: appMonoStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: p.textMute,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: AppSpacing.x12),
        if (resume.isEmpty)
          _EmptyState()
        else ...[
          _BigNumberCard(resume: resume),
          const SizedBox(height: AppSpacing.x14),
          _MetricsGrid(resume: resume),
          const SizedBox(height: AppSpacing.x14),
          _AlertesCard(alertes: resume.alertes()),
          const SizedBox(height: AppSpacing.x14),
          _TopClientsCard(resume: resume),
          const SizedBox(height: AppSpacing.x14),
          _CoequipierCard(resume: resume),
          const SizedBox(height: AppSpacing.x14),
          _TourneesListCard(resume: resume),
        ],
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x28),
      child: Column(
        children: [
          Icon(Icons.calendar_month_outlined, size: 56, color: p.textFaint),
          const SizedBox(height: AppSpacing.x12),
          Text(
            'Aucune tournee cette semaine',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Revenir en arriere avec la fleche < dans l\'entete pour '
            'consulter une semaine precedente.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: p.textMute, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _BigNumberCard extends StatelessWidget {
  const _BigNumberCard({required this.resume});

  final ResumeHebdo resume;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x16),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            '${resume.nbColisLivres}',
            style: appMonoStyle(
              fontSize: 48,
              fontWeight: FontWeight.w800,
              color: p.ink,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'colis livres\ncette semaine',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: p.ink,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.resume});

  final ResumeHebdo resume;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final km = (resume.distanceMeters / 1000).toStringAsFixed(1);
    final h = (resume.durationSeconds / 3600).toStringAsFixed(1);
    final taux = (resume.tauxReussite * 100).round();
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Tournees',
                  value: '${resume.nbTourneesTerminees}/${resume.nbTournees}',
                  variation: resume.variationVsPrev('tournees'),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _Metric(
                  label: 'Stops livres',
                  value: '${resume.nbLivres}',
                  variation: resume.variationVsPrev('nb_livres'),
                ),
              ),
            ],
          ),
          Divider(color: p.divider, height: AppSpacing.x18),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Distance',
                  value: '$km km',
                  variation: resume.variationVsPrev('distance_m'),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _Metric(
                  label: 'Duree',
                  value: '${h}h',
                  variation: resume.variationVsPrev('duree_s'),
                ),
              ),
              const _MetricDivider(),
              Expanded(
                child: _Metric(
                  label: 'Reussite',
                  value: '$taux%',
                  variation: null, // un %, pas un ratio
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.variation,
  });

  final String label;
  final String value;
  final double? variation;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: appMonoStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: p.textMute,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: appMonoStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: p.ink,
            letterSpacing: -0.3,
          ),
        ),
        if (variation != null) ...[
          const SizedBox(height: 2),
          _VariationChip(value: variation!),
        ],
      ],
    );
  }
}

class _VariationChip extends StatelessWidget {
  const _VariationChip({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Zone neutre +/- 1 % pour eviter le bruit.
    if (value.abs() < 0.01) {
      return Text(
        '=',
        style: appMonoStyle(
          fontSize: 11,
          color: p.textMute,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final positif = value > 0;
    final color = positif ? AppColors.emerald : AppColors.red;
    final sign = positif ? '+' : '';
    final pct = (value * 100).round();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          positif ? Icons.arrow_upward : Icons.arrow_downward,
          size: 10,
          color: color,
        ),
        Text(
          ' $sign$pct%',
          style: appMonoStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _MetricDivider extends StatelessWidget {
  const _MetricDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: context.palette.divider);
}

class _AlertesCard extends StatelessWidget {
  const _AlertesCard({required this.alertes});

  final List<String> alertes;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (alertes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.x14),
        decoration: BoxDecoration(
          color: AppColors.emeraldSoft,
          borderRadius: BorderRadius.circular(AppRadius.r14),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, color: AppColors.emerald, size: 18),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: Text(
                'Aucune alerte cette semaine.',
                style: TextStyle(fontSize: 13, color: p.ink),
              ),
            ),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.amber, size: 18),
              SizedBox(width: AppSpacing.x6),
              Text(
                'ALERTES',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          for (final a in alertes)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('• $a', style: TextStyle(fontSize: 12, color: p.ink)),
            ),
        ],
      ),
    );
  }
}

class _TopClientsCard extends StatelessWidget {
  const _TopClientsCard({required this.resume});

  final ResumeHebdo resume;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final top = resume.topClients(limit: 3);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOP CLIENTS',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          if (top.isEmpty)
            Text(
              'Aucun nom client renseigne sur les livraisons.',
              style: TextStyle(fontSize: 12, color: p.textMute),
            )
          else
            for (final (i, t) in top.indexed)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: i == 0
                            ? AppColors.lime
                            : i == 1
                                ? AppColors.emeraldSoft
                                : p.creamSoft,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x8),
                    Expanded(
                      child: Text(
                        t.nomClient,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: p.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '${t.nbLivraisons} liv · ${t.nbColis} colis',
                      style: TextStyle(fontSize: 11, color: p.textMute),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _CoequipierCard extends ConsumerWidget {
  const _CoequipierCard({required this.resume});

  final ResumeHebdo resume;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final top = resume.coequipierLePlusActif();
    if (top == null) {
      // Solo : on cache la card
      return const SizedBox.shrink();
    }
    final coequipiers = ref.watch(coequipiersByIdProvider);
    final nom = top.coequipierId == null
        ? 'Moi'
        : (coequipiers[top.coequipierId]?.nom ??
            'Coequipier #${top.coequipierId}');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_outlined,
              color: AppColors.amber, size: 22),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COEQUIPIER LE PLUS ACTIF',
                  style: appMonoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: p.textMute,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$nom · ${top.nbLivres} livraisons',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TourneesListCard extends StatelessWidget {
  const _TourneesListCard({required this.resume});

  final ResumeHebdo resume;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fmt = DateFormat('EEE d', 'fr');
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TOURNEES (${resume.nbTournees})',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
          for (final t in resume.tournees)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 56,
                    child: Text(
                      fmt.format(t.date),
                      style: appMonoStyle(
                        fontSize: 11,
                        color: p.textMute,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      t.nom,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13,
                        color: p.ink,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  _StatutChip(statut: t.statut),
                  const SizedBox(width: AppSpacing.x6),
                  Text(
                    '${((t.distanceTotaleM ?? 0) / 1000).toStringAsFixed(0)} km',
                    style: TextStyle(fontSize: 11, color: p.textMute),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatutChip extends StatelessWidget {
  const _StatutChip({required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    final (color, short) = switch (statut) {
      'terminee' => (AppColors.emerald, 'OK'),
      'en_cours' => (AppColors.amber, 'EN COURS'),
      'optimisee' => (AppColors.lime, 'OPT'),
      'brouillon' => (AppColors.textMute, 'BRL'),
      _ => (AppColors.textMute, statut.toUpperCase()),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        short,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

