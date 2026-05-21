import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/address_suggestion.dart';
import '../data/database.dart';
import '../providers/database_providers.dart';
import '../providers/geocoding_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/voice_input_button.dart';

/// ════════════════════════════════════════════════════════════════
/// Import bulk d'adresses (copier-coller) dans une tournee.
/// ════════════════════════════════════════════════════════════════
///
/// Workflow Noah : il a une liste de favoris Google Maps qu'il
/// veut transferer dans opti_route. Plutot que de saisir 20 fois
/// l'adresse a la main ou de partager un par un, il :
///   1. Ouvre Google Maps -> Favoris
///   2. Long-press sur chaque adresse -> "Copier l'adresse"
///   3. Colle tout dans cet ecran (1 adresse par ligne)
///   4. Tap "Importer" -> on geocode chaque ligne en parallele
///   5. Toute la tournee est creee avec les arrets pre-remplis
///
/// Aussi utile pour : import depuis un email/SMS du client, un PDF
/// ouvert manuellement, ou n'importe quelle source texte.
///
/// Adresses qui n'ont pas pu etre geocodees -> ajoutees en mode
/// hors-ligne (texte brut, GPS manquant). L'utilisateur peut les
/// re-geocoder plus tard via le bouton "Re-geo" de la tournee.
class BulkPasteScreen extends ConsumerStatefulWidget {
  const BulkPasteScreen({
    super.key,
    required this.tourneeId,
    this.initialText,
  });

  /// Tournee cible : les arrets importes y sont ajoutes.
  final int tourneeId;

  /// Texte pre-rempli dans la textarea (cas : ouverture via share
  /// intent Google Maps avec un nom + URL deja captures).
  final String? initialText;

  @override
  ConsumerState<BulkPasteScreen> createState() => _BulkPasteScreenState();
}

class _BulkPasteScreenState extends ConsumerState<BulkPasteScreen> {
  late final TextEditingController _textCtrl =
      TextEditingController(text: widget.initialText ?? '');
  bool _importing = false;
  int _progress = 0;
  int _total = 0;
  int _failed = 0;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  /// Appende le texte dicte au contenu existant. Si le champ est vide,
  /// pose le texte directement ; sinon ajoute un saut de ligne avant
  /// (1 adresse par ligne, regle du parser). Place le curseur en fin
  /// pour que la prochaine dictee s'ajoute apres.
  void _applyVoiceResult(String spoken) {
    final cleaned = spoken.trim();
    if (cleaned.isEmpty) return;
    final current = _textCtrl.text;
    final separator = (current.isEmpty || current.endsWith('\n')) ? '' : '\n';
    final next = '$current$separator$cleaned';
    _textCtrl.text = next;
    _textCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: next.length),
    );
    setState(() {}); // refresh compteur "X adresses detectees"
  }

  /// Parse le texte multiligne : 1 adresse par ligne, trim, filter
  /// les lignes vides. Skip les lignes qui sont juste des numeros
  /// (probable "1.", "2.") puisque ce ne sont pas des adresses.
  List<String> _parseLines(String raw) {
    return raw
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length >= 3)
        // Ignore les lignes qui ne contiennent que des chiffres / puces
        // ("1.", "•", "-", etc.)
        .where((l) => RegExp(r'[A-Za-zÀ-ÿ]').hasMatch(l))
        .toList();
  }

  Future<void> _doImport() async {
    final lines = _parseLines(_textCtrl.text);
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Colle au moins une adresse (1 par ligne).'),
        ),
      );
      return;
    }
    setState(() {
      _importing = true;
      _progress = 0;
      _total = lines.length;
      _failed = 0;
    });
    final messenger = ScaffoldMessenger.of(context);
    final geocoder = ref.read(geocodingServiceProvider);
    final repo = ref.read(stopsRepositoryProvider);
    final reorder = ref.read(localReorderServiceProvider);

    // Limite la concurrence pour ne pas spam Nominatim (max ~1 req/s
    // par leur politesse). On fait sequentiel avec un petit delai
    // entre chaque pour rester respectueux.
    var inserted = 0;
    for (final line in lines) {
      AddressSuggestion? suggestion;
      try {
        final results = await geocoder.search(line);
        if (results.isNotEmpty) suggestion = results.first;
      } catch (e) {
        debugPrint('[BulkPaste] echec geocode "$line" : $e');
      }
      final companion = StopsCompanion.insert(
        tourneeId: widget.tourneeId,
        adresseBrute: suggestion?.adressePostale ?? line,
        adresseNormalisee: Value(suggestion?.adressePostale ?? line),
        lat: Value(suggestion?.lat),
        lng: Value(suggestion?.lon),
      );
      try {
        await repo.create(companion);
        inserted++;
      } catch (e) {
        debugPrint('[BulkPaste] echec insert "$line" : $e');
      }
      if (suggestion == null) _failed++;
      setState(() => _progress++);
      // 1 req/s pour respecter Nominatim usage policy
      await Future.delayed(const Duration(milliseconds: 1100));
    }

    // Auto-reorder NN+2-opt apres l'import bulk
    await ref
        .read(tourneesRepositoryProvider)
        .invalidateOptimization(widget.tourneeId);
    await reorder.reorder(widget.tourneeId);

    if (!mounted) return;
    HapticFeedback.heavyImpact();
    final failed = _failed;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failed == 0
              ? '$inserted arrets ajoutes a la tournee'
              : '$inserted arrets ajoutes ($failed sans GPS, '
                  'a re-geocoder manuellement)',
        ),
        backgroundColor: failed == 0 ? AppColors.emerald : AppColors.amber,
        duration: const Duration(seconds: 4),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final estimatedSec = _parseLines(_textCtrl.text).length * 2;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Coller plusieurs adresses'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.x12),
                decoration: BoxDecoration(
                  color: AppColors.lime.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.r10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lightbulb_outline,
                            size: 18, color: AppColors.ink),
                        const SizedBox(width: AppSpacing.x8),
                        Text(
                          'Astuce',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: p.ink,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    Text(
                      'Une adresse par ligne. Tu peux copier depuis Google '
                      'Maps (long-press sur l\'epingle → "Copier l\'adresse"), '
                      'un email, un SMS, un PDF...',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textMute,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.x14),
              // Dictee vocale : chaque dictee = une nouvelle ligne dans
              // le champ ci-dessous. Cas d'usage chef d'equipe : il
              // recoit une liste d'adresses par telephone et les
              // enchaine au volant sans avoir a taper.
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Tu peux aussi dicter chaque adresse :',
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textMute,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  VoiceInputButtonOutlined(
                    onResult: _applyVoiceResult,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x10),
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  enabled: !_importing,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Adresses (1 par ligne)',
                    hintText:
                        '14 Impasse du Bois, 28000 Chartres\n'
                        '5 rue de la Paix, 75002 Paris\n'
                        '...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x14),
              if (_importing)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(
                      value: _total == 0 ? 0 : _progress / _total,
                    ),
                    const SizedBox(height: AppSpacing.x6),
                    Text(
                      'Geocodage $_progress / $_total'
                      '${_failed > 0 ? ' ($_failed sans GPS)' : ''}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textMute,
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '${_parseLines(_textCtrl.text).length} adresses '
                      'detectees (~${estimatedSec}s pour geocoder)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: p.textMute,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.x10),
                    FilledButton.icon(
                      onPressed: _textCtrl.text.trim().isEmpty
                          ? null
                          : _doImport,
                      icon: const Icon(Icons.download_for_offline),
                      label: const Text('Importer ces adresses'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 52),
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
