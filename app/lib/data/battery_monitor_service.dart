import 'dart:async';

import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'notifications_service.dart';

/// Resultat de la decision d'alerte batterie : faut-il notifier, et quel
/// est le nouvel etat "deja alerte" (pour le debounce).
class LowBatteryDecision {
  const LowBatteryDecision({required this.notify, required this.alerted});
  final bool notify;
  final bool alerted;
}

/// Logique PURE de l'alerte batterie faible (carte #258), extraite pour
/// etre testable sans le plugin natif.
///
/// - notifie UNE fois quand le niveau passe `<= threshold` en decharge ;
/// - ne re-notifie pas tant qu'on n'est pas remonte au-dessus de
///   `resetAbove` (ou repasse en charge) -> evite le spam si le niveau
///   oscille autour du seuil.
LowBatteryDecision evaluateLowBattery({
  required int level,
  required bool discharging,
  required bool alreadyAlerted,
  int threshold = 15,
  int resetAbove = 20,
}) {
  // Remontee franche OU branche en charge -> on re-arme l'alerte.
  if (level > resetAbove || !discharging) {
    return const LowBatteryDecision(notify: false, alerted: false);
  }
  // Sous le seuil en decharge.
  if (level <= threshold) {
    if (alreadyAlerted) {
      return const LowBatteryDecision(notify: false, alerted: true);
    }
    return const LowBatteryDecision(notify: true, alerted: true);
  }
  // Zone tampon (threshold < level <= resetAbove) en decharge : on garde
  // l'etat courant sans rien faire.
  return LowBatteryDecision(notify: false, alerted: alreadyAlerted);
}

/// Surveille le niveau de batterie et declenche une notification quand il
/// passe sous un seuil bas en tournee (carte #258). On-device, gratuit.
///
/// Verifie a chaque changement d'etat (charge/decharge) + toutes les
/// 3 min tant que l'app tourne (le Timer Dart se met en pause quand l'app
/// est en arriere-plan, ce qui est exactement le comportement voulu : on
/// alerte quand Noah utilise l'app).
class BatteryMonitorService {
  BatteryMonitorService({Battery? battery, NotificationsService? notifications})
      : _battery = battery ?? Battery(),
        _notifications = notifications ?? NotificationsService.instance;

  final Battery _battery;
  final NotificationsService _notifications;

  StreamSubscription<BatteryState>? _stateSub;
  Timer? _pollTimer;
  bool _alerted = false;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _stateSub =
        _battery.onBatteryStateChanged.listen((_) => unawaited(_check()));
    _pollTimer =
        Timer.periodic(const Duration(minutes: 3), (_) => unawaited(_check()));
    unawaited(_check());
  }

  Future<void> _check() async {
    try {
      final level = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      final decision = evaluateLowBattery(
        level: level,
        discharging: state == BatteryState.discharging,
        alreadyAlerted: _alerted,
      );
      _alerted = decision.alerted;
      if (decision.notify) {
        await _notifications.showLowBatteryAlert(level: level);
      }
    } catch (e) {
      // Pas de batterie (desktop / web / emulateur) ou plugin indispo :
      // no-op silencieux.
      if (kDebugMode) debugPrint('[BatteryMonitor] check skip : $e');
    }
  }

  void dispose() {
    _stateSub?.cancel();
    _pollTimer?.cancel();
  }
}

/// Demarre la surveillance batterie a la 1ere lecture (auto-start, comme
/// l'automate de re-geocodage). `main.dart` fait `ref.read(...)` au build.
final batteryMonitorServiceProvider = Provider<BatteryMonitorService>((ref) {
  final svc = BatteryMonitorService()..start();
  ref.onDispose(svc.dispose);
  return svc;
});
