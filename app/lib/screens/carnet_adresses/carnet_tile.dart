import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../carnet_edit_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets de la liste principale du carnet d'adresses.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `carnet_adresses_screen.dart` :
/// - [CarnetTile]      : ligne complete d'une destination (Dismissible
///                       + InkWell + favori tap + ouverture edit screen)
/// - [CarnetEmptyState]: ecran central "Carnet vide" / "Aucun resultat"

/// Tile d'une entree du carnet : pastille couleur (etiquette ou
/// favori), nom du client + adresse, ligne de bas "Livre N fois -
/// dernier le J/M/A". Swipe a gauche = supprimer (avec confirmation
/// AlertDialog). Tap sur la pastille = toggle favori. Tap ailleurs =
/// ouvre l'ecran d'edition.
class CarnetTile extends ConsumerWidget {
  const CarnetTile({super.key, required this.entry});
  final SavedDestination entry;

  /// "Livre N fois - dernier le J/M/A" (ou juste "Livre N fois" si la
  /// derniere date est null). Donne du contexte temporel en une ligne
  /// dans la liste sans cliquer pour ouvrir la fiche.
  static String _formatLivreLine(SavedDestination e) {
    final base = e.useCount > 1
        ? 'Livre ${e.useCount} fois'
        : 'Livre 1 fois';
    final df = DateFormat('d MMM yy', 'fr');
    return '$base - dernier ${df.format(e.lastUsedAt)}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final nom = entry.nomClient?.trim() ?? '';
    final hasNom = nom.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Dismissible(
        key: ValueKey('carnet-${entry.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x22),
          child: const Icon(Icons.delete_outline, color: AppColors.red),
        ),
        confirmDismiss: (_) async {
          return await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Supprimer du carnet ?'),
                  content: Text(
                    hasNom
                        ? '"$nom" sera supprime du carnet d\'adresses local.'
                        : '"${entry.adresseDisplay}" sera supprime du '
                            'carnet d\'adresses local.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Annuler'),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        backgroundColor:
                            AppColors.red.withValues(alpha: 0.15),
                        foregroundColor: AppColors.red,
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Supprimer'),
                    ),
                  ],
                ),
              ) ??
              false;
        },
        onDismissed: (_) async {
          await ref
              .read(savedDestinationsRepositoryProvider)
              .delete(entry.id);
        },
        child: Material(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => CarnetEditScreen(entry: entry),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => ref
                        .read(savedDestinationsRepositoryProvider)
                        .toggleFavori(entry.id),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        // Priorite : colorTag custom > favori amber >
                        // lime par defaut.
                        color: colorFromTag(
                          entry.colorTag,
                          defaultColor: entry.isFavori
                              ? AppColors.amber
                              : AppColors.lime,
                        ),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        entry.isFavori ? Icons.star : Icons.bookmark,
                        color: p.ink,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (hasNom)
                          Text(
                            nom,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: p.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        Text(
                          entry.adresseDisplay,
                          style: TextStyle(
                            fontSize: hasNom ? 12 : 14,
                            color: hasNom
                                ? p.textMute
                                : p.ink,
                            fontWeight:
                                hasNom ? FontWeight.w500 : FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatLivreLine(entry),
                          style: appMonoStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: p.textFaint,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: p.textFaint),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Etat vide affiche au centre quand la liste est vide. Deux variantes
/// selon `hasQuery` :
/// - hasQuery = false : "Carnet vide" avec invitation a livrer des
///   arrets (le carnet se remplit auto a chaque arret livre)
/// - hasQuery = true  : "Aucun resultat" pour signaler que la recherche
///   ne trouve rien (mais le carnet n'est pas vide en general)
class CarnetEmptyState extends StatelessWidget {
  const CarnetEmptyState({super.key, required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: p.creamSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_outline,
                size: 44,
                color: p.ink,
              ),
            ),
            const SizedBox(height: AppSpacing.x18),
            Text(
              hasQuery ? 'Aucun resultat' : 'Carnet vide',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.x8),
            Text(
              hasQuery
                  ? 'Aucune adresse ne correspond a ta recherche.'
                  : 'Le carnet se remplit automatiquement a chaque arret '
                      'valide. Reviens ici plus tard pour modifier ou '
                      'supprimer une entree.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: p.textMute,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
