import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud/cloud_admin_sync.dart';
import '../data/cloud_error_humanizer.dart';
import '../providers/supabase_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/snack.dart';

/// Panel super admin caché (#372).
///
/// Accessible via 5 taps sur le numéro de version (cf [VersionTile]),
/// **uniquement** si `is_super_admin()` répond vrai côté serveur. Permet
/// de consulter/régénérer le **code maître** (#374) qui autorise la
/// création d'entreprises, et de voir toutes les entreprises existantes.
///
/// Toutes les actions sont revérifiées côté serveur (RPC SECURITY DEFINER) :
/// l'écran ne fait que présenter, le serveur reste seul juge.
class AdminPanelScreen extends ConsumerStatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  ConsumerState<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends ConsumerState<AdminPanelScreen> {
  String? _code;
  List<AdminEntrepriseInfo>? _entreprises;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final svc = ref.read(cloudSyncServiceProvider);
      final code = await svc.getMasterCode();
      final ents = await svc.adminListEntreprises();
      if (!mounted) return;
      setState(() {
        _code = code;
        _entreprises = ents;
        _busy = false;
      });
    } on Object catch (e) {
      if (!mounted) return;
      setState(() {
        _error = humanizeAnyError(e);
        _busy = false;
      });
    }
  }

  Future<void> _regenerate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Régénérer le code ?'),
        content: const Text(
            'L\'ancien code cessera immédiatement de fonctionner. Les '
            'personnes qui ne l\'ont pas encore utilisé devront recevoir '
            'le nouveau code.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Régénérer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      final code =
          await ref.read(cloudSyncServiceProvider).regenerateMasterCode();
      if (!mounted) return;
      setState(() => _code = code);
      context.showSuccess('Nouveau code maître généré');
    } on Object catch (e) {
      if (!mounted) return;
      context.showError(humanizeAnyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Panel admin')),
      body: _busy
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(context)
              : _buildContent(context),
    );
  }

  Widget _buildError(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.x16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.x12),
            FilledButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final palette = context.palette;
    final entreprises = _entreprises ?? const <AdminEntrepriseInfo>[];
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: [
        // ─── Carte code maître ───────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Code maître (création d\'entreprise)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: palette.ink,
                      ),
                ),
                const SizedBox(height: AppSpacing.x4),
                Text(
                  'À donner à une personne autorisée à créer une entreprise.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: palette.textMute,
                      ),
                ),
                const SizedBox(height: AppSpacing.x12),
                Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        _code ?? '——————',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: 4,
                              color: AppColors.emerald,
                            ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Copier',
                      onPressed: _code == null
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: _code!));
                              context.showInfo('Code copié');
                            },
                      icon: const Icon(Icons.copy_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x8),
                OutlinedButton.icon(
                  onPressed: _regenerate,
                  icon: const Icon(Icons.autorenew),
                  label: const Text('Régénérer le code'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.x16),
        // ─── Liste des entreprises ───────────────────────────────────
        Text(
          'Entreprises (${entreprises.length})',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: palette.ink,
              ),
        ),
        const SizedBox(height: AppSpacing.x8),
        if (entreprises.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
            child: Text(
              'Aucune entreprise créée pour l\'instant.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.textMute,
                  ),
            ),
          )
        else
          ...entreprises.map(
            (e) => Card(
              child: ListTile(
                leading: Icon(Icons.business_outlined, color: palette.textMute),
                title: Text(e.nom),
                subtitle: Text(
                  e.siret == null ? 'SIRET non renseigné' : 'SIRET ${e.siret}',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
