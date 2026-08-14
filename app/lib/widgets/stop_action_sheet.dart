import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/cloud_error_humanizer.dart';
import '../data/database.dart';
import '../data/navigation_service.dart';
import '../data/stop_types.dart';
import '../providers/database_providers.dart';
import '../screens/navigation_screen.dart';
import '../theme/app_tokens.dart';
import 'stop_action_sheet_pickers.dart';
import 'stop_action_sheet_widgets.dart';
import 'stop_extras_panel.dart';

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

/// Visualise la photo preuve existante (full-screen, pinch-to-zoom).
/// Le caller push [PreuvePhotoViewerScreen] avec [Stop.preuvePhotoPath].
class ViewPreuvePhotoAction extends StopAction {
  const ViewPreuvePhotoAction();
}

/// Voir la signature du destinataire (le caller push
/// [PreuvePhotoViewerScreen] avec [Stop.signaturePath] -- un PNG image).
class ViewSignatureAction extends StopAction {
  const ViewSignatureAction();
}

/// Deplace l'arret vers une autre tournee. Le caller appelle
/// `StopsRepository.moveToTournee` + invalide les optims des 2
/// tournees + relance l'auto-reorder local.
class MoveToTourneeAction extends StopAction {
  const MoveToTourneeAction(this.targetTourneeId);

  /// Id de la tournee de destination (different de la tournee courante).
  final int targetTourneeId;
}

/// Bascule le type entre 'livraison' et 'ramasse'. Le caller appelle
/// `StopsRepository.setType(stopId, newType)`. Sert au "j'ai oublie
/// de cocher ramasse" ou "le client me demande aussi de recuperer un
/// retour" en cours de tournee.
class ConvertTypeAction extends StopAction {
  const ConvertTypeAction(this.newType);

  /// Nouveau type a appliquer ('livraison' ou 'ramasse').
  final String newType;
}

/// Copie l'adresse complete du stop dans le presse-papier (pour la
/// coller dans Google Maps, Waze, SMS au client, etc.). Le caller
/// appelle `Clipboard.setData` + affiche un SnackBar de confirmation.
class CopyAdresseAction extends StopAction {
  const CopyAdresseAction();
}

/// Ouvre Google Maps en mode preview (fiche du lieu) sur l'adresse du
/// stop. Different de `NavigationService.launchGoogleMaps()` qui demarre
/// une route GPS : ici on veut juste voir le batiment / les avis /
/// les heures d'ouverture avant d'y aller. Le caller appelle
/// `launchUrl(https://www.google.com/maps/search/?api=1&query=<adresse>)`.
class OpenInMapsAction extends StopAction {
  const OpenInMapsAction();
}

/// Ouvre Google Street View sur les coordonnees GPS du stop (vue rue
/// 360° de la facade). Necessite `stop.lat` et `stop.lng` non null
/// (le caller affiche un SnackBar "Adresse pas encore geocodee" si
/// null). URL :
/// `https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=<lat>,<lng>`.
class OpenStreetviewAction extends StopAction {
  const OpenStreetviewAction();
}

/// Ouvre le menu de partage natif Android (SMS, WhatsApp, Email, Maps,
/// Drive, etc.) pre-rempli avec l'adresse du stop. Complement de
/// [CopyAdresseAction] : un seul tap au lieu de copier+coller.
/// Le caller appelle `SharePlus.instance.share(ShareParams(text: adresse))`.
class ShareAdresseAction extends StopAction {
  const ShareAdresseAction();
}

/// Ouvre le scanner code-barre AVEC cet arret comme arret attendu :
/// "est-ce bien le colis de ce client ?". Le caller ouvre
/// `ScanColisScreen(expectedStop: stop)`, qui previent alors si le code
/// scanne appartient a un AUTRE arret de la tournee et propose de
/// basculer dessus. Sans arret attendu (scan libre depuis la tournee),
/// ce controle n'a pas lieu d'etre.
class ScanColisPourArretAction extends StopAction {
  const ScanColisPourArretAction();
}

/// Ouvre le dossier litige opposable de cet arret (carte #311) : texte
/// horodate + GPS de passage + reference de la photo preuve, scelle par
/// un hash SHA-256. Le caller push [DossierLitigeScreen] avec le stop.
///
/// N'a de sens que sur un arret au statut DEFINITIF (livre ou echec) :
/// un dossier de litige sur un arret pas encore traite ne prouve rien.
/// La feuille d'actions ne propose donc l'entree que dans ce cas.
class OpenDossierLitigeAction extends StopAction {
  const OpenDossierLitigeAction();
}

