import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets specialises de [TourneeFormScreen].
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `tournee_form_screen.dart` (660 lignes initiales) :
/// - [RappelPickerTile]      : tile date+time pour programmer un rappel
/// - [DangerButton]          : bouton outline rouge (delete tournee)
/// - [DefaultCoequipierTile] : tile + bottom sheet pour affectation
///                             par defaut d'un coequipier

/// Tile compact "Programmer un rappel" : tap = picker date puis time,
/// quand une valeur est posee affiche "EEE d MMM a HH:mm" + bouton X
/// pour effacer.
class RappelPickerTile extends StatelessWidget {
  const RappelPickerTile({
    super.key,
    required this.value,
    required this.defaultDate,
    required this.onChanged,
  });

  final DateTime? value;

  /// Date de la tournee : sert de valeur par defaut pour le selecteur
  /// si l'utilisateur n'a pas encore choisi de date de rappel.
  final DateTime defaultDate;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final v = value;
    return Material(
      color: p.creamSoft,
      borderRadius: BorderRadius.circular(AppRadius.r12),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: () => _pick(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x14,
            vertical: AppSpacing.x12,
          ),
          child: Row(
            children: [
              Icon(Icons.alarm_outlined, color: p.ink),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Text(
                  v == null
                      ? 'Programmer un rappel'
                      : _formatDateTime(v),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                ),
              ),
              if (v != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Effacer le rappel',
                  color: p.textMute,
                  onPressed: () => onChanged(null),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: value ?? defaultDate,
      firstDate: now.subtract(const Duration(minutes: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (pickedDate == null || !context.mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: value != null
          ? TimeOfDay(hour: value!.hour, minute: value!.minute)
          : const TimeOfDay(hour: 7, minute: 0),
    );
    if (pickedTime == null) return;
    onChanged(DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    ));
  }

  static String _formatDateTime(DateTime dt) {
    final date = DateFormat('EEE d MMM', 'fr').format(dt);
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$date a $hh:$mm';
  }
}

/// Bouton outline rouge utilise pour les actions destructrices (delete
/// tournee). Largeur 100% + min height 52 pour respecter le pattern
/// "danger" du design system.
class DangerButton extends StatelessWidget {
  const DangerButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: const BorderSide(color: AppColors.red, width: 1.5),
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.r14)),
          ),
        ),
        icon: const Icon(Icons.delete_outline),
        label: Text(label),
      ),
    );
  }
}

/// Tile "Affecter par defaut a" : ouvre un picker de coequipier qui
/// pre-remplira `coequipierId` pour tous les NOUVEAUX stops crees dans
/// cette tournee. Modifiable apres coup au cas par cas dans la bottom
/// sheet d'un stop. Null = Moi.
class DefaultCoequipierTile extends StatelessWidget {
  const DefaultCoequipierTile({
    super.key,
    required this.coequipiers,
    required this.value,
    required this.onChanged,
  });

  final List<Coequipier> coequipiers;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = value == null
        ? null
        : coequipiers.where((c) => c.id == value).firstOrNull;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.assignment_ind_outlined),
      title: const Text('Affecter par defaut a'),
      subtitle: Text(
        selected == null
            ? 'Moi (defaut)'
            : 'Tous les nouveaux arrets : ${selected.nom}',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: value == null
          ? const Icon(Icons.add)
          : IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () => onChanged(null),
              tooltip: 'Retirer l\'affectation par defaut',
            ),
      onTap: () async {
        final picked = await showModalBottomSheet<int?>(
          context: context,
          backgroundColor: p.cream,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.r22),
            ),
          ),
          builder: (_) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x18,
                vertical: AppSpacing.x14,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Affecter par defaut a',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.x12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.lime,
                      child: Icon(Icons.person, color: AppColors.ink),
                    ),
                    title: const Text('Moi (defaut)'),
                    trailing: value == null
                        ? const Icon(Icons.check, color: AppColors.emerald)
                        : null,
                    onTap: () => Navigator.of(context).pop(null),
                  ),
                  const Divider(),
                  for (final c in coequipiers)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: colorFromTag(
                          c.colorTag,
                          defaultColor: AppColors.creamSoft,
                        ),
                        child: Text(
                          _initialsFor(c.nom),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                      title: Text(c.nom),
                      trailing: c.id == value
                          ? const Icon(Icons.check, color: AppColors.emerald)
                          : null,
                      onTap: () => Navigator.of(context).pop(c.id),
                    ),
                ],
              ),
            ),
          ),
        );
        // Modal ferme avec selection : on accepte aussi `null` (= Moi).
        // Modal ferme sans choix (back) : retourne null aussi mais on
        // ne distingue pas. C'est OK car la valeur null = etat par defaut.
        if (picked != value) onChanged(picked);
      },
    );
  }

  static String _initialsFor(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
