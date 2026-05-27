import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../providers/database_providers.dart';
import '../../providers/optimization_providers.dart';
import '../../theme/app_tokens.dart';
import 'parametres_widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Optimisation de tournee" — cle API OpenRouteService.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche un [StatusCard] (cle saisie ou pas + quota du jour),
/// un TextField masque (visibility toggle) pour entrer la cle, et
/// les boutons Enregistrer / Effacer. Tout passe par
/// `parametresRepositoryProvider` (cle `ors_api_key`).
class OrsSection extends ConsumerStatefulWidget {
  const OrsSection({super.key});

  @override
  ConsumerState<OrsSection> createState() => _OrsSectionState();
}

class _OrsSectionState extends ConsumerState<OrsSection> {
  final _ctrl = TextEditingController();
  bool _obscure = true;
  bool _saving = false;
  bool _initialized = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = _ctrl.text.trim();
    setState(() => _saving = true);
    try {
      final repo = ref.read(parametresRepositoryProvider);
      if (value.isEmpty) {
        await repo.clearOrsApiKey();
      } else {
        await repo.setOrsApiKey(value);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value.isEmpty
              ? 'Cle ORS effacee'
              : 'Cle ORS enregistree, optimisation activee'),
        ),
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

  Future<void> _clear() async {
    setState(() => _saving = true);
    try {
      await ref.read(parametresRepositoryProvider).clearOrsApiKey();
      _ctrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cle ORS effacee')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final orsKeyAsync = ref.watch(orsApiKeyProvider);

    orsKeyAsync.whenData((value) {
      if (!_initialized && value != null) {
        _ctrl.text = value;
        _initialized = true;
      }
    });

    final hasKey = orsKeyAsync.asData?.value?.isNotEmpty ?? false;
    final used = ref.watch(orsUsedTodayProvider).asData?.value ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Optimisation de tournee'),
        const SizedBox(height: AppSpacing.x10),
        StatusCard(
          highlight: hasKey,
          icon: hasKey ? Icons.check_circle : Icons.bolt_outlined,
          title: hasKey
              ? 'OpenRouteService est actif'
              : 'Optimisation desactivee',
          subtitle: hasKey
              ? 'Aujourd\'hui : $used / 500 optimisations utilisees.'
              : 'Saisis une cle ORS pour activer le bouton "Optimiser".',
        ),
        const SizedBox(height: AppSpacing.x18),
        Text(
          'Cle API OpenRouteService',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          'Cree gratuitement un compte sur openrouteservice.org/dev '
          '(500 optimisations/jour, sans carte de credit), puis colle '
          'ta cle ici. Sans cle, le bouton "Optimiser" reste desactive.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x12),
        TextField(
          controller: _ctrl,
          obscureText: _obscure,
          decoration: InputDecoration(
            labelText: 'Cle API ORS',
            hintText: 'Environ 40 caracteres',
            suffixIcon: IconButton(
              icon: Icon(
                _obscure ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          autocorrect: false,
          enableSuggestions: false,
        ),
        const SizedBox(height: AppSpacing.x18),
        FilledButton.icon(
          onPressed: _saving ? null : _save,
          icon: _saving
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.lime,
                  ),
                )
              : const Icon(Icons.check),
          label: const Text('Enregistrer la cle ORS'),
        ),
        if (hasKey) ...[
          const SizedBox(height: AppSpacing.x10),
          OutlinedButton.icon(
            onPressed: _saving ? null : _clear,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Effacer la cle ORS'),
          ),
        ],
      ],
    );
  }
}
