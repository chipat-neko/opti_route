import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/parametres_repository.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import 'parametres_widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Carburant" — cout EUR/litre + conso L/100km.
/// ════════════════════════════════════════════════════════════════
///
/// Deux TextField (prix + conso) + suggestion live du prix Diesel
/// moyen du departement via l'API gratuite data.gouv.fr (carte
/// Trello #39). Le bouton "Utiliser" pre-remplit le champ prix et
/// sauvegarde immediatement. Bouton refresh pour forcer un re-fetch.
class CarburantSection extends ConsumerStatefulWidget {
  const CarburantSection({super.key, this.departement = '28'});

  /// Code INSEE du departement pour la suggestion (default Eure-et-Loir).
  final String departement;

  @override
  ConsumerState<CarburantSection> createState() => _CarburantSectionState();
}

class _CarburantSectionState extends ConsumerState<CarburantSection> {
  final _coutLitreCtrl = TextEditingController();
  final _consoCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(parametresRepositoryProvider);
    final cout = await repo.getCoutCarburantLitre();
    final conso = await repo.getConsoLitresPar100Km();
    if (!mounted) return;
    setState(() {
      _coutLitreCtrl.text = cout.toStringAsFixed(2);
      _consoCtrl.text = conso.toStringAsFixed(1);
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _coutLitreCtrl.dispose();
    _consoCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(parametresRepositoryProvider);
      final cout = double.tryParse(
            _coutLitreCtrl.text.trim().replaceAll(',', '.'),
          ) ??
          ParametresRepository.defaultCoutCarburantLitre;
      final conso = double.tryParse(
            _consoCtrl.text.trim().replaceAll(',', '.'),
          ) ??
          ParametresRepository.defaultConsoLitresPar100Km;
      await repo.setCoutCarburantLitre(cout);
      await repo.setConsoLitresPar100Km(conso);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cout carburant enregistre')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // Pre-remplit + sauvegarde quand on tape "Utiliser" sur la suggestion.
  Future<void> _applySuggestion(double averageEurPerLiter) async {
    _coutLitreCtrl.text = averageEurPerLiter.toStringAsFixed(3);
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Carburant'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Sert au calcul du cout estime affiche sur chaque tournee '
          'optimisee. Sans impact sur les calculs ORS / VROOM.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _coutLitreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Prix EUR / litre',
                  helperText: '1.85 EUR par defaut',
                  helperMaxLines: 2,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: _initialized,
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: TextField(
                controller: _consoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Conso L / 100km',
                  helperText: '7 L/100km par defaut',
                  helperMaxLines: 2,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                enabled: _initialized,
                onSubmitted: (_) => _save(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x10),
        _FuelPriceSuggestion(
          departement: widget.departement,
          onApply: _applySuggestion,
        ),
        const SizedBox(height: AppSpacing.x14),
        FilledButton.icon(
          onPressed: _saving || !_initialized ? null : _save,
          icon: const Icon(Icons.check),
          label: const Text('Enregistrer les couts carburant'),
        ),
      ],
    );
  }
}

/// Widget compact qui affiche le prix moyen du Diesel dans un
/// departement (data.gouv.fr) + bouton "Utiliser" qui appelle
/// [onApply] avec la valeur suggeree. Silencieux si l'API est down
/// ou n'a aucune station (SizedBox.shrink). Carte Trello #39.
class _FuelPriceSuggestion extends ConsumerWidget {
  const _FuelPriceSuggestion({
    required this.departement,
    required this.onApply,
  });

  final String departement;
  final ValueChanged<double> onApply;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final asyncResult = ref.watch(fuelPriceAverageProvider(departement));
    final result = asyncResult.asData?.value;
    if (result == null) {
      return const SizedBox.shrink();
    }
    final priceFr = result.averageEurPerLiter.toStringAsFixed(3);
    final freshness = _formatFreshness(result.lastUpdate);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.lime.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.r10),
        border: Border.all(color: AppColors.lime),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_gas_station_outlined,
              size: 16, color: AppColors.emerald),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prix moyen Diesel dep. $departement : $priceFr EUR/L',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: p.ink,
                  ),
                ),
                Text(
                  'Source data.gouv.fr · ${result.sampleSize} stations · $freshness',
                  style: TextStyle(fontSize: 10.5, color: p.textMute),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Rafraichir le prix',
            onPressed: () {
              ref.invalidate(fuelPriceAverageProvider(departement));
            },
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          TextButton(
            onPressed: () => onApply(result.averageEurPerLiter),
            child: const Text('Utiliser'),
          ),
        ],
      ),
    );
  }

  static String _formatFreshness(DateTime updated) {
    final diff = DateTime.now().difference(updated);
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes.clamp(1, 59);
      return 'maj il y a $m min';
    }
    if (diff.inHours < 24) {
      return 'maj il y a ${diff.inHours} h';
    }
    if (diff.inDays < 7) {
      return 'maj il y a ${diff.inDays} j';
    }
    return 'maj il y a > 1 sem';
  }
}
