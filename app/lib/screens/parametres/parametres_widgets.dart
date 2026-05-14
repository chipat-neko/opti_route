import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets reutilises dans l'ecran Parametres.
/// ════════════════════════════════════════════════════════════════
///
/// Regroupe les helpers UI : titres de section, chips de selection
/// (theme, palette, app de navigation), cards de statut. Tous sont
/// utilises par `ParametresScreen` (voir lib/screens/parametres_screen.dart).

/// Titre de section en majuscule discret (police 11, letter-spacing 0.6).
/// Sert de header pour chaque bloc de l'ecran Parametres (Geocodage,
/// Optimisation, Tournee par defaut, Carburant, etc.).
class ParametresSectionTitle extends StatelessWidget {
  const ParametresSectionTitle(this.label, {super.key});
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

/// Chip de selection du mode de theme (clair / sombre / systeme).
/// Persiste via `parametresRepositoryProvider.setThemeMode`.
class ThemeChip extends ConsumerWidget {
  const ThemeChip({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
  });

  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final selected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        final repo = ref.read(parametresRepositoryProvider);
        await repo.setThemeMode(switch (value) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        });
      },
      selectedColor: AppColors.lime,
      backgroundColor: p.paper,
      side: BorderSide(
        color: selected ? AppColors.lime : p.inkLine,
      ),
      labelStyle: TextStyle(
        color: p.ink,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

/// Tile de selection d'un preset de palette (lime / ocean / terracotta /
/// mono). Affiche le swatch light + dark, le nom et la description,
/// avec un check icon si selectionne. Persiste via
/// `parametresRepositoryProvider.setThemePreset`.
class PaletteTile extends ConsumerWidget {
  const PaletteTile({
    super.key,
    required this.preset,
    required this.selected,
  });

  final AppThemePreset preset;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: () async {
          await ref
              .read(parametresRepositoryProvider)
              .setThemePreset(preset.name);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12,
            vertical: AppSpacing.x10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? preset.previewColor.withValues(alpha: 0.10)
                : p.paper,
            borderRadius: BorderRadius.circular(AppRadius.r12),
            border: Border.all(
              color: selected ? preset.previewColor : p.inkLine,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Mini swatch double (light + dark) pour previewer
              _SwatchPreview(preset: preset),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      preset.description,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textMute,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle,
                    color: preset.previewColor, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

/// Mini preview d'une palette : deux carres superposes (light en
/// haut-gauche, dark en bas-droite) qui montrent les couleurs cream
/// et ink des 2 modes du preset.
class _SwatchPreview extends StatelessWidget {
  const _SwatchPreview({required this.preset});

  final AppThemePreset preset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: _swatch(preset.light.cream, preset.light.ink),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: _swatch(preset.dark.cream, preset.dark.ink),
          ),
        ],
      ),
    );
  }

  Widget _swatch(Color bg, Color border) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border.withValues(alpha: 0.4), width: 1),
      ),
    );
  }
}

/// Chip de selection de l'app de navigation par defaut (Maps / Waze /
/// systeme). Sert dans la section "Tournee par defaut" pour eviter
/// la question a chaque bottom sheet d'arret.
class NavAppChip extends StatelessWidget {
  const NavAppChip({
    super.key,
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final String? value;
  final String? groupValue;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final selected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.lime,
      backgroundColor: p.paper,
      side: BorderSide(
        color: selected ? AppColors.lime : p.inkLine,
      ),
      labelStyle: TextStyle(
        color: p.ink,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

/// Carte de statut affichee en haut des sections "Geocodage" et
/// "Optimisation de tournee" : indique si la cle ORS est saisie,
/// le quota restant, etc. `highlight: true` -> fond lime (cas OK
/// remarquable), sinon fond cream discret.
class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.highlight,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool highlight;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Quand highlight=true, fond lime fixe -> texte ink fixe (signal
    // accent qui doit rester lisible dans les 2 modes light/dark).
    final fg = highlight ? AppColors.ink : p.ink;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.lime : p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: appMonoStyle(
                    fontSize: 11,
                    color: fg.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
