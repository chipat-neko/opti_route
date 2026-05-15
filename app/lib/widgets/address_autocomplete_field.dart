import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:latlong2/latlong.dart';

import '../data/address_suggestion.dart';
import '../data/database.dart';
import '../data/geocoding_service.dart';
import '../providers/database_providers.dart';
import '../providers/geocoding_providers.dart';
import '../screens/pointer_carte_screen.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Champ texte d'adresse avec autocomplete Nominatim.
///
/// L'utilisateur ne saisit qu'une adresse libre ; les coordonnees GPS
/// sont calculees automatiquement et exposees via [onSuggestionSelected].
/// Le formulaire parent ne doit pas valider tant qu'une suggestion n'a
/// pas ete choisie (la selection invalide a chaque keystroke).
class AddressAutocompleteField extends ConsumerStatefulWidget {
  const AddressAutocompleteField({
    super.key,
    required this.labelText,
    required this.onSuggestionSelected,
    this.hintText,
    this.initialDisplayText,
    this.initialSuggestion,
  });

  final String labelText;
  final String? hintText;

  /// Texte initial du champ, par exemple en mode edition.
  /// Si [initialSuggestion] est non null, on l'utilise et on considere
  /// le champ comme deja valide.
  final String? initialDisplayText;
  final AddressSuggestion? initialSuggestion;

  /// Appele a chaque selection (ou null quand l'utilisateur invalide
  /// en re-editant le texte).
  final ValueChanged<AddressSuggestion?> onSuggestionSelected;

  @override
  ConsumerState<AddressAutocompleteField> createState() =>
      _AddressAutocompleteFieldState();
}

