import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/navigation_service.dart';
import '../providers/database_providers.dart';
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
class StopActionSheet extends ConsumerStatefulWidget {
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
  ConsumerState<StopActionSheet> createState() => _StopActionSheetState();
}

class _StopActionSheetState extends ConsumerState<StopActionSheet> {
  /// Quand non null, on affiche l'etape "raison d'echec".
  bool _pickingRaison = false;
  String? _navAppDefault;

  /// Etat local du nb de colis (le widget est ferme/reouvert, on a
  /// une copie locale pour repondre instantanement aux taps - / +
  /// avant que le stream Drift ne rafraichisse).
  late int _nbColis;

  @override
  void initState() {
    super.initState();
    _nbColis = widget.stop.nbColis;
    _loadNavDefault();
  }

  Future<void> _adjustNbColis(int delta) async {
    final next = (_nbColis + delta).clamp(1, 999);
    if (next == _nbColis) return;
    setState(() => _nbColis = next);
    await ref.read(stopsRepositoryProvider).update(
          widget.stop.id,
          StopsCompanion(nbColis: Value(next)),
        );
  }

  Future<void> _loadNavDefault() async {
    final v =
        await ref.read(parametresRepositoryProvider).getNavAppDefault();
    if (!mounted) return;
    setState(() => _navAppDefault = v);
  }

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
            const SizedBox(height: AppSpacing.x14),

            // Edition rapide du nb de colis (+/-) : utile a la livraison
            // quand on decouvre 1 colis en plus/moins que prevu sans
            // avoir a ouvrir l'ecran d'edition complet.
            if (!_pickingRaison)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x12,
                  vertical: AppSpacing.x8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.creamSoft,
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.inventory_2_outlined,
                        size: 18, color: AppColors.ink),
                    const SizedBox(width: AppSpacing.x8),
                    const Text(
                      'Colis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const Spacer(),
                    _StepperButton(
                      icon: Icons.remove,
                      onPressed: _nbColis > 1
                          ? () => _adjustNbColis(-1)
                          : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.x14,
                      ),
                      child: Text(
                        '$_nbColis',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.ink,
                        ),
                      ),
                    ),
                    _StepperButton(
                      icon: Icons.add,
                      onPressed: () => _adjustNbColis(1),
                    ),
                  ],
                ),
              ),
            if (!_pickingRaison) const SizedBox(height: AppSpacing.x14),

            if (!_pickingRaison && stop.lat != null && stop.lng != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _NavButton(
                      label: 'Maps',
                      icon: Icons.map_outlined,
                      preferred: _navAppDefault == 'maps',
                      onPressed: () => NavigationService.launchGoogleMaps(
                        lat: stop.lat!,
                        lng: stop.lng!,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x10),
                  Expanded(
                    child: _NavButton(
                      label: 'Waze',
                      icon: Icons.navigation_outlined,
                      preferred: _navAppDefault == 'waze',
                      onPressed: () => NavigationService.launchWaze(
                        lat: stop.lat!,
                        lng: stop.lng!,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x14),
            ],

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

/// Bouton circulaire - / + pour le compteur de colis. Disabled si
/// `onPressed == null` (typiquement quand on est a 1 et qu'on veut
/// pas descendre en dessous).
class _StepperButton extends StatelessWidget {
  const _StepperButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: disabled ? AppColors.inkLine : AppColors.paper,
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
            color: disabled ? AppColors.textFaint : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Bouton 'Maps' / 'Waze' dans le bottom sheet. Quand `preferred` est
/// vrai (= cette app a ete choisie comme defaut dans Parametres), on
/// l'affiche en plein (FilledButton vert) pour la mettre en avant.
/// Sinon en outlined neutre.
class _NavButton extends StatelessWidget {
  const _NavButton({
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
    if (preferred) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.emerald,
          foregroundColor: AppColors.paper,
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
        foregroundColor: AppColors.ink,
        minimumSize: const Size(0, 48),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.w700)),
    );
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
