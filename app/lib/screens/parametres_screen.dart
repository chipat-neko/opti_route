import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud_error_humanizer.dart';
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
import 'parametres/apparence_accessibilite_section.dart';
import 'parametres/cloud_section.dart';
import 'parametres/donnees_section.dart';
import 'parametres/entreprise_form.dart';
import 'parametres/ocr_stats_tile.dart';
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
          const ApparenceSection(),
          const SizedBox(height: AppSpacing.x28),
          const Divider(),
          const SizedBox(height: AppSpacing.x18),
          const AccessibiliteSection(),
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
          const ParametresSectionTitle('Compte cloud'),
          const SizedBox(height: AppSpacing.x10),
          Text(
            'Phase 2 (en construction) : connecte un compte pour '
            'synchroniser entre tes appareils et partager les tournees '
            'avec tes coequipiers en temps reel. Pour l\'instant le '
            'mode local-only reste l\'autorite.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.textMute,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.x12),
          const CloudSection(),
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
          const BackupTile(),
          const RestoreTile(),
          const AutoBackupTile(),
          const OcrStatsTile(),
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
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
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
        SnackBar(content: Text('Erreur : ${humanizeAnyError(e)}')),
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
