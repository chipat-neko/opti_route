import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ecran de verrouillage : pavé numérique PIN (4-6 chiffres) + bouton
/// biométrie si activée et disponible. Affiche au cold start et au
/// retour foreground après auto-lock.
///
/// L'écran est tres "modal" volontairement : pas de Scaffold avec
/// AppBar/back button. La seule sortie est de réussir l'authentification
/// (le `onUnlocked` callback) — sinon on reste bloqué.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({
    super.key,
    required this.onUnlocked,
    this.allowBiometric = true,
  });

  /// Callback déclenché quand l'utilisateur a saisi le bon PIN ou
  /// reussi l'authentification biometrique.
  final VoidCallback onUnlocked;

  /// Désactive le bouton biométrie. Utile pour le flow "Changer PIN"
  /// où on veut forcer la saisie du PIN actuel.
  final bool allowBiometric;

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  final List<int> _digits = [];
  bool _error = false;
  bool _checking = false;
  bool _biometricAvailable = false;

  static const int _pinLength = 4;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    if (!widget.allowBiometric) return;
    final params = ref.read(parametresRepositoryProvider);
    final svc = ref.read(securityServiceProvider);
    if (!await params.getBiometrieActive()) return;
    if (!await svc.canUseBiometrics()) return;
    if (!mounted) return;
    setState(() => _biometricAvailable = true);
    // Tente automatiquement au premier rendu (UX : pas besoin de tap).
    _tryBiometric();
  }

  Future<void> _tryBiometric() async {
    final svc = ref.read(securityServiceProvider);
    final ok = await svc.authenticateBiometric();
    if (!mounted) return;
    if (ok) {
      HapticFeedback.lightImpact();
      widget.onUnlocked();
    }
  }

  void _addDigit(int d) {
    if (_checking) return;
    if (_digits.length >= 6) return;
    setState(() {
      _digits.add(d);
      _error = false;
    });
    HapticFeedback.selectionClick();
    // Auto-valide a 4 chiffres si PIN 4-digits, sinon attend tap valider.
    if (_digits.length == _pinLength) {
      _tryUnlock();
    }
  }

  void _removeDigit() {
    if (_checking) return;
    if (_digits.isEmpty) return;
    setState(() {
      _digits.removeLast();
      _error = false;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _tryUnlock() async {
    if (_digits.length < _pinLength) return;
    setState(() => _checking = true);
    final svc = ref.read(securityServiceProvider);
    final pin = _digits.join();
    final ok = await svc.verifyPin(pin);
    if (!mounted) return;
    if (ok) {
      HapticFeedback.mediumImpact();
      widget.onUnlocked();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _error = true;
      _checking = false;
      _digits.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: p.creamSoft,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: Column(
              children: [
                const Spacer(),
                // Icone cadenas
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.lime,
                    borderRadius: BorderRadius.circular(AppRadius.r22),
                  ),
                  child: const Icon(
                    Icons.lock_outline_rounded,
                    color: AppColors.ink,
                    size: 36,
                  ),
                ),
                const SizedBox(height: AppSpacing.x18),
                Text(
                  'opti_route',
                  style: appMonoStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.textMute,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: AppSpacing.x6),
                Text(
                  _error ? 'Code incorrect' : 'Saisis ton code',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: _error ? AppColors.red : p.ink,
                  ),
                ),
                const SizedBox(height: AppSpacing.x22),
                _PinDots(filled: _digits.length, error: _error),
                const SizedBox(height: AppSpacing.x28),
                _Keypad(
                  onDigit: _addDigit,
                  onBackspace: _removeDigit,
                  onBiometric: _biometricAvailable ? _tryBiometric : null,
                ),
                const Spacer(),
                if (_checking)
                  const Padding(
                    padding: EdgeInsets.only(bottom: AppSpacing.x18),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.lime,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PinDots extends StatelessWidget {
  const _PinDots({required this.filled, required this.error});

  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_LockScreenState._pinLength, (i) {
        final isFilled = i < filled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: error
                  ? AppColors.red
                  : isFilled
                      ? AppColors.lime
                      : p.divider,
              border: isFilled
                  ? null
                  : Border.all(color: p.textMute.withValues(alpha: 0.4)),
            ),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.onBiometric,
  });

  final void Function(int) onDigit;
  final VoidCallback onBackspace;
  final VoidCallback? onBiometric;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          _row([1, 2, 3], onDigit),
          _row([4, 5, 6], onDigit),
          _row([7, 8, 9], onDigit),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _LeftSpecialKey(onTap: onBiometric),
              _DigitKey(value: 0, onTap: onDigit),
              _BackspaceKey(onTap: onBackspace),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<int> digits, void Function(int) onDigit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _DigitKey(value: d, onTap: onDigit))
          .toList(),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.value, required this.onTap});

  final int value;
  final void Function(int) onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Material(
        color: p.paper,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => onTap(value),
          child: SizedBox(
            width: 72,
            height: 72,
            child: Center(
              child: Text(
                '$value',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: p.ink,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BackspaceKey extends StatelessWidget {
  const _BackspaceKey({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child: InkResponse(
          radius: 36,
          onTap: onTap,
          child: Icon(
            Icons.backspace_outlined,
            size: 22,
            color: p.textMute,
          ),
        ),
      ),
    );
  }
}

class _LeftSpecialKey extends StatelessWidget {
  const _LeftSpecialKey({required this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: SizedBox(
        width: 72,
        height: 72,
        child: onTap == null
            ? const SizedBox.shrink()
            : InkResponse(
                radius: 36,
                onTap: onTap,
                child: Icon(
                  Icons.fingerprint,
                  size: 28,
                  color: AppColors.emerald,
                ),
              ),
      ),
    );
  }
}
