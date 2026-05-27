import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/doublon_detection_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'carnet_adresses/providers.dart';

/// Ecran de revue des doublons potentiels du carnet (carte #103).
///
/// Liste les paires detectees par [carnetDoublonsProvider]. Pour chaque
/// paire, Noah peut fusionner (en choisissant la fiche a conserver) ou
/// ignorer (garder les 2). Les paires ignorees sont masquees pour la
/// session courante (pas de persistance : un doublon reellement non
/// fusionne ressortira a la prochaine ouverture, ce qui est voulu).
class CarnetDoublonsScreen extends ConsumerStatefulWidget {
  const CarnetDoublonsScreen({super.key});

  @override
  ConsumerState<CarnetDoublonsScreen> createState() =>
      _CarnetDoublonsScreenState();
}

class _CarnetDoublonsScreenState
    extends ConsumerState<CarnetDoublonsScreen> {
  /// Cles de paires ignorees cette session (format "minId-maxId").
  final Set<String> _ignored = {};

  static String _key(DoublonPaire p) {
    final lo = p.a.id < p.b.id ? p.a.id : p.b.id;
    final hi = p.a.id < p.b.id ? p.b.id : p.a.id;
    return '$lo-$hi';
  }

  Future<void> _fusionner(int keepId, int dropId) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(savedDestinationsRepositoryProvider)
        .mergeInto(keepId, dropId);
    // Le carnetStreamProvider emettra la nouvelle liste -> la paire
    // disparait automatiquement.
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Fiches fusionnees'),
        backgroundColor: AppColors.emerald,
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final paires = ref
        .watch(carnetDoublonsProvider)
        .where((d) => !_ignored.contains(_key(d)))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doublons du carnet'),
      ),
      body: paires.isEmpty
          ? _EmptyState()
          : ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.x16),
              itemCount: paires.length + 1,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.x12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.x4),
                    child: Text(
                      '${paires.length} doublon'
                      '${paires.length > 1 ? "s" : ""} potentiel'
                      '${paires.length > 1 ? "s" : ""}. Verifie chaque '
                      'paire avant de fusionner.',
                      style: TextStyle(fontSize: 13, color: p.textMute),
                    ),
                  );
                }
                final paire = paires[i - 1];
                return _PaireCard(
                  paire: paire,
                  onFusionGauche: () =>
                      _fusionner(paire.a.id, paire.b.id),
                  onFusionDroite: () =>
                      _fusionner(paire.b.id, paire.a.id),
                  onIgnorer: () =>
                      setState(() => _ignored.add(_key(paire))),
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 44, color: p.textFaint),
            const SizedBox(height: AppSpacing.x14),
            Text(
              'Aucun doublon detecte',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              'Ton carnet est propre. On detecte les fiches au nom '
              'similaire et proches geographiquement, ou a la meme '
              'adresse.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: p.textMute),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaireCard extends StatelessWidget {
  const _PaireCard({
    required this.paire,
    required this.onFusionGauche,
    required this.onFusionDroite,
    required this.onIgnorer,
  });

  final DoublonPaire paire;
  final VoidCallback onFusionGauche;
  final VoidCallback onFusionDroite;
  final VoidCallback onIgnorer;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r16),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Raison + distance.
          Row(
            children: [
              Icon(Icons.merge_type, size: 16, color: AppColors.amber),
              const SizedBox(width: AppSpacing.x6),
              Expanded(
                child: Text(
                  paire.raison,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
              ),
              Text(
                '${paire.distanceMeters.round()} m',
                style: appMonoStyle(fontSize: 11, color: p.textMute),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _FicheApercu(d: paire.a)),
              Container(
                width: 1,
                height: 64,
                margin: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x10,
                ),
                color: p.divider,
              ),
              Expanded(child: _FicheApercu(d: paire.b)),
            ],
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onFusionGauche,
                  child: const Text('Garder gauche'),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: OutlinedButton(
                  onPressed: onFusionDroite,
                  child: const Text('Garder droite'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x6),
          TextButton(
            onPressed: onIgnorer,
            child: const Text('Ce ne sont pas des doublons'),
          ),
        ],
      ),
    );
  }
}

class _FicheApercu extends StatelessWidget {
  const _FicheApercu({required this.d});

  final SavedDestination d;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (d.nomClient?.trim().isNotEmpty ?? false)
              ? d.nomClient!
              : '(sans nom)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: p.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          d.adresseDisplay,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: p.textMute, height: 1.3),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          'utilise ${d.useCount}x'
          '${d.isFavori ? " · favori" : ""}',
          style: appMonoStyle(fontSize: 10, color: p.textFaint),
        ),
      ],
    );
  }
}
