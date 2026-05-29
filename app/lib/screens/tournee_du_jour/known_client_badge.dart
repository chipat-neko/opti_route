import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// Badge visuel discret a cote du nom client dans la liste de stops,
/// pour signaler "ce client est deja dans ton carnet, tu l'as deja
/// livre N fois". Carte Trello #94.
///
/// Niveaux :
/// - Pas connu (null ou useCount == 1)  : `SizedBox.shrink()`
/// - useCount 2-3                        : petit point lime 6x6
/// - useCount >= 4                       : etoile lime contour 14px
/// - isFavori (peu importe useCount)     : etoile emerald pleine 14px
///
/// Le lookup carnet est fuzzy (Levenshtein + ratio) via
/// [ClientMemoryService] -> tolerant aux fautes OCR. Le resultat est
/// cache par Riverpod (family par nom) et le carnet n'est charge qu'une
/// fois pour toute la liste (cf `carnetForMatchingProvider`, audit #213),
/// donc pas de re-query a chaque rebuild ni par stop.
class KnownClientBadge extends ConsumerWidget {
  const KnownClientBadge({super.key, required this.nomClient});

  final String? nomClient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nom = nomClient;
    if (nom == null || nom.trim().isEmpty) return const SizedBox.shrink();
    final dest = ref.watch(clientHistoryProvider(nom)).asData?.value;
    if (dest == null) return const SizedBox.shrink();

    if (dest.isFavori) {
      return const Padding(
        padding: EdgeInsets.only(left: AppSpacing.x6),
        child: Tooltip(
          message: 'Client favori',
          child: Icon(Icons.star, color: AppColors.emerald, size: 14),
        ),
      );
    }
    if (dest.useCount >= 4) {
      return Padding(
        padding: const EdgeInsets.only(left: AppSpacing.x6),
        child: Tooltip(
          message: 'Client regulier (livre ${dest.useCount} fois)',
          child: const Icon(Icons.star_outline, color: AppColors.lime, size: 14),
        ),
      );
    }
    if (dest.useCount >= 2) {
      return Padding(
        padding: const EdgeInsets.only(left: AppSpacing.x6),
        child: Tooltip(
          message: 'Deja livre ${dest.useCount} fois',
          child: Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.lime,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
