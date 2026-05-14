import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/geocoding_providers.dart';
import '../theme/app_tokens.dart';

/// Bandeau "N arrets sans GPS" : visible seulement quand au moins un
/// arret est en attente de geocodage (lat null dans Drift).
///
/// Discret quand il n'y a rien a signaler (retourne SizedBox.shrink()),
/// visible avec un CTA "Re-essayer maintenant" sinon. Tap = force un
/// `retryAllPending()` immediat (sans attendre la prochaine fenetre de
/// connectivite).
///
/// A poser idealement en haut des ecrans qui listent des tournees ou
/// des arrets, ou dans le drawer.
class OfflineGeocodeBanner extends ConsumerWidget {
  const OfflineGeocodeBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final pendingAsync = ref.watch(pendingGeocodeCountProvider);
    final count = pendingAsync.asData?.value ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x18,
        vertical: AppSpacing.x6,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.amber.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(AppRadius.r12),
          border: Border.all(
            color: AppColors.amber.withValues(alpha: 0.45),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12,
          vertical: AppSpacing.x10,
        ),
        child: Row(
          children: [
            const Icon(Icons.gps_off, color: AppColors.amber, size: 18),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: Text(
                count == 1
                    ? '1 arret en attente de geolocalisation'
                    : '$count arrets en attente de geolocalisation',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: p.ink,
                ),
              ),
            ),
            TextButton(
              onPressed: () => _onRetry(context, ref),
              style: TextButton.styleFrom(
                foregroundColor: p.ink,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                minimumSize: const Size(0, 32),
              ),
              child: const Text('Re-essayer'),
            ),
          ],
        ),
      ),
    );
  }

  /// Declenche un retry immediat (ignore le throttle anti-spam de
  /// l'automate). Affiche un SnackBar avec le bilan.
  Future<void> _onRetry(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final automation = ref.read(offlineGeocodeAutomationProvider);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Re-geocodage en cours...'),
        duration: Duration(seconds: 2),
      ),
    );
    try {
      final result = await automation.forceRetry();
      if (!context.mounted) return;
      final r = result.resolved.length;
      final u = result.unresolved.length;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            r == 0 && u == 0
                ? 'Rien a geocoder.'
                : r > 0
                    ? '$r arret${r > 1 ? "s" : ""} geolocalise${r > 1 ? "s" : ""} sur ${r + u}'
                    : 'Aucun resultat (verifie ta connexion et l\'adresse).',
          ),
          backgroundColor: r > 0 ? AppColors.emerald : null,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }
}
