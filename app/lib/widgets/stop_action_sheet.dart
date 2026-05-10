import 'package:flutter/material.dart';

import '../data/database.dart';
import '../theme/app_tokens.dart';

/// Action choisie par le livreur dans la bottom sheet de validation
/// d'un arret.
sealed class StopAction {
  const StopAction();
}

class MarkLivreAction extends StopAction {
  const MarkLivreAction();
}

class MarkEchecAction extends StopAction {
  const MarkEchecAction(this.raison);
  /// 'absent' / 'refuse' / 'adresse_fausse' / 'autre'.
  final String raison;
}

class MarkAaLivrerAction extends StopAction {
  const MarkAaLivrerAction();
}

class OpenDetailsAction extends StopAction {
  const OpenDetailsAction();
}

/// Bottom sheet de validation d'un arret. Tap sur "Livre" -> retour
/// immediat avec [MarkLivreAction]. Tap sur "Echec" -> 2e etape pour
/// choisir la raison, puis retour avec [MarkEchecAction].
class StopActionSheet extends StatefulWidget {
  const StopActionSheet({super.key, required this.stop});

  final Stop stop;

  static Future<StopAction?> show(BuildContext context, Stop stop) {
    return showModalBottomSheet<StopAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (_) => StopActionSheet(stop: stop),
    );
  }

  @override
  State<StopActionSheet> createState() => _StopActionSheetState();
}

class _StopActionSheetState extends State<StopActionSheet> {
  /// Quand non null, on affiche l'etape "raison d'echec".
  bool _pickingRaison = false;

  @override
  Widget build(BuildContext context) {
    final stop = widget.stop;
    final nom = stop.nomClient?.trim() ?? '';
    final hasNom = nom.isNotEmpty;
    final adresse = stop.adresseNormalisee ?? stop.adresseBrute;
    final isLivre = stop.statutLivraison == 'livre';
    final isEchec = stop.statutLivraison == 'echec';
    final hasStatut = isLivre || isEchec;

    return SafeArea(
      child: Padding(
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
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: AppSpacing.x14),
                decoration: BoxDecoration(
                  color: AppColors.inkLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header : nom + adresse
            if (hasNom)
              Text(
                nom,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              adresse,
              style: TextStyle(
                fontSize: hasNom ? 13 : 16,
                color: hasNom ? AppColors.textMute : AppColors.ink,
                fontWeight: hasNom ? FontWeight.w500 : FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.x18),

            if (_pickingRaison)
              _RaisonEchecPicker(
                onPicked: (raison) =>
                    Navigator.of(context).pop(MarkEchecAction(raison)),
                onBack: () => setState(() => _pickingRaison = false),
              )
            else ...[
              if (hasStatut)
                _StatutBanner(
                  isLivre: isLivre,
                  raison: stop.raisonEchec,
                ),
              if (hasStatut) const SizedBox(height: AppSpacing.x14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.paper,
                  minimumSize: const Size(0, 56),
                ),
                onPressed: isLivre
                    ? null
                    : () => Navigator.of(context).pop(const MarkLivreAction()),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  isLivre ? 'Deja livre' : 'Marquer livre',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: const BorderSide(color: AppColors.red, width: 1.5),
                  minimumSize: const Size(0, 52),
                ),
                onPressed: () => setState(() => _pickingRaison = true),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text(
                  'Marquer echec',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              if (hasStatut) ...[
                const SizedBox(height: AppSpacing.x10),
                TextButton.icon(
                  onPressed: () =>
                      Navigator.of(context).pop(const MarkAaLivrerAction()),
                  icon: const Icon(Icons.undo, size: 18),
                  label: const Text('Annuler le statut'),
                ),
              ],
              const Divider(height: AppSpacing.x28),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink,
                ),
                onPressed: () =>
                    Navigator.of(context).pop(const OpenDetailsAction()),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Voir / modifier les details'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatutBanner extends StatelessWidget {
  const _StatutBanner({required this.isLivre, this.raison});

  final bool isLivre;
  final String? raison;

  @override
  Widget build(BuildContext context) {
    final bg = isLivre
        ? AppColors.emeraldSoft
        : AppColors.red.withValues(alpha: 0.12);
    final fg = isLivre ? AppColors.emerald : AppColors.red;
    final libelle = isLivre ? 'Livre' : 'Echec : ${_humanRaison(raison)}';
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

  static String _humanRaison(String? r) {
    return switch (r) {
      'absent' => 'absent',
      'refuse' => 'refuse',
      'adresse_fausse' => 'adresse fausse',
      'autre' => 'autre',
      _ => 'sans raison',
    };
  }
}

class _RaisonEchecPicker extends StatelessWidget {
  const _RaisonEchecPicker({required this.onPicked, required this.onBack});

  final ValueChanged<String> onPicked;
  final VoidCallback onBack;

  static const _options = [
    ('absent', 'Absent', Icons.person_off_outlined),
    ('refuse', 'Refuse le colis', Icons.front_hand_outlined),
    ('adresse_fausse', 'Adresse fausse', Icons.wrong_location_outlined),
    ('autre', 'Autre', Icons.more_horiz),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Raison de l\'echec',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
        const SizedBox(height: AppSpacing.x10),
        for (final (id, label, icon) in _options) ...[
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ink,
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
