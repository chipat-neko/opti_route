import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../data/database.dart';
import '../../data/tile_prefetch_service.dart';
import '../../providers/database_providers.dart';
import '../../providers/optimization_providers.dart';
import '../../providers/tile_provider.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/ordre_priorite_dialog.dart';
import '../parametres_screen.dart';
import '../tournee_du_jour_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Handlers d'optimisation / duplication / prefetch tuiles extraits
/// de [TourneeDuJourScreen] (refactor jalon 2026-05-17 phase 4).
/// ════════════════════════════════════════════════════════════════
///
/// `optimize` necessite un callback `setOptimizing(bool)` pour
/// piloter le spinner du bouton dans le screen parent (l'etat
/// `_optimizing` reste dans le screen).
class OptimTourneeActions {
  OptimTourneeActions._();

  /// Duplique la tournee courante a la meme date + 7 jours. Reset le
  /// statut + statuts arrets (via `duplicate`). Affiche un snackbar
  /// avec un bouton "Ouvrir" qui navigue vers la nouvelle tournee.
  static Future<void> duplicatePlus7({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(tourneesRepositoryProvider);
      final targetDate = tournee.date.add(const Duration(days: 7));
      final newId = await repo.duplicate(tournee.id, targetDate: targetDate);
      final newTournee = await repo.getById(newId);
      if (!context.mounted || newTournee == null) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Duplique en "${newTournee.nom}" pour la semaine prochaine',
          ),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () {
              navigator.pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => TourneeDuJourScreen(tournee: newTournee),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  /// Optimise la tournee via OpenRouteService. Etapes :
  /// 1. Check cle ORS configuree
  /// 2. Demander ordre arrets EN 1ER / EN DERNIER si plusieurs
  /// 3. Persister `ordrePriorite`
  /// 4. Appeler le solveur + applyOptimizedOrder + incrementer quota
  /// 5. UPDATE statut + distance + duree + trace
  ///
  /// `setOptimizing` est appele avec true au debut, false a la fin
  /// (ou en cas d'erreur). Permet au screen parent de gerer le
  /// spinner du bouton.
  static Future<void> optimize({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
    required ValueChanged<bool> setOptimizing,
  }) async {
    final optimizer = ref.read(optimizationServiceProvider);
    if (optimizer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Cle OpenRouteService manquante. Configure-la dans les Parametres.',
          ),
          action: SnackBarAction(
            label: 'Ouvrir',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const ParametresScreen(),
              ),
            ),
          ),
        ),
      );
      return;
    }

    final stopsRepo = ref.read(stopsRepositoryProvider);
    final stops = await stopsRepo.getByTournee(tournee.id);
    final geocoded =
        stops.where((s) => s.lat != null && s.lng != null).toList();
    if (geocoded.length < 2) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Au moins 2 arrets avec coordonnees sont necessaires.'),
        ),
      );
      return;
    }

    // 1. Si plusieurs arrets EN 1ER : demander a Noah l'ordre voulu
    //    entre eux. Idem pour EN DERNIER. VROOM ne sait pas le faire :
    //    son champ priority est un score, pas un ordre absolu.
    final firsts = geocoded
        .where((s) => s.priorite == 'obligatoire_premier')
        .toList()
      ..sort(_existingOrdrePrio);
    final lasts = geocoded
        .where((s) => s.priorite == 'obligatoire_dernier')
        .toList()
      ..sort(_existingOrdrePrio);

    if (!context.mounted) return;
    final firstsOrdered = await OrdrePrioriteDialog.showIfNeeded(
      context,
      titre: 'Ordre des arrets EN 1ER',
      sousTitre: 'Tu as ${firsts.length} arrets a livrer en premier. '
          'Glisse-les dans l\'ordre voulu : 1, 2, 3...',
      stops: firsts,
    );
    if (firstsOrdered == null) return; // annule
    if (!context.mounted) return;
    final lastsOrdered = await OrdrePrioriteDialog.showIfNeeded(
      context,
      titre: 'Ordre des arrets EN DERNIER',
      sousTitre: 'Tu as ${lasts.length} arrets a livrer en fin de tournee. '
          'Glisse-les dans l\'ordre voulu.',
      stops: lasts,
    );
    if (lastsOrdered == null) return;

    // 2. Persister `ordrePriorite` pour que le solveur (et la prochaine
    //    optimisation) le retrouvent.
    await _persistOrdrePriorite(ref, firstsOrdered);
    await _persistOrdrePriorite(ref, lastsOrdered);

    // Recharger les stops pour avoir les ordrePriorite a jour avant
    // d'appeler le solveur.
    final stopsRefreshed = await stopsRepo.getByTournee(tournee.id);
    final geocodedRefreshed = stopsRefreshed
        .where((s) => s.lat != null && s.lng != null)
        .toList(growable: false);

    if (!context.mounted) return;
    setOptimizing(true);
    try {
      final result = await optimizer.optimize(
        tournee: tournee,
        stops: geocodedRefreshed,
      );
      // Incremente le compteur du quota ORS (best-effort).
      try {
        await ref.read(parametresRepositoryProvider).incrementOrsUsed();
      } catch (_) {}

      await ref
          .read(stopsRepositoryProvider)
          .applyOptimizedOrder(result.orderedStopIds);

      // Serialise la geometry GeoJSON en string JSON pour stockage
      // SQLite. La carte la decodera en LineString a l'affichage.
      final traceJson = result.routeGeometry == null
          ? null
          : jsonEncode(result.routeGeometry);
      await ref.read(tourneesRepositoryProvider).update(
            tournee.id,
            TourneesCompanion(
              statut: const Value('optimisee'),
              distanceTotaleM: Value(result.totalDistanceMeters),
              dureeTotaleS: Value(result.totalDurationSeconds),
              optimiseeLe: Value(DateTime.now()),
              traceGeojson: Value(traceJson),
            ),
          );

      if (!context.mounted) return;
      final km = (result.totalDistanceMeters / 1000).toStringAsFixed(1);
      final dur = _formatDuration(result.totalDurationSeconds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tournee optimisee : $km km · $dur'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'optimisation : $e')),
      );
    } finally {
      if (context.mounted) setOptimizing(false);
    }
  }

  /// Pre-telecharge les tuiles OSM de la bbox (depot + arrets
  /// geocodes) aux zooms 13-16. Dialog confirmation + progress.
  static Future<void> prefetchTuiles({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final stops = await ref
        .read(stopsRepositoryProvider)
        .getByTournee(tournee.id);
    if (!context.mounted) return;

    final points = <LatLng>[
      LatLng(tournee.pointDepartLat, tournee.pointDepartLng),
      for (final s in stops)
        if (s.lat != null && s.lng != null) LatLng(s.lat!, s.lng!),
    ];
    if (points.length < 2) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Aucun arret geocode. Geolocalise d\'abord les arrets.'),
      ));
      return;
    }

    final estimate = TilePrefetchService.estimate(points: points);
    if (estimate.tiles > TilePrefetchService.maxTiles) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          'Zone trop large (${estimate.tiles} tuiles). Limite '
          '${TilePrefetchService.maxTiles}.',
        ),
      ));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Telecharger pour hors-ligne ?'),
        content: Text(
          '${estimate.tiles} tuiles a telecharger '
          '(~${estimate.estimatedSizeLabel}).\n\n'
          'Les tuiles serviront a afficher la carte meme sans 4G '
          'pendant cette tournee. Operation a faire de preference '
          'en wifi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Telecharger'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final service = TilePrefetchService(ref.read(cachedTileProviderInstance));
    final progress = ValueNotifier<({int done, int total})>(
      (done: 0, total: estimate.tiles),
    );

    // Progress dialog non-bloquante (rentre dans la stack mais on la
    // pop nous-meme a la fin).
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Telechargement...'),
        content: ValueListenableBuilder<({int done, int total})>(
          valueListenable: progress,
          builder: (_, v, _) {
            final ratio = v.total == 0 ? 0.0 : v.done / v.total;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: ratio),
                const SizedBox(height: 12),
                Text('${v.done} / ${v.total} tuiles'),
              ],
            );
          },
        ),
      ),
    ));

    var downloaded = 0;
    String? errorMsg;
    try {
      downloaded = await service.prefetchBbox(
        points: points,
        onProgress: (done, total) {
          progress.value = (done: done, total: total);
        },
      );
    } on TilePrefetchError catch (e) {
      errorMsg = e.message;
    } catch (e) {
      errorMsg = 'Erreur : $e';
    }

    if (context.mounted) Navigator.of(context).pop(); // ferme la progress
    progress.dispose();
    if (!context.mounted) return;
    if (errorMsg != null) {
      messenger.showSnackBar(SnackBar(content: Text(errorMsg)));
      return;
    }
    final failed = estimate.tiles - downloaded;
    messenger.showSnackBar(SnackBar(
      content: Text(
        '$downloaded / ${estimate.tiles} tuiles en cache'
        '${failed > 0 ? ' ($failed echec(s))' : ''}',
      ),
      backgroundColor: AppColors.emerald,
    ));
  }

  /// Tri stable d'arrets par `ordrePriorite` (croissant). Null tombe a
  /// la fin -- les arrets non encore ordonnes apparaissent en queue,
  /// l'utilisateur les classera dans le dialog.
  static int _existingOrdrePrio(Stop a, Stop b) {
    final ao = a.ordrePriorite;
    final bo = b.ordrePriorite;
    if (ao == null && bo == null) return a.id.compareTo(b.id);
    if (ao == null) return 1;
    if (bo == null) return -1;
    return ao.compareTo(bo);
  }

  /// Ecrit `ordrePriorite = position dans la liste` (1-based) pour
  /// chaque stop. Permet aux prochaines optimisations de reprendre
  /// l'ordre choisi sans redemander.
  static Future<void> _persistOrdrePriorite(
    WidgetRef ref,
    List<int> orderedIds,
  ) async {
    if (orderedIds.isEmpty) return;
    await ref
        .read(stopsRepositoryProvider)
        .applyOrdrePriorite(orderedIds);
  }

  static String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }
}
