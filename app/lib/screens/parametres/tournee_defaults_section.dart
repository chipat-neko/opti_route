import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import 'parametres_widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Tournee par defaut" — capacite, duree d'arret, app nav.
/// ════════════════════════════════════════════════════════════════
///
/// Trois reglages preremplis a la creation d'une nouvelle tournee :
///   - Capacite vehicule (nb colis max, 0 = illimite)
///   - Duree d'arret en minutes (3 par defaut)
///   - App de navigation pousee dans le bottom sheet (Maps / Waze /
///     demander a chaque fois)
class TourneeDefaultsSection extends ConsumerStatefulWidget {
  const TourneeDefaultsSection({super.key});

  @override
  ConsumerState<TourneeDefaultsSection> createState() =>
      _TourneeDefaultsSectionState();
}

class _TourneeDefaultsSectionState
    extends ConsumerState<TourneeDefaultsSection> {
  final _capaciteCtrl = TextEditingController();
  final _dureeArretCtrl = TextEditingController();
  bool _initialized = false;
  bool _saving = false;
  String? _navAppDefault;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = ref.read(parametresRepositoryProvider);
    final cap = await repo.getCapaciteDefault();
    final duree = await repo.getDureeArretDefault();
    final nav = await repo.getNavAppDefault();
    if (!mounted) return;
    setState(() {
      _capaciteCtrl.text = cap?.toString() ?? '';
      _dureeArretCtrl.text = duree?.toString() ?? '';
      _navAppDefault = nav;
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _capaciteCtrl.dispose();
    _dureeArretCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(parametresRepositoryProvider);
      final cap = int.tryParse(_capaciteCtrl.text.trim());
      final duree = int.tryParse(_dureeArretCtrl.text.trim());

      if (cap != null && cap >= 0) {
        await repo.setCapaciteDefault(cap);
      } else if (_capaciteCtrl.text.trim().isEmpty) {
        await repo.clearCapaciteDefault();
      }

      if (duree != null && duree >= 0) {
        await repo.setDureeArretDefault(duree);
      } else if (_dureeArretCtrl.text.trim().isEmpty) {
        await repo.clearDureeArretDefault();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valeurs par defaut enregistrees')),
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

  Future<void> _setNavApp(String? value) async {
    setState(() => _navAppDefault = value);
    final repo = ref.read(parametresRepositoryProvider);
    if (value == null) {
      await repo.clearNavAppDefault();
    } else {
      await repo.setNavAppDefault(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Tournee par defaut'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Valeurs preremplies a la creation d\'une nouvelle tournee '
          'ou d\'un nouvel arret. Tu peux les modifier au cas par cas.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x14),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _capaciteCtrl,
                decoration: const InputDecoration(
                  labelText: 'Capacite vehicule',
                  helperText: 'Nb de colis max (0 = illimite)',
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                enabled: _initialized,
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: TextField(
                controller: _dureeArretCtrl,
                decoration: const InputDecoration(
                  labelText: 'Duree d\'arret',
                  helperText: 'Minutes / arret (3 par defaut)',
                  helperMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                enabled: _initialized,
                onSubmitted: (_) => _save(),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x14),
        Text(
          'App de navigation par defaut',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          'Quand tu tapes sur un arret en mode tournee, l\'app de nav '
          'choisie sera mise en avant dans le bottom sheet.',
          style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x10),
        Wrap(
          spacing: AppSpacing.x8,
          children: [
            NavAppChip(
              label: 'Aucune (demander)',
              value: null,
              groupValue: _navAppDefault,
              onSelected: _setNavApp,
            ),
            NavAppChip(
              label: 'Google Maps',
              value: 'maps',
              groupValue: _navAppDefault,
              onSelected: _setNavApp,
            ),
            NavAppChip(
              label: 'Waze',
              value: 'waze',
              groupValue: _navAppDefault,
              onSelected: _setNavApp,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.x14),
        FilledButton.icon(
          onPressed: _saving || !_initialized ? null : _save,
          icon: const Icon(Icons.check),
          label: const Text('Enregistrer les valeurs par defaut'),
        ),
      ],
    );
  }
}
