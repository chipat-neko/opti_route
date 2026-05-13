import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database.dart';
import '../data/navigation_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import 'stop_action_sheet_widgets.dart';

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

/// Capture une photo preuve avant ou apres validation (depend du
/// statut courant du stop). Le caller appelle PreuvePhotoService.capturer
/// et setPreuvePhoto sur le repo.
class TakePreuvePhotoAction extends StopAction {
  const TakePreuvePhotoAction();
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
      backgroundColor: context.palette.cream,
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

  /// Champ notes en edition locale ; persiste sur perte de focus ou
  /// fermeture de la bottom sheet.
  late TextEditingController _notesCtrl;
  Timer? _notesDebounce;
  String _initialNotes = '';

  @override
  void initState() {
    super.initState();
    _nbColis = widget.stop.nbColis;
    _initialNotes = widget.stop.notes ?? '';
    _notesCtrl = TextEditingController(text: _initialNotes);
    _loadNavDefault();
  }

  @override
  void dispose() {
    _notesDebounce?.cancel();
    // Save final si modifs en attente.
    if (_notesCtrl.text != _initialNotes) {
      _persistNotes(_notesCtrl.text);
    }
    _notesCtrl.dispose();
    super.dispose();
  }

  void _onNotesChanged(String value) {
    _notesDebounce?.cancel();
    _notesDebounce = Timer(const Duration(milliseconds: 600), () {
      _persistNotes(value);
    });
  }

  Future<void> _persistNotes(String value) async {
    final trimmed = value.trim();
    final v = trimmed.isEmpty ? null : trimmed;
    await ref.read(stopsRepositoryProvider).update(
          widget.stop.id,
          StopsCompanion(notes: Value(v)),
        );
    _initialNotes = value;
  }

