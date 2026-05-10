import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_providers.dart';
import '../providers/geocoding_providers.dart';
import '../providers/optimization_providers.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

class ParametresScreen extends ConsumerStatefulWidget {
  const ParametresScreen({super.key});

  @override
  ConsumerState<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends ConsumerState<ParametresScreen> {
  final _keyCtrl = TextEditingController();
  final _orsKeyCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureOrs = true;
  bool _saving = false;
  bool _initialized = false;
  bool _orsInitialized = false;

  @override
  void dispose() {
    _keyCtrl.dispose();
    _orsKeyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiKeyAsync = ref.watch(tomtomApiKeyProvider);
    final orsKeyAsync = ref.watch(orsApiKeyProvider);

    apiKeyAsync.whenData((value) {
      if (!_initialized && value != null) {
        _keyCtrl.text = value;
        _initialized = true;
      }
    });
    orsKeyAsync.whenData((value) {
      if (!_orsInitialized && value != null) {
        _orsKeyCtrl.text = value;
        _orsInitialized = true;
      }
    });

    final hasKey = apiKeyAsync.asData?.value?.isNotEmpty ?? false;
    final hasOrsKey = orsKeyAsync.asData?.value?.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: [
          _SectionTitle('Geocodage'),
          const SizedBox(height: AppSpacing.x10),
          _ProviderStatusCard(active: hasKey ? 'TomTom' : 'Photon'),
          const SizedBox(height: AppSpacing.x18),
          Text(
            'Cle API TomTom',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Cree gratuitement un compte sur developer.tomtom.com '
            '(2500 requetes/jour, sans carte de credit), copie ta cle '
            'API et colle-la ici. Si vide, on utilise Photon en fallback.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          TextField(
            controller: _keyCtrl,
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Cle API',
              hintText: '32 caracteres alphanumeriques',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
                tooltip: _obscure ? 'Afficher' : 'Masquer',
              ),
            ),
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: AppSpacing.x18),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.lime,
                    ),
                  )
                : const Icon(Icons.check),
            label: const Text('Enregistrer'),
          ),
          if (hasKey) ...[
            const SizedBox(height: AppSpacing.x10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _clear,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Effacer la cle (revenir a Photon)'),
            ),
          ],
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const _SectionTitle('Optimisation de tournee'),
          const SizedBox(height: AppSpacing.x10),
          _ProviderStatusCard(
            active: hasOrsKey ? 'OpenRouteService' : 'Aucun',
            label: hasOrsKey ? 'ORS est actif' : 'Optimisation desactivee',
            sub: hasOrsKey
                ? '500 optimisations/jour, gratuit.'
                : 'Saisis une cle ORS pour activer le bouton "Optimiser".',
          ),
          const SizedBox(height: AppSpacing.x18),
          Text(
            'Cle API OpenRouteService',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Cree gratuitement un compte sur openrouteservice.org/dev '
            '(500 optimisations/jour, sans carte de credit), puis colle '
            'ta cle ici. Sans cle, le bouton "Optimiser" reste desactive.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          TextField(
            controller: _orsKeyCtrl,
            obscureText: _obscureOrs,
            decoration: InputDecoration(
              labelText: 'Cle API ORS',
              hintText: 'Environ 40 caracteres',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureOrs ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscureOrs = !_obscureOrs),
              ),
            ),
            autocorrect: false,
            enableSuggestions: false,
          ),
          const SizedBox(height: AppSpacing.x18),
          FilledButton.icon(
            onPressed: _saving ? null : _saveOrs,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer la cle ORS'),
          ),
          if (hasOrsKey) ...[
            const SizedBox(height: AppSpacing.x10),
            OutlinedButton.icon(
              onPressed: _saving ? null : _clearOrs,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Effacer la cle ORS'),
            ),
          ],
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const _SectionTitle('Cache'),
          const SizedBox(height: AppSpacing.x10),
          OutlinedButton.icon(
            onPressed: _saving ? null : _purgeCache,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Vider le cache de geocodage'),
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Force toutes les recherches d\'adresse a re-interroger le '
            'fournisseur. Utile apres avoir change de fournisseur.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final value = _keyCtrl.text.trim();
    setState(() => _saving = true);
    try {
      if (value.isEmpty) {
        await ref.read(parametresRepositoryProvider).clearTomTomApiKey();
      } else {
        await ref.read(parametresRepositoryProvider).setTomTomApiKey(value);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value.isEmpty
              ? 'Cle effacee, retour a Photon'
              : 'Cle TomTom enregistree'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    try {
      await ref.read(parametresRepositoryProvider).clearTomTomApiKey();
      _keyCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cle effacee, retour a Photon')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _saveOrs() async {
    final value = _orsKeyCtrl.text.trim();
    setState(() => _saving = true);
    try {
      if (value.isEmpty) {
        await ref.read(parametresRepositoryProvider).clearOrsApiKey();
      } else {
        await ref.read(parametresRepositoryProvider).setOrsApiKey(value);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(value.isEmpty
              ? 'Cle ORS effacee'
              : 'Cle ORS enregistree, optimisation activee'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _clearOrs() async {
    setState(() => _saving = true);
    try {
      await ref.read(parametresRepositoryProvider).clearOrsApiKey();
      _orsKeyCtrl.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cle ORS effacee')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _purgeCache() async {
    setState(() => _saving = true);
    try {
      final removed = await ref
          .read(geocodeCacheRepositoryProvider)
          .purgeExpired();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            removed > 0
                ? '$removed entree(s) expiree(s) supprimee(s)'
                : 'Aucune entree expiree',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: AppColors.textMute,
      ),
    );
  }
}

class _ProviderStatusCard extends StatelessWidget {
  const _ProviderStatusCard({
    required this.active,
    this.label,
    this.sub,
  });

  final String active;
  final String? label;
  final String? sub;

  @override
  Widget build(BuildContext context) {
    final highlight = active != 'Photon' && active != 'Aucun';
    final defaultLabel = switch (active) {
      'TomTom' => 'TomTom est actif',
      'Photon' => 'Photon (par defaut)',
      _ => 'Inactif',
    };
    final defaultSub = switch (active) {
      'TomTom' => 'Qualite maximale, 2500 requetes/jour.',
      'Photon' =>
        'Pas de cle API. Saisis-en une pour passer a TomTom.',
      _ => '',
    };
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.lime : AppColors.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Row(
        children: [
          Icon(
            highlight ? Icons.check_circle : Icons.public,
            color: AppColors.ink,
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label ?? defaultLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sub ?? defaultSub,
                  style: appMonoStyle(
                    fontSize: 11,
                    color: AppColors.ink.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
