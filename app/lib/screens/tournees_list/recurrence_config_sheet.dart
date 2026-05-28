import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/recurrence_service.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// Ouvre la bottom sheet de configuration de la recurrence automatique
/// d'un template (carte #113). Charge la recurrence existante puis
/// affiche le formulaire. No-op si l'utilisateur ferme sans valider.
Future<void> showRecurrenceConfigSheet({
  required BuildContext context,
  required WidgetRef ref,
  required int templateId,
  required String templateNom,
}) async {
  final existing =
      await ref.read(recurrencesRepositoryProvider).getByTemplate(templateId);
  if (!context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.palette.cream,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.r22)),
    ),
    builder: (_) => _RecurrenceConfigBody(
      templateId: templateId,
      templateNom: templateNom,
      existing: existing,
    ),
  );
}

class _RecurrenceConfigBody extends ConsumerStatefulWidget {
  const _RecurrenceConfigBody({
    required this.templateId,
    required this.templateNom,
    required this.existing,
  });

  final int templateId;
  final String templateNom;
  final TourneeRecurrence? existing;

  @override
  ConsumerState<_RecurrenceConfigBody> createState() =>
      _RecurrenceConfigBodyState();
}

class _RecurrenceConfigBodyState extends ConsumerState<_RecurrenceConfigBody> {
  late bool _actif;
  late String _frequence;
  late int _jourSemaine; // 1..7
  late int _jourMois; // 1..28

  static const _joursSemaine = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final now = DateTime.now();
    _actif = e?.actif ?? true;
    _frequence = e?.frequence ?? RecurrenceFrequence.joursOuvres;
    _jourSemaine = e?.jourSemaine ?? now.weekday;
    _jourMois = (e?.jourMois ?? now.day).clamp(1, 28);
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(recurrencesRepositoryProvider).upsert(
          templateId: widget.templateId,
          frequence: _frequence,
          jourSemaine:
              _frequence == RecurrenceFrequence.hebdo ? _jourSemaine : null,
          jourMois:
              _frequence == RecurrenceFrequence.mensuel ? _jourMois : null,
          actif: _actif,
        );
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(_actif
            ? 'Recurrence activee : ${_resume()}'
            : 'Recurrence enregistree (desactivee)'),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _supprimer() async {
    final messenger = ScaffoldMessenger.of(context);
    await ref
        .read(recurrencesRepositoryProvider)
        .deleteForTemplate(widget.templateId);
    if (!mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Recurrence supprimee')),
    );
  }

  /// Phrase resumant la recurrence choisie (pour le SnackBar + l'apercu).
  String _resume() {
    switch (_frequence) {
      case RecurrenceFrequence.quotidien:
        return 'tous les jours';
      case RecurrenceFrequence.joursOuvres:
        return 'du lundi au vendredi';
      case RecurrenceFrequence.hebdo:
        return 'chaque ${_joursSemaine[_jourSemaine - 1].toLowerCase()}';
      case RecurrenceFrequence.mensuel:
        return 'le $_jourMois de chaque mois';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x18,
          AppSpacing.x14,
          AppSpacing.x18,
          AppSpacing.x18,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.x14),
                decoration: BoxDecoration(
                  color: p.inkLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Recurrence automatique',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: p.ink,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Genere "${widget.templateNom}" automatiquement a l\'ouverture '
              'de l\'app le jour prevu.',
              style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.3),
            ),
            const SizedBox(height: AppSpacing.x10),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _actif,
              title: const Text('Activer la recurrence'),
              onChanged: (v) => setState(() => _actif = v),
            ),
            if (_actif) ...[
              const SizedBox(height: AppSpacing.x4),
              _freqTile(RecurrenceFrequence.quotidien, 'Tous les jours'),
              _freqTile(RecurrenceFrequence.joursOuvres,
                  'Du lundi au vendredi'),
              _freqTile(RecurrenceFrequence.hebdo, 'Chaque semaine'),
              if (_frequence == RecurrenceFrequence.hebdo) _weekdayPicker(p),
              _freqTile(RecurrenceFrequence.mensuel, 'Chaque mois'),
              if (_frequence == RecurrenceFrequence.mensuel) _monthDayPicker(p),
            ],
            const SizedBox(height: AppSpacing.x14),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.lime,
                foregroundColor: AppColors.ink,
                minimumSize: const Size(0, 52),
              ),
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: const Text(
                'Enregistrer',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            if (widget.existing != null) ...[
              const SizedBox(height: AppSpacing.x8),
              TextButton.icon(
                onPressed: _supprimer,
                style: TextButton.styleFrom(foregroundColor: AppColors.red),
                icon: const Icon(Icons.delete_outline, size: 18),
                label: const Text('Supprimer la recurrence'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _freqTile(String value, String label) {
    final selected = _frequence == value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: Icon(
        selected
            ? Icons.radio_button_checked
            : Icons.radio_button_unchecked,
        color: selected ? AppColors.emerald : null,
      ),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      onTap: () => setState(() => _frequence = value),
    );
  }

  Widget _weekdayPicker(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.x12,
        bottom: AppSpacing.x8,
      ),
      child: Wrap(
        spacing: AppSpacing.x6,
        children: [
          for (var i = 1; i <= 7; i++)
            ChoiceChip(
              label: Text(_joursSemaine[i - 1]),
              selected: _jourSemaine == i,
              onSelected: (_) => setState(() => _jourSemaine = i),
            ),
        ],
      ),
    );
  }

  Widget _monthDayPicker(AppPalette p) {
    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.x12,
        bottom: AppSpacing.x8,
      ),
      child: Row(
        children: [
          Text('Le ', style: TextStyle(color: p.ink)),
          DropdownButton<int>(
            value: _jourMois,
            items: [
              for (var d = 1; d <= 28; d++)
                DropdownMenuItem(value: d, child: Text('$d')),
            ],
            onChanged: (v) => setState(() => _jourMois = v ?? _jourMois),
          ),
          Text(' de chaque mois', style: TextStyle(color: p.ink)),
        ],
      ),
    );
  }
}
