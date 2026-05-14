import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/backup_service.dart';
import '../data/notifications_service.dart';
import '../data/parametres_repository.dart';
import '../providers/database_providers.dart';
import '../providers/geocoding_providers.dart';
import '../providers/optimization_providers.dart';
import '../providers/tile_provider.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import 'backups_list_screen.dart';
import 'coequipiers_screen.dart';
import 'mentions_legales_screen.dart';
import 'parametres/entreprise_form.dart';
import 'parametres/parametres_widgets.dart';
import 'parametres/securite_section.dart';

class ParametresScreen extends ConsumerStatefulWidget {
  const ParametresScreen({super.key});

  @override
  ConsumerState<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends ConsumerState<ParametresScreen> {
  final _orsKeyCtrl = TextEditingController();
  final _capaciteCtrl = TextEditingController();
  final _dureeArretCtrl = TextEditingController();
  final _coutLitreCtrl = TextEditingController();
  final _consoCtrl = TextEditingController();
  bool _obscureOrs = true;
  bool _saving = false;
  bool _orsInitialized = false;
  bool _defaultsInitialized = false;
  String? _navAppDefault;

  // Stats cache (chargees au build et apres chaque purge)
  int? _tilesCacheBytes;
  int? _geocodeCacheCount;

  @override
  void initState() {
    super.initState();
    _loadDefaults();
    _loadCacheStats();
  }

  Future<void> _loadDefaults() async {
    final repo = ref.read(parametresRepositoryProvider);
    final cap = await repo.getCapaciteDefault();
    final duree = await repo.getDureeArretDefault();
    final nav = await repo.getNavAppDefault();
    final coutLitre = await repo.getCoutCarburantLitre();
    final conso = await repo.getConsoLitresPar100Km();
    if (!mounted) return;
    setState(() {
      _capaciteCtrl.text = cap?.toString() ?? '';
      _dureeArretCtrl.text = duree?.toString() ?? '';
      _navAppDefault = nav;
      _coutLitreCtrl.text = coutLitre.toStringAsFixed(2);
      _consoCtrl.text = conso.toStringAsFixed(1);
      _defaultsInitialized = true;
    });
  }

  /// Charge les stats de cache (taille tuiles + nb entrees geocodage)
  /// pour affichage dans la section Cache. Best-effort : si une lecture
  /// echoue on garde null et l'UI affiche "..." plutot qu'une erreur.
  Future<void> _loadCacheStats() async {
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
  /// Seuils en base 1000 (decimal) plus parlants pour le grand public
  /// qu'un base 1024 (binaire).
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

  @override
  void dispose() {
    _orsKeyCtrl.dispose();
    _capaciteCtrl.dispose();
    _dureeArretCtrl.dispose();
    _coutLitreCtrl.dispose();
    _consoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
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
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x18),
        children: [
          const ParametresSectionTitle('Geocodage'),
          const SizedBox(height: AppSpacing.x10),
          const StatusCard(
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
          const ParametresSectionTitle('Optimisation de tournee'),
          const SizedBox(height: AppSpacing.x10),
          StatusCard(
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
          Text(
            'Cree gratuitement un compte sur openrouteservice.org/dev '
            '(500 optimisations/jour, sans carte de credit), puis colle '
            'ta cle ici. Sans cle, le bouton "Optimiser" reste desactive.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
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
          const ParametresSectionTitle('Tournee par defaut'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Valeurs preremplies a la creation d\'une nouvelle tournee '
            'ou d\'un nouvel arret. Tu peux les modifier au cas par cas.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
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
          Text(
            'Quand tu tapes sur un arret en mode tournee, l\'app de nav '
            'choisie sera mise en avant dans le bottom sheet.',
            style: TextStyle(
              fontSize: 12,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Wrap(
            spacing: AppSpacing.x8,
            children: [
              NavAppChip(
                label: 'Aucune (demander)',
                value: null,
                groupValue: _navAppDefault,
                onSelected: _setNavApp,
              ),
              NavAppChip(
                label: 'Google Maps',
                value: 'maps',
                groupValue: _navAppDefault,
                onSelected: _setNavApp,
              ),
              NavAppChip(
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
          const ParametresSectionTitle('Carburant'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Sert au calcul du cout estime affiche sur chaque tournee '
            'optimisee. Sans impact sur les calculs ORS / VROOM.',
            style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.x12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _coutLitreCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Prix EUR / litre',
                    helperText: '1.85 EUR par defaut',
                    helperMaxLines: 2,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  enabled: _defaultsInitialized,
                  onSubmitted: (_) => _saveCarburant(),
                ),
              ),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: TextField(
                  controller: _consoCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Conso L / 100km',
                    helperText: '7 L/100km par defaut',
                    helperMaxLines: 2,
                  ),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  enabled: _defaultsInitialized,
                  onSubmitted: (_) => _saveCarburant(),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x14),
          FilledButton.icon(
            onPressed: _saving || !_defaultsInitialized ? null : _saveCarburant,
            icon: const Icon(Icons.check),
            label: const Text('Enregistrer les couts carburant'),
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('Cache'),
          const SizedBox(height: AppSpacing.x10),
          // Mini-stats : aide Noah a decider s'il faut purger ou pas.
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
                      _geocodeCacheCount == null
                          ? '...'
                          : '$_geocodeCacheCount',
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
            onPressed: _saving ? null : _purgeCache,
            icon: const Icon(Icons.cleaning_services_outlined),
            label: const Text('Vider le cache de geocodage'),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Force toutes les recherches d\'adresse a re-interroger les '
            'sources. Utile si tu as modifie une adresse ou que tu veux '
            'reessayer une saisie qui a echoue.',
            style: TextStyle(
              fontSize: 12,
              color: p.textMute,
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
          Text(
            'Supprime definitivement les tournees datees d\'il y a plus '
            'd\'un an, avec tous leurs arrets. Garde l\'app legere et la '
            'base de donnees compacte.',
            style: TextStyle(
              fontSize: 12,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Supprime les tuiles OpenStreetMap stockees localement '
            '(utilisees comme cache pour fonctionner hors-ligne dans les '
            'zones deja visitees). Les tuiles seront re-telechargees a '
            'la prochaine visite.',
            style: TextStyle(
              fontSize: 12,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('Notifications'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Les notifications locales (rappels de tournee) sont gerees '
            'par le telephone, pas par un serveur. Aucune CB requise.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          OutlinedButton.icon(
            onPressed: _saving ? null : _testNotification,
            icon: const Icon(Icons.notifications_active_outlined),
            label: const Text('Test : notif dans 2 min'),
          ),
          const SizedBox(height: AppSpacing.x10),
          OutlinedButton.icon(
            onPressed: _saving ? null : _cancelAllNotifications,
            icon: const Icon(Icons.notifications_off_outlined),
            label: const Text('Annuler tous les rappels programmes'),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Coupe les rappels de toutes les tournees + la notif de test '
            'si elle est encore en attente. Pratique en vacances pour pas '
            'etre reveille par un rappel programme la semaine derniere.',
            style: TextStyle(
              fontSize: 12,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x6),
          Text(
            'Programme une notification de test 120 secondes apres le '
            'tap. Ferme l\'app ou eteins l\'ecran pour verifier que la '
            'notif arrive bien.',
            style: TextStyle(
              fontSize: 12,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('Apparence'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Mode sombre pour la conduite de nuit. "Auto" suit les '
            'reglages Android.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
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
                  ThemeChip(
                    label: 'Auto',
                    value: ThemeMode.system,
                    groupValue: mode,
                  ),
                  ThemeChip(
                    label: 'Clair',
                    value: ThemeMode.light,
                    groupValue: mode,
                  ),
                  ThemeChip(
                    label: 'Sombre',
                    value: ThemeMode.dark,
                    groupValue: mode,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x18),
          Text(
            'Palette de couleurs',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Change l\'ambiance des surfaces. Les couleurs metier '
            '(vert = livre, rouge = echec) restent identiques.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          Consumer(
            builder: (context, ref, _) {
              final preset = ref.watch(themePresetProvider).asData?.value ??
                  AppThemePreset.lime;
              return Column(
                children: [
                  for (final p in AppThemePreset.all)
                    PaletteTile(
                      preset: p,
                      selected: p.name == preset.name,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('Accessibilite & confort'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Adapte l\'interface pour la conduite ou les conditions '
            'difficiles (soleil, vibrations).',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          Consumer(
            builder: (context, ref, _) {
              final repo = ref.watch(parametresRepositoryProvider);
              final densite = ref.watch(densiteUiProvider).asData?.value ??
                  'normal';
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: densite == 'large',
                title: const Text('Mode XL (conduite)'),
                subtitle: const Text(
                  'Polices +15%, cibles tactiles agrandies',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (v) async {
                  await repo.setDensiteUi(v ? 'large' : 'normal');
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final repo = ref.watch(parametresRepositoryProvider);
              final contraste = ref
                      .watch(contrasteEleveProvider)
                      .asData
                      ?.value ??
                  false;
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: contraste,
                title: const Text('Contraste eleve'),
                subtitle: const Text(
                  'Bordures et textes renforces pour lire en plein soleil',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (v) async {
                  await repo.setContrasteEleve(v);
                },
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final repo = ref.watch(parametresRepositoryProvider);
              final hhmm = ref
                  .watch(veilleReminderHHmmProvider)
                  .asData
                  ?.value;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.bedtime_outlined),
                title: const Text('Rappel veille auto'),
                subtitle: Text(
                  hhmm == null
                      ? 'Desactive — programme un rappel la veille de '
                          'chaque tournee'
                      : 'Active a $hhmm la veille de chaque tournee',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: hhmm == null
                    ? const Icon(Icons.add)
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(hhmm,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              )),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 20),
                            onPressed: () =>
                                repo.clearVeilleReminderHHmm(),
                          ),
                        ],
                      ),
                onTap: () async {
                  final initial = hhmm == null
                      ? const TimeOfDay(hour: 21, minute: 0)
                      : TimeOfDay(
                          hour: int.parse(hhmm.split(':')[0]),
                          minute: int.parse(hhmm.split(':')[1]),
                        );
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: initial,
                  );
                  if (picked != null) {
                    final h = picked.hour.toString().padLeft(2, '0');
                    final m = picked.minute.toString().padLeft(2, '0');
                    await repo.setVeilleReminderHHmm('$h:$m');
                  }
                },
              );
            },
          ),
          // Mode "Ne pas deranger" : 2 TimePickers cote a cote pour
          // configurer le creneau silencieux. Pendant ce creneau, les
          // notifs immediates (fin de tournee, arrets oublies) sont
          // silencieusement skip. Les rappels planifies par l'user
          // (veille de tournee) restent prioritaires car explicites.
          const _QuietHoursTile(),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('Entreprise & equipe'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Si tu es chef d\'equipe ou si tu factures sous une raison '
            'sociale, renseigne tes infos pour personnaliser tes exports.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          const EntrepriseForm(),
          const SizedBox(height: AppSpacing.x14),
          // Toggle "Mode chef" : active la vue tableau de bord equipe
          // + affectation en masse. Cache si pas pertinent (livreur solo).
          Consumer(
            builder: (context, ref, _) {
              final repo = ref.watch(parametresRepositoryProvider);
              final mode =
                  ref.watch(modeChefProvider).asData?.value ?? false;
              return SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: mode,
                title: const Text('Mode chef d\'equipe'),
                subtitle: const Text(
                  'Active le tableau de bord equipe + affectation en masse',
                  style: TextStyle(fontSize: 12),
                ),
                onChanged: (v) async {
                  await repo.setModeChef(v);
                },
              );
            },
          ),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('Mon equipe'),
          const SizedBox(height: AppSpacing.x10),
          Consumer(
            builder: (context, ref, _) {
              final list =
                  ref.watch(coequipiersAllProvider).asData?.value ?? const [];
              final nbActifs = list.where((c) => c.actif).length;
              return ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('Coequipiers'),
                subtitle: Text(
                  list.isEmpty
                      ? 'Aucun coequipier — ajoute tes aidants pour '
                          'tracker qui livre quoi'
                      : '$nbActifs actif${nbActifs > 1 ? "s" : ""}'
                          '${list.length > nbActifs ? " · ${list.length - nbActifs} archive${list.length - nbActifs > 1 ? "s" : ""}" : ""}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right),
                contentPadding: EdgeInsets.zero,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const CoequipiersScreen(),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('Securite'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Verrouille l\'app avec un code a 4 chiffres (et la biometrie '
            'si ton phone le supporte). Protege le carnet clients, les '
            'codes interphones et les photos preuves si tu perds ton '
            'telephone.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          const SecuriteSection(),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('Donnees'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Sauvegarde complete de l\'app dans un zip portable '
            '(DB SQLite + photos preuves). Conserve sur Drive ou clef '
            'USB pour retrouver tes donnees en cas de perte du phone.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x10),
          const _BackupTile(),
          const _RestoreTile(),
          const _AutoBackupTile(),
          // Tile "Mes backups" : ouvre la liste des .zip auto-generes
          // avec actions par entree (Restaurer / Partager / Supprimer).
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.folder_open_outlined),
            title: const Text('Mes backups'),
            subtitle: const Text(
              'Voir, partager ou supprimer les .zip auto-generes',
              style: TextStyle(fontSize: 12),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const BackupsListScreen(),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const ParametresSectionTitle('A propos'),
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

  Future<void> _saveCarburant() async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(parametresRepositoryProvider);
      final cout = double.tryParse(
              _coutLitreCtrl.text.trim().replaceAll(',', '.')) ??
          ParametresRepository.defaultCoutCarburantLitre;
      final conso = double.tryParse(
              _consoCtrl.text.trim().replaceAll(',', '.')) ??
          ParametresRepository.defaultConsoLitresPar100Km;
      await repo.setCoutCarburantLitre(cout);
      await repo.setConsoLitresPar100Km(conso);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cout carburant enregistre')),
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

  Future<void> _cancelAllNotifications() async {
    setState(() => _saving = true);
    try {
      await NotificationsService.instance.cancelAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tous les rappels programmes ont ete annules'),
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
      await _loadCacheStats();
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
      await _loadCacheStats();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

/// Tile "Ne pas deranger" : 2 TimePickers cote a cote pour configurer
/// le creneau silencieux. Une croix par champ permet d'effacer
/// (= desactive si l'un des 2 est vide).
///
/// Pendant le creneau, les notifs immediates declenchees par l'app
/// (fin de tournee, arrets oublies, etc.) sont silencieusement skip.
/// Les rappels planifies par l'utilisateur (veille de tournee) ne
/// sont PAS impactes : il a explicitement choisi cette heure.
///
/// Gere le cas "creneau qui passe minuit" : par ex 22h -> 06h. La
/// logique de detection vit dans [ParametresRepository.isWithinQuietHours].
class _QuietHoursTile extends ConsumerWidget {
  const _QuietHoursTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final repo = ref.watch(parametresRepositoryProvider);
    final start = ref.watch(_quietStartProvider).asData?.value;
    final end = ref.watch(_quietEndProvider).asData?.value;
    final enabled = start != null && end != null;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.do_not_disturb_on_outlined),
      title: const Text('Ne pas deranger'),
      subtitle: Text(
        enabled
            ? 'Notifs muettes de $start a $end'
            : 'Pas de creneau silencieux configure',
        style: const TextStyle(fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SmallTimeBtn(
            label: start ?? 'Debut',
            isPlaceholder: start == null,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: start == null
                    ? const TimeOfDay(hour: 12, minute: 0)
                    : TimeOfDay(
                        hour: int.parse(start.split(':')[0]),
                        minute: int.parse(start.split(':')[1]),
                      ),
              );
              if (picked != null) {
                final h = picked.hour.toString().padLeft(2, '0');
                final m = picked.minute.toString().padLeft(2, '0');
                await repo.setQuietHoursStart('$h:$m');
              }
            },
            onClear: start == null ? null : () => repo.clearQuietHoursStart(),
            color: p,
          ),
          const SizedBox(width: 6),
          Text('→', style: TextStyle(color: p.textMute)),
          const SizedBox(width: 6),
          _SmallTimeBtn(
            label: end ?? 'Fin',
            isPlaceholder: end == null,
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: end == null
                    ? const TimeOfDay(hour: 14, minute: 0)
                    : TimeOfDay(
                        hour: int.parse(end.split(':')[0]),
                        minute: int.parse(end.split(':')[1]),
                      ),
              );
              if (picked != null) {
                final h = picked.hour.toString().padLeft(2, '0');
                final m = picked.minute.toString().padLeft(2, '0');
                await repo.setQuietHoursEnd('$h:$m');
              }
            },
            onClear: end == null ? null : () => repo.clearQuietHoursEnd(),
            color: p,
          ),
        ],
      ),
    );
  }
}

class _SmallTimeBtn extends StatelessWidget {
  const _SmallTimeBtn({
    required this.label,
    required this.isPlaceholder,
    required this.onTap,
    required this.onClear,
    required this.color,
  });
  final String label;
  final bool isPlaceholder;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  final AppPalette color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.r8),
      onTap: onTap,
      onLongPress: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.creamSoft,
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isPlaceholder ? color.textMute : color.ink,
          ),
        ),
      ),
    );
  }
}

/// Stream du quiet_hours_start (HH:mm ou null si non configure).
final _quietStartProvider = StreamProvider<String?>((ref) {
  return ref.watch(parametresRepositoryProvider).watchQuietHoursStart();
});

/// Stream du quiet_hours_end (HH:mm ou null si non configure).
final _quietEndProvider = StreamProvider<String?>((ref) {
  return ref.watch(parametresRepositoryProvider).watchQuietHoursEnd();
});

/// Tile "Creer une sauvegarde" dans la section Donnees. Genere un
/// zip avec la DB SQLite + le dossier preuves/ et declenche le share
/// natif Android. Operation potentiellement longue (selon nb de
/// photos), donc loading state pendant le travail.
class _BackupTile extends ConsumerStatefulWidget {
  const _BackupTile();

  @override
  ConsumerState<_BackupTile> createState() => _BackupTileState();
}

class _BackupTileState extends ConsumerState<_BackupTile> {
  bool _running = false;

  Future<void> _onBackup() async {
    setState(() => _running = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await BackupService().createBackup();
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            path == null
                ? 'Backup pret (share annule)'
                : 'Backup partage avec succes',
          ),
          backgroundColor: AppColors.emerald,
          duration: const Duration(seconds: 2),
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup refuse : ${e.message}'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur backup : $e')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.archive_outlined),
      title: const Text('Creer une sauvegarde (.zip)'),
      subtitle: const Text(
        'DB + photos preuves dans un fichier partageable',
        style: TextStyle(fontSize: 12),
      ),
      trailing: _running
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.ios_share),
      onTap: _running ? null : _onBackup,
    );
  }
}

/// Tile "Restaurer depuis un .zip" dans la section Donnees.
///
/// Workflow (cf BackupService.prepareRestore) :
/// 1. Dialog de confirmation forte (irreversible : remplace TOUTE
///    la donnee courante).
/// 2. file_picker pour choisir le zip.
/// 3. `prepareRestore` decompresse + valide manifest + pose la DB
///    en `.pending_restore` + extrait les photos preuves.
/// 4. Dialog "Redemarre l'app pour finaliser". Au prochain boot,
///    [BackupService.applyPendingRestoreIfAny] dans main() swap la
///    DB et l'app demarre sur les donnees restaurees.
class _RestoreTile extends ConsumerStatefulWidget {
  const _RestoreTile();

  @override
  ConsumerState<_RestoreTile> createState() => _RestoreTileState();
}

class _RestoreTileState extends ConsumerState<_RestoreTile> {
  bool _running = false;

  Future<void> _onRestore() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // 1. Confirmation forte (operation irreversible)
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurer un backup ?'),
        content: const Text(
          'Cette action va REMPLACER toutes tes donnees actuelles '
          '(tournees, arrets, carnet, parametres) par celles du fichier '
          'zip choisi. Cette operation est IRREVERSIBLE.\n\n'
          'Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuer'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    // 2. file_picker
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
      dialogTitle: 'Choisir un backup opti_route (.zip)',
    );
    if (picked == null || picked.files.isEmpty) return;
    final path = picked.files.first.path;
    if (path == null) return;
    if (!mounted) return;

    setState(() => _running = true);
    try {
      // 3. Prepare le restore (deferred swap)
      await BackupService().prepareRestore(path);
      if (!mounted) return;
      // 4. Dialog "Redemarre l'app"
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: const Text('Restore prepare'),
          content: const Text(
            'Le backup a ete charge avec succes. Ferme completement '
            'l\'app (swipe out du multitache) et relance-la pour que '
            'tes donnees soient restaurees.',
          ),
          actions: [
            FilledButton(
              onPressed: () => navigator.pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } on BackupException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('Restore refuse : ${e.message}'),
          backgroundColor: AppColors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur restore : $e')),
      );
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.unarchive_outlined),
      title: const Text('Restaurer depuis un .zip'),
      subtitle: const Text(
        'Remplace les donnees actuelles par celles du backup',
        style: TextStyle(fontSize: 12),
      ),
      trailing: _running
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _running ? null : _onRestore,
    );
  }
}

/// Tile "Sauvegarde auto" : permet a l'utilisateur de configurer la
/// frequence des backups automatiques (jamais / hebdo / mensuel).
///
/// Les backups auto sont generes au demarrage de l'app si la periode
/// est echue (cf AutoBackupService.maybeRunAutoBackup), dans le
/// dossier `/Android/data/<pkg>/files/auto_backups/`. Rotation des 5
/// derniers pour eviter le gonflement.
///
/// Affiche aussi la date du dernier backup auto reussi pour donner
/// du feedback a l'utilisateur ("ah ok, ca tourne bien").
class _AutoBackupTile extends ConsumerWidget {
  const _AutoBackupTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(_autoBackupPeriodProvider).asData?.value ??
        'jamais';
    final lastAtAsync = ref.watch(_lastAutoBackupAtProvider);
    final lastAt = lastAtAsync.asData?.value;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.history),
      title: const Text('Sauvegarde auto'),
      subtitle: Text(
        _subtitle(period, lastAt),
        style: const TextStyle(fontSize: 12),
      ),
      trailing: DropdownButton<String>(
        value: period,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'jamais', child: Text('Jamais')),
          DropdownMenuItem(value: 'hebdo', child: Text('Hebdo')),
          DropdownMenuItem(value: 'mensuel', child: Text('Mensuel')),
        ],
        onChanged: (v) async {
          if (v == null) return;
          await ref
              .read(parametresRepositoryProvider)
              .setAutoBackupPeriod(v);
        },
      ),
    );
  }

  static String _subtitle(String period, DateTime? lastAt) {
    if (period == 'jamais') {
      return 'Active pour generer un .zip dans Android/data/<app>/files/';
    }
    if (lastAt == null) {
      return 'Programme ($period) - premier backup au prochain demarrage';
    }
    final now = DateTime.now();
    final d = now.difference(lastAt);
    final ago = d.inDays > 0
        ? 'il y a ${d.inDays}j'
        : d.inHours > 0
            ? 'il y a ${d.inHours}h'
            : 'a l\'instant';
    return 'Programme ($period) - dernier $ago';
  }
}

/// Stream du auto_backup_period courant (jamais / hebdo / mensuel).
final _autoBackupPeriodProvider = StreamProvider<String>((ref) {
  return ref.watch(parametresRepositoryProvider).watchAutoBackupPeriod();
});

/// Future du dernier timestamp de backup auto. Non-stream car valeur
/// figee jusqu'au prochain run du service ; lecture one-shot
/// suffisante pour l'affichage "dernier il y a Nj".
final _lastAutoBackupAtProvider = FutureProvider<DateTime?>((ref) {
  // On watch la periode pour re-lire le timestamp quand l'user toggle.
  ref.watch(_autoBackupPeriodProvider);
  return ref.read(parametresRepositoryProvider).getLastAutoBackupAt();
});
