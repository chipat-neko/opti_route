import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/address_suggestion.dart';
import '../data/cloud_error_humanizer.dart';
import '../data/database.dart';
import '../data/stop_types.dart';
import '../providers/database_providers.dart';
import '../providers/geocoding_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/address_autocomplete_field.dart';
import '../widgets/voice_input_button.dart';
import 'ajout_arret/bordereau_scan_handler.dart';
import 'ajout_arret/delete_helper.dart';
import 'ajout_arret/dialogs.dart';
import 'ajout_arret/doublon_helpers.dart';
import 'ajout_arret/form_widgets.dart';

/// Ajout (potentiellement multiple) d'arrets a une tournee, avec
/// imperatifs sur la meme page :
///   - adresse (autocomplete Nominatim, lat/lng caches en backend)
///   - priorite (premier / flexible / dernier / eviter)
///   - nb de colis
///   - fenetre horaire debut/fin (optionnel)
///   - duree estimee de l'arret
///   - nom du client + notes (optionnel)
///
/// Mode creation : deux boutons : "Enregistrer" (retour home) et
/// "+ Ajouter un autre" (sauve, reset, reste sur la page).
/// Mode edition (passe `initial`) : un seul bouton "Enregistrer".
class AjoutArretScreen extends ConsumerStatefulWidget {
  const AjoutArretScreen({
    super.key,
    required this.tourneeId,
    this.initial,
    this.trackingInitial,
  });

  final int tourneeId;
  final Stop? initial;

  /// Numero de tracking (code-barre) pre-rempli si l'ecran est ouvert
  /// depuis le scanner colis sans match dans la tournee. Le code sera
  /// stocke dans `tracking_numbers` au save du nouvel arret + ajoute
  /// au champ Notes pour visibilite.
  final String? trackingInitial;

  @override
  ConsumerState<AjoutArretScreen> createState() => _AjoutArretScreenState();
}

