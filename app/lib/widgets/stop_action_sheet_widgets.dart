import 'package:flutter/material.dart';

import '../data/stop_types.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets internes de la `StopActionSheet`.
/// ════════════════════════════════════════════════════════════════
///
/// Regroupe les helpers UI utilises uniquement par la bottom sheet
/// d'actions d'un arret (Marquer livre / Marquer echec / Details /
/// Photo preuve). Extraits du fichier principal pour rendre
/// `stop_action_sheet.dart` plus court et focalise sur la logique
/// de state.

/// Bandeau de statut affiche en haut de la sheet quand le stop a
/// deja ete valide (livre ou echec). Vert emerald pour livre, rouge
/// pour echec avec la raison humanisee. Le verbe est adapte au [type]
/// du stop : "Livre" pour livraison, "Ramasse" pour ramasse.
class StatutBanner extends StatelessWidget {
  const StatutBanner({
    super.key,
    required this.isLivre,
    this.raison,
    this.type = kStopTypeLivraison,
  });

  final bool isLivre;

  /// Raison de l'echec (code interne : 'absent', 'refuse',
  /// 'adresse_fausse', 'autre'). Ignore si `isLivre == true`.
  final String? raison;

  /// Type du stop : adapte le libelle ('Livre' / 'Ramasse').
  final String type;

