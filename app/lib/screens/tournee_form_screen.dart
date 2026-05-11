import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/address_suggestion.dart';
import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/address_autocomplete_field.dart';

class TourneeFormScreen extends ConsumerStatefulWidget {
  const TourneeFormScreen({super.key, this.initial});

  final Tournee? initial;

  @override
  ConsumerState<TourneeFormScreen> createState() => _TourneeFormScreenState();
}

class _TourneeFormScreenState extends ConsumerState<TourneeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _capaciteCtrl;
  late DateTime _date;
  AddressSuggestion? _depart;
  bool _saving = false;
  late String _profilOrs;
  late bool _eviterPeages;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _nomCtrl = TextEditingController(text: t?.nom ?? '');
    _capaciteCtrl =
        TextEditingController(text: (t?.vehiculeCapaciteColis ?? 0).toString());
    _date = t?.date ?? DateTime.now();
    _profilOrs = t?.profilOrs ?? 'driving-car';
    _eviterPeages = t?.eviterPeages ?? false;
    if (t != null) {
      _depart = AddressSuggestion(
        displayName: t.pointDepartLabel,
        lat: t.pointDepartLat,
        lon: t.pointDepartLng,
      );
    } else {
      // Mode creation : preremplir la capacite avec la valeur par
      // defaut configuree dans Parametres (si elle existe).
      _loadDefaults();
    }
  }

  Future<void> _loadDefaults() async {
    final cap = await ref
        .read(parametresRepositoryProvider)
        .getCapaciteDefault();
    if (!mounted || cap == null) return;
    setState(() => _capaciteCtrl.text = cap.toString());
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _capaciteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final dateFormat = DateFormat('EEEE d MMMM y', 'fr');

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Modifier la tournee' : 'Nouvelle tournee'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.x18),
          children: [
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom de la tournee',
                hintText: 'Ex: Tournee Mardi 12/05',
              ),
              textInputAction: TextInputAction.next,
              validator: _validateNom,
            ),
            const SizedBox(height: AppSpacing.x18),
            ListTile(
              contentPadding: EdgeInsets.zero,
              tileColor: Colors.transparent,
              title: const Text('Date'),
              subtitle: Text(dateFormat.format(_date)),
              trailing: const Icon(Icons.calendar_today_outlined),
              onTap: _pickDate,
            ),
            const SizedBox(height: AppSpacing.x18),
            AddressAutocompleteField(
              labelText: 'Adresse de depart',
              hintText: 'Tape la rue, la ville, le code postal...',
              initialDisplayText: widget.initial?.pointDepartLabel,
              initialSuggestion: _depart,
              onSuggestionSelected: (s) => setState(() => _depart = s),
            ),
            const SizedBox(height: AppSpacing.x18),
            TextFormField(
              controller: _capaciteCtrl,
              decoration: const InputDecoration(
                labelText: 'Capacite vehicule (colis)',
                helperText: 'Nombre maximum de colis. 0 = illimite.',
              ),
              keyboardType: TextInputType.number,
              validator: _validatePositiveInt,
            ),
            const SizedBox(height: AppSpacing.x18),
            Text(
              'Profil vehicule',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: AppSpacing.x6),
            Text(
              'Voiture/VUL pour les livraisons standards. Camion >3.5t '
              'respecte les restrictions de hauteur/poids et evite les '
              'centres pietonnises.',
              style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.x8),
            Wrap(
              spacing: AppSpacing.x8,
              children: [
                ChoiceChip(
                  label: const Text('Voiture / VUL'),
                  selected: _profilOrs == 'driving-car',
                  onSelected: (_) =>
                      setState(() => _profilOrs = 'driving-car'),
                ),
                ChoiceChip(
                  label: const Text('Camion >3.5t'),
                  selected: _profilOrs == 'driving-hgv',
                  onSelected: (_) =>
                      setState(() => _profilOrs = 'driving-hgv'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.x14),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              tileColor: Colors.transparent,
              title: const Text('Eviter les peages'),
              subtitle: Text(
                'Rallonge souvent l\'itineraire ; utile si tu veux pas '
                'payer de peages sur ton compte perso.',
                style: TextStyle(fontSize: 12, color: p.textMute),
              ),
              value: _eviterPeages,
              onChanged: (v) => setState(() => _eviterPeages = v),
            ),
            const SizedBox(height: AppSpacing.x28),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
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
              label: Text(_isEdit ? 'Enregistrer' : 'Creer la tournee'),
            ),
            if (_isEdit) ...[
              const SizedBox(height: AppSpacing.x18),
              const Divider(),
              const SizedBox(height: AppSpacing.x18),
              _DangerButton(
                label: 'Supprimer cette tournee',
                onPressed: _saving ? null : _confirmDelete,
              ),
              const SizedBox(height: AppSpacing.x6),
              Text(
                'Tous les arrets de cette tournee seront supprimes definitivement.',
                style: TextStyle(fontSize: 12, color: p.textMute),
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
        title: const Text('Supprimer cette tournee ?'),
        content: Text(
          '"${widget.initial!.nom}" et tous ses arrets seront supprimes '
          'definitivement.',
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
      await ref.read(tourneesRepositoryProvider).delete(widget.initial!.id);
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

  String? _validateNom(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Donne un nom a la tournee';
    if (s.length > 100) return 'Maximum 100 caracteres';
    return null;
  }

  String? _validatePositiveInt(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return null;
    final n = int.tryParse(s);
    if (n == null || n < 0) return 'Entier positif';
    return null;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_depart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une adresse de depart')),
      );
      return;
    }
    setState(() => _saving = true);

    final repo = ref.read(tourneesRepositoryProvider);
    final companion = TourneesCompanion(
      nom: Value(_nomCtrl.text.trim()),
      date: Value(_date),
      pointDepartLat: Value(_depart!.lat),
      pointDepartLng: Value(_depart!.lon),
      pointDepartLabel: Value(_depart!.displayName),
      vehiculeCapaciteColis:
          Value(int.tryParse(_capaciteCtrl.text.trim()) ?? 0),
      profilOrs: Value(_profilOrs),
      eviterPeages: Value(_eviterPeages),
    );

    try {
      if (_isEdit) {
        // Le depart, le profil ou l'evitement de peages ont-ils bouge ?
        // Tout ca change la geometrie de l'itineraire optimal -> on
        // invalide pour reactiver le bouton "Optimiser". Un simple
        // changement de nom / capacite ne touche pas a la geometrie.
        final initial = widget.initial!;
        final geometryChanged = initial.pointDepartLat != _depart!.lat ||
            initial.pointDepartLng != _depart!.lon ||
            initial.profilOrs != _profilOrs ||
            initial.eviterPeages != _eviterPeages;
        await repo.update(initial.id, companion);
        if (geometryChanged) {
          await repo.invalidateOptimization(initial.id);
        }
      } else {
        await repo.create(companion);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'enregistrement : $e')),
      );
    }
  }
}

class _DangerButton extends StatelessWidget {
  const _DangerButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red,
          side: const BorderSide(color: AppColors.red, width: 1.5),
          minimumSize: const Size(0, 52),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.r14)),
          ),
        ),
        icon: const Icon(Icons.delete_outline),
        label: Text(label),
      ),
    );
  }
}
