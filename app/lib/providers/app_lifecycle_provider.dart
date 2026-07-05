import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Etat premier-plan / arriere-plan de l'app, expose en provider pour que
/// les consommateurs coûteux en batterie (capteur de luminosite, push de
/// presence GPS...) se suspendent quand l'app n'est plus visible —
/// SANS dependre de l'exemption systeme "optimisation batterie"
/// (feat/opti-batterie).
enum AppForeground { foreground, background }

/// Vrai si l'etat de cycle de vie correspond a un arriere-plan REEL.
///
/// - `paused` / `hidden` : l'app n'est plus visible -> arriere-plan.
/// - `resumed` : au premier plan.
/// - `inactive` : etat TRANSITOIRE (bandeau systeme, volet de notifs a
///   demi tire, app switcher qui s'ouvre...). On le traite comme
///   premier-plan pour eviter de couper/relancer les streams a chaque
///   micro-transition (flapping). Le vrai passage en fond emet toujours
///   `paused` ensuite.
///
/// Fonction PURE (testable sans binding Flutter).
bool isAppBackground(AppLifecycleState state) {
  return state == AppLifecycleState.paused ||
      state == AppLifecycleState.hidden;
}

/// Notifier qui observe le cycle de vie de l'app et publie
/// [AppForeground]. S'enregistre comme [WidgetsBindingObserver] au build
/// et se desenregistre a la disposition (jamais avant la fin de l'app en
/// pratique : provider keep-alive).
class AppLifecycleNotifier extends Notifier<AppForeground>
    with WidgetsBindingObserver {
  @override
  AppForeground build() {
    final binding = WidgetsBinding.instance;
    binding.addObserver(this);
    ref.onDispose(() => binding.removeObserver(this));
    // Etat initial : au boot, l'app est au premier plan. On lit l'etat
    // courant du binding si disponible (sinon on assume foreground).
    final current = binding.lifecycleState;
    if (current != null && isAppBackground(current)) {
      return AppForeground.background;
    }
    return AppForeground.foreground;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final next = isAppBackground(state)
        ? AppForeground.background
        : AppForeground.foreground;
    // `state` (parametre) = etat de cycle de vie ; `this.state` = etat
    // du Notifier (AppForeground).
    if (next != this.state) this.state = next;
  }
}

/// Provider (keep-alive) de l'etat premier-plan / arriere-plan.
final appForegroundProvider =
    NotifierProvider<AppLifecycleNotifier, AppForeground>(
  AppLifecycleNotifier.new,
);
