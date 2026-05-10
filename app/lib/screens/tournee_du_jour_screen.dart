import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../providers/optimization_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/ordre_priorite_dialog.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AjoutArretScreen(tourneeId: widget.tournee.id),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un arret'),
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

      await ref.read(tourneesRepositoryProvider).update(
            widget.tournee.id,
            TourneesCompanion(
              statut: const Value('optimisee'),
              distanceTotaleM: Value(result.totalDistanceMeters),
              dureeTotaleS: Value(result.totalDurationSeconds),
              optimiseeLe: Value(DateTime.now()),
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

class _StopRow extends StatelessWidget {
  const _StopRow({
    required this.stop,
    required this.index,
    required this.onDelete,
  });

  final Stop stop;
  final int index;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tags = _buildTags(stop);
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
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => AjoutArretScreen(
              tourneeId: stop.tourneeId,
              initial: stop,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x14,
            vertical: AppSpacing.x14,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IndexChip(index: index, priorite: stop.priorite),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _primaryLine(stop),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.ink,
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
  const _IndexChip({required this.index, required this.priorite});

  final int index;
  final String priorite;

  @override
  Widget build(BuildContext context) {
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
