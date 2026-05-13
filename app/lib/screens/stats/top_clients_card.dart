import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../carnet_adresses_screen.dart' show carnetStreamProvider;

/// ════════════════════════════════════════════════════════════════
/// Carte "Top 5 clients" — lue directement depuis le carnet.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche les 5 clients du carnet ayant le plus grand `use_count`
/// (nombre de fois ou ils ont ete livres). Ne consulte PAS l'historique
/// des stops : c'est le carnet d'adresses qui est la source de verite
/// pour cette stat (le compteur est incremente a chaque utilisation).
///
/// Le rang 1 a un badge lime, les autres prennent leur `colorTag`
/// custom du carnet (ou creamSoft par defaut). Permet a Noah de
/// reconnaitre ses recurrents d'un coup d'oeil.
class TopClientsCard extends ConsumerWidget {
  const TopClientsCard({super.key});

  static const _topN = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final stream = ref.watch(carnetStreamProvider);
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
            'TOP $_topN CLIENTS',
            style: appMonoStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: p.textMute,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          stream.when(
            data: (all) {
              if (all.isEmpty) {
                return Text(
                  'Aucun client dans le carnet.',
                  style: TextStyle(color: p.textMute),
                );
              }
              // Tri descendant par useCount, garde les N premiers.
              final sorted = [...all]..sort(
                  (a, b) => b.useCount.compareTo(a.useCount),
                );
              final top = sorted.take(_topN).toList();
              return Column(
                children: [
                  for (var i = 0; i < top.length; i++) ...[
                    _TopClientRow(rank: i + 1, client: top[i]),
                    if (i < top.length - 1) const Divider(height: 1),
                  ],
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

/// Une ligne du top clients : badge rang colore + nom client + compteur
/// "Xx" en mono emerald.
class _TopClientRow extends StatelessWidget {
  const _TopClientRow({required this.rank, required this.client});

  final int rank;
  final SavedDestination client;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final nom = (client.nomClient?.trim().isNotEmpty ?? false)
        ? client.nomClient!.trim()
        : client.adresseDisplay;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              // Priorite : couleur custom du carnet > lime pour rang 1 >
              // creamSoft par defaut. La couleur custom permet a Noah
              // d'identifier ses clients d'un coup d'oeil ici aussi.
              color: colorFromTag(
                client.colorTag,
                defaultColor:
                    rank == 1 ? AppColors.lime : p.creamSoft,
              ),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: appMonoStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              nom,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: p.ink,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Text(
            '${client.useCount}x',
            style: appMonoStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}
