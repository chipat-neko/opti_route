import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/fuel_price_service.dart';
import '../data/location_service.dart';
import '../data/navigation_service.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';

/// Formulaire de creation / edition d'un frais.
///
/// Champs :
///  - Type (chips : carburant / peage / parking / repas / autre)
///  - Date (date picker, default = aujourd'hui)
///  - Montant en EUR (input numerique, conversion en centimes a la
///    sauvegarde pour eviter les imprecisions float)
///  - Libelle (1-80 chars)
///  - Notes (optionnel)
///  - Tournee rattachee (optionnel, selecteur)
///
/// Pas de photo justificatif pour le MVP -- on l'ajoutera si Noah le
/// demande (image_picker existe deja dans les deps via le scan
/// bordereau).
class FraisFormScreen extends ConsumerStatefulWidget {
  const FraisFormScreen({super.key, this.initial});

  /// Si non null, formulaire en mode EDIT (pre-rempli + bouton
  /// "Enregistrer" au lieu de "Ajouter").
  final Frai? initial;

  @override
  ConsumerState<FraisFormScreen> createState() => _FraisFormScreenState();
}

/// Liste des types proposes dans le picker chips. Ordre = frequence
/// estimee d'utilisation (carburant > peage > parking > repas > autre).
const _typesDispos = <String>[
  'carburant',
  'peage',
  'parking',
  'repas',
  'autre',
];