  @override
  Widget build(BuildContext context) {
    final bg = isLivre
        ? AppColors.emeraldSoft
        : AppColors.red.withValues(alpha: 0.12);
    final fg = isLivre ? AppColors.emerald : AppColors.red;
    final libelle = isLivre
        ? (type == kStopTypeRamasse ? 'Ramasse' : 'Livre')
        : (type == kStopTypeRamasse
            ? 'Pas ramasse : ${_humanRaison(raison)}'
            : 'Echec : ${_humanRaison(raison)}');
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x10,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        children: [
          Icon(
            isLivre ? Icons.check_circle : Icons.cancel,
            color: fg,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              libelle,
              style: TextStyle(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Traduction des codes raison vers du francais lisible. Inclut les
  /// raisons specifiques aux ramasses (pas_pret, introuvable).
  static String _humanRaison(String? r) {
    return switch (r) {
      'absent' => 'absent',
      'refuse' => 'refuse',
      'adresse_fausse' => 'adresse fausse',
      'pas_pret' => 'colis pas pret',
      'introuvable' => 'colis introuvable',
      'autre' => 'autre',
      _ => 'sans raison',
    };
  }
}

/// Bouton circulaire `-` / `+` pour le compteur de colis dans la sheet.
/// Disabled (gris) quand `onPressed == null`, typiquement quand on
/// est a 1 et qu'on ne peut plus decrementer.
class StepperButton extends StatelessWidget {
  const StepperButton({
    super.key,
    required this.icon,
    required this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final disabled = onPressed == null;
    return Material(
      color: disabled ? p.inkLine : p.paper,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Icon(
            icon,
            size: 18,
            color: disabled ? p.textFaint : p.ink,
          ),
        ),
      ),
    );
  }
}

/// Bouton 'Maps' / 'Waze' dans la sheet. Quand `preferred == true`
/// (cette app a ete choisie comme defaut dans Parametres), il
/// s'affiche en FilledButton emerald pour la mettre en avant.
/// Sinon en OutlinedButton neutre pour offrir l'alternative discrete.
class NavButton extends StatelessWidget {
  const NavButton({
    super.key,
    required this.label,
    required this.icon,
    required this.preferred,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool preferred;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (preferred) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: p.paper,
          minimumSize: const Size(0, 48),
        ),
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.ink,
        minimumSize: const Size(0, 48),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }
}

/// Picker compact d'une heure (format HH:mm) pour les fenetres
/// horaires de livraison ("pas avant" / "pas apres"). Persiste inline
/// via `onChanged`. Affiche le label en petit + la valeur en gros.
/// Long-press = effacer la valeur ; bouton X visible si une valeur
/// est definie.
class FenetreInlineField extends StatelessWidget {
  const FenetreInlineField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final filled = value != null && value!.isNotEmpty;
    return Material(
      color: p.creamSoft,
      borderRadius: BorderRadius.circular(AppRadius.r10),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r10),
        onTap: () => _pick(context),
        onLongPress: filled ? () => onChanged(null) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x10,
            vertical: AppSpacing.x8,
          ),
          child: Row(
            children: [
              Icon(Icons.access_time, size: 16, color: p.textMute),
              const SizedBox(width: AppSpacing.x6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: appMonoStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: p.textMute,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      filled ? value! : '--:--',
                      style: appMonoStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: filled ? p.ink : p.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              if (filled)
                GestureDetector(
                  onTap: () => onChanged(null),
                  child: Icon(Icons.close, size: 16, color: p.textMute),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Ouvre le TimePicker Material avec la valeur courante (ou 09:00
  /// par defaut) et propage le format "HH:mm" via `onChanged`.
  Future<void> _pick(BuildContext context) async {
    final init = _parseHHmm(value) ?? const TimeOfDay(hour: 9, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime: init,
    );
    if (picked == null) return;
    final hh = picked.hour.toString().padLeft(2, '0');
    final mm = picked.minute.toString().padLeft(2, '0');
    onChanged('$hh:$mm');
  }

  /// Parse "HH:mm" -> TimeOfDay. Retourne null si format invalide
  /// (sera traite comme "pas de valeur initiale" par le picker).
  static TimeOfDay? _parseHHmm(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}

/// Sous-ecran de la sheet qui propose les raisons d'echec possibles
/// (absent, refuse, etc.) sous forme de OutlinedButtons. Tap sur une
/// option -> propage le code via `onPicked`. Tap "Retour" -> revient
/// a la sheet principale.
///
/// Le set de raisons est adapte au [type] du stop :
/// - livraison : absent / refuse le colis / adresse fausse / autre
/// - ramasse   : pas pret / introuvable / refuse / absent / autre
class RaisonEchecPicker extends StatelessWidget {
  const RaisonEchecPicker({
    super.key,
    required this.onPicked,
    required this.onBack,
    this.type = kStopTypeLivraison,
  });

  /// Callback : recoit le code interne ('absent' / 'refuse' /
  /// 'adresse_fausse' / 'autre' / 'pas_pret' / 'introuvable').
  final ValueChanged<String> onPicked;
  final VoidCallback onBack;

  /// Type du stop -- determine quel set de raisons afficher.
  final String type;

  static const _optionsLivraison = [
    ('absent', 'Absent', Icons.person_off_outlined),
    ('refuse', 'Refuse le colis', Icons.front_hand_outlined),
    ('adresse_fausse', 'Adresse fausse', Icons.wrong_location_outlined),
    ('autre', 'Autre', Icons.more_horiz),
  ];

  static const _optionsRamasse = [
    ('pas_pret', 'Colis pas pret', Icons.hourglass_empty),
    ('introuvable', 'Colis introuvable', Icons.search_off_outlined),
    ('refuse', 'Refuse de donner', Icons.front_hand_outlined),
    ('absent', 'Absent', Icons.person_off_outlined),
    ('autre', 'Autre', Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final options = type == kStopTypeRamasse
        ? _optionsRamasse
        : _optionsLivraison;
    final title = type == kStopTypeRamasse
        ? 'Pourquoi pas de ramasse ?'
        : 'Raison de l\'echec';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: p.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        for (final (id, label, icon) in options) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: p.ink,
              minimumSize: const Size(0, 48),
              alignment: Alignment.centerLeft,
            ),
            onPressed: () => onPicked(id),
            icon: Icon(icon, size: 18),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: AppSpacing.x8),
        ],
        const SizedBox(height: AppSpacing.x6),
        TextButton.icon(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Retour'),
        ),
      ],
    );
  }
}