/// Verrouille / deverrouille l'arret a sa position courante (carte
/// #114). Le caller appelle `StopsRepository.setPositionLocked(stopId,
/// locked)`. Un arret verrouille n'est pas deplace par le tri rapide,
/// l'optim VROOM ni le drag&drop.
class ToggleLockPositionAction extends StopAction {
  const ToggleLockPositionAction(this.locked);

  /// Nouvel etat voulu : true = verrouiller, false = deverrouiller.
  final bool locked;
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

  /// Wrapper qui delegue a [showTargetTourneePicker] puis pop le sheet
  /// principal avec [MoveToTourneeAction]. Place ici plutot que dans
  /// le picker car ce dernier ne connait pas l'action sealed.
  Future<void> _onMoveTo(BuildContext context) async {
    final pickedId = await showTargetTourneePicker(
      context: context,
      ref: ref,
      stop: widget.stop,
    );
    if (pickedId == null) return;
    if (!context.mounted) return;
    Navigator.of(context).pop(MoveToTourneeAction(pickedId));
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
      // SingleChildScrollView : depuis qu'on a ajoute 'Convertir en
      // ramasse' (PR #156) la sheet depassait la hauteur disponible
      // sur certains devices (Xiaomi Noah : BOTTOM OVERFLOWED BY 32
      // PIXELS). On la rend scrollable pour eviter l'overflow et
      // garantir que tous les boutons sont accessibles meme en mode
      // paysage / petit ecran.
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
            // Header : nom + adresse + bouton "Appeler client" (lookup
            // tel: dans le carnet par nomClient, QW4 audit #337).
            if (hasNom)
              Row(
                children: [
                  Expanded(
                    child: Text(
                      nom,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: p.ink,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _CallClientButton(nomClient: nom, directPhone: stop.telephone),
                ],
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
            // Bandeau consignes client (preferencePersonnalisee +
            // photoObligatoire depuis le carnet, F5+F6 sprint immediat).
            if (hasNom) _ClientConsignesBanner(nomClient: nom),
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

            // Panel "Options livraison" : memoVocal, deposeSansContact,
            // COD montant+encaisse, notationEmoji (F1-F4 sprint immediat).
            if (!_pickingRaison) StopExtrasPanel(stop: stop),
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
              const SizedBox(height: AppSpacing.x10),
              // PoC GPS turn-by-turn integre (cf docs/plan-gps-integre.md).
              // Push le NavigationScreen plein ecran qui montre la
              // position GPS live + une ligne droite vers le stop.
              // Pas un vrai turn-by-turn (Etape 2 : ORS directions).
              // Si l'utilisateur tape "J'y suis" sur le FAB, le pop
              // remonte `true` -> on relance la bottom sheet StopAction
              // pour qu'il marque livre / echec sans repasser par la liste.
              SizedBox(
                width: double.infinity,
                child: NavButton(
                  label: 'Suivre dans l\'app',
                  icon: Icons.gps_fixed,
                  preferred: false,
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final arrived = await navigator.push<bool>(
                      MaterialPageRoute<bool>(
                        builder: (_) => NavigationScreen(stop: widget.stop),
                      ),
                    );
                    // Si l'utilisateur a tape "J'y suis", on ferme la
                    // bottom sheet courante avec OpenDetailsAction pour
                    // que le caller (StopRow._onTap) rouvre la sheet
                    // immediatement -- pratique pour valider livre
                    // direct apres etre arrive.
                    if (arrived == true && mounted) {
                      navigator.pop(const OpenDetailsAction());
                    }
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.x14),
            ],

            if (_pickingRaison)
              RaisonEchecPicker(
                type: stop.type,
                onPicked: (raison) =>
                    Navigator.of(context).pop(MarkEchecAction(raison)),
                onBack: () => setState(() => _pickingRaison = false),
              )
            else ...[
              if (hasStatut)
                StatutBanner(
                  isLivre: isLivre,
                  raison: stop.raisonEchec,
                  type: stop.type,
                ),
              if (hasStatut) const SizedBox(height: AppSpacing.x14),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.emerald,
                        foregroundColor: p.paper,
                        minimumSize: const Size(0, 56),
                      ),
                      onPressed: isLivre
                          ? null
                          : () => Navigator.of(context)
                              .pop(const MarkLivreAction()),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        isLivre
                            ? (stop.type == kStopTypeRamasse
                                ? 'Deja ramasse'
                                : 'Deja livre')
                            : (stop.type == kStopTypeRamasse
                                ? 'Marquer ramasse'
                                : 'Marquer livre'),
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x10),
                  // Bouton Photo a cote de "Marquer livre" (demande Noah) :
                  // prendre la photo preuve direct depuis la sheet, sans
                  // re-chercher l'arret dans la liste. Pop l'action -> le
                  // caller lance la camera (TakePreuvePhotoAction).
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lime,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(0, 56),
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
                    ),
                    onPressed: () => Navigator.of(context)
                        .pop(const TakePreuvePhotoAction()),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text(
                      'Photo',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
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
                label: Text(
                  stop.type == kStopTypeRamasse
                      ? 'Pas pu ramasser'
                      : 'Marquer echec',
                  style: const TextStyle(
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
                            showCoequipierPicker(
                              context: context,
                              ref: ref,
                              stop: widget.stop,
                              coequipiers: coequipiers,
                            ),
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
              // Si une photo existe deja : 2 boutons separes (Voir + Refaire)
              // pour que Noah ou un coequipier puisse visualiser sans
              // risquer d'effacer la photo en relancant la camera.
              if (widget.stop.preuvePhotoPath != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: p.ink),
                  onPressed: () => Navigator.of(context)
                      .pop(const ViewPreuvePhotoAction()),
                  icon: const Icon(Icons.image_outlined, size: 18),
                  label: const Text('Voir la photo preuve'),
                ),
              // Signature capturee au "livre" (#signature Noah) : bouton
              // pour la revoir (le viewer affiche n'importe quel fichier
              // image, donc le PNG de signature fonctionne tel quel).
              if (widget.stop.signaturePath != null)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: p.ink),
                  onPressed: () => Navigator.of(context)
                      .pop(const ViewSignatureAction()),
                  icon: const Icon(Icons.draw_outlined, size: 18),
                  label: const Text('Voir la signature'),
                ),
              // Dossier litige : au meme endroit que les autres preuves,
              // mais uniquement sur un arret deja tranche (livre/echec).
              // Sur un arret "a livrer" il n'y aurait ni horodatage, ni
              // GPS de passage, ni photo -- rien d'opposable.
              if (hasStatut)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: p.ink),
                  onPressed: () => Navigator.of(context)
                      .pop(const OpenDossierLitigeAction()),
                  icon: const Icon(Icons.description_outlined, size: 18),
                  label: const Text('Dossier litige'),
                ),
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
              // Scan "cible" : contrairement au scan libre du FAB, il sait
              // quel arret est attendu, donc il peut prevenir qu'on est en
              // train de flasher le colis du voisin.
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: p.ink),
                onPressed: () => Navigator.of(context)
                    .pop(const ScanColisPourArretAction()),
                icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                label: const Text('Scanner le colis de cet arret'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: p.ink),
                onPressed: () => Navigator.of(context)
                    .pop(const OpenInMapsAction()),
                icon: const Icon(Icons.map_outlined, size: 18),
                label: const Text('Voir sur Maps'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: p.ink),
                onPressed: () => Navigator.of(context)
                    .pop(const OpenStreetviewAction()),
                icon: const Icon(Icons.streetview_outlined, size: 18),
                label: const Text('Street View (vue rue)'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: p.ink),
                onPressed: () => Navigator.of(context)
                    .pop(const CopyAdresseAction()),
                icon: const Icon(Icons.content_copy_outlined, size: 18),
                label: const Text('Copier l\'adresse'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: p.ink),
                onPressed: () => Navigator.of(context)
                    .pop(const ShareAdresseAction()),
                icon: const Icon(Icons.share_outlined, size: 18),
                label: const Text('Partager l\'adresse'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: p.ink,
                ),
                onPressed: () => _onMoveTo(context),
                icon: const Icon(Icons.swap_horiz, size: 18),
                label: const Text('Deplacer vers une autre tournee'),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  foregroundColor: p.ink,
                ),
                onPressed: () => Navigator.of(context).pop(
                  ConvertTypeAction(
                    stop.type == kStopTypeRamasse
                        ? kStopTypeLivraison
                        : kStopTypeRamasse,
                  ),
                ),
                icon: Icon(
                  stop.type == kStopTypeRamasse
                      ? Icons.local_shipping_outlined
                      : Icons.move_to_inbox_outlined,
                  size: 18,
                ),
                label: Text(
                  stop.type == kStopTypeRamasse
                      ? 'Convertir en livraison'
                      : 'Convertir en ramasse',
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(foregroundColor: p.ink),
                onPressed: () => Navigator.of(context).pop(
                  ToggleLockPositionAction(!stop.positionLocked),
                ),
                icon: Icon(
                  stop.positionLocked
                      ? Icons.lock_open_outlined
                      : Icons.lock_outline,
                  size: 18,
                ),
                label: Text(
                  stop.positionLocked
                      ? 'Deverrouiller la position'
                      : 'Verrouiller a cette position',
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

/// Bandeau d'alerte affichant les consignes client persistantes
/// (preferencePersonnalisee et photoObligatoire depuis saved_destinations).
///
/// F5+F6 sprint immediat 2026-05-31 : les 2 colonnes existaient sans UI.
/// Aujourd'hui, Noah voit en gros dans le header de la sheet :
/// - Une consigne forte ("client sourd, sonner 3 fois") si stockee dans
///   le carnet (`preferencePersonnalisee`)
/// - Un warning amber "Photo preuve obligatoire" si le client l'exige
///   (`photoObligatoire`)
///
/// Tout ou rien : si aucune des 2 n'est dans le carnet, retourne
/// SizedBox.shrink (zero pollution UI).
class _ClientConsignesBanner extends ConsumerWidget {
  const _ClientConsignesBanner({required this.nomClient});

  final String nomClient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(clientConsignesByNomProvider(nomClient));
    final consignes = async.asData?.value;
    if (consignes == null) return const SizedBox.shrink();
    final hasPref = consignes.preference != null;
    final hasPhoto = consignes.photoObligatoire;
    if (!hasPref && !hasPhoto) return const SizedBox.shrink();
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasPref)
            Container(
              padding: const EdgeInsets.all(AppSpacing.x10),
              decoration: BoxDecoration(
                color: AppColors.lime.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.r10),
                border: Border.all(color: AppColors.lime, width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.priority_high, size: 18, color: p.ink),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      consignes.preference!,
                      style: TextStyle(
                        fontSize: 13,
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (hasPref && hasPhoto) const SizedBox(height: AppSpacing.x6),
          if (hasPhoto)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x10, vertical: AppSpacing.x8),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.r10),
                border: Border.all(color: AppColors.amber, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.photo_camera_outlined,
                      size: 16, color: AppColors.amber),
                  const SizedBox(width: AppSpacing.x8),
                  Expanded(
                    child: Text(
                      'Photo preuve OBLIGATOIRE pour ce client',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.ink,
                        fontWeight: FontWeight.w700,
                      ),
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

/// Petit bouton "Appeler" affiche dans le header de StopActionSheet
/// quand le carnet a une entree avec telephone pour ce nomClient.
///
/// QW4 audit #337 (2026-05-31) : avant, Noah devait quitter la sheet,
/// ouvrir le carnet, chercher le client, taper le numero. Maintenant
/// 1 tap = appel direct via intent natif `tel:`.
class _CallClientButton extends ConsumerWidget {
  const _CallClientButton({required this.nomClient, this.directPhone});

  final String nomClient;

  /// Numero saisi directement sur l'arret (stop.telephone, #B Noah). S'il
  /// est present, il a la PRIORITE sur le carnet (le numero de l'arret est
  /// plus specifique que celui d'un client generique du carnet).
  final String? directPhone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1) numero de l'arret s'il existe, 2) sinon lookup carnet par nom.
    final direct = directPhone?.trim();
    final phone = (direct != null && direct.isNotEmpty)
        ? direct
        : ref.watch(clientPhoneByNomProvider(nomClient)).asData?.value;
    if (phone == null || phone.isEmpty) {
      return const SizedBox.shrink();
    }
    return IconButton(
      icon: const Icon(Icons.phone_outlined),
      tooltip: 'Appeler $phone',
      color: AppColors.emerald,
      onPressed: () => _call(context, phone),
    );
  }

  Future<void> _call(BuildContext context, String phone) async {
    // Normalise : enleve espaces et caracteres non-tel, garde + et chiffres.
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible d\'ouvrir le dialer pour $phone')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur appel : ${humanizeAnyError(e)}')),
        );
      }
    }
  }
}
