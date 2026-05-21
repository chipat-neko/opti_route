import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show HapticFeedback;
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
    // `tourneesDuJourProvider` est un Provider sync qui filtre les
    // tournees par la date d'aujourd'hui. Si la tournee courante est
    // la seule, on n'affiche rien.
    final all = ref.watch(tourneesDuJourProvider);
    final autres = all.where((t) => t.id != currentTourneeId).toList();
    if (autres.isEmpty) return const SizedBox.shrink();

    // Wrap dans un DragTarget<Stop> : permet de drop un arret deplace
    // depuis la liste (LongPressDraggable dans stops_list.dart). Quand
    // un stop est lache sur le banner :
    //  - 1 seule autre tournee : deplacement direct
    //  - 2+ autres tournees : ouvre la sheet selector
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.x10),
      child: DragTarget<Stop>(
        onWillAcceptWithDetails: (details) =>
            details.data.tourneeId == currentTourneeId,
        onAcceptWithDetails: (details) async {
          HapticFeedback.mediumImpact();
          if (autres.length == 1) {
            await _moveStop(context, ref, details.data, autres.first);
          } else {
            await _pickAndMove(context, ref, details.data, autres);
          }
        },
        builder: (context, candidateData, _) {
          final isHover = candidateData.isNotEmpty;
          return _BannerBody(
            autres: autres,
            isDropHover: isHover,
            onTap: () => _showSwitcher(context, autres),
          );
        },
      ),
    );
  }

  /// Deplace un stop vers une tournee cible. Invalide l'optim source +
  /// dest, relance reorder local, affiche SnackBar de confirmation.
  static Future<void> _moveStop(
    BuildContext context,
    WidgetRef ref,
    Stop stop,
    Tournee target,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = ref.read(stopsRepositoryProvider);
    final tourneesRepo = ref.read(tourneesRepositoryProvider);
    final sourceId = stop.tourneeId;
    await repo.moveToTournee(stop.id, target.id);
    await tourneesRepo.invalidateOptimization(sourceId);
    await tourneesRepo.invalidateOptimization(target.id);
    await ref.read(localReorderServiceProvider).reorder(sourceId);
    await ref.read(localReorderServiceProvider).reorder(target.id);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text('Arret deplace vers "${target.nom}"'),
        backgroundColor: AppColors.emerald,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Affiche une bottom sheet listant les autres tournees du jour pour
  /// que l'utilisateur choisisse la cible du deplacement. Variante de
  /// [_showSwitcher] dediee au drop trans-tournees.
  static Future<void> _pickAndMove(
    BuildContext context,
    WidgetRef ref,
    Stop stop,
    List<Tournee> autres,
  ) async {
    final p = context.palette;
    final picked = await showModalBottomSheet<Tournee>(
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
                'Deplacer vers quelle tournee ?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x10),
              for (final t in autres) ...[
                Material(
                  color: p.paper,
                  borderRadius: BorderRadius.circular(AppRadius.r12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.r12),
                    onTap: () => Navigator.of(sheetContext).pop(t),
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
                          Icon(Icons.chevron_right, color: p.textMute),
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
    if (picked != null && context.mounted) {
      await _moveStop(context, ref, stop, picked);
    }
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

/// Visuel du banner. Reagit a [isDropHover] : passe en lime translucide
/// + bordure lime + icone "deposez ici" quand un stop est traine au
/// dessus. Sinon affichage normal cream creamSoft.
class _BannerBody extends StatelessWidget {
  const _BannerBody({
    required this.autres,
    required this.isDropHover,
    required this.onTap,
  });

  final List<Tournee> autres;
  final bool isDropHover;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.r10),
        border: isDropHover
            ? Border.all(color: AppColors.lime, width: 2)
            : Border.all(color: Colors.transparent, width: 2),
      ),
      child: Material(
        color: isDropHover
            ? AppColors.lime.withValues(alpha: 0.25)
            : p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r10),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.r10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x12,
              vertical: AppSpacing.x10,
            ),
            child: Row(
              children: [
                Icon(
                  isDropHover ? Icons.move_down : Icons.swap_horiz,
                  color: p.ink,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: Text(
                    isDropHover
                        ? 'Deposer ici pour deplacer'
                        : (autres.length == 1
                            ? '1 autre tournee aujourd\'hui'
                            : '${autres.length} autres tournees aujourd\'hui'),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ),
                if (!isDropHover)
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
}
