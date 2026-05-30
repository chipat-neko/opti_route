import 'dart:io' show File, Platform, Process;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../data/update_checker_service.dart';
import '../theme/app_tokens.dart';

/// Carte "Mise à jour" dans Paramètres : bouton "Vérifier", affichage
/// version locale vs version distante, et sur Windows un bouton
/// "Lancer la MAJ" qui exécute `MAJ_optiroute_chef.bat` sur le bureau.
class UpdateCheckCard extends StatefulWidget {
  const UpdateCheckCard({super.key});

  @override
  State<UpdateCheckCard> createState() => _UpdateCheckCardState();
}

class _UpdateCheckCardState extends State<UpdateCheckCard> {
  String? _currentVersion;
  UpdateStatus? _status;
  bool _loading = false;
  final UpdateCheckerService _svc = UpdateCheckerService();

  @override
  void initState() {
    super.initState();
    _loadCurrentVersion();
  }

  @override
  void dispose() {
    _svc.close();
    super.dispose();
  }

  Future<void> _loadCurrentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() => _currentVersion = '${info.version}+${info.buildNumber}');
    } catch (_) {
      // package_info pas dispo sur cette plateforme -> on garde null
    }
  }

  Future<void> _check() async {
    if (_currentVersion == null) return;
    setState(() => _loading = true);
    final result = await _svc.check(currentVersion: _currentVersion!);
    if (!mounted) return;
    setState(() {
      _status = result;
      _loading = false;
    });
  }

  /// Cherche le launcher MAJ dans plusieurs emplacements connus,
  /// dans l'ordre de préférence : raccourci bureau (.lnk créé par
  /// Creer_raccourci_bureau.bat) > nouveau .bat scripts/ > ancien
  /// .bat sur le bureau (compat). Retourne null si rien trouvé.
  String? _findUpdater() {
    final home = Platform.environment['USERPROFILE'] ?? '';
    final candidates = <String>[
      '$home\\Desktop\\MAJ opti_route chef.lnk',
      'E:\\opti_route\\scripts\\MAJ_optiroute_chef.bat',
      'D:\\opti_route\\scripts\\MAJ_optiroute_chef.bat',
      '$home\\Desktop\\MAJ_optiroute_chef.bat',
    ];
    for (final path in candidates) {
      if (File(path).existsSync()) return path;
    }
    return null;
  }

  Future<void> _launchUpdater() async {
    if (kIsWeb || !Platform.isWindows) return;
    final launcher = _findUpdater();
    if (launcher == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Launcher MAJ introuvable. Lance Creer_raccourci_bureau.bat '
            'depuis le dossier scripts/ du repo.',
          ),
        ),
      );
      return;
    }
    try {
      // Lance le .bat ou .lnk dans une nouvelle fenetre cmd, sans bloquer l'app.
      await Process.start('cmd', ['/c', 'start', '', launcher]);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'MAJ en cours dans une autre fenêtre. Ferme l\'app pour la relancer après.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lancement : $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final status = _status;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: p.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.system_update_alt, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Text(
                'Mise à jour',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          if (_currentVersion != null)
            Text(
              'Version installée : $_currentVersion',
              style: TextStyle(fontSize: 12, color: p.textMute),
            ),
          if (status != null) ...[
            const SizedBox(height: AppSpacing.x8),
            _StatusLine(status: status),
          ],
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loading || _currentVersion == null ? null : _check,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child:
                              CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('Vérifier'),
                ),
              ),
              if (!kIsWeb &&
                  Platform.isWindows &&
                  status != null &&
                  status.hasUpdate) ...[
                const SizedBox(width: AppSpacing.x8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _launchUpdater,
                    icon: const Icon(Icons.download_for_offline_outlined,
                        size: 18),
                    label: const Text('Lancer la MAJ'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusLine extends StatelessWidget {
  const _StatusLine({required this.status});

  final UpdateStatus status;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    if (status.isUpToDate) {
      return Row(
        children: [
          const Icon(Icons.check_circle_outline,
              size: 16, color: AppColors.emerald),
          const SizedBox(width: 6),
          Text(
            'À jour',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.emerald),
          ),
        ],
      );
    }
    if (status.hasUpdate) {
      return Row(
        children: [
          const Icon(Icons.fiber_new, size: 16, color: AppColors.amber),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Nouvelle version : ${status.remoteVersion}',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.ink),
            ),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Icon(Icons.error_outline, size: 16, color: AppColors.red),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            status.errorMessage ?? 'Erreur',
            style: TextStyle(fontSize: 12, color: p.textMute),
          ),
        ),
      ],
    );
  }
}
