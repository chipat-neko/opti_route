import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Tableau de bord du chef d'equipe : vue d'ensemble des tournees du
/// jour, regroupees par coequipier (avec "Moi" en premier).
///
/// 100% local au telephone du chef : il consolide ce qui est dans sa
/// base SQLite. Pour une vraie sync entre apps de coequipiers (chaque
/// coequipier sur son propre telephone, push temps reel), il faudrait
/// un backend → roadmap Phase 2 CB.
class TableauBordEquipeScreen extends ConsumerWidget {
  const TableauBordEquipeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tourneesAujourdhui = ref.watch(tourneesDuJourProvider);
    final coequipiers = ref.watch(coequipiersAllProvider).asData?.value ??
        const <Coequipier>[];
    final coequipiersById = {for (final c in coequipiers) c.id: c};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tableau de bord equipe'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30),
          child: Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.x18,
              right: AppSpacing.x18,
              bottom: AppSpacing.x8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                DateFormat('EEEE d MMMM y', 'fr')
                    .format(DateTime.now())
                    .toLowerCase(),
                style: appMonoStyle(
                  fontSize: 11,
                  color: p.textMute,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ),
      body: tourneesAujourdhui.isEmpty
          ? _EmptyDay()
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.x18),
              children: [
                _GlobalSummary(tournees: tourneesAujourdhui),
                const SizedBox(height: AppSpacing.x18),
                for (final t in tourneesAujourdhui)
                  _TourneeCardEquipe(
                    tournee: t,
                    coequipiersById: coequipiersById,
                  ),
              ],
            ),
    );
  }
}

