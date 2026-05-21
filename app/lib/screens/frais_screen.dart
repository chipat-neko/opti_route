import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/app_drawer.dart';
import '../widgets/drawer_badge_icon.dart';
import 'frais_form_screen.dart';

/// Ecran "Notes de frais" : liste les depenses du mois selectionne,
/// avec total par type et total general. FAB +Ajouter ouvre le form.
///
/// Workflow :
///  - Au boot, mois courant selectionne
///  - Selecteur de mois (chevron < >) pour naviguer dans le passe
///  - Liste plate triee par date desc
///  - Tap sur un frais -> form en mode edit
///  - Long-press -> confirm + delete
///  - FAB lime -> form en mode creation
///
/// 100% local. Pas de cloud sync, pas d'export pour l'instant (le
/// dashboard CSV web pourra l'ajouter plus tard si besoin).
class FraisScreen extends ConsumerStatefulWidget {
  const FraisScreen({super.key});

  @override
  ConsumerState<FraisScreen> createState() => _FraisScreenState();
}

class _FraisScreenState extends ConsumerState<FraisScreen> {
  late DateTime _moisSelectionne;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _moisSelectionne = DateTime(now.year, now.month);
  }

  void _moisPrecedent() {
    setState(() {
      _moisSelectionne = DateTime(
        _moisSelectionne.year,
        _moisSelectionne.month - 1,
      );
    });
  }

  void _moisSuivant() {
    final maxMois = DateTime(DateTime.now().year, DateTime.now().month);
    if (_moisSelectionne.isBefore(maxMois)) {
      setState(() {
        _moisSelectionne = DateTime(
          _moisSelectionne.year,
          _moisSelectionne.month + 1,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final ym = (_moisSelectionne.year, _moisSelectionne.month);
    final fraisAsync = ref.watch(fraisByMonthProvider(ym));
    final moisLabel = DateFormat('MMMM yyyy', 'fr').format(_moisSelectionne);
    final canGoNext = _moisSelectionne
        .isBefore(DateTime(DateTime.now().year, DateTime.now().month));

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerBadgeIcon(),
        title: const Text('Notes de frais'),
      ),
      body: Column(
        children: [
          // Selecteur de mois
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x14,
              AppSpacing.x14,
              AppSpacing.x14,
              AppSpacing.x8,
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Mois precedent',
                  onPressed: _moisPrecedent,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      moisLabel[0].toUpperCase() + moisLabel.substring(1),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: canGoNext ? 'Mois suivant' : 'Mois courant',
                  onPressed: canGoNext ? _moisSuivant : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: fraisAsync.when(
              data: (frais) => _buildContent(frais),
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) =>
                  Center(child: Text('Erreur : $e')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: p.paper,
        foregroundColor: p.ink,
        icon: const Icon(Icons.add, color: AppColors.emerald),
        label: const Text(
          'Ajouter un frais',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const FraisFormScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(List<Frai> frais) {
    final p = context.palette;
    if (frais.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: p.textMute,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.x14),
              Text(
                'Aucun frais ce mois',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(
                'Tape sur "Ajouter un frais" pour saisir une depense '
                '(carburant, peage, parking...).',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: p.textMute,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Total par type + total general
    final parType = <String, int>{};
    var total = 0;
    for (final f in frais) {
      parType[f.type] = (parType[f.type] ?? 0) + f.montantCentimes;
      total += f.montantCentimes;
    }
    return ListView(
      // Bottom padding ~96 pour laisser respirer la liste sous le FAB
      // extended "Ajouter un frais" (sinon le dernier item est cache).
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x14,
        0,
        AppSpacing.x14,
        96,
      ),
      children: [
        // Card "Total du mois" + chips par type
        Container(
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
                'TOTAL DU MOIS',
                style: appMonoStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: p.textMute,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(
                _formatEur(total),
                style: appMonoStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
              if (parType.length > 1) ...[
                const SizedBox(height: AppSpacing.x12),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: parType.entries
                      .map((e) => Chip(
                            backgroundColor: _colorForType(e.key)
                                .withValues(alpha: 0.18),
                            side: BorderSide.none,
                            visualDensity: VisualDensity.compact,
                            label: Text(
                              '${_labelForType(e.key)} '
                              '${_formatEur(e.value)}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _colorForType(e.key),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        // Liste des frais
        for (final f in frais)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.x8),
            child: _FraisRow(
              frais: f,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => FraisFormScreen(initial: f),
                ),
              ),
              onLongPress: () => _confirmDelete(f),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(Frai f) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer ce frais ?'),
        content: Text('${_labelForType(f.type)} - ${f.libelle}\n'
            '${_formatEur(f.montantCentimes)}'),
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
    if (confirmed == true && mounted) {
      await ref.read(fraisRepositoryProvider).delete(f.id);
    }
  }
}

class _FraisRow extends StatelessWidget {
  const _FraisRow({
    required this.frais,
    required this.onTap,
    required this.onLongPress,
  });

  final Frai frais;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dateLabel = DateFormat('EEE d MMM', 'fr').format(frais.date);
    final color = _colorForType(frais.type);
    return Material(
      color: p.paper,
      borderRadius: BorderRadius.circular(AppRadius.r14),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x14,
            vertical: AppSpacing.x12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(_iconForType(frais.type), color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      frais.libelle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_labelForType(frais.type)} · $dateLabel',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: p.textMute,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatEur(frais.montantCentimes),
                style: appMonoStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Helpers communs (color + label + icon + format) ───────────────

String _formatEur(int centimes) {
  final eur = centimes / 100;
  return NumberFormat.currency(locale: 'fr_FR', symbol: 'EUR').format(eur);
}

String _labelForType(String type) {
  return switch (type) {
    'carburant' => 'Carburant',
    'peage' => 'Peage',
    'parking' => 'Parking',
    'repas' => 'Repas',
    'autre' => 'Autre',
    _ => type[0].toUpperCase() + type.substring(1),
  };
}

Color _colorForType(String type) {
  return switch (type) {
    'carburant' => AppColors.amber,
    'peage' => AppColors.emerald,
    'parking' => const Color(0xFF7C4DFF),
    'repas' => AppColors.red,
    'autre' => AppColors.textMute,
    _ => AppColors.textMute,
  };
}

IconData _iconForType(String type) {
  return switch (type) {
    'carburant' => Icons.local_gas_station_outlined,
    'peage' => Icons.toll_outlined,
    'parking' => Icons.local_parking_outlined,
    'repas' => Icons.restaurant_outlined,
    'autre' => Icons.receipt_outlined,
    _ => Icons.receipt_outlined,
  };
}
