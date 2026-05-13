import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/address_suggestion.dart';
import '../data/bordereau_extraction.dart';
import '../data/database.dart';
import '../data/geo_utils.dart';
import '../providers/database_providers.dart';
import '../providers/geocoding_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/address_autocomplete_field.dart';
import 'scan_bordereau_screen.dart';

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
  });

  final int tourneeId;
  final Stop? initial;

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
    _nbColisCtrl.dispose();
    _dureeArretCtrl.dispose();
    _nomClientCtrl.dispose();
    _notesCtrl.dispose();
    setState(() {
      _nbColisCtrl = TextEditingController(text: '1');
      _dureeArretCtrl = TextEditingController(text: '3');
      _nomClientCtrl = TextEditingController();
      _notesCtrl = TextEditingController();
      _address = null;
      _priorite = 'flexible';
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
              _OfflineAddressBanner(
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
            const _SectionTitle('Client / Enseigne (optionnel)'),
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
            const _SectionTitle('Priorite'),
            const SizedBox(height: AppSpacing.x10),
            _PriorityChips(
              value: _priorite,
              onChanged: (v) => setState(() => _priorite = v),
            ),
            const SizedBox(height: AppSpacing.x22),
            const _SectionTitle('Colis'),
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
            const _SectionTitle('Fenetre horaire (optionnel)'),
            const SizedBox(height: AppSpacing.x10),
            Row(
              children: [
                Expanded(
                  child: _TimePickerField(
                    label: 'Pas avant',
                    value: _fenetreDebut,
                    onChanged: (t) => setState(() => _fenetreDebut = t),
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: _TimePickerField(
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cet arret ?'),
        content: Text(
          widget.initial!.nomClient != null &&
                  widget.initial!.nomClient!.isNotEmpty
              ? '${widget.initial!.nomClient} - ${widget.initial!.adresseBrute}'
              : widget.initial!.adresseBrute,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red.withValues(alpha: 0.15),
              foregroundColor: AppColors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ref.read(stopsRepositoryProvider).delete(widget.initial!.id);
      await ref
          .read(tourneesRepositoryProvider)
          .invalidateOptimization(widget.tourneeId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la suppression : $e')),
      );
    }
  }

  String? _validatePositiveInt(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Requis';
    final n = int.tryParse(s);
    if (n == null || n < 0) return 'Entier positif';
    return null;
  }

  Future<void> _scanBordereau() async {
    final extraction = await Navigator.of(context).push<BordereauExtraction?>(
      MaterialPageRoute(
        builder: (_) => const ScanBordereauScreen(),
      ),
    );
    if (extraction == null || !mounted) return;

    // Pre-remplit nom client et nb colis si presents.
    if (extraction.nomDestinataire != null &&
        extraction.nomDestinataire!.isNotEmpty) {
      _nomClientCtrl.text = extraction.nomDestinataire!;
    }
    if (extraction.nbColis != null && extraction.nbColis! > 0) {
      _nbColisCtrl.text = extraction.nbColis!.toString();
    }

    // Recherche d'adresse en 2 temps (demande explicite de Noah) :
    // 1) D'abord par nom d'entreprise + ville (SIRENE, Photon).
    // 2) Si rien, fallback sur l'adresse postale (BAN).
    AddressSuggestion? found;
    final service = ref.read(geocodingServiceProvider);

    final nomQuery = extraction.rechercheParNom;
    if (nomQuery != null && nomQuery.length >= 3) {
      try {
        final r = await service.search(nomQuery);
        if (r.isNotEmpty) found = r.first;
      } catch (_) {/* on tente l'adresse */}
    }

    final addrQuery = extraction.adressePostale;
    if (found == null && addrQuery != null && addrQuery.length >= 3) {
      try {
        final r = await service.search(addrQuery);
        if (r.isNotEmpty) found = r.first;
      } catch (_) {/* tant pis */}
    }

    if (!mounted) return;
    setState(() {
      if (found != null) {
        // Adresse validee directement : on a les coordonnees + le label.
        _address = found;
        _scannedAddress = null;
      } else {
        // Aucun match : on met le scan en string libre dans le champ
        // adresse, l'utilisateur affinera (suggestions s'afficheront
        // automatiquement grace au declenchement de la recherche).
        _scannedAddress = addrQuery ?? nomQuery;
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
      final doublon = await _findPossibleDoublon(
        lat: _address!.lat,
        lng: _address!.lon,
        adresse: _address!.adressePostale,
      );
      if (doublon != null && mounted) {
        final keepGoing = await _askConfirmDoublon(doublon);
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
      } else {
        // Pre-remplit le coequipier par defaut de la tournee s'il y en
        // a un (mode chef d'equipe : "tous les arrets de cette tournee
        // sont pour Lucas").
        final tournee = await ref
            .read(tourneesRepositoryProvider)
            .getById(widget.tourneeId);
        final defautCoId = tournee?.coequipierDefautId;
        final companion = StopsCompanion.insert(
          tourneeId: widget.tourneeId,
          adresseBrute: adresseBrute,
          adresseNormalisee: Value(adresseBrute),
          lat: Value(lat),
          lng: Value(lng),
          nbColis: Value(int.tryParse(_nbColisCtrl.text.trim()) ?? 1),
          priorite: Value(_priorite),
          fenetreDebut: Value(_formatTime(_fenetreDebut)),
          fenetreFin: Value(_formatTime(_fenetreFin)),
          dureeArretMin: Value(int.tryParse(_dureeArretCtrl.text.trim()) ?? 3),
          notes: Value(_orNull(_notesCtrl.text)),
          nomClient: Value(_orNull(_nomClientCtrl.text)),
          coequipierId: Value(defautCoId),
        );
        await repo.create(companion);
        await ref
            .read(tourneesRepositoryProvider)
            .invalidateOptimization(widget.tourneeId);
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
        SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
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

  /// Retourne le Stop deja present dans la tournee qui ressemble a
  /// l'adresse passee, soit par coords (< 30 m haversine), soit par
  /// adresse brute identique (case-insensitive). Null si pas de
  /// doublon detecte.
  Future<Stop?> _findPossibleDoublon({
    required double lat,
    required double lng,
    required String adresse,
  }) async {
    final repo = ref.read(stopsRepositoryProvider);
    final stops = await repo.getByTournee(widget.tourneeId);
    final adresseLower = adresse.toLowerCase().trim();
    for (final s in stops) {
      if (s.adresseBrute.toLowerCase().trim() == adresseLower) return s;
      if (s.lat != null && s.lng != null) {
        if (GeoUtils.areClose(
          lat1: lat,
          lon1: lng,
          lat2: s.lat!,
          lon2: s.lng!,
          thresholdMeters: 30,
        )) {
          return s;
        }
      }
    }
    return null;
  }

  /// Dialog "Doublon possible" : affiche les details du Stop ressemblant
  /// et demande confirmation. Retourne true si l'utilisateur veut
  /// quand meme creer le nouvel arret.
  Future<bool> _askConfirmDoublon(Stop doublon) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Doublon possible ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Un arret tres proche existe deja dans cette tournee :',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.x10),
            Container(
              padding: const EdgeInsets.all(AppSpacing.x10),
              decoration: BoxDecoration(
                color: AppColors.amber.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppRadius.r10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (doublon.nomClient != null &&
                      doublon.nomClient!.isNotEmpty)
                    Text(
                      doublon.nomClient!,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  Text(
                    doublon.adresseBrute,
                    style: const TextStyle(color: AppColors.ink),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Ajouter quand meme'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // Note : haversine deplace dans `GeoUtils` (lib/data/geo_utils.dart)
  // pour pouvoir le tester sans dependance Flutter et l'utiliser depuis
  // d'autres ecrans.

  /// Dialog "Saisie hors-ligne" : un seul champ texte que l'utilisateur
  /// remplit a la main quand l'autocomplete echoue (zone rurale sans
  /// 4G typiquement). Le texte sauvegarde dans `_offlineAddressText`
  /// devient `adresseBrute` du Stop, sans lat/lng. L'arret apparait
  /// avec un badge "GPS manquant" dans la tournee et peut etre
  /// re-edite plus tard pour declencher le geocodage.
  Future<void> _enterOfflineAddress() async {
    final ctrl = TextEditingController(text: _offlineAddressText ?? '');
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Saisie hors ligne'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tape l\'adresse complete a la main. Le GPS sera '
                'manquant tant que tu n\'auras pas re-edite cet arret '
                'avec une connexion (re-selection depuis l\'autocomplete).',
                style: TextStyle(fontSize: 12.5, height: 1.4),
              ),
              const SizedBox(height: AppSpacing.x12),
              TextField(
                controller: ctrl,
                autofocus: true,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Adresse',
                  hintText: '12 rue des Lilas, 28100 Dreux',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(ctrl.text.trim()),
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );
    if (!mounted) return;
    if (result == null) return;
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

/// Bandeau orange/amber affiche sous le champ Adresse quand
/// `_offlineAddressText` est rempli. Indique clairement que cet arret
/// n'a pas de coordonnees GPS et offre un bouton pour effacer la saisie
/// hors-ligne et revenir a l'autocomplete normal.
class _OfflineAddressBanner extends StatelessWidget {
  const _OfflineAddressBanner({required this.text, required this.onClear});

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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
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

class _PriorityChips extends StatelessWidget {
  const _PriorityChips({required this.value, required this.onChanged});

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

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({
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