class _AddressAutocompleteFieldState
    extends ConsumerState<AddressAutocompleteField> {
  static const _debounce = Duration(milliseconds: 400);

  late final TextEditingController _controller;
  Timer? _debounceTimer;
  List<AddressSuggestion> _suggestions = const [];
  bool _loading = false;
  String? _errorMessage;
  AddressSuggestion? _selected;

  /// Query la plus recente envoyee en recherche. Sert a ignorer les
  /// resultats out-of-order : si l'utilisateur tape "A" puis "B" alors
  /// que la recherche "A" est encore en flight, on rejette "A" quand
  /// il finit (sinon on overwrite les resultats "B" avec du stale).
  String _activeQuery = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initialDisplayText ?? '';
    _controller = TextEditingController(text: initial);
    _selected = widget.initialSuggestion;

    // Si on a un texte initial mais pas de suggestion validee
    // (typiquement : retour d'un scan OCR), on lance automatiquement
    // l'autocomplete dessus.
    if (widget.initialSuggestion == null && initial.trim().length >= 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _runSearch(initial);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _handleChange(String value) {
    if (_selected != null) {
      _selected = null;
      widget.onSuggestionSelected(null);
    }
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounce, () => _runSearch(value));
  }

  Future<void> _runSearch(String query) async {
    _activeQuery = query;
    if (query.trim().length < 2) {
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _errorMessage = null;
        _loading = false;
      });
      return;
    }

    // Etape 1 : carnet local (instantane). On l'affiche tout de suite,
    // l'API distante viendra completer ensuite.
    final carnetRepo = ref.read(savedDestinationsRepositoryProvider);
    final localResults = await carnetRepo.search(query, limit: 5);
    if (_activeQuery != query) return; // user a tape, on jette ce stale
    final localSuggestions = localResults.map(_carnetToSuggestion).toList();

    if (!mounted) return;
    setState(() {
      _suggestions = localSuggestions;
      _loading = query.trim().length >= 3;
      _errorMessage = null;
    });

    // Etape 2 : recherche distante (BAN/SIRENE/Photon) seulement a
    // partir de 3 caracteres (l'API limite ses requetes).
    if (query.trim().length < 3) return;

    try {
      final service = ref.read(geocodingServiceProvider);
      final remote = await service.search(query);
      if (!mounted) return;
      if (_activeQuery != query) return; // user a tape, abandon
      // Dedup : on retire les resultats distants dont les coords sont
      // tres proches (< ~11m) d'une suggestion locale.
      final dedupedRemote = remote.where((r) {
        return !localSuggestions.any((l) =>
            (l.lat - r.lat).abs() < 0.0001 &&
            (l.lon - r.lon).abs() < 0.0001);
      }).toList();

      setState(() {
        _suggestions = [...localSuggestions, ...dedupedRemote];
        _loading = false;
        _errorMessage = (_suggestions.isEmpty)
            ? 'Pas trouve. Si c\'est un commerce inconnu de nos sources, '
                'tape l\'adresse postale du colis ici et mets le nom dans '
                '"Client / Enseigne".'
            : null;
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      if (_activeQuery != query) return;
      setState(() {
        // On garde les suggestions locales meme si l'API distante echoue.
        _errorMessage = localSuggestions.isEmpty ? e.message : null;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      if (_activeQuery != query) return;
      setState(() {
        _errorMessage =
            localSuggestions.isEmpty ? 'Erreur reseau, reessaie' : null;
        _loading = false;
      });
    }
  }

  /// Convertit une entree du carnet local en `AddressSuggestion` pour
  /// pouvoir la traiter de maniere uniforme dans l'UI.
  AddressSuggestion _carnetToSuggestion(SavedDestination d) {
    return AddressSuggestion(
      displayName: d.adresseDisplay,
      lat: d.lat,
      lon: d.lng,
      road: d.rue,
      postcode: d.codePostal,
      city: d.ville,
      poiName: d.nomClient,
      fromCarnet: true,
      notesCarnet: d.notesCarnet,
    );
  }

  void _selectSuggestion(AddressSuggestion suggestion) {
    setState(() {
      _selected = suggestion;
      _controller.text = suggestion.displayName;
      _suggestions = const [];
      _errorMessage = null;
    });
    widget.onSuggestionSelected(suggestion);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isValid = _selected != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: widget.labelText,
            hintText: widget.hintText,
            prefixIcon: Icon(
              Icons.place_outlined,
              color: isValid ? AppColors.emerald : p.ink,
            ),
            suffixIcon: _buildSuffix(isValid),
            errorText: _errorMessage,
          ),
          textInputAction: TextInputAction.search,
          onChanged: _handleChange,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Saisis une adresse';
            }
            if (_selected == null) {
              return 'Choisis une suggestion dans la liste';
            }
            return null;
          },
        ),
        if (_suggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x8),
          Container(
            decoration: BoxDecoration(
              color: p.paper,
              borderRadius: BorderRadius.circular(AppRadius.r14),
              border: Border.all(color: p.divider),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _suggestions.length; i++) ...[
                  _SuggestionTile(
                    suggestion: _suggestions[i],
                    onTap: () => _selectSuggestion(_suggestions[i]),
                  ),
                  if (i < _suggestions.length - 1)
                    const Divider(height: 1, indent: AppSpacing.x16),
                ],
              ],
            ),
          ),
        ],
        if (isValid) ...[
          const SizedBox(height: AppSpacing.x6),
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 14,
                color: AppColors.emerald,
              ),
              const SizedBox(width: AppSpacing.x6),
              Expanded(
                child: Text(
                  'Adresse validee',
                  style: appMonoStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.emerald,
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          // Quand pas (encore) de selection : bouton de fallback pour
          // pointer manuellement sur la carte. Indispensable quand
          // l'autocomplete n'a rien (lieu sans adresse postale, hangar
          // industriel, contremarque mal indexee...).
          const SizedBox(height: AppSpacing.x6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _openPointerCarte,
              icon: const Icon(Icons.touch_app_outlined, size: 16),
              label: const Text(
                'Pointer sur la carte',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                foregroundColor: p.ink,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.x10,
                  vertical: 4,
                ),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _openPointerCarte() async {
    // Si on a deja une suggestion locale, on centre la carte dessus
    // pour eviter a Noah de re-zoomer depuis la France entiere.
    LatLng? initialCenter;
    if (_selected != null) {
      initialCenter = LatLng(_selected!.lat, _selected!.lon);
    } else if (_suggestions.isNotEmpty) {
      final s = _suggestions.first;
      initialCenter = LatLng(s.lat, s.lon);
    }
    final result = await Navigator.of(context).push<AddressSuggestion>(
      MaterialPageRoute(
        builder: (_) => PointerCarteScreen(initialCenter: initialCenter),
      ),
    );
    if (result == null || !mounted) return;
    _selectSuggestion(result);
  }

  Widget? _buildSuffix(bool isValid) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.x12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (isValid) {
      return const Icon(Icons.check, color: AppColors.emerald);
    }
    return null;
  }
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.suggestion, required this.onTap});

  final AddressSuggestion suggestion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final isPoi = suggestion.isPoi;
    final hasNumber = suggestion.houseNumber != null &&
        suggestion.houseNumber!.isNotEmpty;

    final fromCarnet = suggestion.fromCarnet;
    final iconBg = fromCarnet
        ? AppColors.lime
        : (isPoi ? AppColors.emeraldSoft : (hasNumber ? AppColors.lime : p.creamSoft));
    final iconColor = fromCarnet
        ? p.ink
        : (isPoi
            ? AppColors.emerald
            : (hasNumber ? p.ink : p.textMute));
    final iconData = fromCarnet
        ? Icons.bookmark
        : (isPoi ? Icons.storefront_outlined : Icons.place_outlined);

    final secondary = (fromCarnet || isPoi)
        ? _poiAddressLine(suggestion)
        : suggestion.secondaryLabel;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.r14),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x14,
          vertical: AppSpacing.x12,
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.r8),
              ),
              child: Icon(iconData, size: 16, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.x12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.primaryLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: p.ink,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (secondary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        secondary,
                        style: appMonoStyle(
                          fontSize: 11,
                          color: p.textMute,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (fromCarnet)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _Badge(
                        label: 'DEJA LIVRE',
                        bg: AppColors.lime,
                        fg: p.ink,
                      ),
                    )
                  else if (isPoi)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _Badge(
                        label: 'COMMERCE',
                        bg: AppColors.emeraldSoft,
                        fg: AppColors.emerald,
                      ),
                    )
                  else if (!hasNumber)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _Badge(
                        label: 'SANS NUMERO',
                        bg: AppColors.amber.withValues(alpha: 0.2),
                        fg: AppColors.amber.withValues(alpha: 0.95),
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.north_west,
              size: 16,
              color: p.textFaint,
            ),
          ],
        ),
      ),
    );
  }

  /// Pour un POI, on construit une sub-line lisible : numero + rue +
  /// postcode + ville. Plus riche que le secondaryLabel par defaut.
  String _poiAddressLine(AddressSuggestion s) {
    final parts = <String>[];
    if (s.road != null && s.road!.isNotEmpty) {
      parts.add(s.houseNumber != null && s.houseNumber!.isNotEmpty
          ? '${s.houseNumber} ${s.road}'
          : s.road!);
    }
    final localityBits = <String>[
      if (s.postcode != null && s.postcode!.isNotEmpty) s.postcode!,
      if (s.city != null && s.city!.isNotEmpty) s.city!,
    ];
    if (localityBits.isNotEmpty) parts.add(localityBits.join(' '));
    if (parts.isEmpty) return s.displayName;
    return parts.join(' · ');
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.bg, required this.fg});

  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
          color: fg,
        ),
      ),
    );
  }
}
