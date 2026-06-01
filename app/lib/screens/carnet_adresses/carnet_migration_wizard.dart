import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/snack.dart';

/// ════════════════════════════════════════════════════════════════
/// Wizard de migration du carnet local → cloud partagé (carte #365).
/// ════════════════════════════════════════════════════════════════
///
/// Épopée multi-tenant #361, jalon 4/6. Permet à l'utilisateur de
/// décider, **adresse par adresse** (décision Q6 du questionnaire), si
/// chacune de ses adresses locales reste privée ou est partagée avec
/// son entreprise / un de ses entrepôts (portée Q3 : entreprise +
/// entrepôt).
///
/// Flux :
///   1. Snapshot des adresses privées au montage (liste figée pour ne
///      pas changer sous les doigts pendant l'édition).
///   2. Pour chaque adresse, un menu déroulant : Privé / Toute
///      l'entreprise / Entrepôt X. Boutons en masse en tête.
///   3. « Enregistrer » applique les portées (bump updatedAt → l'auto-
///      push cloud propage) et marque le wizard terminé.
///
/// L'écran n'est ouvert que si l'utilisateur a au moins une entreprise
/// (garanti par le banner appelant). Pour le MVP on cible la **première**
/// entreprise de l'utilisateur (cas mono-entreprise de Noah) ; le
/// multi-entreprise viendra si le besoin émerge.
class CarnetMigrationWizard extends ConsumerStatefulWidget {
  const CarnetMigrationWizard({super.key, required this.entreprise});

  /// Entreprise cible du partage (la 1re de l'utilisateur).
  final Entreprise entreprise;

  @override
  ConsumerState<CarnetMigrationWizard> createState() =>
      _CarnetMigrationWizardState();
}

/// Choix de portée pour une adresse. `entrepotId` n'a de sens que si
/// `entrepriseId` est non-null. (null, null) = privé.
class _Portee {
  const _Portee({this.entrepriseId, this.entrepotId});
  final String? entrepriseId;
  final String? entrepotId;

  bool get isPrive => entrepriseId == null;

  /// Clé d'identité pour le `value` du DropdownButton.
  String get key => entrepotId ?? (entrepriseId ?? 'prive');
}