  /// Sauvegarde la fenetre horaire (debut/fin au format "HH:mm",
  /// null pour effacer). Appele depuis les 2 TimePicker inline.
  Future<void> _persistFenetre({String? debut, String? fin}) async {
    await ref.read(stopsRepositoryProvider).update(
          widget.stop.id,
          StopsCompanion(
            fenetreDebut: Value(debut),
            fenetreFin: Value(fin),
          ),
        );
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

  /// Sub-dialog pour choisir un coequipier dans la liste des actifs.
  /// "Personne" reset l'affectation (coequipierId -> null).
  Future<void> _pickCoequipier(
    BuildContext context,
    WidgetRef ref,
    List<Coequipier> coequipiers,
  ) async {
    final p = context.palette;
    final currentId = widget.stop.coequipierId;
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
                'Affecter a',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(
                  backgroundColor: AppColors.lime,
                  child: Icon(Icons.person, color: AppColors.ink),
                ),
                title: const Text('Moi (par defaut)'),
                trailing: currentId == null
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
                  trailing: c.id == currentId
                      ? const Icon(Icons.check, color: AppColors.emerald)
                      : null,
                  onTap: () => Navigator.of(context).pop(c.id),
                ),
            ],
          ),
        ),
      ),
    );
    // Modal ferme sans selection (back / tap exterieur) : on ne touche
    // pas a l'affectation. Modal ferme avec selection (meme `null` =
    // "Moi") : on update.
    if (!context.mounted) return;
    if (picked == widget.stop.coequipierId) return;
    await ref
        .read(stopsRepositoryProvider)
        .setCoequipier(widget.stop.id, picked);
  }

  static String _initialsFor(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
                  color: p.inkLine,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Header : nom + adresse
            if (hasNom)
              Text(
                nom,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: AppSpacing.x4),
            Text(
              adresse,
              style: TextStyle(
                fontSize: hasNom ? 13 : 16,
                color: hasNom ? p.textMute : p.ink,
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
                  color: p.creamSoft,
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 18, color: p.ink),
                    const SizedBox(width: AppSpacing.x8),
                    Text(
                      'Colis',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                    ),
                    const Spacer(),
                    StepperButton(
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
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: p.ink,
                        ),
                      ),
                    ),
                    StepperButton(
                      icon: Icons.add,
                      onPressed: () => _adjustNbColis(1),
                    ),
                  ],
                ),
              ),
            if (!_pickingRaison) const SizedBox(height: AppSpacing.x10),

            // Edition rapide des notes : utile pour ajouter "code 1234B"
            // ou "porte garage cote droit" sans ouvrir l'ecran complet.
            // Auto-sauvegarde en debounce 600ms apres la derniere frappe
            // + flush sur dispose si edits en attente.
            if (!_pickingRaison)
              TextField(
                controller: _notesCtrl,
                onChanged: _onNotesChanged,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Code · porte · etage...',
                  isDense: true,
                ),
              ),
            if (!_pickingRaison) const SizedBox(height: AppSpacing.x10),

            // Edition rapide de la fenetre horaire : utile quand un
            // client appelle pour decaler son creneau. Tap = ouvre un
            // TimePicker, sauvegarde direct.
            if (!_pickingRaison)
              Row(
                children: [
                  Expanded(
                    child: FenetreInlineField(
                      label: 'Pas avant',
                      value: stop.fenetreDebut,
                      onChanged: (t) =>
                          _persistFenetre(debut: t, fin: stop.fenetreFin),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x10),
                  Expanded(
                    child: FenetreInlineField(
                      label: 'Avant',
                      value: stop.fenetreFin,
                      onChanged: (t) => _persistFenetre(
                          debut: stop.fenetreDebut, fin: t),
                    ),
                  ),
                ],
              ),
            if (!_pickingRaison) const SizedBox(height: AppSpacing.x14),

            if (!_pickingRaison && stop.lat != null && stop.lng != null) ...[
              Row(
                children: [
                  Expanded(
                    child: NavButton(
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
                    child: NavButton(
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
              RaisonEchecPicker(
                onPicked: (raison) =>
                    Navigator.of(context).pop(MarkEchecAction(raison)),
                onBack: () => setState(() => _pickingRaison = false),
              )
            else ...[
              if (hasStatut)
                StatutBanner(
                  isLivre: isLivre,
                  raison: stop.raisonEchec,
                ),
              if (hasStatut) const SizedBox(height: AppSpacing.x14),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: p.paper,
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
              // Affectation a un coequipier (cache si aucun coequipier
              // actif en base : evite de polluer l'UI quand Noah bosse seul).
              Consumer(
                builder: (context, ref, _) {
                  final coequipiers = ref
                          .watch(coequipiersActifsProvider)
                          .asData
                          ?.value ??
                      const [];
                  if (coequipiers.isEmpty) return const SizedBox.shrink();
                  final currentId = widget.stop.coequipierId;
                  final current = currentId == null
                      ? null
                      : coequipiers
                          .where((c) => c.id == currentId)
                          .firstOrNull;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: p.ink,
                          alignment: Alignment.centerLeft,
                        ),
                        onPressed: () =>
                            _pickCoequipier(context, ref, coequipiers),
                        icon: const Icon(Icons.groups_outlined, size: 18),
                        label: Text(
                          current == null
                              ? 'Affecter a un coequipier'
                              : 'Affecte : ${current.nom}',
                        ),
                      ),
                    ],
                  );
                },
              ),
              // Photo preuve : accessible avant ou apres validation.
              // Si une photo existe deja, on l'indique discretement.
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: p.ink,
                ),
                onPressed: () => Navigator.of(context)
                    .pop(const TakePreuvePhotoAction()),
                icon: Icon(
                  widget.stop.preuvePhotoPath != null
                      ? Icons.photo_camera
                      : Icons.photo_camera_outlined,
                  size: 18,
                ),
                label: Text(
                  widget.stop.preuvePhotoPath != null
                      ? 'Refaire la photo preuve'
                      : 'Prendre une photo preuve',
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: p.ink,
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