class _AjoutArretScreenState extends ConsumerState<AjoutArretScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nbColisCtrl;
  late TextEditingController _dureeArretCtrl;
  late TextEditingController _nomClientCtrl;
  late TextEditingController _notesCtrl;

  AddressSuggestion? _address;
  String? _scannedAddress;
  String _priorite = 'flexible';
  String _type = kStopTypeLivraison;
  TimeOfDay? _fenetreDebut;
  TimeOfDay? _fenetreFin;
  bool _saving = false;
  int _addressFieldVersion = 0;

  /// Mode hors-ligne : Noah a entre une adresse brute non geocodee
  /// (pas de coords lat/lng). On garde le texte ici pour le sauver
  /// dans `adresseBrute`. L'arret sera flagge "GPS manquant" dans la
  /// liste de la tournee et l'utilisateur pourra le re-geocoder plus
  /// tard (en l'editant) une fois revenu en zone couverte.
  String? _offlineAddressText;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    _initFromInitial();
    if (widget.initial == null) {
      // Mode creation : preremplir la duree d'arret avec la valeur
      // par defaut configuree dans Parametres (si elle existe).
      _loadDefaults();
    }
  }

  void _initFromInitial() {
    final s = widget.initial;
    _nbColisCtrl = TextEditingController(text: (s?.nbColis ?? 1).toString());
    _dureeArretCtrl =
        TextEditingController(text: (s?.dureeArretMin ?? 3).toString());
    _nomClientCtrl = TextEditingController(text: s?.nomClient ?? '');
    _notesCtrl = TextEditingController(text: s?.notes ?? '');
    _priorite = s?.priorite ?? 'flexible';
    _type = s?.type ?? kStopTypeLivraison;
    _fenetreDebut = _parseTime(s?.fenetreDebut);
    _fenetreFin = _parseTime(s?.fenetreFin);
    if (s != null && s.lat != null && s.lng != null) {
      _address = AddressSuggestion(
        displayName: s.adresseNormalisee ?? s.adresseBrute,
        lat: s.lat!,
        lon: s.lng!,
      );
    }
  }

  Future<void> _loadDefaults() async {
    final duree = await ref
        .read(parametresRepositoryProvider)
        .getDureeArretDefault();
    if (!mounted || duree == null) return;
    setState(() => _dureeArretCtrl.text = duree.toString());
  }

  void _resetForm() {
    // Audit 2026-05-17 fix : avant on faisait dispose + new sur les
    // controllers, mais ils restaient reference par le Form / les
    // TextField pendant le re-build, ce qui pouvait crasher. Utiliser
    // .text = ... + .clear() est safe : meme instance preservee.
    setState(() {
      _nbColisCtrl.text = '1';
      _dureeArretCtrl.text = '3';
      _nomClientCtrl.clear();
      _notesCtrl.clear();
      _address = null;
      _priorite = 'flexible';
      _type = kStopTypeLivraison;
      _fenetreDebut = null;
      _fenetreFin = null;
    });
    _formKey.currentState?.reset();
  }

  @override
  void dispose() {
    _nbColisCtrl.dispose();
    _dureeArretCtrl.dispose();
    _nomClientCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier l\'arret' : 'Ajouter un arret'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x18),
          children: [
            // Toggle Livraison/Ramasse en haut du form : visible avant
            // meme de taper l'adresse, evite d'oublier de switcher.
            StopTypeToggle(
              value: _type,
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: AppSpacing.x14),
            AddressAutocompleteField(
              key: ValueKey(
                'address-${widget.initial?.id ?? "new"}-$_addressFieldVersion',
              ),
              labelText: 'Adresse',
              hintText: 'Tape la rue, la ville, ou le nom d\'un client deja livre...',
              initialSuggestion: _address,
              initialDisplayText: _scannedAddress ?? _address?.displayName,
              onSuggestionSelected: (s) {
                setState(() {
                  _address = s;
                  // Une vraie suggestion ecrase la saisie hors-ligne.
                  if (s != null) _offlineAddressText = null;
                  // Si c'est une selection du carnet local, on pre-remplit
                  // aussi le champ "Nom du client" (sauf si l'utilisateur
                  // a deja saisi quelque chose).
                  if (s != null &&
                      s.fromCarnet &&
                      s.poiName != null &&
                      s.poiName!.isNotEmpty &&
                      _nomClientCtrl.text.trim().isEmpty) {
                    _nomClientCtrl.text = s.poiName!;
                  }
                  // Idem pour les notes pre-definies du carnet (code
                  // interphone, instructions). On les pre-remplit
                  // seulement si Noah n'a pas encore tape ses propres
                  // notes pour cet arret.
                  if (s != null &&
                      s.fromCarnet &&
                      s.notesCarnet != null &&
                      s.notesCarnet!.trim().isNotEmpty &&
                      _notesCtrl.text.trim().isEmpty) {
                    _notesCtrl.text = s.notesCarnet!;
                  }
                });
              },
            ),
            if (_offlineAddressText != null) ...[
              const SizedBox(height: AppSpacing.x6),
              OfflineAddressBanner(
                text: _offlineAddressText!,
                onClear: () =>
                    setState(() => _offlineAddressText = null),
              ),
            ],
            const SizedBox(height: AppSpacing.x10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _scanBordereau,
                    icon: const Icon(Icons.document_scanner_outlined),
                    label: const Text('Scanner'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x10),
                // Bouton Dicter : reconnaissance vocale on-device pour
                // entrer une adresse mains-libres au volant. Inspire de
                // Spoke route planner ("Speak, search, or scan to add
                // stops"). Le texte reconnu remplit le champ adresse
                // qui declenche l'autocomplete Nominatim derriere.
                Expanded(
                  child: VoiceInputButtonOutlined(
                    onResult: _onVoiceAddress,
                  ),
                ),
                const SizedBox(width: AppSpacing.x10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _saving ? null : _enterOfflineAddress,
                    icon: const Icon(Icons.signal_cellular_off_outlined),
                    label: const Text('Hors ligne'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x22),
            const SectionTitle('Client / Enseigne (optionnel)'),
            const SizedBox(height: AppSpacing.x10),
            TextFormField(
              controller: _nomClientCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom du client ou de l\'enseigne',
                hintText: 'Mme Aubry · Unikalo · Carrefour · Pharmacie...',
                helperText:
                    'Astuce : si le commerce n\'apparait pas dans l\'autocomplete '
                    'd\'adresse, mets son nom ici et tape l\'adresse postale du '
                    'colis dans le champ Adresse au-dessus.',
                helperMaxLines: 3,
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: AppSpacing.x12),
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Code 1234B · porte garage · 3e etage',
              ),
              maxLines: 3,
              textInputAction: TextInputAction.newline,
            ),
            const SizedBox(height: AppSpacing.x22),
            const SectionTitle('Priorite'),
            const SizedBox(height: AppSpacing.x10),
            PriorityChips(
              value: _priorite,
              onChanged: (v) => setState(() => _priorite = v),
            ),
            const SizedBox(height: AppSpacing.x22),
            const SectionTitle('Colis'),
            const SizedBox(height: AppSpacing.x10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nbColisCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de colis',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validatePositiveInt,
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: TextFormField(
                    controller: _dureeArretCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Duree (min)',
                      helperText: 'Temps estime sur place',
                    ),
                    keyboardType: TextInputType.number,
                    validator: _validatePositiveInt,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x22),
            const SectionTitle('Fenetre horaire (optionnel)'),
            const SizedBox(height: AppSpacing.x10),
            Row(
              children: [
                Expanded(
                  child: TimePickerField(
                    label: 'Pas avant',
                    value: _fenetreDebut,
                    onChanged: (t) => setState(() => _fenetreDebut = t),
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: TimePickerField(
                    label: 'Avant',
                    value: _fenetreFin,
                    onChanged: (t) => setState(() => _fenetreFin = t),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x28),
            FilledButton.icon(
              onPressed: _saving ? null : () => _save(addAnother: false),
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
              label: const Text('Enregistrer'),
            ),
            if (!_isEdit) ...[
              const SizedBox(height: AppSpacing.x10),
              OutlinedButton.icon(
                onPressed: _saving ? null : () => _save(addAnother: true),
                icon: const Icon(Icons.add),
                label: const Text('+ Ajouter un autre'),
              ),
            ],
            if (_isEdit) ...[
              const SizedBox(height: AppSpacing.x18),
              const Divider(),
              const SizedBox(height: AppSpacing.x18),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _saving ? null : _confirmDelete,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red,
                    side: const BorderSide(color: AppColors.red, width: 1.5),
                    minimumSize: const Size(0, 52),
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.all(Radius.circular(AppRadius.r14)),
                    ),
                  ),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Supprimer cet arret'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    if (widget.initial == null) return;
    setState(() => _saving = true);
    final ok = await confirmAndDeleteStop(
      context,
      ref,
      stop: widget.initial!,
      tourneeId: widget.tourneeId,
    );
    if (!mounted) {
      return;
    }
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() => _saving = false);
    }
  }

  String? _validatePositiveInt(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Requis';
    final n = int.tryParse(s);
    if (n == null || n < 0) return 'Entier positif';
    return null;
  }

  /// Callback du bouton micro : recoit le texte reconnu, lance la
  /// recherche d'adresse via Nominatim et pre-remplit le champ
  /// Adresse avec le 1er resultat. Si rien trouve, bascule en mode
  /// hors-ligne avec le texte brut.
  ///
  /// Style Spoke route planner : dictation mains-libres au volant.
  Future<void> _onVoiceAddress(String spoken) async {
    final messenger = ScaffoldMessenger.of(context);
    final cleaned = spoken.trim();
    if (cleaned.isEmpty) return;
    final service = ref.read(geocodingServiceProvider);
    try {
      final results = await service.search(cleaned);
      if (!mounted) return;
      if (results.isEmpty) {
        // Pas d'adresse trouvee : on stocke en hors-ligne avec le
        // texte brut. Noah pourra re-geocoder plus tard.
        setState(() {
          _offlineAddressText = cleaned;
          _address = null;
          _scannedAddress = cleaned;
          _addressFieldVersion++;
        });
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Adresse non geocodee, ajoutee en hors ligne. '
              'Tu pourras la re-geocoder plus tard.',
            ),
          ),
        );
        return;
      }
      // 1er resultat : on le selectionne d'office.
      setState(() {
        _address = results.first;
        _scannedAddress = results.first.displayName;
        _offlineAddressText = null;
        _addressFieldVersion++;
      });
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Recherche d\'adresse echouee : $e')),
      );
    }
  }

  Future<void> _scanBordereau() async {
    final scan = await handleBordereauScan(context, ref);
    if (scan == null || !mounted) return;

    if (scan.nomClient != null && scan.nomClient!.isNotEmpty) {
      _nomClientCtrl.text = scan.nomClient!;
    }
    if (scan.nbColis != null && scan.nbColis! > 0) {
      _nbColisCtrl.text = scan.nbColis!.toString();
    }
    setState(() {
      if (scan.isEnlevement) _type = kStopTypeRamasse;
      if (scan.address != null) {
        _address = scan.address;
        _scannedAddress = null;
      } else {
        _scannedAddress = scan.scannedAddressText;
        _address = null;
      }
      _addressFieldVersion++;
    });
  }

  Future<void> _save({required bool addAnother}) async {
    if (!_formKey.currentState!.validate()) return;
    if (_address == null && _offlineAddressText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une adresse')),
      );
      return;
    }

    // Detection doublon : si on est en train de creer (pas edit) ET
    // on a des coords, on regarde s'il existe deja un arret dans la
    // tournee tres proche (< 30 m haversine) ou avec la meme adresse
    // brute (case-insensitive). Avertit avant de creer.
    if (!_isEdit && _address != null) {
      final doublon = await findPossibleDoublon(
        ref,
        tourneeId: widget.tourneeId,
        lat: _address!.lat,
        lng: _address!.lon,
        adresse: _address!.adressePostale,
      );
      if (doublon != null && mounted) {
        final keepGoing =
            await askConfirmDoublon(context, doublon: doublon);
        if (!keepGoing) return;
      }
    }

    setState(() => _saving = true);

    final repo = ref.read(stopsRepositoryProvider);
    final carnet = ref.read(savedDestinationsRepositoryProvider);

    // En mode hors-ligne : adresseBrute = texte tape, lat/lng = null.
    // Sinon : on prend l'AddressSuggestion complete.
    final isOffline = _address == null && _offlineAddressText != null;
    final adresseBrute =
        isOffline ? _offlineAddressText! : _address!.adressePostale;
    final lat = isOffline ? null : _address!.lat;
    final lng = isOffline ? null : _address!.lon;

    try {
      if (_isEdit) {
        final companion = StopsCompanion(
          adresseBrute: Value(adresseBrute),
          adresseNormalisee: Value(adresseBrute),
          lat: Value(lat),
          lng: Value(lng),
          nbColis: Value(int.tryParse(_nbColisCtrl.text.trim()) ?? 1),
          priorite: Value(_priorite),
          type: Value(_type),
          fenetreDebut: Value(_formatTime(_fenetreDebut)),
          fenetreFin: Value(_formatTime(_fenetreFin)),
          dureeArretMin: Value(int.tryParse(_dureeArretCtrl.text.trim()) ?? 3),
          notes: Value(_orNull(_notesCtrl.text)),
          nomClient: Value(_orNull(_nomClientCtrl.text)),
        );
        await repo.update(widget.initial!.id, companion);
        await ref
            .read(tourneesRepositoryProvider)
            .invalidateOptimization(widget.tourneeId);
        // Auto-reorder local apres edit : si l'utilisateur a change
        // l'adresse (donc les coords), la position dans l'ordre NN
        // doit etre recalculee.
        await ref
            .read(localReorderServiceProvider)
            .reorder(widget.tourneeId);
      } else {
        // Pre-remplit le coequipier par defaut de la tournee s'il y en
        // a un (mode chef d'equipe : "tous les arrets de cette tournee
        // sont pour Lucas").
        final tournee = await ref
            .read(tourneesRepositoryProvider)
            .getById(widget.tourneeId);
        final defautCoId = tournee?.coequipierDefautId;
        // Si l'ecran a ete ouvert via le scanner colis, on persiste le
        // numero de tracking dans la colonne JSON pour qu'un scan
        // ulterieur du meme code +1 colis (vs creer un doublon).
        final trackingJson = widget.trackingInitial != null
            ? jsonEncode([widget.trackingInitial!])
            : null;
        final companion = StopsCompanion.insert(
          tourneeId: widget.tourneeId,
          adresseBrute: adresseBrute,
          adresseNormalisee: Value(adresseBrute),
          lat: Value(lat),
          lng: Value(lng),
          nbColis: Value(int.tryParse(_nbColisCtrl.text.trim()) ?? 1),
          priorite: Value(_priorite),
          type: Value(_type),
          fenetreDebut: Value(_formatTime(_fenetreDebut)),
          fenetreFin: Value(_formatTime(_fenetreFin)),
          dureeArretMin: Value(int.tryParse(_dureeArretCtrl.text.trim()) ?? 3),
          notes: Value(_orNull(_notesCtrl.text)),
          nomClient: Value(_orNull(_nomClientCtrl.text)),
          coequipierId: Value(defautCoId),
          trackingNumbers: Value(trackingJson),
        );
        await repo.create(companion);
        await ref
            .read(tourneesRepositoryProvider)
            .invalidateOptimization(widget.tourneeId);
        // Auto-reorder local apres ajout : maintient l'ordre "du plus
        // proche au plus loin depuis le depart" a jour, comme Spoke.
        // Le bug 2026-05-20 : cet appel manquait, donc la liste
        // gardait l'ordre d'insertion (chronologique) au lieu du NN.
        await ref
            .read(localReorderServiceProvider)
            .reorder(widget.tourneeId);
      }

      // Carnet d'adresses : seulement si on a des coords (sinon
      // l'entree carnet est inutile, on ne peut pas la geolocaliser
      // ni la reproposer en autocomplete avec une distance).
      // Ne doit jamais bloquer l'enregistrement de l'arret.
      if (!isOffline) {
        try {
          await carnet.upsertFromValidatedStop(
            nomClient: _orNull(_nomClientCtrl.text),
            adresseDisplay: _address!.adressePostale,
            lat: _address!.lat,
            lng: _address!.lon,
            rue: _address!.road == null
                ? null
                : (_address!.houseNumber != null &&
                        _address!.houseNumber!.isNotEmpty
                    ? '${_address!.houseNumber} ${_address!.road}'
                    : _address!.road),
            codePostal: _address!.postcode,
            ville: _address!.city,
          );
        } catch (_) {
          // Silencieux : le carnet est un bonus, pas un bloquant.
        }
      }

      if (!mounted) return;
      // Confirmation tactile : sauvegarde OK. Light si "ajouter encore"
      // (action repetee), medium pour "enregistrer + fermer".
      HapticFeedback.lightImpact();
      if (addAnother) {
        _resetForm();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arret ajoute, saisis le suivant')),
        );
        setState(() => _saving = false);
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Erreur lors de l\'enregistrement : ${humanizeAnyError(e)}')),
      );
    }
  }

  String? _formatTime(TimeOfDay? t) {
    if (t == null) return null;
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  TimeOfDay? _parseTime(String? s) {
    if (s == null || s.isEmpty) return null;
    final parts = s.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  String? _orNull(String s) => s.trim().isEmpty ? null : s.trim();

  // findPossibleDoublon + askConfirmDoublon extraits dans
  // `lib/screens/ajout_arret/doublon_helpers.dart` (carte #165).

  /// Dialog "Saisie hors-ligne" : un seul champ texte que l'utilisateur
  /// remplit a la main quand l'autocomplete echoue (zone rurale sans
  /// 4G typiquement). Le texte sauvegarde dans `_offlineAddressText`
  /// devient `adresseBrute` du Stop, sans lat/lng. L'arret apparait
  /// avec un badge "GPS manquant" dans la tournee et peut etre
  /// re-edite plus tard pour declencher le geocodage.
  Future<void> _enterOfflineAddress() async {
    final result =
        await showOfflineAddressDialog(context, initial: _offlineAddressText);
    if (!mounted || result == null) return;
    final trimmed = result.trim();
    if (trimmed.isEmpty) {
      setState(() => _offlineAddressText = null);
      return;
    }
    setState(() {
      _offlineAddressText = trimmed;
      _address = null;
    });
  }
}
