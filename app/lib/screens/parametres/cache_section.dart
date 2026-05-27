import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../providers/database_providers.dart';
import '../../providers/geocoding_providers.dart';
import '../../providers/tile_provider.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import 'parametres_widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Cache" — gestion des donnees locales recyclees.
/// ════════════════════════════════════════════════════════════════
///
/// Affiche les stats de cache (taille tuiles + nb entrees geocodage)
/// et 3 actions destructives confirmees par snack-bar :
///   - Vider cache geocodage : force re-fetch des recherches adresse
///   - Vider cache tuiles : re-telechargera les fonds OSM au besoin
///   - Nettoyer tournees > 1 an : supprime definitivement les vieilles
///     tournees + tous leurs arrets (confirmation dialog avant action)
class CacheSection extends ConsumerStatefulWidget {
  const CacheSection({super.key});

  @override
  ConsumerState<CacheSection> createState() => _CacheSectionState();
}

class _CacheSectionState extends ConsumerState<CacheSection> {
  bool _saving = false;
  int? _tilesCacheBytes;
  int? _geocodeCacheCount;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    int? bytes;
    int? count;
    try {
      bytes = await ref.read(cachedTileProviderInstance).cacheSizeBytes();
    } catch (_) {}
    try {
      count = await ref.read(geocodeCacheRepositoryProvider).count();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _tilesCacheBytes = bytes;
      _geocodeCacheCount = count;
    });
  }

  /// Formatage humain d'une taille en octets : "4.2 Mo", "523 Ko", etc.
  /// Base 1000 (decimal) -- plus parlant grand public que base 1024.
  static String _formatBytes(int? bytes) {
    if (bytes == null) return '...';
    if (bytes < 1000) return '$bytes o';
    if (bytes < 1000 * 1000) {
      return '${(bytes / 1000).toStringAsFixed(0)} Ko';
    }
    if (bytes < 1000 * 1000 * 1000) {
      return '${(bytes / (1000 * 1000)).toStringAsFixed(1)} Mo';
    }
    return '${(bytes / (1000 * 1000 * 1000)).toStringAsFixed(2)} Go';
  }

  Future<void> _purgeGeocode() async {
    setState(() => _saving = true);
    try {
      final removed =
          await ref.read(geocodeCacheRepositoryProvider).purgeAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removed > 0
                ? '$removed entree(s) supprimee(s) du cache'
                : 'Cache deja vide',
          ),
        ),
      );
      await _loadStats();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _purgeTiles() async {
    setState(() => _saving = true);
    try {
      await ref.read(cachedTileProviderInstance).clearCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cache des cartes vide')),
      );
      await _loadStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _cleanupOldTournees() async {
    final repo = ref.read(tourneesRepositoryProvider);
    final cutoff = DateTime.now().subtract(const Duration(days: 365));
    final count = await repo.countOlderThan(cutoff);
    if (!mounted) return;
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune tournee de plus d\'un an a nettoyer'),
        ),
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Nettoyer les vieilles tournees ?'),
        content: Text(
          '$count tournee(s) datee(s) d\'il y a plus d\'un an vont '
          'etre supprimees, avec tous leurs arrets. Cette action est '
          'definitive.',
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
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      final deleted = await repo.deleteOlderThan(cutoff);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$deleted tournee(s) supprimee(s)'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Cache'),
        const SizedBox(height: AppSpacing.x10),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x12,
            vertical: AppSpacing.x10,
          ),
          decoration: BoxDecoration(
            color: p.creamSoft,
            borderRadius: BorderRadius.circular(AppRadius.r12),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tuiles cartes en cache',
                    style: TextStyle(fontSize: 12.5, color: p.textMute),
                  ),
                  Text(
                    _formatBytes(_tilesCacheBytes),
                    style: appMonoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recherches geocodees memorisees',
                    style: TextStyle(fontSize: 12.5, color: p.textMute),
                  ),
                  Text(
                    _geocodeCacheCount == null ? '...' : '$_geocodeCacheCount',
                    style: appMonoStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p.ink,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        OutlinedButton.icon(
          onPressed: _saving ? null : _purgeGeocode,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text('Vider le cache de geocodage'),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          'Force toutes les recherches d\'adresse a re-interroger les '
          'sources. Utile si tu as modifie une adresse ou que tu veux '
          'reessayer une saisie qui a echoue.',
          style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x14),
        OutlinedButton.icon(
          onPressed: _saving ? null : _purgeTiles,
          icon: const Icon(Icons.layers_clear_outlined),
          label: const Text('Vider le cache des cartes'),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          'Supprime les tuiles OpenStreetMap stockees localement '
          '(utilisees comme cache pour fonctionner hors-ligne dans les '
          'zones deja visitees). Les tuiles seront re-telechargees a '
          'la prochaine visite.',
          style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x14),
        OutlinedButton.icon(
          onPressed: _saving ? null : _cleanupOldTournees,
          icon: const Icon(Icons.history_toggle_off_outlined),
          label: const Text('Nettoyer les tournees > 1 an'),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          'Supprime definitivement les tournees datees d\'il y a plus '
          'd\'un an, avec tous leurs arrets. Garde l\'app legere et la '
          'base de donnees compacte.',
          style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
        ),
      ],
    );
  }
}
