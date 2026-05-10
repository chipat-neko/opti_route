import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/address_suggestion.dart';
import '../data/geocoding_service.dart';
import '../providers/geocoding_providers.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialDisplayText ?? '',
    );
    _selected = widget.initialSuggestion;
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
    if (query.trim().length < 3) {
      if (!mounted) return;
      setState(() {
        _suggestions = const [];
        _errorMessage = null;
        _loading = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final service = ref.read(geocodingServiceProvider);
      final results = await service.search(query);
      if (!mounted) return;
      setState(() {
        _suggestions = results;
        _loading = false;
        _errorMessage = results.isEmpty ? 'Aucune adresse trouvee' : null;
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _suggestions = const [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur reseau, reessaie';
        _suggestions = const [];
        _loading = false;
      });
    }
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
              color: isValid ? AppColors.emerald : AppColors.ink,
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
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.r14),
              border: Border.all(color: AppColors.divider),
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
        ],
      ],
    );
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
    final isPoi = suggestion.isPoi;
    final hasNumber = suggestion.houseNumber != null &&
        suggestion.houseNumber!.isNotEmpty;

    final iconBg =
        isPoi ? AppColors.emeraldSoft : (hasNumber ? AppColors.lime : AppColors.creamSoft);
    final iconColor = isPoi
        ? AppColors.emerald
        : (hasNumber ? AppColors.ink : AppColors.textMute);
    final iconData = isPoi ? Icons.storefront_outlined : Icons.place_outlined;

    final secondary = isPoi ? _poiAddressLine(suggestion) : suggestion.secondaryLabel;

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
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.ink,
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
                          color: AppColors.textMute,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  if (isPoi)
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
            const Icon(
              Icons.north_west,
              size: 16,
              color: AppColors.textFaint,
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
