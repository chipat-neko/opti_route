import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../theme/app_tokens.dart';

/// Helper reutilisable pour afficher des info-bulles guidees au 1er
/// lancement d'un ecran. Idempotent : si `alreadyDoneCheck` retourne
/// true, on ne re-affiche rien.
///
/// Usage typique dans un StatefulWidget :
/// ```dart
/// final fabKey = GlobalKey();
///
/// @override
/// void initState() {
///   super.initState();
///   CoachMarkHelper.showIfFirstTime(
///     context,
///     alreadyDoneCheck: () =>
///         ref.read(parametresRepositoryProvider).getCoachTourneeDone(),
///     markDone: () =>
///         ref.read(parametresRepositoryProvider).setCoachTourneeDone(),
///     steps: [
///       CoachStep(
///         key: fabKey,
///         title: 'Scanner un bordereau',
///         description: 'Appuie ici pour ajouter un arret depuis un...',
///       ),
///     ],
///   );
/// }
///
/// FloatingActionButton(key: fabKey, ...)
/// ```
class CoachMarkHelper {
  CoachMarkHelper._();

  /// Affiche les coach marks SI `alreadyDoneCheck()` retourne false.
  /// `markDone()` est appelé apres validation (finish OU skip) pour ne
  /// plus re-afficher cet ecran.
  ///
  /// Le `addPostFrameCallback` garantit que les widgets cibles sont
  /// rendus (sinon les GlobalKey n'ont pas encore de RenderObject).
  static void showIfFirstTime(
    BuildContext context, {
    required Future<bool> Function() alreadyDoneCheck,
    required Future<void> Function() markDone,
    required List<CoachStep> steps,
  }) async {
    if (steps.isEmpty) return;
    final done = await alreadyDoneCheck();
    if (done) return;
    if (!context.mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      // Filtre les steps dont la GlobalKey n'a pas de currentContext
      // (widget pas encore monté ou retiré entre temps). Evite des
      // crashs si l'ecran ferme avant que les coach marks s'affichent.
      final valid = steps
          .where((s) => s.key.currentContext != null)
          .toList();
      if (valid.isEmpty) return;
      final targets = valid
          .map((s) => TargetFocus(
                identify: s.title,
                keyTarget: s.key,
                shape: ShapeLightFocus.RRect,
                radius: 8,
                contents: [
                  TargetContent(
                    align: s.align,
                    builder: (ctx, controller) {
                      return _CoachContent(
                        title: s.title,
                        description: s.description,
                        onNext: controller.next,
                        onSkip: controller.skip,
                      );
                    },
                  ),
                ],
              ))
          .toList();
      TutorialCoachMark(
        targets: targets,
        colorShadow: AppColors.ink,
        opacityShadow: 0.85,
        paddingFocus: 8,
        hideSkip: false,
        textSkip: 'Passer',
        // On marque comme done a la fin OU au skip (l'utilisateur a
        // vu / decide de ne pas voir, peu importe).
        onFinish: () => markDone(),
        onSkip: () {
          markDone();
          return true;
        },
      ).show(context: context);
    });
  }
}

/// Une etape de coach mark : pointe vers un widget (via [key]),
/// affiche [title] + [description] dans une bulle alignee selon
/// [align] (haut/bas/gauche/droite du widget cible).
class CoachStep {
  const CoachStep({
    required this.key,
    required this.title,
    required this.description,
    this.align = ContentAlign.bottom,
  });

  final GlobalKey key;
  final String title;
  final String description;
  final ContentAlign align;
}

/// Contenu visuel d'une bulle coach mark. Style cohérent avec la
/// palette app : fond cream/paper, accent lime, texte ink.
class _CoachContent extends StatelessWidget {
  const _CoachContent({
    required this.title,
    required this.description,
    required this.onNext,
    required this.onSkip,
  });

  final String title;
  final String description;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            description,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onSkip,
                child: const Text('Passer tout'),
              ),
              const SizedBox(width: AppSpacing.x6),
              FilledButton(
                onPressed: onNext,
                child: const Text('Suivant'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
