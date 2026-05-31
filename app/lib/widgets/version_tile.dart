import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:package_info_plus/package_info_plus.dart';

/// Tile "Version" dans Parametres > A propos.
///
/// Affiche `version+build` (ex : `2.9.0+4050`) lu via package_info_plus.
/// Long-press = copier dans le presse-papier (pratique pour bug reports
/// — le support sait quelle version tu utilises).
///
/// Sortie audit #337 (QW3) : avant, "A propos" n'affichait ni version
/// ni build, ce qui bloquait le tri des bug reports.
class VersionTile extends StatefulWidget {
  const VersionTile({super.key});

  @override
  State<VersionTile> createState() => _VersionTileState();
}

class _VersionTileState extends State<VersionTile> {
  String? _label;

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
      onTap: _copy,
      onLongPress: _copy,
    );
  }
}
