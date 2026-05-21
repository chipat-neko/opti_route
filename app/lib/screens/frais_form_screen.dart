import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter, HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
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
