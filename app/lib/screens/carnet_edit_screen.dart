import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/address_suggestion.dart';
import '../data/database.dart';
import '../data/saved_destinations_repository.dart';
import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
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
  late final TextEditingController _notesCarnetCtrl;
  late final TextEditingController _codeAccesCtrl;
  late final TextEditingController _etageCtrl;
  late final TextEditingController _tagsCtrl;
  AddressSuggestion? _address;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _nomCtrl = TextEditingController(text: e.nomClient ?? '');
    _notesCarnetCtrl = TextEditingController(text: e.notesCarnet ?? '');
    _codeAccesCtrl = TextEditingController(text: e.codeAcces ?? '');
    _etageCtrl = TextEditingController(text: e.etageBatiment ?? '');
    final initialTags = SavedDestinationsRepository.parseTags(e.tagsJson);
    _tagsCtrl = TextEditingController(text: initialTags.join(', '));
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
    _notesCarnetCtrl.dispose();
    _codeAccesCtrl.dispose();
    _etageCtrl.dispose();
    _tagsCtrl.dispose();
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
          _ClientStatsBlock(savedDestinationId: widget.entry.id),
          const SizedBox(height: AppSpacing.x18),
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
          const SizedBox(height: AppSpacing.x18),
          // Code d'acces (interphone, portail) - mis en gros dans la
          // fiche pour etre rapidement lisible en livraison.
          TextField(
            controller: _codeAccesCtrl,
            decoration: const InputDecoration(
              labelText: 'Code d\'acces (interphone / portail)',
              hintText: 'Ex: 1234B',
              prefixIcon: Icon(Icons.lock_outlined),
            ),
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: AppSpacing.x14),
          // Etage / batiment / appartement
          TextField(
            controller: _etageCtrl,
            decoration: const InputDecoration(
              labelText: 'Batiment / etage (optionnel)',
              hintText: 'Ex: Bat C, 3e etage, app. 12',
              prefixIcon: Icon(Icons.apartment_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          // Tags libres, separes par virgules dans l'UI, stockes en JSON.
          TextField(
            controller: _tagsCtrl,
            decoration: const InputDecoration(
              labelText: 'Tags (optionnel)',
              hintText: 'Ex: pro, fragile, prioritaire',
              helperText: 'Separe les tags par des virgules. '
                  'Sert a filtrer la liste du carnet.',
              helperMaxLines: 2,
              prefixIcon: Icon(Icons.local_offer_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.x18),
          TextField(
            controller: _notesCarnetCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes pre-definies (optionnel)',
              hintText: 'Code 1234B · sonner 2 fois · porte garage',
              helperText:
                  'Pre-remplies dans le champ Notes a chaque nouvel '
                  'arret cree pour ce client. Modifiables au cas par cas.',
              helperMaxLines: 3,
            ),
            maxLines: 3,
          ),
          const SizedBox(height: AppSpacing.x18),
          // Picker de couleur pour reperer visuellement le client
          // dans la liste du carnet.
          Text(
            'Couleur (optionnel)',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.x8),
          _ColorPicker(
            currentTag: widget.entry.colorTag,
            onPicked: (tag) async {
              await ref
                  .read(savedDestinationsRepositoryProvider)
                  .setColorTag(widget.entry.id, tag);
              if (!context.mounted) return;
              setState(() {});
            },
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
      final repo = ref.read(savedDestinationsRepositoryProvider);
      await repo.update(
        widget.entry.id,
        nomClient: _nomCtrl.text.trim(),
        adresseDisplay: _address!.adressePostale,
        lat: _address!.lat,
        lng: _address!.lon,
        rue: _address!.road ?? '',
        codePostal: _address!.postcode ?? '',
        ville: _address!.city ?? '',
        notesCarnet: _notesCarnetCtrl.text.trim(),
        codeAcces: _codeAccesCtrl.text.trim(),
        etageBatiment: _etageCtrl.text.trim(),
      );
      // Tags : on parse la saisie "tag1, tag2, tag3" en liste, on filtre
      // les vides + duplicats (case-insensitive), puis on persiste.
      final rawTags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      final seen = <String>{};
      final tags = <String>[];
      for (final t in rawTags) {
        final k = t.toLowerCase();
        if (seen.add(k)) tags.add(t);
      }
      await repo.setTags(widget.entry.id, tags);

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

/// Mini-dashboard "historique des livraisons chez ce client" affiche
/// en haut de l'ecran d'edition. Recupere les stats via le provider
/// (qui fait le matching nom + coords) et affiche : nb livraisons,
/// nb echecs, derniere visite, top 3 raisons d'echec.
class _ClientStatsBlock extends ConsumerWidget {
  const _ClientStatsBlock({required this.savedDestinationId});

  final int savedDestinationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final statsAsync = ref.watch(clientStatsProvider(savedDestinationId));
    return statsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (stats) {
        if (stats.isEmpty) {
          return const SizedBox.shrink();
        }
        final tauxPct = (stats.tauxReussite * 100).toStringAsFixed(0);
        final dernier = stats.derniereLivraison == null
            ? ' - '
            : DateFormat('dd/MM/yyyy', 'fr')
                .format(stats.derniereLivraison!);
        return Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: p.creamSoft,
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'HISTORIQUE CHEZ CE CLIENT',
                style: appMonoStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: p.textMute,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      label: 'Livraisons',
                      value: '${stats.nbLivraisons}',
                      color: AppColors.emerald,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Echecs',
                      value: '${stats.nbEchecs}',
                      color: stats.nbEchecs > 0
                          ? AppColors.red
                          : p.textMute,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      label: 'Reussite',
                      value: '$tauxPct%',
                      color: p.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                'Derniere visite : $dernier',
                style: TextStyle(
                  fontSize: 12,
                  color: p.textMute,
                ),
              ),
              if (stats.raisonsEchecCourantes.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.x6),
                Text(
                  'Echecs frequents : ${stats.raisonsEchecCourantes.map((r) => "${r.raison} (${r.n})").join(", ")}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.red,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: appMonoStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: p.textMute,
            letterSpacing: 0.4,
          ),
        ),
        Text(
          value,
          style: appMonoStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

/// Picker de couleur en cercle pour le `colorTag` du client. Tap sur
/// "Aucune" reset au default. Le cercle selectionne a un anneau ink
/// autour.
class _ColorPicker extends StatelessWidget {
  const _ColorPicker({required this.currentTag, required this.onPicked});

  final String? currentTag;
  final ValueChanged<String?> onPicked;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Wrap(
      spacing: AppSpacing.x8,
      runSpacing: AppSpacing.x8,
      children: [
        // Bouton "Aucune" : cercle rayÃ© cream
        _ColorDot(
          color: p.creamSoft,
          selected: currentTag == null,
          label: 'Aucune',
          onTap: () => onPicked(null),
        ),
        for (final (tag, color) in colorTagOptions)
          _ColorDot(
            color: color,
            selected: currentTag == tag,
            label: tag,
            onTap: () => onPicked(tag),
          ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(color: p.ink, width: 3)
              : Border.all(color: p.inkLine, width: 1),
        ),
        child: selected
            ? Icon(Icons.check, size: 18, color: p.ink)
            : null,
      ),
    );
  }
}