class _CarnetMigrationWizardState
    extends ConsumerState<CarnetMigrationWizard> {
  /// Snapshot figé des adresses à trier (chargé une fois).
  List<SavedDestination>? _adresses;

  /// Décision courante par id d'adresse. Défaut implicite = privé.
  final Map<int, _Portee> _choix = {};

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSnapshot();
  }

  Future<void> _loadSnapshot() async {
    final repo = ref.read(savedDestinationsRepositoryProvider);
    final list = await repo.watchPrivees().first;
    if (!mounted) return;
    setState(() => _adresses = list);
  }

  /// Applique une portée en masse à toutes les adresses du snapshot.
  void _appliquerAToutes(_Portee portee) {
    final list = _adresses;
    if (list == null) return;
    setState(() {
      for (final a in list) {
        _choix[a.id] = portee;
      }
    });
  }

  Future<void> _enregistrer() async {
    final list = _adresses;
    if (list == null || _saving) return;
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final repo = ref.read(savedDestinationsRepositoryProvider);
      var partagees = 0;
      for (final a in list) {
        final portee = _choix[a.id] ?? const _Portee();
        // On n'écrit que si la portée change réellement (évite des
        // bumps updatedAt + pushes inutiles sur les adresses laissées
        // privées qui l'étaient déjà).
        final dejaPrive = a.entrepriseId == null && a.entrepotId == null;
        if (portee.isPrive && dejaPrive) continue;
        if (a.entrepriseId == portee.entrepriseId &&
            a.entrepotId == portee.entrepotId) {
          continue;
        }
        await repo.setPortee(
          a.id,
          entrepriseId: portee.entrepriseId,
          entrepotId: portee.entrepotId,
        );
        if (!portee.isPrive) partagees++;
      }
      await ref
          .read(parametresRepositoryProvider)
          .setCarnetMigrationDone(true);
      if (!mounted) return;
      messenger.showSuccess(partagees == 0
          ? 'Carnet rangé — tout est resté privé.'
          : '$partagees adresse${partagees > 1 ? "s" : ""} partagée'
              '${partagees > 1 ? "s" : ""} (synchro en cours)');
      navigator.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        context.showError('Échec : $e');
      }
    }
  }

  /// Marque le wizard terminé sans rien partager (« Plus tard » / croix).
  Future<void> _ignorer() async {
    await ref.read(parametresRepositoryProvider).setCarnetMigrationDone(true);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final entrepotsAsync =
        ref.watch(entrepotsParEntrepriseProvider(widget.entreprise.cloudId));
    final entrepots = entrepotsAsync.asData?.value ?? const [];

    return Scaffold(
      backgroundColor: p.cream,
      appBar: AppBar(
        title: const Text('Partager mon carnet'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _ignorer,
            child: const Text('Plus tard'),
          ),
        ],
      ),
      body: SafeArea(
        child: _adresses == null
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(p, entrepots),
      ),
      bottomNavigationBar: _adresses == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x16),
                child: FilledButton.icon(
                  onPressed: _saving ? null : _enregistrer,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
            ),
    );
  }

  Widget _buildBody(AppPalette p, List<Entrepot> entrepots) {
    final list = _adresses!;
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x22),
          child: Text(
            'Toutes tes adresses sont déjà rangées 👍',
            style: TextStyle(color: p.textMute),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x16,
            AppSpacing.x12,
            AppSpacing.x16,
            AppSpacing.x8,
          ),
          child: Text(
            'Choisis quelles adresses partager avec ${widget.entreprise.nom}. '
            'Les adresses partagées seront visibles par tes employés ; '
            'les autres restent privées sur ton téléphone.',
            style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
          ),
        ),
        // Boutons en masse
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x12),
          child: Wrap(
            spacing: AppSpacing.x8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _appliquerAToutes(const _Portee()),
                icon: const Icon(Icons.lock_outline, size: 16),
                label: const Text('Tout garder privé'),
              ),
              OutlinedButton.icon(
                onPressed: () => _appliquerAToutes(
                    _Portee(entrepriseId: widget.entreprise.cloudId)),
                icon: const Icon(Icons.business, size: 16),
                label: const Text('Tout à l\'entreprise'),
              ),
            ],
          ),
        ),
        const Divider(height: AppSpacing.x22),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x12),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.x4),
            itemBuilder: (_, i) => _ligne(list[i], entrepots, p),
          ),
        ),
      ],
    );
  }

  Widget _ligne(
      SavedDestination a, List<Entrepot> entrepots, AppPalette p) {
    final portee = _choix[a.id] ?? const _Portee();
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x12, vertical: AppSpacing.x8),
      decoration: BoxDecoration(
        color: portee.isPrive ? null : AppColors.lime.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.r10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.nomClient?.trim().isNotEmpty == true
                      ? a.nomClient!
                      : a.adresseDisplay,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style:
                      TextStyle(fontWeight: FontWeight.w600, color: p.ink),
                ),
                if (a.nomClient?.trim().isNotEmpty == true)
                  Text(
                    a.adresseDisplay,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: p.textMute),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          _dropdown(a, portee, entrepots),
        ],
      ),
    );
  }

  Widget _dropdown(
      SavedDestination a, _Portee portee, List<Entrepot> entrepots) {
    return DropdownButton<String>(
      value: portee.key,
      underline: const SizedBox.shrink(),
      isDense: true,
      items: [
        const DropdownMenuItem(value: 'prive', child: Text('Privé')),
        DropdownMenuItem(
          value: widget.entreprise.cloudId,
          child: const Text('Entreprise'),
        ),
        for (final e in entrepots)
          DropdownMenuItem(
            value: e.cloudId,
            child: Text(e.nom, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: (value) {
        setState(() {
          if (value == null || value == 'prive') {
            _choix[a.id] = const _Portee();
          } else if (value == widget.entreprise.cloudId) {
            _choix[a.id] = _Portee(entrepriseId: widget.entreprise.cloudId);
          } else {
            // value = cloudId d'un entrepôt
            _choix[a.id] = _Portee(
              entrepriseId: widget.entreprise.cloudId,
              entrepotId: value,
            );
          }
        });
      },
    );
  }
}