class _FraisFormScreenState extends ConsumerState<FraisFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _libelleCtrl;
  late final TextEditingController _montantCtrl;
  late final TextEditingController _notesCtrl;
  late DateTime _date;
  late String _type;
  int? _tourneeId;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _libelleCtrl = TextEditingController(text: init?.libelle ?? '');
    _montantCtrl = TextEditingController(
      text: init == null ? '' : (init.montantCentimes / 100).toStringAsFixed(2),
    );
    _notesCtrl = TextEditingController(text: init?.notes ?? '');
    _date = init?.date ?? DateTime.now();
    _type = init?.type ?? 'carburant';
    _tourneeId = init?.tourneeId;
  }

  @override
  void dispose() {
    _libelleCtrl.dispose();
    _montantCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  /// Ouvre la bottomsheet "Stations Diesel proches" (carte Trello
  /// #39 V4). Recupere la position GPS courante (best-effort 4s),
  /// fetch les 5 stations Diesel les plus proches (rayon 10 km) via
  /// l'API data.gouv.fr, propose un clic pour pre-remplir le libelle
  /// et le montant suggere base sur ~50L de plein.
  Future<void> _openNearbyStations() async {
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.selectionClick();
    // Etape 1 : GPS one-shot (timeout 4s). Si refuse / indispo, on
    // affiche un message clair et on stoppe.
    try {
      final ok = await LocationService.ensurePermission();
      if (!ok) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Permission GPS refusee. Active-la pour localiser les stations.',
            ),
          ),
        );
        return;
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Permission GPS refusee. Active-la pour localiser les stations.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    ({double lat, double lng})? pos;
    try {
      final p = await LocationService.currentPosition()
          .timeout(const Duration(seconds: 4));
      pos = (lat: p.latitude, lng: p.longitude);
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'GPS indisponible. Ouvre les Reglages pour activer la geoloc.',
          ),
        ),
      );
      return;
    }
    if (!mounted) return;
    // Etape 2 : ouvre la bottomsheet qui fait le fetch via le provider.
    final picked = await showModalBottomSheet<FuelStation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.palette.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (_) => _NearbyStationsSheet(lat: pos!.lat, lng: pos.lng),
    );
    if (picked == null || !mounted) return;
    // Etape 3 : pre-remplit le libelle (nom ou adresse + ville) et le
    // montant suggere = 50L au prix Diesel station (estim plein
    // typique fourgon Noah). L'utilisateur ajuste s'il a fait <50L.
    final label = picked.name.isNotEmpty
        ? '${picked.name} · ${picked.ville}'
        : (picked.address.isNotEmpty
            ? '${picked.address} · ${picked.ville}'
            : picked.ville);
    final suggested = (picked.dieselPriceEur * 50).toStringAsFixed(2);
    setState(() {
      _libelleCtrl.text = label;
      _montantCtrl.text = suggested.replaceAll('.', ',');
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      locale: const Locale('fr', 'FR'),
      helpText: 'Date du frais',
    );
    if (picked != null && mounted) {
      setState(() => _date = picked);
    }
  }

  /// Convertit "12,35" ou "12.35" en 1235 centimes. Retourne null si
  /// la chaine n'est pas parsable ou negative.
  int? _parseMontantCentimes(String raw) {
    final cleaned = raw.trim().replaceAll(',', '.');
    final value = double.tryParse(cleaned);
    if (value == null || value < 0) return null;
    return (value * 100).round();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final centimes = _parseMontantCentimes(_montantCtrl.text)!;
      final notes = _notesCtrl.text.trim();
      final repo = ref.read(fraisRepositoryProvider);
      if (_isEdit) {
        await repo.update(
          widget.initial!.id,
          date: _date,
          type: _type,
          montantCentimes: centimes,
          libelle: _libelleCtrl.text,
          notes: notes.isEmpty ? null : notes,
          clearNotes: notes.isEmpty,
          tourneeId: _tourneeId,
          clearTournee: _tourneeId == null,
        );
      } else {
        await repo.create(
          date: _date,
          type: _type,
          montantCentimes: centimes,
          libelle: _libelleCtrl.text,
          notes: notes.isEmpty ? null : notes,
          tourneeId: _tourneeId,
        );
      }
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      navigator.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur enregistrement : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dateLabel = DateFormat('EEEE d MMMM y', 'fr').format(_date);
    // Liste des tournees pour le selecteur "rattacher a..." (last 90
    // jours uniquement pour limiter la longueur du picker).
    final allTournees =
        ref.watch(tourneesStreamProvider).asData?.value ?? const [];
    final tourneesRecentes = allTournees
        .where((t) => t.date.isAfter(
            DateTime.now().subtract(const Duration(days: 90))))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier le frais' : 'Nouveau frais'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x18),
          children: [
            // ─── Type (chips) ────────────────────────────────────
            Text(
              'Type',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: p.textMute,
              ),
            ),
            const SizedBox(height: AppSpacing.x8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _typesDispos.map((t) {
                final selected = _type == t;
                return ChoiceChip(
                  label: Text(_labelForType(t)),
                  selected: selected,
                  avatar: Icon(
                    _iconForType(t),
                    size: 16,
                    color: selected ? p.ink : _colorForType(t),
                  ),
                  onSelected: (_) => setState(() => _type = t),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.x22),

            // ─── Date ────────────────────────────────────────────
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date'),
              subtitle: Text(dateLabel),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: AppSpacing.x14),

            // ─── Montant ─────────────────────────────────────────
            TextFormField(
              controller: _montantCtrl,
              decoration: const InputDecoration(
                labelText: 'Montant',
                suffixText: 'EUR',
                hintText: '12,35',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(
                  RegExp(r'[0-9.,]'),
                ),
              ],
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Saisis un montant';
                }
                final c = _parseMontantCentimes(v);
                if (c == null) return 'Format invalide (ex : 12,35)';
                if (c == 0) return 'Doit etre superieur a 0';
                return null;
              },
            ),
            // Bouton "Stations Diesel proches" : visible uniquement
            // pour le type carburant. Carte Trello #39 V4.
            if (_type == 'carburant') ...[
              const SizedBox(height: AppSpacing.x8),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openNearbyStations,
                  icon: const Icon(Icons.local_gas_station_outlined,
                      size: 16),
                  label: const Text('Stations Diesel proches'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.x8,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.x18),

            // ─── Libelle ─────────────────────────────────────────
            TextFormField(
              controller: _libelleCtrl,
              decoration: const InputDecoration(
                labelText: 'Libelle',
                hintText: 'Ex: Station Total Luce, Peage A11 sortie 4',
              ),
              maxLength: 80,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Donne un libelle';
                }
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.x10),

            // ─── Notes ───────────────────────────────────────────
            TextFormField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optionnel)',
                hintText: 'Numero de facture, remboursable, contexte...',
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: AppSpacing.x18),

            // ─── Tournee rattachee (optionnel) ───────────────────
            if (tourneesRecentes.isNotEmpty) ...[
              Text(
                'Rattacher a une tournee (optionnel)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: p.textMute,
                ),
              ),
              const SizedBox(height: AppSpacing.x8),
              DropdownButtonFormField<int?>(
                initialValue: _tourneeId,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.link),
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Aucune (depense generale)'),
                  ),
                  ...tourneesRecentes.map(
                    (t) => DropdownMenuItem<int?>(
                      value: t.id,
                      child: Text(
                        '${t.nom} - ${DateFormat('d MMM', 'fr').format(t.date)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _tourneeId = v),
              ),
              const SizedBox(height: AppSpacing.x18),
            ],

            // ─── CTA ─────────────────────────────────────────────
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.lime,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(_isEdit ? 'Enregistrer' : 'Ajouter le frais'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Helpers dupliques de frais_screen.dart (eviter import cyclique) ─

String _labelForType(String type) {
  return switch (type) {
    'carburant' => 'Carburant',
    'peage' => 'Peage',
    'parking' => 'Parking',
    'repas' => 'Repas',
    'autre' => 'Autre',
    _ => type[0].toUpperCase() + type.substring(1),
  };
}

Color _colorForType(String type) {
  return switch (type) {
    'carburant' => AppColors.amber,
    'peage' => AppColors.emerald,
    'parking' => const Color(0xFF7C4DFF),
    'repas' => AppColors.red,
    'autre' => AppColors.textMute,
    _ => AppColors.textMute,
  };
}

IconData _iconForType(String type) {
  return switch (type) {
    'carburant' => Icons.local_gas_station_outlined,
    'peage' => Icons.toll_outlined,
    'parking' => Icons.local_parking_outlined,
    'repas' => Icons.restaurant_outlined,
    'autre' => Icons.receipt_outlined,
    _ => Icons.receipt_outlined,
  };
}

/// BottomSheet "Stations Diesel proches" (carte Trello #39 V4).
/// Fetch les 5 stations les plus proches via `nearbyDieselStationsProvider`
/// et propose pour chacune : nom + adresse + prix + distance + bouton
/// "Itineraire" (lance Maps avec lat/lng). Tap sur la card = pop avec
/// la station selectionnee.
class _NearbyStationsSheet extends ConsumerWidget {
  const _NearbyStationsSheet({required this.lat, required this.lng});

  final double lat;
  final double lng;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    // Arrondit a 0.01 deg (~1 km) pour cache stable.
    final coords = (
      (lat * 100).round() / 100,
      (lng * 100).round() / 100,
    );
    final async = ref.watch(nearbyDieselStationsProvider(coords));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.x18,
          AppSpacing.x18,
          AppSpacing.x18,
          AppSpacing.x10,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.local_gas_station_outlined,
                    color: AppColors.emerald),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: Text(
                    'Stations Diesel proches',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: p.ink,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 18),
                  tooltip: 'Rafraichir',
                  onPressed: () =>
                      ref.invalidate(nearbyDieselStationsProvider(coords)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              'Tap sur une station pour pre-remplir le libelle + montant '
              '(estim 50L de plein). Source data.gouv.fr.',
              style: TextStyle(fontSize: 11.5, color: p.textMute, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.x12),
            async.when(
              data: (stations) {
                if (stations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.x22,
                    ),
                    child: Center(
                      child: Text(
                        'Aucune station trouvee dans un rayon de 10 km '
                        '(reseau down ou zone isolee).',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: p.textMute,
                        ),
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final st in stations)
                      _StationTile(station: st),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.x22),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.x18,
                ),
                child: Text(
                  'Erreur de chargement : $e',
                  style: const TextStyle(color: AppColors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationTile extends StatelessWidget {
  const _StationTile({required this.station});

  final FuelStation station;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final priceFr = station.dieselPriceEur.toStringAsFixed(3);
    final distFr = station.distanceKm < 1
        ? '${(station.distanceKm * 1000).round()} m'
        : '${station.distanceKm.toStringAsFixed(1)} km';
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.r12),
        onTap: () => Navigator.of(context).pop(station),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      station.displayLabel,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.ink,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${station.codePostal} ${station.ville} · $distFr',
                      style: TextStyle(fontSize: 11, color: p.textMute),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$priceFr EUR',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.emerald,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.directions, size: 18),
                    tooltip: 'Itineraire',
                    onPressed: () => NavigationService.launchGoogleMaps(
                      lat: station.lat,
                      lng: station.lng,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
