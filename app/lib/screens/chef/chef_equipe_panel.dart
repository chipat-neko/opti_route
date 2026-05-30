import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/dispatch_transfer.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// Panneau "Équipe" du logiciel chef :
/// - Vue d'ensemble coéquipiers + comptes stops affectés (#333)
/// - Pointage vers actions invitation (existant ailleurs)
///
/// MVP : agrège tous les stops de toutes les tournées en cours et
/// montre la répartition par coéquipier. Le drag-and-drop live de
/// stops d'un livreur vers l'autre est à wire dans une future PR
/// (RealtimeChannel Supabase).
class ChefEquipePanel extends ConsumerWidget {
  const ChefEquipePanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final tourneesAsync = ref.watch(tourneesStreamProvider);
    final coeqMap = ref.watch(coequipiersByIdProvider);
    return Container(
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.groups_outlined, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Text('Équipe',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: p.ink)),
            ],
          ),
          const Divider(height: AppSpacing.x22),
          Expanded(
            child: tourneesAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Text('Erreur : $e',
                    style: TextStyle(color: p.textMute)),
              ),
              data: (tournees) {
                final enCours = tournees
                    .where((t) => t.statut == 'en_cours')
                    .toList();
                if (enCours.isEmpty) {
                  return Center(
                    child: Text('Aucune tournée en cours.',
                        style: TextStyle(color: p.textMute)),
                  );
                }
                return _LoadStopsAndShow(
                  tournees: enCours,
                  coeqMap: coeqMap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadStopsAndShow extends ConsumerWidget {
  const _LoadStopsAndShow({
    required this.tournees,
    required this.coeqMap,
  });

  final List<Tournee> tournees;
  final Map<int, Coequipier> coeqMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopsRepo = ref.read(stopsRepositoryProvider);
    return FutureBuilder<List<Stop>>(
      future: () async {
        final all = <Stop>[];
        for (final t in tournees) {
          all.addAll(await stopsRepo.getByTournee(t.id));
        }
        return all;
      }(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final counts = DispatchTransfer.countByCoequipier(snap.data!);
        return ListView(
          children: [
            for (final entry in counts.entries)
              _CoequipierRow(
                coequipierId: entry.key,
                count: entry.value,
                coeqMap: coeqMap,
              ),
          ],
        );
      },
    );
  }
}

class _CoequipierRow extends StatelessWidget {
  const _CoequipierRow({
    required this.coequipierId,
    required this.count,
    required this.coeqMap,
  });

  final int? coequipierId;
  final int count;
  final Map<int, Coequipier> coeqMap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final coeq = coequipierId == null ? null : coeqMap[coequipierId];
    final name = coeq?.nom ?? 'Non affecté';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor:
                coeq == null ? p.creamSoft : AppColors.lime,
            child: Text(
              coeq == null ? '?' : _initials(name),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink),
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(child: Text(name, style: TextStyle(color: p.ink))),
          Text('$count stops',
              style: appMonoStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.textMute)),
        ],
      ),
    );
  }

  static String _initials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
