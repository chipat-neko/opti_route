import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import 'lock_screen.dart';

/// Wrap le contenu d'app et intercale un [LockScreen] si :
/// - le verrou est actif ET
/// - on est au cold start OU on revient au foreground apres N minutes
///   d'inactivite (auto-lock).
///
/// Place le widget aussi haut que possible dans l'arbre (juste apres
/// `MaterialApp` via le builder), pour qu'il couvre toutes les routes.
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate>
    with WidgetsBindingObserver {
  bool _locked = true;
  DateTime? _backgroundedAt;
  bool _initialCheckDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _initialCheck() async {
    final svc = ref.read(securityServiceProvider);
    final enabled = await svc.isLockEnabled();
    if (!mounted) return;
    setState(() {
      _locked = enabled;
      _initialCheckDone = true;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      _maybeAutoLock();
    }
  }

  Future<void> _maybeAutoLock() async {
    if (_locked) return;
    final since = _backgroundedAt;
    _backgroundedAt = null;
    if (since == null) return;
    final svc = ref.read(securityServiceProvider);
    if (!await svc.isLockEnabled()) return;
    final params = ref.read(parametresRepositoryProvider);
    final minutes = await params.getAutoLockMinutes();
    if (minutes <= 0) return;
    final elapsed = DateTime.now().difference(since);
    if (elapsed.inMinutes >= minutes) {
      if (!mounted) return;
      setState(() => _locked = true);
    }
  }

  void _onUnlocked() {
    setState(() {
      _locked = false;
      _backgroundedAt = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Carte #268 : tant que le check verrou async n'est pas termine, on
    // affiche un ecran neutre -> on ne flashe NI le contenu protege (a un
    // user verrouille) NI le LockScreen (a un user sans verrou). Le check
    // = un simple read DB, donc ~1 frame en pratique (apres le splash
    // natif). Prend le relais du splash sans montrer de donnees.
    if (!_initialCheckDone) return const Scaffold();
    if (!_locked) return widget.child;
    return LockScreen(onUnlocked: _onUnlocked);
  }
}
