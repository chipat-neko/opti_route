import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/cloud_sync_service.dart';
import '../../data/supabase_service.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';
import '../cloud/auth_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Compte cloud" des Parametres (Phase 2 backend Supabase).
/// ════════════════════════════════════════════════════════════════
///
/// **Jalon 1 (cette PR)** : seule l'authentification (sign in / out)
/// est exposee. Aucun sync automatique des donnees vers le cloud.
/// La section affiche :
///   - si pas configure (build sans SUPABASE_URL) -> info "non
///     disponible sur cette build"
///   - si pas connecte -> bouton "Connecter mon compte"
///   - si connecte -> email du user + bouton "Se deconnecter"
///
/// **Jalons suivants** : sync tournees, partage equipe temps reel,
/// ETA SMS Twilio, etc. La section grossira de toggles au fur et a
/// mesure.
class CloudSection extends ConsumerWidget {
  const CloudSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configured = ref.watch(cloudConfiguredProvider);
    final userAsync = ref.watch(cloudUserProvider);
    final p = context.palette;

    if (!configured) {
      return _NotConfiguredTile(palette: p);
    }
    return userAsync.when(
      data: (user) => user == null
          ? _SignInTile(palette: p)
          : Column(
              children: [
                _SignedInTile(user: user),
                const _PullCloudTile(),
              ],
            ),
      loading: () => const _LoadingTile(),
      error: (e, _) => _ErrorTile(message: '$e', palette: p),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
      title: Text('Verification de la session...'),
    );
  }
}

class _NotConfiguredTile extends StatelessWidget {
  const _NotConfiguredTile({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: palette.creamSoft,
        foregroundColor: palette.textMute,
        child: const Icon(Icons.cloud_off_outlined, size: 18),
      ),
      title: const Text('Sync cloud non disponible'),
      subtitle: Text(
        'Cette build de l\'app n\'inclut pas les credentials Supabase. '
        'Mode local-only, tes donnees restent sur ce telephone.',
        style: TextStyle(fontSize: 12, color: palette.textMute, height: 1.4),
      ),
      isThreeLine: true,
    );
  }
}

class _SignInTile extends ConsumerWidget {
  const _SignInTile({required this.palette});
  final AppPalette palette;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.emeraldSoft,
        foregroundColor: AppColors.emerald,
        child: const Icon(Icons.cloud_outlined, size: 18),
      ),
      title: const Text('Connecter mon compte'),
      subtitle: Text(
        'Active la synchronisation cloud entre tes appareils.',
        style: TextStyle(fontSize: 12, color: palette.textMute),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<bool>(
          builder: (_) => const CloudAuthScreen(),
        ),
      ),
    );
  }
}

class _SignedInTile extends ConsumerStatefulWidget {
  const _SignedInTile({required this.user});
  final User user;

  @override
  ConsumerState<_SignedInTile> createState() => _SignedInTileState();
}

class _SignedInTileState extends ConsumerState<_SignedInTile> {
  bool _signingOut = false;

  Future<void> _confirmAndSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se deconnecter ?'),
        content: Text(
          'Ton compte cloud sera deconnecte. Tes donnees locales '
          '(tournees, carnet) restent intactes sur ce telephone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red.withValues(alpha: 0.15),
              foregroundColor: AppColors.red,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Se deconnecter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _signingOut = true);
    try {
      await SupabaseService.instance.signOut();
    } catch (_) {/* best-effort */}
    if (!mounted) return;
    setState(() => _signingOut = false);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.emeraldSoft,
        foregroundColor: AppColors.emerald,
        child: const Icon(Icons.cloud_done_outlined, size: 18),
      ),
      title: Text(
        widget.user.email ?? 'Compte cloud',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Connecte · Sync des tournees viendra dans un prochain jalon',
        style: TextStyle(fontSize: 12, color: p.textMute),
      ),
      trailing: _signingOut
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: _confirmAndSignOut,
              child: const Text('Deconnecter'),
            ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  const _ErrorTile({required this.message, required this.palette});
  final String message;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: AppColors.red,
        foregroundColor: Colors.white,
        child: Icon(Icons.error_outline, size: 18),
      ),
      title: const Text('Erreur de session cloud'),
      subtitle: Text(
        message,
        style: TextStyle(fontSize: 12, color: palette.textMute),
      ),
    );
  }
}

/// Tile "Re-telecharger depuis le cloud" (sous-jalon 2.D-1a). Fait un
/// pull manuel des 4 tables (coequipiers/tournees/stops/saved_dests)
/// avec confirmation dialog parce que ca peut ecraser des modifs
/// locales non sync (cloud-wins strategy pour les rows deja sync).
class _PullCloudTile extends ConsumerStatefulWidget {
  const _PullCloudTile();

  @override
  ConsumerState<_PullCloudTile> createState() => _PullCloudTileState();
}

class _PullCloudTileState extends ConsumerState<_PullCloudTile> {
  bool _pulling = false;

  Future<void> _confirmAndPull() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Re-telecharger depuis le cloud ?'),
        content: const Text(
          'Toutes les donnees du cloud seront recuperees et fusionnees '
          'avec celles de ce telephone.\n\n'
          'Attention : si tu as modifie une tournee LOCALEMENT depuis '
          'son dernier push, ces modifs seront ECRASEES par la version '
          'cloud. Utilise plutot "Pousser au cloud" sur la tournee '
          'concernee d\'abord si tu n\'es pas sur.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Re-telecharger'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _pulling = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result =
          await ref.read(cloudSyncServiceProvider).pullAllForCurrentUser();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.summary),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 5),
        ),
      );
    } on CloudSyncException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) setState(() => _pulling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.emeraldSoft,
        foregroundColor: AppColors.emerald,
        child: const Icon(Icons.cloud_download_outlined, size: 18),
      ),
      title: const Text('Re-telecharger depuis le cloud'),
      subtitle: Text(
        'Recupere toutes tes tournees / arrets / carnet du cloud',
        style: TextStyle(fontSize: 12, color: p.textMute),
      ),
      trailing: _pulling
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _pulling ? null : _confirmAndPull,
    );
  }
}
