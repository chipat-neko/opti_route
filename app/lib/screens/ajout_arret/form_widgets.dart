import 'package:flutter/material.dart';

import '../../data/stop_types.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets reutilises dans [AjoutArretScreen].
/// ════════════════════════════════════════════════════════════════
///
/// Regroupe 4 widgets statiques extraits de `ajout_arret_screen.dart`
/// (952 lignes initiales) pour alleger l'ecran principal :
/// - [OfflineAddressBanner] : encart "GPS manquant" mode hors-ligne
/// - [SectionTitle]          : titre de section gris discret
/// - [PriorityChips]         : 4 chips de priorite (premier/flexible/...)
/// - [TimePickerField]       : champ horaire avec long-press = effacer
///
/// Tous sont stateless purs, pas d'etat ni de provider.

/// Toggle large "Livraison / Ramasse" affiche en haut du form d'ajout
/// d'arret. Bien visible pour eviter de saisir un arret en livraison
/// par defaut alors qu'il faut le ramasse (ou inverse).
///
/// Visuel : 2 segments cote a cote. Le segment selectionne prend une
/// couleur d'accent (lime pour livraison = cohesion app, orange pour
/// ramasse = action distincte). Icones differentes (download / upload)
/// pour reinforcer visuellement.
class StopTypeToggle extends StatelessWidget {
  const StopTypeToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Expanded(
          child: _Segment(
            label: 'Livraison',
            icon: Icons.local_shipping_outlined,
            selected: value == kStopTypeLivraison,
            accent: AppColors.lime,
            onTap: () => onChanged(kStopTypeLivraison),
            palette: p,
          ),
        ),
        const SizedBox(width: AppSpacing.x10),
        Expanded(
          child: _Segment(
            label: 'Ramasse',
            icon: Icons.move_to_inbox_outlined,
            selected: value == kStopTypeRamasse,
            accent: AppColors.amber,
            onTap: () => onChanged(kStopTypeRamasse),
            palette: p,
          ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.accent,
    required this.onTap,
    required this.palette,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x14,
          vertical: AppSpacing.x12,
        ),
        decoration: BoxDecoration(
          color: selected ? accent : palette.paper,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(
            color: selected ? accent : palette.inkLine,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: palette.ink,
            ),
            const SizedBox(width: AppSpacing.x8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: palette.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Encart jaune affiche au-dessus du champ adresse quand l'utilisateur
/// a saisi une adresse en mode hors-ligne (sans geocodage). Permet de
/// signaler que l'arret sera flagge "GPS manquant" + bouton croix pour
/// effacer la saisie.
class OfflineAddressBanner extends StatelessWidget {
  const OfflineAddressBanner({
    super.key,
    required this.text,
    required this.onClear,
  });

  final String text;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x12,
        AppSpacing.x10,
        AppSpacing.x6,
        AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppRadius.r10),
        border: Border.all(color: AppColors.amber, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.signal_cellular_off_outlined,
            size: 18,
            color: AppColors.ink,
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              'Hors ligne · GPS manquant\n$text',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.ink,
                height: 1.3,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.ink,
            onPressed: onClear,
            tooltip: 'Effacer la saisie hors ligne',
          ),
        ],
      ),
    );
  }
}

/// Titre de section en majuscules grises (fontSize 11, letterSpacing 0.6).
/// Sert de header pour chaque bloc thematique du formulaire d'ajout
/// d'arret (Adresse, Priorite, Fenetre horaire, etc.).
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.label, {super.key});
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: p.textMute,
      ),
    );
  }
}

/// 4 chips de priorite d'arret. Codees comme valeurs Drift, lisibles
/// par l'optimisateur VROOM cote backend :
///   - obligatoire_premier  : 1er stop de la tournee
///   - flexible             : pas de contrainte (defaut)
///   - obligatoire_dernier  : dernier stop
///   - eviter_si_possible   : penalise mais pas exclus
class PriorityChips extends StatelessWidget {
  const PriorityChips({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const _options = [
    ('obligatoire_premier', 'En premier', AppColors.lime),
    ('flexible', 'Flexible', AppColors.creamSoft),
    ('obligatoire_dernier', 'En dernier', AppColors.lime),
    ('eviter_si_possible', 'Eviter', AppColors.amber),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: AppSpacing.x8,
      runSpacing: AppSpacing.x8,
      children: [
        for (final (id, label, accent) in _options)
          ChoiceChip(
            label: Text(label),
            selected: value == id,
            onSelected: (sel) {
              if (sel) onChanged(id);
            },
            selectedColor: accent,
            backgroundColor: p.paper,
            side: BorderSide(
              color: value == id ? accent : p.inkLine,
            ),
            labelStyle: TextStyle(
              color: p.ink,
              fontWeight: value == id ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
      ],
    );
  }
}

/// Champ horaire pour la fenetre debut/fin. Tap = ouvrir TimePicker,
/// long-press = effacer (passer a null = pas de contrainte).
class TimePickerField extends StatelessWidget {
  const TimePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final display = value == null
        ? ' - '
        : '${value!.hour.toString().padLeft(2, '0')}:${value!.minute.toString().padLeft(2, '0')}';
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r14),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: value ?? const TimeOfDay(hour: 9, minute: 0),
        );
        if (picked != null) onChanged(picked);
      },
      onLongPress: value == null ? null : () => onChanged(null),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x14,
          vertical: AppSpacing.x12,
        ),
        decoration: BoxDecoration(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          border: Border.all(color: p.inkLine),
        ),
        child: Row(
          children: [
            Icon(Icons.access_time, size: 18, color: p.ink),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textMute,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    display,
                    style: appMonoStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
