import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/location_service.dart';
import '../data/navigation_service.dart';
import '../data/stops_repository.dart';
import '../data/tournees_repository.dart';
import '../providers/database_providers.dart';
import '../providers/location_providers.dart';
import '../providers/optimization_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/ordre_priorite_dialog.dart';
import '../widgets/stop_action_sheet.dart';
import 'ajout_arret_screen.dart';
import 'carte_screen.dart';
import 'parametres_screen.dart';
import 'tournee_form_screen.dart';

class TourneeDuJourScreen extends ConsumerStatefulWidget {
  const TourneeDuJourScreen({super.key, required this.tournee});

  final Tournee tournee;

  @override
  ConsumerState<TourneeDuJourScreen> createState() =>
      _TourneeDuJourScreenState();
}

class _TourneeDuJourScreenState extends ConsumerState<TourneeDuJourScreen> {
  bool _optimizing = false;

  @override
  Widget build(BuildContext context) {
    final stopsAsync = ref.watch(stopsByTourneeProvider(widget.tournee.id));
    final optimizer = ref.watch(optimizationServiceProvider);

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Tournee du jour'),
        actions: [
          IconButton(
            icon: _optimizing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bolt_outlined),
            tooltip: optimizer == null
                ? 'Configure ta cle ORS dans les Parametres'
                : 'Optimiser la tournee',
            onPressed: _optimizing ? null : _onOptimizePressed,
          ),
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Voir sur la carte',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CarteScreen(tournee: widget.tournee),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Modifier la tournee',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TourneeFormScreen(initial: widget.tournee),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Plus',
            onSelected: (value) {
              if (value == 'delete') _confirmDeleteTournee();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, color: AppColors.red),
                  title: Text('Supprimer la tournee'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: stopsAsync.when(
        data: (stops) => _Body(tournee: widget.tournee, stops: stops),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erreur : $err')),
      ),
      floatingActionButton: _Fabs(
        tournee: widget.tournee,
        onAjouter: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AjoutArretScreen(tourneeId: widget.tournee.id),
          ),
        ),
        onDemarrer: _onDemarrerPressed,
        onArreter: _onArreterPressed,
      ),
    );
  }

  Future<void> _confirmDeleteTournee() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette tournee ?'),
        content: Text(
          '"${widget.tournee.nom}" et tous ses arrets seront supprimes '
          'definitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red.withValues(alpha: 0.15),
              foregroundColor: AppColors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ref.read(tourneesRepositoryProvider).delete(widget.tournee.id);
      if (!mounted) return;
      // Le HomeScreen va detecter qu'il n'y a plus de tournee du jour
      // et basculer sur l'empty state — pas besoin de pop manuellement.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }

  Future<void> _onDemarrerPressed() async {
    final messenger = ScaffoldMessenger.of(context);
    // Demande la permission GPS avant de basculer en mode en_cours
    // pour eviter d'afficher la card "prochain arret" sans donnees.
    try {
      final ok = await LocationService.ensurePermission();
      if (!ok) return;
    } on LocationPermissionDenied catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }
    if (!mounted) return;
    await ref.read(tourneesRepositoryProvider).update(
          widget.tournee.id,
          const TourneesCompanion(statut: Value('en_cours')),
        );
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Tournee demarree. Bonne route !'),
        backgroundColor: AppColors.emerald,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _onArreterPressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mettre la tournee en pause ?'),
        content: const Text(
          'La tournee repasse en mode "optimisee". Tu pourras la '
          'relancer plus tard.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Mettre en pause'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(tourneesRepositoryProvider).update(
          widget.tournee.id,
          const TourneesCompanion(statut: Value('optimisee')),
        );
  }

  Future<void> _onOptimizePressed() async {
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
    final stops = await stopsRepo.getByTournee(widget.tournee.id);
    final geocoded =
        stops.where((s) => s.lat != null && s.lng != null).toList();
    if (geocoded.length < 2) {
      if (!mounted) return;
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

    if (!mounted) return;
    final firstsOrdered = await OrdrePrioriteDialog.showIfNeeded(
      context,
      titre: 'Ordre des arrets EN 1ER',
      sousTitre: 'Tu as ${firsts.length} arrets a livrer en premier. '
          'Glisse-les dans l\'ordre voulu : 1, 2, 3...',
      stops: firsts,
    );
    if (firstsOrdered == null) return; // annule
    if (!mounted) return;
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
    await _persistOrdrePriorite(firstsOrdered);
    await _persistOrdrePriorite(lastsOrdered);

    // Recharger les stops pour avoir les ordrePriorite a jour avant
    // d'appeler le solveur.
    final stopsRefreshed = await stopsRepo.getByTournee(widget.tournee.id);
    final geocodedRefreshed = stopsRefreshed
        .where((s) => s.lat != null && s.lng != null)
        .toList(growable: false);

    if (!mounted) return;
    setState(() => _optimizing = true);
    try {
      final result = await optimizer.optimize(
        tournee: widget.tournee,
        stops: geocodedRefreshed,
      );

      await ref
          .read(stopsRepositoryProvider)
          .applyOptimizedOrder(result.orderedStopIds);

      // On serialise la geometry GeoJSON en string JSON pour stockage
      // SQLite. La carte la decodera en LineString a l'affichage.
      final traceJson = result.routeGeometry == null
          ? null
          : jsonEncode(result.routeGeometry);
      await ref.read(tourneesRepositoryProvider).update(
            widget.tournee.id,
            TourneesCompanion(
              statut: const Value('optimisee'),
              distanceTotaleM: Value(result.totalDistanceMeters),
              dureeTotaleS: Value(result.totalDurationSeconds),
              optimiseeLe: Value(DateTime.now()),
              traceGeojson: Value(traceJson),
            ),
          );

      if (!mounted) return;
      final km = (result.totalDistanceMeters / 1000).toStringAsFixed(1);
      final dur = _formatDuration(result.totalDurationSeconds);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tournee optimisee : $km km · $dur'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur d\'optimisation : $e')),
      );
    } finally {
      if (mounted) setState(() => _optimizing = false);
    }
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
  Future<void> _persistOrdrePriorite(List<int> orderedIds) async {
    if (orderedIds.isEmpty) return;
    final repo = ref.read(stopsRepositoryProvider);
    for (var i = 0; i < orderedIds.length; i++) {
      await repo.update(
        orderedIds[i],
        StopsCompanion(ordrePriorite: Value(i + 1)),
      );
    }
  }
}

