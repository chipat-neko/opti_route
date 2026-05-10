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

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _nomCtrl = TextEditingController(text: t?.nom ?? '');
    _capaciteCtrl =
        TextEditingController(text: (t?.vehiculeCapaciteColis ?? 0).toString());
    _date = t?.date ?? DateTime.now();
    if (t != null) {
      _depart = AddressSuggestion(
        displayName: t.pointDepartLabel,
        lat: t.pointDepartLat,
        lon: t.pointDepartLng,
      );
    }
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _capaciteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          ],
        ),
      ),
    );
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
    );

    try {
      if (_isEdit) {
        await repo.update(widget.initial!.id, companion);
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
