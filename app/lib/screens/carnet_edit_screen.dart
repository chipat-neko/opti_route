import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/address_suggestion.dart';
import '../data/database.dart';
import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/address_autocomplete_field.dart';

/// Edition manuelle d'une entree du carnet : on peut modifier le nom
/// du client et/ou re-geocoder l'adresse, ou supprimer l'entree.
class CarnetEditScreen extends ConsumerStatefulWidget {
  const CarnetEditScreen({super.key, required this.entry});

  final SavedDestination entry;

  @override
  ConsumerState<CarnetEditScreen> createState() => _CarnetEditScreenState();
}

class _CarnetEditScreenState extends ConsumerState<CarnetEditScreen> {
  late final TextEditingController _nomCtrl;
  AddressSuggestion? _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _nomCtrl = TextEditingController(text: e.nomClient ?? '');
    _address = AddressSuggestion(
      displayName: e.adresseDisplay,
      lat: e.lat,
      lon: e.lng,
      road: e.rue,
      postcode: e.codePostal,
      city: e.ville,
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier l\'adresse'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: [
          TextField(
            controller: _nomCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom du client / enseigne',
              hintText: 'Ex: Carrosserie Coculo',
              helperText: 'Peut etre vide si tu memorises juste l\'adresse.',
              helperMaxLines: 2,
            ),
          ),
          const SizedBox(height: AppSpacing.x18),
          AddressAutocompleteField(
            labelText: 'Adresse',
            hintText: 'Tape la rue, la ville...',
            initialDisplayText: widget.entry.adresseDisplay,
            initialSuggestion: _address,
            onSuggestionSelected: (s) => setState(() => _address = s),
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
            label: const Text('Enregistrer'),
          ),
          const SizedBox(height: AppSpacing.x18),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.red,
              side: const BorderSide(color: AppColors.red, width: 1.5),
              minimumSize: const Size(0, 52),
            ),
            onPressed: _saving ? null : _confirmDelete,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Supprimer du carnet'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (_address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choisis une adresse')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(savedDestinationsRepositoryProvider).update(
            widget.entry.id,
            nomClient: _nomCtrl.text.trim(),
            adresseDisplay: _address!.adressePostale,
            lat: _address!.lat,
            lng: _address!.lon,
            rue: _address!.road ?? '',
            codePostal: _address!.postcode ?? '',
            ville: _address!.city ?? '',
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer du carnet ?'),
        content: const Text(
          'Cette adresse ne sera plus suggeree quand tu cherches dans '
          'le champ Adresse. Tu peux toujours la re-saisir manuellement.',
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
    await ref
        .read(savedDestinationsRepositoryProvider)
        .delete(widget.entry.id);
    if (!mounted) return;
    Navigator.of(context).pop();
  }
}