String _formatDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  if (h == 0) return '${m}min';
  return '${h}h${m.toString().padLeft(2, '0')}';
}

class _Body extends StatelessWidget {
  const _Body({required this.tournee, required this.stops});

  final Tournee tournee;
  final List<Stop> stops;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x18,
        AppSpacing.x8,
        AppSpacing.x18,
        AppSpacing.x18,
      ),
      children: [
        _Header(tournee: tournee),
        const SizedBox(height: AppSpacing.x16),
        _StatRow(
          arretsCount: stops.length,
          distanceMeters: tournee.distanceTotaleM,
          durationSeconds: tournee.dureeTotaleS,
        ),
        if (tournee.statut == 'optimisee') ...[
          const SizedBox(height: AppSpacing.x12),
          _OptimisedBanner(tournee: tournee),
        ],
        if (stops.any((s) =>
            s.statutLivraison == 'livre' || s.statutLivraison == 'echec')) ...[
          const SizedBox(height: AppSpacing.x12),
          _ProgressBanner(
            stops: stops,
            tourneeTerminee: tournee.statut == 'terminee',
          ),
        ],
        if (tournee.statut == 'en_cours') ...[
          const SizedBox(height: AppSpacing.x12),
          _ProchainArretCard(stops: stops),
        ],
        const SizedBox(height: AppSpacing.x18),
        if (stops.isEmpty)
          const _StopsPlaceholder()
        else
          _StopsList(stops: stops),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context) {
    final dateLabel = DateFormat('EEEE d MMMM', 'fr')
        .format(tournee.date)
        .toUpperCase();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          dateLabel,
          style: appMonoStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.textMute,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          tournee.nom,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.5,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.x4),
        Text(
          'Depart : ${tournee.pointDepartLabel}',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMute,
            height: 1.4,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.arretsCount,
    this.distanceMeters,
    this.durationSeconds,
  });

  final int arretsCount;
  final int? distanceMeters;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    final hasDistance = distanceMeters != null && distanceMeters! > 0;
    final hasDuration = durationSeconds != null && durationSeconds! > 0;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x14,
      ),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      child: Row(
        children: [
          _StatTile(label: 'Arrets', value: '$arretsCount'),
          const _StatDivider(),
          _StatTile(
            label: 'Distance',
            value: hasDistance
                ? (distanceMeters! / 1000).toStringAsFixed(1)
                : '—',
            unit: hasDistance ? 'km' : null,
          ),
          const _StatDivider(),
          _StatTile(
            label: 'Duree',
            value: hasDuration ? _formatDuration(durationSeconds!) : '—',
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: AppColors.divider);
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              text: TextSpan(
                style: appMonoStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.5,
                ),
                children: [
                  TextSpan(text: value),
                  if (unit != null)
                    TextSpan(
                      text: ' $unit',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMute,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMute,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptimisedBanner extends StatelessWidget {
  const _OptimisedBanner({required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context) {
    final timeLabel = tournee.optimiseeLe == null
        ? null
        : DateFormat('HH:mm', 'fr').format(tournee.optimiseeLe!);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: AppColors.ink,
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
            child: const Icon(Icons.bolt, color: AppColors.ink, size: 18),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Itineraire optimise',
                  style: TextStyle(
                    color: AppColors.paper,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                if (timeLabel != null)
                  Text(
                    'Calcule a $timeLabel',
                    style: TextStyle(
                      color: AppColors.paper.withValues(alpha: 0.65),
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

/// Card "Prochain arret" affichee en haut de l'ecran pendant que la
/// tournee est en cours. Met en avant le 1er arret encore "a livrer"
/// dans l'ordre optimise, avec :
/// - Distance vol d'oiseau live depuis la position GPS du chauffeur.
/// - Boutons rapides Maps / Waze.
/// - Tap sur la card -> bottom sheet d'action (livre / echec / details).
class _ProchainArretCard extends ConsumerWidget {
  const _ProchainArretCard({required this.stops});

  final List<Stop> stops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Stop? candidat;
    for (final s in stops) {
      if (s.statutLivraison == 'a_livrer' &&
          s.lat != null &&
          s.lng != null) {
        candidat = s;
        break;
      }
    }
    if (candidat == null) {
      // Tous valides ou pas de coords : on n'affiche rien (le
      // _ProgressBanner / la liste suffisent).
      return const SizedBox.shrink();
    }
    // Promotion non-null : variable `final` apres l'early return.
    final prochain = candidat;
    final lat = prochain.lat!;
    final lng = prochain.lng!;

    final positionAsync = ref.watch(currentPositionProvider);
    final distanceLabel = positionAsync.maybeWhen(
      data: (pos) {
        if (pos == null) return null;
        final m = LocationService.distanceMeters(
          fromLat: pos.latitude,
          fromLng: pos.longitude,
          toLat: lat,
          toLng: lng,
        );
        return _formatDistanceMeters(m);
      },
      orElse: () => null,
    );

    final nom = (prochain.nomClient ?? '').trim();
    final hasNom = nom.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.ink,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(AppSpacing.x16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.lime,
                  borderRadius: BorderRadius.circular(AppRadius.r6),
                ),
                child: Text(
                  'PROCHAIN',
                  style: appMonoStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.ink,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
              const Spacer(),
              if (distanceLabel != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.near_me_outlined,
                      color: AppColors.lime,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      distanceLabel,
                      style: appMonoStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lime,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          if (hasNom)
            Text(
              nom,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.paper,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (hasNom) const SizedBox(height: 2),
          Text(
            prochain.adresseNormalisee ?? prochain.adresseBrute,
            style: TextStyle(
              fontSize: hasNom ? 13 : 16,
              color: AppColors.paper.withValues(alpha: hasNom ? 0.7 : 1),
              fontWeight: hasNom ? FontWeight.w500 : FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.paper,
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => NavigationService.launchGoogleMaps(
                    lat: lat,
                    lng: lng,
                  ),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: const Text(
                    'Maps',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.paper,
                    foregroundColor: AppColors.ink,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => NavigationService.launchWaze(
                    lat: lat,
                    lng: lng,
                  ),
                  icon: const Icon(Icons.navigation_outlined, size: 16),
                  label: const Text(
                    'Waze',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDistanceMeters(double m) {
    if (m < 1000) return '${m.round()} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }
}

/// Pile de FloatingActionButtons en bas a droite. Le bouton du bas est
/// 'Ajouter un arret' (toujours present). Au-dessus, selon le statut
/// de la tournee :
/// - 'optimisee' : 'Demarrer' (vert lime).
/// - 'en_cours'  : 'Pause' (amber).
/// - autres : aucun bouton supplementaire.
class _Fabs extends StatelessWidget {
  const _Fabs({
    required this.tournee,
    required this.onAjouter,
    required this.onDemarrer,
    required this.onArreter,
  });

  final Tournee tournee;
  final VoidCallback onAjouter;
  final VoidCallback onDemarrer;
  final VoidCallback onArreter;

  @override
  Widget build(BuildContext context) {
    final isOptimisee = tournee.statut == 'optimisee';
    final isEnCours = tournee.statut == 'en_cours';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isOptimisee)
          FloatingActionButton.extended(
            heroTag: 'fab-demarrer',
            backgroundColor: AppColors.lime,
            foregroundColor: AppColors.ink,
            onPressed: onDemarrer,
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text(
              'Demarrer',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        if (isEnCours)
          FloatingActionButton.extended(
            heroTag: 'fab-arreter',
            backgroundColor: AppColors.amber,
            foregroundColor: AppColors.ink,
            onPressed: onArreter,
            icon: const Icon(Icons.pause_rounded),
            label: const Text(
              'Pause',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        if (isOptimisee || isEnCours) const SizedBox(height: AppSpacing.x10),
        FloatingActionButton.extended(
          heroTag: 'fab-ajouter',
          onPressed: onAjouter,
          icon: const Icon(Icons.add),
          label: const Text('Ajouter un arret'),
        ),
      ],
    );
  }
}

/// Bandeau de progression / bilan qui s'affiche des qu'au moins un
/// arret a un statut definitif. Quand toute la tournee est terminee,
/// passe en mode "Tournee terminee" avec un fond vert.
class _ProgressBanner extends StatelessWidget {
  const _ProgressBanner({
    required this.stops,
    required this.tourneeTerminee,
  });

  final List<Stop> stops;
  final bool tourneeTerminee;

  @override
  Widget build(BuildContext context) {
    final livres =
        stops.where((s) => s.statutLivraison == 'livre').length;
    final echecs = stops.where((s) => s.statutLivraison == 'echec').length;
    final total = stops.length;
    final restants = total - livres - echecs;

    final bg = tourneeTerminee ? AppColors.emerald : AppColors.paper;
    final fg = tourneeTerminee ? AppColors.paper : AppColors.ink;
    final mute = tourneeTerminee
        ? AppColors.paper.withValues(alpha: 0.75)
        : AppColors.textMute;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: tourneeTerminee
            ? null
            : Border.all(color: AppColors.divider),
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
                            ? AppColors.paper.withValues(alpha: 0.2)
                            : AppColors.creamSoft,
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

class _StopsPlaceholder extends StatelessWidget {
  const _StopsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x22),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: AppColors.creamSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.add_road_outlined,
              color: AppColors.ink,
              size: 26,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          const Text(
            'Pas encore d\'arrets',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Tape sur "Ajouter un arret" pour commencer a remplir ta tournee.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _StopsList extends ConsumerWidget {
  const _StopsList({required this.stops});

  final List<Stop> stops;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(AppRadius.r18),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < stops.length; i++) ...[
            _StopRow(
              stop: stops[i],
              index: i + 1,
              onDelete: () => _confirmDelete(context, ref, stops[i]),
            ),
            if (i < stops.length - 1)
              const Divider(height: 1, indent: AppSpacing.x16),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Stop stop,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet arret ?'),
        content: Text(
          stop.nomClient != null && stop.nomClient!.isNotEmpty
              ? '${stop.nomClient} - ${stop.adresseBrute}'
              : stop.adresseBrute,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(stopsRepositoryProvider).delete(stop.id);
    }
  }
}

class _StopRow extends ConsumerWidget {
  const _StopRow({
    required this.stop,
    required this.index,
    required this.onDelete,
  });

  final Stop stop;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tags = _buildTags(stop);
    final isLivre = stop.statutLivraison == 'livre';
    final isEchec = stop.statutLivraison == 'echec';
    return Dismissible(
      key: ValueKey('stop-${stop.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: AppColors.red.withValues(alpha: 0.12),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x22),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: InkWell(
        onTap: () => _onTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x14,
            vertical: AppSpacing.x14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IndexChip(
                index: index,
                priorite: stop.priorite,
                statut: stop.statutLivraison,
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _primaryLine(stop),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isLivre ? AppColors.textMute : AppColors.ink,
                        decoration:
                            isLivre ? TextDecoration.lineThrough : null,
                        decorationColor: AppColors.textMute,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_secondaryLine(stop) != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        _secondaryLine(stop)!,
                        style: appMonoStyle(
                          fontSize: 11,
                          color: AppColors.textMute,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (isEchec) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Echec : ${_humanRaison(stop.raisonEchec)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.red,
                        ),
                      ),
                    ],
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.x8),
                      Wrap(
                        spacing: AppSpacing.x6,
                        runSpacing: AppSpacing.x4,
                        children: tags,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);

    final action = await StopActionSheet.show(context, stop);
    if (action == null) return;
    var statutChange = false;
    switch (action) {
      case MarkLivreAction():
        await repo.markLivre(stop.id);
        statutChange = true;
        messenger.showSnackBar(
          SnackBar(
            content: Text('${_primaryLine(stop)} marque livre'),
            backgroundColor: AppColors.emerald,
            duration: const Duration(seconds: 2),
          ),
        );
      case MarkEchecAction(raison: final r):
        await repo.markEchec(stop.id, r);
        statutChange = true;
        messenger.showSnackBar(
          SnackBar(
            content: Text(
                '${_primaryLine(stop)} en echec : ${_humanRaison(r)}'),
            backgroundColor: AppColors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      case MarkAaLivrerAction():
        await repo.markAaLivrer(stop.id);
        statutChange = true;
      case OpenDetailsAction():
        await navigator.push<void>(
          MaterialPageRoute(
            builder: (_) => AjoutArretScreen(
              tourneeId: stop.tourneeId,
              initial: stop,
            ),
          ),
        );
    }

    if (statutChange) {
      await _maybeFinishTournee(repo, tourneesRepo, stop.tourneeId);
    }
  }

  /// Verifie si tous les arrets ont un statut definitif (livre / echec)
  /// et bascule la tournee en 'terminee' le cas echeant. Si on annule
  /// un statut, on revient a 'optimisee' / 'en_cours'.
  Future<void> _maybeFinishTournee(
    StopsRepository stopsRepo,
    TourneesRepository tourneesRepo,
    int tourneeId,
  ) async {
    final stops = await stopsRepo.getByTournee(tourneeId);
    if (stops.isEmpty) return;
    final tournee = await tourneesRepo.getById(tourneeId);
    if (tournee == null) return;
    final tousValides = stops.every(
      (s) => s.statutLivraison == 'livre' || s.statutLivraison == 'echec',
    );
    final wasTerminee = tournee.statut == 'terminee';
    if (tousValides && !wasTerminee) {
      await tourneesRepo.update(
        tourneeId,
        const TourneesCompanion(statut: Value('terminee')),
      );
    } else if (!tousValides && wasTerminee) {
      // L'utilisateur a annule un statut deja pose. On retire la
      // marque "terminee" pour qu'il finisse la tournee.
      await tourneesRepo.update(
        tourneeId,
        const TourneesCompanion(statut: Value('optimisee')),
      );
    }
  }

  static String _humanRaison(String? r) {
    return switch (r) {
      'absent' => 'absent',
      'refuse' => 'refuse',
      'adresse_fausse' => 'adresse fausse',
      'autre' => 'autre',
      _ => 'sans raison',
    };
  }

  String _primaryLine(Stop s) {
    if (s.nomClient != null && s.nomClient!.isNotEmpty) {
      return s.nomClient!;
    }
    return s.adresseBrute.split(',').first.trim();
  }

  String? _secondaryLine(Stop s) {
    if (s.nomClient != null && s.nomClient!.isNotEmpty) {
      return s.adresseBrute.split(',').take(2).join(',').trim();
    }
    if (s.notes != null && s.notes!.isNotEmpty) return s.notes;
    return null;
  }

  List<Widget> _buildTags(Stop s) {
    final out = <Widget>[];
    final priority = _priorityTag(s.priorite);
    if (priority != null) out.add(priority);
    if (s.nbColis > 1) {
      out.add(_Tag(
        label: '${s.nbColis} colis',
        bg: AppColors.creamSoft,
        fg: AppColors.ink,
      ));
    }
    if (s.fenetreDebut != null || s.fenetreFin != null) {
      final start = s.fenetreDebut ?? '--:--';
      final end = s.fenetreFin ?? '--:--';
      out.add(_Tag(
        label: '$start → $end',
        bg: const Color(0x33F2A341),
        fg: const Color(0xFF7A4F0E),
        mono: true,
      ));
    }
    return out;
  }

  Widget? _priorityTag(String priorite) {
    return switch (priorite) {
      'obligatoire_premier' => const _Tag(
          label: 'En 1er',
          bg: AppColors.lime,
          fg: AppColors.ink,
        ),
      'obligatoire_dernier' => const _Tag(
          label: 'En dernier',
          bg: AppColors.lime,
          fg: AppColors.ink,
        ),
      'eviter_si_possible' => _Tag(
          label: 'Eviter',
          bg: AppColors.amber.withValues(alpha: 0.25),
          fg: const Color(0xFF7A4F0E),
        ),
      _ => null,
    };
  }
}

class _IndexChip extends StatelessWidget {
  const _IndexChip({
    required this.index,
    required this.priorite,
    this.statut = 'a_livrer',
  });

  final int index;
  final String priorite;
  final String statut;

  @override
  Widget build(BuildContext context) {
    if (statut == 'livre') {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.emerald,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.check, color: AppColors.paper, size: 20),
      );
    }
    if (statut == 'echec') {
      return Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.red,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.close, color: AppColors.paper, size: 20),
      );
    }
    final isActive =
        priorite == 'obligatoire_premier' || priorite == 'obligatoire_dernier';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isActive ? AppColors.ink : AppColors.paper,
        border: Border.all(color: AppColors.ink, width: 1.5),
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$index',
        style: appMonoStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isActive ? AppColors.lime : AppColors.ink,
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.bg,
    required this.fg,
    this.mono = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final style = mono
        ? appMonoStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: fg)
        : TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: fg,
            letterSpacing: 0.4,
          );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label.toUpperCase(),
        style: style,
      ),
    );
  }
}
