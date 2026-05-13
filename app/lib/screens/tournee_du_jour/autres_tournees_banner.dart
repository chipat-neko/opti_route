import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../tournee_du_jour_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Bandeau "N autres tournees aujourd'hui" — switcher rapide.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche en haut de l'ecran un bandeau cream cliquable quand il
/// existe d'autres tournees programmees pour la meme date que celle
/// affichee. Tap -> bottom sheet listant ces autres tournees, avec
/// pour chacune le nom + le statut (BROUILLON, OPTIMISEE, EN COURS,
/// TERMINEE) colore. Tap sur une entree de la sheet : pushReplacement
/// vers le TourneeDuJourScreen correspondant.
///
/// Si aucune autre tournee n'existe ce jour-la, le bandeau retourne
/// `SizedBox.shrink()` (rien affiche).
///
/// Use case typique : chef d'equipe qui prepare 4 tournees pour 4
/// coequipiers le matin, et veut pouvoir basculer rapidement de
/// l'une a l'autre sans repasser par la liste generale.
class AutresTourneesDuJourBanner extends ConsumerWidget {
  const AutresTourneesDuJourBanner({
    super.key,
    required this.currentTourneeId,
  });

  /// Id de la tournee actuellement affichee, qu'on exclut de la
  /// liste des "autres".
  final int currentTourneeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    // `tourneesDuJourProvider` est un Provider sync qui filtre les
    // tournees par la date d'aujourd'hui. Si la tournee courante est
    // la seule, on n'affiche rien.
    final all = ref.watch(tourneesDuJourProvider);
    final autres = all.where((t) => t.id != currentTourneeId).toList();
    if (autres.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x10),
      child: Material(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r10),
          onTap: () => _showSwitcher(context, autres),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x12,
              vertical: AppSpacing.x10,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.swap_horiz,
                  color: p.ink,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: Text(
                    autres.length == 1
                        ? '1 autre tournee aujourd\'hui'
                        : '${autres.length} autres tournees aujourd\'hui',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: p.textMute,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ouvre la bottom sheet contenant la liste cliquable des autres
  /// tournees du jour. Chaque entree affiche nom + statut, tap =
  /// `pushReplacement` vers le TourneeDuJourScreen choisi (on
  /// remplace la route courante, pas d'empilement).
  Future<void> _showSwitcher(
    BuildContext context,
    List<Tournee> autres,
  ) async {
    final p = context.palette;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x18,
            AppSpacing.x14,
            AppSpacing.x18,
            AppSpacing.x18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle indicatif (la petite barre grise en haut).
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: p.inkLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Autres tournees du jour',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              // Liste des autres tournees, chacune est une card
              // tappable qui bascule vers l'ecran correspondant.
              for (final t in autres) ...[
                Material(
                  color: p.paper,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => TourneeDuJourScreen(tournee: t),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.x12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.nom,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _statutLabel(t.statut),
                                  style: appMonoStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _statutColor(t.statut),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right,
                            color: p.textMute,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Label d'affichage pour un statut de tournee. Majuscules pour la
  /// chip mono dans la sheet (visuel "code").
  static String _statutLabel(String s) => switch (s) {
        'brouillon' => 'BROUILLON',
        'optimisee' => 'OPTIMISEE',
        'en_cours' => 'EN COURS',
        'terminee' => 'TERMINEE',
        _ => s.toUpperCase(),
      };

  /// Couleur associee a un statut : emerald pour "actif" (en cours,
  /// terminee), ink pour optimisee (pret a demarrer), textMute pour
  /// les brouillons.
  static Color _statutColor(String s) => switch (s) {
        'en_cours' => AppColors.emerald,
        'terminee' => AppColors.emerald,
        'optimisee' => AppColors.ink,
        _ => AppColors.textMute,
      };
}