class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today_outlined, size: 44, color: p.textFaint),
            const SizedBox(height: AppSpacing.x14),
            Text(
              'Aucune tournee aujourd\'hui',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              'Cree une tournee depuis l\'accueil. Toutes les tournees '
              'datees d\'aujourd\'hui s\'afficheront ici.',
              style: TextStyle(fontSize: 13, color: p.textMute),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Banniere de stats agreges sur l'ensemble des tournees du jour
/// (total colis, livres, restants, taux global).
class _GlobalSummary extends ConsumerWidget {
  const _GlobalSummary({required this.tournees});

  final List<Tournee> tournees;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // On agrege via watch des stops pour chaque tournee. C'est suffisant
    // pour 5-10 tournees simultanees ; au dela il faudrait un compute
    // dedie StatsService.compteursDuJour().
    return Consumer(
      builder: (context, ref, _) {
        var totalStops = 0;
        var totalLivres = 0;
        var totalEchecs = 0;
        var totalColisLivres = 0;
        for (final t in tournees) {
          final stops =
              ref.watch(stopsByTourneeProvider(t.id)).asData?.value ?? const [];
          totalStops += stops.length;
          for (final s in stops) {
            if (s.statutLivraison == 'livre') {
              totalLivres++;
              totalColisLivres += s.nbColis;
            } else if (s.statutLivraison == 'echec') {
              totalEchecs++;
            }
          }
        }
        final restants = totalStops - totalLivres - totalEchecs;

        return Container(
          padding: const EdgeInsets.all(AppSpacing.x16),
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.r18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AUJOURD\'HUI - ${tournees.length} '
                'TOURNEE${tournees.length > 1 ? "S" : ""}',
                style: appMonoStyle(
                  fontSize: 11,
                  color: AppColors.lime,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              Row(
                children: [
                  _StatBox(label: 'Arrets', value: '$totalStops'),
                  _StatBox(label: 'Livres', value: '$totalLivres'),
                  _StatBox(
                    label: 'Restant',
                    value: '$restants',
                    color: AppColors.lime,
                  ),
                  if (totalEchecs > 0)
                    _StatBox(
                      label: 'Echecs',
                      value: '$totalEchecs',
                      color: AppColors.red,
                    ),
                ],
              ),
              if (totalColisLivres > 0) ...[
                const SizedBox(height: AppSpacing.x8),
                Text(
                  '$totalColisLivres colis livres',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.cream.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.value,
    this.color,
  });

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: appMonoStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.cream,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: appMonoStyle(
              fontSize: 9,
              color: AppColors.cream.withValues(alpha: 0.6),
              letterSpacing: 0.6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte par tournee : nom + statut + avancement + breakdown par
/// coequipier (mini avatars + compteurs). Tap = ouvre la tournee.
class _TourneeCardEquipe extends ConsumerWidget {
  const _TourneeCardEquipe({
    required this.tournee,
    required this.coequipiersById,
  });

  final Tournee tournee;
  final Map<int, Coequipier> coequipiersById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final stops =
        ref.watch(stopsByTourneeProvider(tournee.id)).asData?.value ?? const [];
    final livres = stops.where((s) => s.statutLivraison == 'livre').length;
    final echecs = stops.where((s) => s.statutLivraison == 'echec').length;
    final total = stops.length;
    final pct = total == 0 ? 0.0 : (livres + echecs) / total;

    // Breakdown par coequipier (cle null = Moi)
    final byCo = <int?, ({int total, int livres})>{};
    for (final s in stops) {
      final cur = byCo[s.coequipierId] ?? (total: 0, livres: 0);
      byCo[s.coequipierId] = (
        total: cur.total + 1,
        livres: cur.livres + (s.statutLivraison == 'livre' ? 1 : 0),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r18),
        onTap: () {
          // Pour ouvrir une tournee specifique, on simule une activation
          // via la home en passant directement par la liste.
          Navigator.of(context).pop();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournee.nom,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: p.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tournee.pointDepartLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: p.textMute,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatutBadge(tournee: tournee),
                ],
              ),
              const SizedBox(height: AppSpacing.x10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 6,
                  backgroundColor: p.creamSoft,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct == 1 ? AppColors.emerald : AppColors.lime,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(
                '$livres / $total livres'
                '${echecs > 0 ? " - $echecs echec${echecs > 1 ? "s" : ""}" : ""}',
                style: appMonoStyle(
                  fontSize: 11,
                  color: p.textMute,
                ),
              ),
              if (byCo.length > 1) ...[
                const SizedBox(height: AppSpacing.x10),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.x8),
                Wrap(
                  spacing: AppSpacing.x6,
                  runSpacing: AppSpacing.x4,
                  children: [
                    for (final entry in byCo.entries)
                      _CoequipierProgress(
                        coequipier: entry.key == null
                            ? null
                            : coequipiersById[entry.key],
                        coequipierId: entry.key,
                        total: entry.value.total,
                        livres: entry.value.livres,
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  const _StatutBadge({required this.tournee});
  final Tournee tournee;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (label, color) = switch (tournee.statut) {
      'en_cours' => ('EN COURS', AppColors.lime),
      'optimisee' => ('OPTIMISEE', AppColors.emerald),
      'terminee' => ('TERMINEE', AppColors.creamSoft),
      _ => ('BROUILLON', p.inkLine),
    };
    final isPaused = tournee.pauseeLe != null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isPaused ? AppColors.amber : color,
        borderRadius: BorderRadius.circular(AppRadius.r8),
      ),
      child: Text(
        isPaused ? 'EN PAUSE' : label,
        style: appMonoStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.ink,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _CoequipierProgress extends StatelessWidget {
  const _CoequipierProgress({
    required this.coequipier,
    required this.coequipierId,
    required this.total,
    required this.livres,
  });

  final Coequipier? coequipier;
  final int? coequipierId;
  final int total;
  final int livres;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isMoi = coequipierId == null;
    final nom = isMoi
        ? 'Moi'
        : (coequipier?.nom ?? 'Coequipier #$coequipierId');
    final color = isMoi
        ? AppColors.lime
        : colorFromTag(coequipier?.colorTag, defaultColor: AppColors.creamSoft);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$nom $livres/$total',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
