import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications_service.dart';
import '../providers/database_providers.dart';
import '../providers/geocoding_providers.dart';
import '../providers/optimization_providers.dart';
import '../providers/tile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/tournee_en_cours_pill.dart';
import 'mentions_legales_screen.dart';

class ParametresScreen extends ConsumerStatefulWidget {
  const ParametresScreen({super.key});

  @override
  ConsumerState<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends ConsumerState<ParametresScreen> {
  final _orsKeyCtrl = TextEditingController();
  final _capaciteCtrl = TextEditingController();
  final _dureeArretCtrl = TextEditingController();
  bool _obscureOrs = true;
  bool _saving = false;
  bool _orsInitialized = false;
  bool _defaultsInitialized = false;
  String? _navAppDefault;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
  }

  Future<void> _loadDefaults() async {
    final repo = ref.read(parametresRepositoryProvider);
    final cap = await repo.getCapaciteDefault();
    final duree = await repo.getDureeArretDefault();
    final nav = await repo.getNavAppDefault();
    if (!mounted) return;
    setState(() {
      _capaciteCtrl.text = cap?.toString() ?? '';
      _dureeArretCtrl.text = duree?.toString() ?? '';
      _navAppDefault = nav;
      _defaultsInitialized = true;
    });
  }

  @override
  void dispose() {
    _orsKeyCtrl.dispose();
    _capaciteCtrl.dispose();
    _dureeArretCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orsKeyAsync = ref.watch(orsApiKeyProvider);

    orsKeyAsync.whenData((value) {
      if (!_orsInitialized && value != null) {
        _orsKeyCtrl.text = value;
        _orsInitialized = true;
      }
    });

    final hasOrsKey = orsKeyAsync.asData?.value?.isNotEmpty ?? false;
    final orsUsed = ref.watch(orsUsedTodayProvider).asData?.value ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parametres'),
        actions: const [TourneeEnCoursPill()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: [
          const _SectionTitle('Geocodage'),
          const SizedBox(height: AppSpacing.x10),
          const _StatusCard(
            highlight: true,
            icon: Icons.verified_outlined,
            title: 'Geocodage 3 sources',
            subtitle:
                'BAN (cadastre officiel) · Recherche-Entreprises '
                '(SIRENE/INSEE) · Photon/OSM (enseignes & marques). '
                'Aucune cle, aucune limite stricte.',
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const _SectionTitle('Optimisation de tournee'),
          const SizedBox(height: AppSpacing.x10),
          _StatusCard(
            highlight: hasOrsKey,
            icon: hasOrsKey ? Icons.check_circle : Icons.bolt_outlined,
            title: hasOrsKey
                ? 'OpenRouteService est actif'
                : 'Optimisation desactivee',
            subtitle: hasOrsKey
                ? 'Aujourd\'hui : $orsUsed / 500 optimisations utilisees.'
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
          const _SectionTitle('Tournee par defaut'),
          const SizedBox(height: AppSpacing.x10),
          const Text(
            'Valeurs preremplies a la creation d\'une nouvelle tournee '
            'ou d\'un nouvel arret. Tu peux les modifier au cas par cas.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _capaciteCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Capacite vehicule',
                    helperText: 'Nb de colis max (0 = illimite)',
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: _defaultsInitialized,
                  onSubmitted: (_) => _saveDefaults(),
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: TextField(
                  controller: _dureeArretCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Duree d\'arret',
                    helperText: 'Minutes / arret (3 par defaut)',
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  enabled: _defaultsInitialized,
                  onSubmitted: (_) => _saveDefaults(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x14),
          Text(
            'App de navigation par defaut',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Quand tu tapes sur un arret en mode tournee, l\'app de nav '
            'choisie sera mise en avant dans le bottom sheet.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Wrap(
            spacing: AppSpacing.x8,
            children: [
              _NavAppChip(
                label: 'Aucune (demander)',
                value: null,
                groupValue: _navAppDefault,
                onSelected: _setNavApp,
              ),
              _NavAppChip(
                label: 'Google Maps',
                value: 'maps',
                groupValue: _navAppDefault,
                onSelected: _setNavApp,
              ),
              _NavAppChip(
                label: 'Waze',
                value: 'waze',
                groupValue: _navAppDefault,
                onSelected: _setNavApp,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x14),
          FilledButton.icon(
            onPressed: _saving || !_defaultsInitialized ? null : _saveDefaults,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer les valeurs par defaut'),
          ),
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
            'Force toutes les recherches d\'adresse a re-interroger les '
            'sources. Utile si tu as modifie une adresse ou que tu veux '
            'reessayer une saisie qui a echoue.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          OutlinedButton.icon(
            onPressed: _saving ? null : _purgeTilesCache,
            icon: const Icon(Icons.layers_clear_outlined),
            label: const Text('Vider le cache des cartes'),
          ),
          const SizedBox(height: AppSpacing.x14),
          OutlinedButton.icon(
            onPressed: _saving ? null : _cleanupOldTournees,
            icon: const Icon(Icons.history_toggle_off_outlined),
            label: const Text('Nettoyer les tournees > 1 an'),
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Supprime definitivement les tournees datees d\'il y a plus '
            'd\'un an, avec tous leurs arrets. Garde l\'app legere et la '
            'base de donnees compacte.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Supprime les tuiles OpenStreetMap stockees localement '
            '(utilisees comme cache pour fonctionner hors-ligne dans les '
            'zones deja visitees). Les tuiles seront re-telechargees a '
            'la prochaine visite.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const _SectionTitle('Notifications'),
          const SizedBox(height: AppSpacing.x10),
          const Text(
            'Les notifications locales (rappels de tournee) sont gerees '
            'par le telephone, pas par un serveur. Aucune CB requise.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          OutlinedButton.icon(
            onPressed: _saving ? null : _testNotification,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Test : notif dans 2 min'),
          ),
          const SizedBox(height: AppSpacing.x6),
          const Text(
            'Programme une notification de test 120 secondes apres le '
            'tap. Ferme l\'app ou eteins l\'ecran pour verifier que la '
            'notif arrive bien.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x14),
          const _DailyReminderToggle(),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const _SectionTitle('Apparence'),
          const SizedBox(height: AppSpacing.x10),
          const Text(
            'Mode sombre pour la conduite de nuit. "Auto" suit les '
            'reglages Android.',
            style: TextStyle(
              fontSize: 12.5,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Consumer(
            builder: (context, ref, _) {
              final mode = ref.watch(themeModeProvider).asData?.value ??
                  ThemeMode.system;
              return Wrap(
                spacing: AppSpacing.x8,
                children: [
                  _ThemeChip(
                    label: 'Auto',
                    value: ThemeMode.system,
                    groupValue: mode,
                  ),
                  _ThemeChip(
                    label: 'Clair',
                    value: ThemeMode.light,
                    groupValue: mode,
                  ),
                  _ThemeChip(
                    label: 'Sombre',
                    value: ThemeMode.dark,
                    groupValue: mode,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const _SectionTitle('A propos'),
          const SizedBox(height: AppSpacing.x10),
          ListTile(
            leading: const Icon(Icons.policy_outlined),
            title: const Text('Mentions legales'),
            subtitle: const Text(
              'Confidentialite + conditions d\'utilisation',
              style: TextStyle(fontSize: 12),
            ),
            contentPadding: EdgeInsets.zero,
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MentionsLegalesScreen(),
              ),
            ),
          ),
        ],
      ),
    );
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

  Future<void> _saveDefaults() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(parametresRepositoryProvider);
      final cap = int.tryParse(_capaciteCtrl.text.trim());
      final duree = int.tryParse(_dureeArretCtrl.text.trim());

      if (cap != null && cap >= 0) {
        await repo.setCapaciteDefault(cap);
      } else if (_capaciteCtrl.text.trim().isEmpty) {
        await repo.clearCapaciteDefault();
      }

      if (duree != null && duree >= 0) {
        await repo.setDureeArretDefault(duree);
      } else if (_dureeArretCtrl.text.trim().isEmpty) {
        await repo.clearDureeArretDefault();
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valeurs par defaut enregistrees')),
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

  Future<void> _setNavApp(String? value) async {
    setState(() => _navAppDefault = value);
    final repo = ref.read(parametresRepositoryProvider);
    if (value == null) {
      await repo.clearNavAppDefault();
    } else {
      await repo.setNavAppDefault(value);
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
        SnackBar(content: Text('Erreur : $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _testNotification() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await NotificationsService.instance.scheduleTest(seconds: 120);
      if (!mounted) return;
      final when = DateTime.now().add(const Duration(seconds: 120));
      final hh = when.hour.toString().padLeft(2, '0');
      final mm = when.minute.toString().padLeft(2, '0');
      final ss = when.second.toString().padLeft(2, '0');
      messenger.showSnackBar(
        SnackBar(
          content: Text('Notification programmee pour $hh:$mm:$ss'),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }
  }

  Future<void> _purgeTilesCache() async {
    setState(() => _saving = true);
    try {
      await ref.read(cachedTileProviderInstance).clearCache();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache des cartes vide'),
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

  Future<void> _purgeCache() async {
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
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Toggle "Rappel quotidien tournee" : si ON, planifie une notif
/// recurrente a 19h00 pour rappeler a Noah de verifier la tournee du
/// lendemain. Quand OFF, cancel la notif programmee. Persiste l'etat
/// dans ParametresRepository.
class _DailyReminderToggle extends ConsumerWidget {
  const _DailyReminderToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref
            .watch(parametresRepositoryProvider)
            .watchDailyReminderEnabled();
    return StreamBuilder<bool>(
      stream: enabled,
      builder: (context, snap) {
        final value = snap.data ?? false;
        return SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text(
            'Rappel quotidien a 19h00',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          subtitle: const Text(
            'Une notif chaque soir pour penser a verifier la tournee du lendemain.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMute,
              height: 1.4,
            ),
          ),
          value: value,
          activeThumbColor: AppColors.emerald,
          onChanged: (v) async {
            await ref
                .read(parametresRepositoryProvider)
                .setDailyReminderEnabled(v);
            if (v) {
              await NotificationsService.instance
                  .scheduleDailyTourneeReminder();
            } else {
              await NotificationsService.instance.cancelDailyTourneeReminder();
            }
          },
        );
      },
    );
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

class _ThemeChip extends ConsumerWidget {
  const _ThemeChip({
    required this.label,
    required this.value,
    required this.groupValue,
  });

  final String label;
  final ThemeMode value;
  final ThemeMode groupValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) async {
        final repo = ref.read(parametresRepositoryProvider);
        await repo.setThemeMode(switch (value) {
          ThemeMode.light => 'light',
          ThemeMode.dark => 'dark',
          ThemeMode.system => 'system',
        });
      },
      selectedColor: AppColors.lime,
      backgroundColor: AppColors.paper,
      side: BorderSide(
        color: selected ? AppColors.lime : AppColors.inkLine,
      ),
      labelStyle: TextStyle(
        color: AppColors.ink,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _NavAppChip extends StatelessWidget {
  const _NavAppChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final String? value;
  final String? groupValue;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(value),
      selectedColor: AppColors.lime,
      backgroundColor: AppColors.paper,
      side: BorderSide(
        color: selected ? AppColors.lime : AppColors.inkLine,
      ),
      labelStyle: TextStyle(
        color: AppColors.ink,
        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.highlight,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final bool highlight;
  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: highlight ? AppColors.lime : AppColors.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.ink),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: appMonoStyle(
                    fontSize: 11,
                    color: AppColors.ink.withValues(alpha: 0.75),
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
