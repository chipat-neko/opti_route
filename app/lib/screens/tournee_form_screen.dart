import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../providers/database_providers.dart';

class TourneeFormScreen extends ConsumerStatefulWidget {
  const TourneeFormScreen({super.key, this.initial});

  final Tournee? initial;

  @override
  ConsumerState<TourneeFormScreen> createState() => _TourneeFormScreenState();
}

class _TourneeFormScreenState extends ConsumerState<TourneeFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomCtrl;
  late final TextEditingController _labelCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  late final TextEditingController _capaciteCtrl;
  late DateTime _date;
  bool _saving = false;

  bool get _isEdit => widget.initial != null;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _nomCtrl = TextEditingController(text: t?.nom ?? '');
    _labelCtrl = TextEditingController(text: t?.pointDepartLabel ?? '');
    _latCtrl = TextEditingController(text: t?.pointDepartLat.toString() ?? '');
    _lngCtrl = TextEditingController(text: t?.pointDepartLng.toString() ?? '');
    _capaciteCtrl =
        TextEditingController(text: (t?.vehiculeCapaciteColis ?? 0).toString());
    _date = t?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _labelCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
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
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Nom *',
                hintText: 'Ex: Tournee Mardi 12/05',
              ),
              textInputAction: TextInputAction.next,
              validator: _validateNom,
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date *'),
              subtitle: Text(dateFormat.format(_date)),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDate,
            ),
            const Divider(),
            const SizedBox(height: 8),
            Text(
              'Point de depart',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Adresse / libelle *',
                hintText: 'Ex: Depot Paris 11',
              ),
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Indique l\'adresse de depart'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latCtrl,
                    decoration: const InputDecoration(labelText: 'Latitude *'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (v) => _validateCoord(v, -90, 90),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngCtrl,
                    decoration: const InputDecoration(labelText: 'Longitude *'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                      signed: true,
                    ),
                    validator: (v) => _validateCoord(v, -180, 180),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Au jalon 5 le geocodage rendra ces deux champs automatiques.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Divider(height: 32),
            TextFormField(
              controller: _capaciteCtrl,
              decoration: const InputDecoration(
                labelText: 'Capacite vehicule (colis)',
                helperText: 'Nombre maximum de colis transportables. 0 = illimite.',
              ),
              keyboardType: TextInputType.number,
              validator: _validatePositiveInt,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
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

  String? _validateCoord(String? v, double min, double max) {
    final s = v?.trim().replaceAll(',', '.') ?? '';
    if (s.isEmpty) return 'Requis';
    final n = double.tryParse(s);
    if (n == null) return 'Nombre invalide';
    if (n < min || n > max) return 'Entre $min et $max';
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
    setState(() => _saving = true);

    final repo = ref.read(tourneesRepositoryProvider);
    final companion = TourneesCompanion(
      nom: Value(_nomCtrl.text.trim()),
      date: Value(_date),
      pointDepartLat:
          Value(double.parse(_latCtrl.text.trim().replaceAll(',', '.'))),
      pointDepartLng:
          Value(double.parse(_lngCtrl.text.trim().replaceAll(',', '.'))),
      pointDepartLabel: Value(_labelCtrl.text.trim()),
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
