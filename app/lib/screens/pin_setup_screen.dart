import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../theme/app_tokens.dart';

/// Ecran de creation / changement de PIN.
///
/// Workflow en 2 etapes : 1) saisir un nouveau PIN, 2) le confirmer.
/// A la confirmation, on enregistre via [SecurityService.enableLock].
class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key, this.initialPinLength = 4});

  /// Longueur du PIN a saisir (par defaut 4 chiffres).
  final int initialPinLength;

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final List<int> _firstPin = [];
  final List<int> _confirmPin = [];
  bool _mismatch = false;
  bool _saving = false;

  bool get _confirming => _firstPin.length == widget.initialPinLength;

  List<int> get _current => _confirming ? _confirmPin : _firstPin;

  void _addDigit(int d) {
    if (_saving) return;
    if (_current.length >= widget.initialPinLength) return;
    setState(() {
      _current.add(d);
      _mismatch = false;
    });
    HapticFeedback.selectionClick();
    if (_confirming && _confirmPin.length == widget.initialPinLength) {
      _save();
    }
  }

  void _removeDigit() {
    if (_saving) return;
    if (_current.isEmpty && _confirming) {
      // Revient a l'etape 1 si on backspace l'ecran de confirmation vide.
      setState(() => _firstPin.clear());
      return;
    }
    if (_current.isEmpty) return;
    setState(() {
      _current.removeLast();
      _mismatch = false;
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _save() async {
    if (_firstPin.join() != _confirmPin.join()) {
      HapticFeedback.heavyImpact();
      setState(() {
        _mismatch = true;
        _confirmPin.clear();
      });
      return;
    }
    setState(() => _saving = true);
    final svc = ref.read(securityServiceProvider);
    final ok = await svc.enableLock(_firstPin.join());
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _mismatch = true;
        _firstPin.clear();
        _confirmPin.clear();
      });
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final title = _confirming ? 'Confirme ton code' : 'Choisis un code';
    final subtitle = _confirming
        ? 'Re-saisis pour confirmer'
        : 'Un code a ${widget.initialPinLength} chiffres protege l\'app';

    return Scaffold(
      backgroundColor: p.creamSoft,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Verrouillage'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.lime,
                borderRadius: BorderRadius.circular(AppRadius.r22),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.ink,
                size: 32,
              ),
            ),
            const SizedBox(height: AppSpacing.x18),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _mismatch ? AppColors.red : p.ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _mismatch ? 'Les codes ne correspondent pas' : subtitle,
              style: TextStyle(
                fontSize: 13,
                color: _mismatch ? AppColors.red : p.textMute,
              ),
            ),
            const SizedBox(height: AppSpacing.x22),
            _SetupDots(
              filled: _current.length,
              length: widget.initialPinLength,
              error: _mismatch,
            ),
            const SizedBox(height: AppSpacing.x28),
            _SetupKeypad(
              onDigit: _addDigit,
              onBackspace: _removeDigit,
            ),
            const Spacer(),
            if (_saving)
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
    );
  }
}

class _SetupDots extends StatelessWidget {
  const _SetupDots({
    required this.filled,
    required this.length,
    required this.error,
  });

  final int filled;
  final int length;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
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

class _SetupKeypad extends StatelessWidget {
  const _SetupKeypad({required this.onDigit, required this.onBackspace});

  final void Function(int) onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Column(
        children: [
          _row([1, 2, 3]),
          _row([4, 5, 6]),
          _row([7, 8, 9]),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _SetupSpacer(),
              _SetupDigitKey(value: 0, onTap: onDigit),
              _SetupBackspaceKey(onTap: onBackspace),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(List<int> digits) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits
          .map((d) => _SetupDigitKey(value: d, onTap: onDigit))
          .toList(),
    );
  }
}

class _SetupDigitKey extends StatelessWidget {
  const _SetupDigitKey({required this.value, required this.onTap});

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

class _SetupBackspaceKey extends StatelessWidget {
  const _SetupBackspaceKey({required this.onTap});

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

class _SetupSpacer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const SizedBox(width: 72, height: 72);
}
