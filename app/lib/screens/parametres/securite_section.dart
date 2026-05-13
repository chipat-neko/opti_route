import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/parametres_repository.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import '../lock_screen.dart';
import '../pin_setup_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Securite" — gestion du verrouillage local de l'app.
/// ════════════════════════════════════════════════════════════════
///
/// Expose 4 controles :
///   - SwitchListTile "Verrouiller l'app" : active / desactive le
///     verrou. A l'activation, pousse [PinSetupScreen] pour creer
///     un PIN ; a la desactivation, demande le PIN actuel via
///     [LockScreen] pour confirmer.
///   - ListTile "Changer le code" : demande l'ancien PIN puis le
///     nouveau (deux ecrans successifs).
///   - SwitchListTile "Empreinte / visage" : visible uniquement si
///     le device supporte la biometrie (capteur + au moins une
///     empreinte enregistree dans le systeme).
///   - ListTile "Verrouillage auto" : bottom sheet pour choisir le
///     delai (Jamais / 1 / 5 / 15 / 30 / 60 min) avant que l'app
///     ne se reverrouille apres background.
///
/// La persistance va dans `ParametresRepository` (cles
/// `verrou_actif`, `pin_hash`, `biometrie_active`, `auto_lock_minutes`).
/// Le hash du PIN est en SHA-256 (jamais le PIN en clair).
class SecuriteSection extends ConsumerStatefulWidget {
  const SecuriteSection({super.key});

  @override
  ConsumerState<SecuriteSection> createState() => _SecuriteSectionState();
}

class _SecuriteSectionState extends ConsumerState<SecuriteSection> {
  bool _biometricSupported = false;
  bool _biometricActive = false;
  int _autoLockMinutes = ParametresRepository.defaultAutoLockMinutes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  /// Recharge les 3 etats depuis les services :
  /// - support biometrie via SecurityService (capteur + enrolement)
  /// - flag biometrie active depuis les parametres
  /// - delai d'auto-lock courant
  Future<void> _refresh() async {
    final params = ref.read(parametresRepositoryProvider);
    final svc = ref.read(securityServiceProvider);
    final supported = await svc.canUseBiometrics();
    final bio = await params.getBiometrieActive();
    final mins = await params.getAutoLockMinutes();
    if (!mounted) return;
    setState(() {
      _biometricSupported = supported;
      _biometricActive = bio;
      _autoLockMinutes = mins;
      _loading = false;
    });
  }

  /// Active OU desactive le verrou. Activation -> pousse PinSetupScreen
  /// pour creer un PIN. Desactivation -> demande verification du PIN
  /// actuel via LockScreen avant de purger le hash.
  Future<void> _toggleVerrou(bool wantOn) async {
    if (wantOn) {
      final ok = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      );
      if (ok != true) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verrouillage active')),
      );
    } else {
      // Demande verification PIN avant de desactiver.
      final ok = await _askPinConfirm(
        title: 'Desactiver le verrou',
        message: 'Saisis ton code pour confirmer',
      );
      if (ok != true) return;
      await ref.read(securityServiceProvider).disableLock();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verrouillage desactive')),
      );
      _refresh();
    }
  }

  /// Pousse LockScreen en plein ecran et retourne true si le user a
  /// reussi a saisir le bon PIN. `allowBiometric: false` force la
  /// saisie manuelle (anti-bypass biometrique sur les operations
  /// sensibles comme la desactivation du verrou).
  Future<bool?> _askPinConfirm({
    required String title,
    required String message,
  }) async {
    bool unlocked = false;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LockScreen(
          allowBiometric: false,
          onUnlocked: () {
            unlocked = true;
            Navigator.of(context).pop();
          },
        ),
      ),
    );
    return unlocked;
  }

  /// Changement de PIN en 2 etapes : valider l'ancien, puis saisir
  /// le nouveau. PinSetupScreen ecrit directement le nouveau hash
  /// dans les parametres si l'utilisateur valide.
  Future<void> _changePin() async {
    final ok = await _askPinConfirm(
      title: 'Changer le code',
      message: 'Saisis ton code actuel',
    );
    if (ok != true) return;
    if (!mounted) return;
    final picked = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
    );
    if (picked == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Code mis a jour')),
      );
    }
  }

  Future<void> _toggleBiometrie(bool v) async {
    final params = ref.read(parametresRepositoryProvider);
    await params.setBiometrieActive(v);
    if (!mounted) return;
    setState(() => _biometricActive = v);
  }

  Future<void> _setAutoLock(int minutes) async {
    final params = ref.read(parametresRepositoryProvider);
    await params.setAutoLockMinutes(minutes);
    if (!mounted) return;
    setState(() => _autoLockMinutes = minutes);
  }

  /// Texte humain pour le delai d'auto-lock. "0 = uniquement au
  /// demarrage" car le lock initial reste actif meme avec 0.
  String _formatAutoLock(int m) {
    if (m == 0) return 'Jamais (uniquement au demarrage)';
    if (m == 1) return 'Apres 1 minute';
    return 'Apres $m minutes';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x14),
        child: Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    // Source de verite live du flag verrou via stream (pour suivre
    // les toggles externes, ex: changement de PIN depuis ailleurs).
    final lockEnabled = ref
            .watch(lockEnabledStreamProvider)
            .asData
            ?.value ??
        false;

    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: lockEnabled,
          title: const Text('Verrouiller l\'app'),
          subtitle: Text(
            lockEnabled
                ? 'Code a 4 chiffres demande au demarrage'
                : 'Ouvre l\'app sans confirmation (defaut)',
            style: const TextStyle(fontSize: 12),
          ),
          onChanged: _toggleVerrou,
        ),
        if (lockEnabled) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.pin_outlined),
            title: const Text('Changer le code'),
            subtitle: const Text(
              'Renouvelle ton PIN apres saisie de l\'actuel',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: _changePin,
          ),
          if (_biometricSupported)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _biometricActive,
              title: const Text('Empreinte / visage'),
              subtitle: const Text(
                'Deverrouille sans saisir le code',
                style: TextStyle(fontSize: 12),
              ),
              secondary: const Icon(Icons.fingerprint),
              onChanged: _toggleBiometrie,
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Verrouillage auto'),
            subtitle: Text(
              _formatAutoLock(_autoLockMinutes),
              style: const TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final picked = await showModalBottomSheet<int>(
                context: context,
                builder: (_) => _AutoLockPicker(current: _autoLockMinutes),
              );
              if (picked != null) await _setAutoLock(picked);
            },
          ),
        ],
      ],
    );
  }
}

/// Bottom sheet de selection du delai d'auto-lock. Liste de 6 options
/// pre-definies (de "Jamais" a "Apres 1 heure"). L'option actuelle a
/// un check emerald. Retourne la valeur en minutes au pop.
class _AutoLockPicker extends StatelessWidget {
  const _AutoLockPicker({required this.current});
  final int current;

  static const _options = [
    (0, 'Jamais'),
    (1, 'Apres 1 minute'),
    (5, 'Apres 5 minutes'),
    (15, 'Apres 15 minutes'),
    (30, 'Apres 30 minutes'),
    (60, 'Apres 1 heure'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: _options.map((o) {
          final selected = o.$1 == current;
          return ListTile(
            title: Text(o.$2),
            trailing: selected
                ? const Icon(Icons.check, color: AppColors.emerald)
                : null,
            onTap: () => Navigator.of(context).pop(o.$1),
          );
        }).toList(),
      ),
    );
  }
}
