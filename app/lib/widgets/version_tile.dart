import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../providers/supabase_providers.dart';
import '../screens/admin_panel_screen.dart';

/// Tile "Version" dans Parametres > A propos.
///
/// Affiche `version+build` (ex : `2.9.0+4050`) lu via package_info_plus.
/// Long-press = copier dans le presse-papier (pratique pour bug reports
/// — le support sait quelle version tu utilises).
///
/// **Easter-egg admin (#372)** : 5 taps rapprochés ouvrent le panel super
/// admin, mais SEULEMENT si `is_super_admin()` répond vrai côté serveur.
/// Pour un utilisateur normal, les taps ne font rien de spécial (juste la
/// copie habituelle) — aucun indice de l'existence du panel.
///
/// Sortie audit #337 (QW3) : avant, "A propos" n'affichait ni version
/// ni build, ce qui bloquait le tri des bug reports.
class VersionTile extends ConsumerStatefulWidget {
  const VersionTile({super.key});

  @override
  ConsumerState<VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends ConsumerState<VersionTile> {
  String? _label;
  int _taps = 0;
  DateTime? _lastTap;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _label = '${info.version}+${info.buildNumber}');
    } catch (_) {
      if (!mounted) return;
      setState(() => _label = 'inconnue');
    }
  }

  Future<void> _copy() async {
    final v = _label;
    if (v == null) return;
    await Clipboard.setData(ClipboardData(text: 'opti_route $v'));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Version copiee : $v'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Tap : compte les taps rapprochés (easter-egg admin) + copie habituelle.
  void _onTap() {
    final now = DateTime.now();
    if (_lastTap == null ||
        now.difference(_lastTap!) > const Duration(seconds: 2)) {
      _taps = 0;
    }
    _lastTap = now;
    _taps++;
    if (_taps >= 5) {
      _taps = 0;
      _tryOpenAdmin();
    } else {
      _copy();
    }
  }

  Future<void> _tryOpenAdmin() async {
    bool isAdmin = false;
    try {
      isAdmin = await ref.read(cloudSyncServiceProvider).isSuperAdmin();
    } on Object {
      isAdmin = false;
    }
    if (!mounted || !isAdmin) return; // non-admin : silencieux
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const AdminPanelScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('Version'),
      subtitle: Text(
        _label ?? '…',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: const Icon(Icons.copy_outlined, size: 18),
      contentPadding: EdgeInsets.zero,
      onTap: _onTap,
      onLongPress: _copy,
    );
  }
}
