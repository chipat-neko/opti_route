import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/cloud/cloud_membres_entreprise_sync.dart' show EntrepriseMembreInfo;
import '../data/cloud_error_humanizer.dart';
import '../data/database.dart';
import '../providers/database_providers.dart';
import '../providers/supabase_providers.dart';
import '../theme/app_tokens.dart';
import '../widgets/snack.dart';

/// ════════════════════════════════════════════════════════════════
/// Écran « Liste des employés » (carte #361, demande Noah 2026-06-01).
/// ════════════════════════════════════════════════════════════════
///
/// Réservé au chef d'entreprise (admin). Affiche **une carte par entrepôt**
/// de l'entreprise. Dans chaque carte : les **chefs d'entrepôt** en haut,
/// puis les **chauffeurs** en dessous. Le chef peut **muter** un employé :
/// promouvoir/rétrograder (chef ⇄ chauffeur), le déplacer vers un autre
/// entrepôt, ou le révoquer (RPC `set_employe_entrepot` / `revoke_employe`).
///
/// Source de vérité = cloud (RPC `list_entreprise_members`), regroupée
/// côté client par entrepôt.
class ListeEmployesScreen extends ConsumerStatefulWidget {
  const ListeEmployesScreen({
    super.key,
    required this.entrepriseId,
    required this.titre,
    this.peutMuter = false,
    this.filtreEntrepotId,
  });

  final String entrepriseId;

  /// Titre de l'AppBar (« Mon entreprise » / « Mon entrepôt X »).
  final String titre;

  /// Vrai pour le chef d'entreprise (admin) : actions (promouvoir,
  /// déplacer, révoquer) disponibles. Faux = lecture seule (chauffeur).
  final bool peutMuter;

  /// Si non-null, n'affiche QUE la carte de cet entrepôt (vue chef
  /// entrepôt / chauffeur limitée à leur entrepôt).
  final String? filtreEntrepotId;

  @override
  ConsumerState<ListeEmployesScreen> createState() =>
      _ListeEmployesScreenState();
}

class _ListeEmployesScreenState extends ConsumerState<ListeEmployesScreen> {
  bool _busy = false;

  String get _entrepriseId => widget.entrepriseId;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) context.showError(humanizeCloudError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    ref.invalidate(entrepriseMembresProvider(_entrepriseId));
  }

  @override
  Widget build(BuildContext context) {
    final membresAsync = ref.watch(entrepriseMembresProvider(_entrepriseId));
    final entrepotsAsync =
        ref.watch(entrepotsParEntrepriseProvider(_entrepriseId));
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(entrepriseMembresProvider(_entrepriseId)),
        child: membresAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _erreur(humanizeCloudError(e)),
          data: (membres) {
            final entrepots = entrepotsAsync.asData?.value ?? const <Entrepot>[];
            return _contenu(membres, entrepots);
          },
        ),
      ),
    );
  }

  Widget _erreur(String msg) => ListView(
        padding: const EdgeInsets.all(AppSpacing.x16),
        children: [
          const SizedBox(height: AppSpacing.x28),
          Icon(Icons.error_outline, color: context.palette.textMute, size: 40),
          const SizedBox(height: AppSpacing.x12),
          Text(msg, textAlign: TextAlign.center),
        ],
      );

  Widget _contenu(List<EntrepriseMembreInfo> membres, List<Entrepot> entrepots) {
    final p = context.palette;
    if (entrepots.isEmpty) {
      return _erreur('Aucun entrepôt. Crée d\'abord un entrepôt dans '
          'Paramètres → Mon entreprise.');
    }
    // Regroupe les adhésions entrepôt par entrepotId (on ne garde que les
    // lignes rattachées à un entrepôt — la RPC renvoie aussi les lignes
    // entreprise sans entrepôt, qu'on ignore ici).
    final parEntrepot = <String, List<EntrepriseMembreInfo>>{};
    for (final m in membres) {
      if (m.entrepotId == null) continue;
      (parEntrepot[m.entrepotId!] ??= []).add(m);
    }
    // Chef entrepôt / chauffeur : on ne montre que leur entrepôt.
    final entrepotsAffiches = widget.filtreEntrepotId == null
        ? entrepots
        : entrepots.where((e) => e.cloudId == widget.filtreEntrepotId).toList();
    // Membres « sans entrepôt » : présents au niveau entreprise mais
    // rattachés à aucun entrepôt (invités niveau entreprise), hors admin.
    // Affiché seulement pour le chef d'entreprise (vue globale).
    final usersAvecEntrepot =
        membres.where((m) => m.entrepotId != null).map((m) => m.userId).toSet();
    final sansEntrepot = <EntrepriseMembreInfo>[];
    final vus = <String>{};
    if (widget.peutMuter && widget.filtreEntrepotId == null) {
      for (final m in membres) {
        if (m.entrepotId != null) continue; // ligne entrepôt
        if (m.role == 'admin_entreprise') continue; // l'admin lui-même
        if (usersAvecEntrepot.contains(m.userId)) continue; // déjà affecté
        if (!vus.add(m.userId)) continue; // dédoublonne
        sansEntrepot.add(m);
      }
    }
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: [
        if (sansEntrepot.isNotEmpty)
          _carteSansEntrepot(sansEntrepot, entrepots),
        for (final ent in entrepotsAffiches)
          _carteEntrepot(ent, parEntrepot[ent.cloudId] ?? const [], entrepots),
        const SizedBox(height: AppSpacing.x16),
        if (widget.peutMuter)
          Text(
            'Astuce : appuie sur ⋮ à côté d\'un employé pour le promouvoir, '
            'le déplacer ou le révoquer.',
            style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
          ),
      ],
    );
  }

  /// Carte spéciale en haut : membres rattachés à aucun entrepôt. Le chef
  /// peut les affecter à un entrepôt (en tant que chauffeur) ou révoquer.
  Widget _carteSansEntrepot(
      List<EntrepriseMembreInfo> membres, List<Entrepot> entrepots) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x14),
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline, size: 20, color: AppColors.amber),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text('Sans entrepôt',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.ink)),
              ),
              Text('${membres.length}',
                  style: TextStyle(color: p.textMute, fontSize: 13)),
            ],
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            'Ces membres ont rejoint l\'entreprise sans entrepôt. Affecte-les '
            'à un entrepôt.',
            style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
          ),
          const SizedBox(height: AppSpacing.x8),
          for (final m in membres) _ligneSansEntrepot(m, entrepots),
        ],
      ),
    );
  }

  Widget _ligneSansEntrepot(EntrepriseMembreInfo m, List<Entrepot> entrepots) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: p.textMute),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(m.nomAffiche,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: p.ink, fontWeight: FontWeight.w600)),
          ),
          PopupMenuButton<String>(
            tooltip: 'Affecter',
            enabled: !_busy,
            icon: Icon(Icons.more_vert, size: 20, color: p.textMute),
            onSelected: (v) {
              if (v == 'revoke') {
                _revoquer(m);
              } else {
                final ent = entrepots.firstWhere((e) => e.cloudId == v);
                _affecter(m, ent);
              }
            },
            itemBuilder: (_) => [
              for (final e in entrepots)
                PopupMenuItem(value: e.cloudId, child: Text('Affecter à ${e.nom}')),
              const PopupMenuItem(
                  value: 'revoke', child: Text('Révoquer l\'employé')),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _affecter(EntrepriseMembreInfo m, Entrepot ent) async {
    await _run(() async {
      await ref.read(cloudSyncServiceProvider).setEmployeEntrepot(
            entrepriseId: _entrepriseId,
            userId: m.userId,
            entrepotId: ent.cloudId,
            role: 'employe',
          );
      if (mounted) context.showSuccess('${m.email} affecté à ${ent.nom}');
    });
  }

  Widget _carteEntrepot(
    Entrepot ent,
    List<EntrepriseMembreInfo> membres,
    List<Entrepot> tousEntrepots,
  ) {
    final p = context.palette;
    // Chefs en haut, chauffeurs en dessous, révoqués/expirés à la fin.
    final chefs = membres.where((m) => m.role == 'chef_entrepot').toList();
    final chauffeurs = membres.where((m) => m.role == 'employe').toList();
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x14),
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.warehouse_outlined, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(ent.nom,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: p.ink)),
              ),
              Text('${membres.length}',
                  style: TextStyle(color: p.textMute, fontSize: 13)),
            ],
          ),
          const Divider(height: AppSpacing.x22),
          _sousSection('Chefs d\'entrepôt', Icons.shield_outlined, chefs, ent,
              tousEntrepots),
          const SizedBox(height: AppSpacing.x10),
          _sousSection('Chauffeurs', Icons.local_shipping_outlined, chauffeurs,
              ent, tousEntrepots),
        ],
      ),
    );
  }

  Widget _sousSection(
    String titre,
    IconData icone,
    List<EntrepriseMembreInfo> membres,
    Entrepot ent,
    List<Entrepot> tousEntrepots,
  ) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(icone, size: 16, color: p.textMute),
            const SizedBox(width: AppSpacing.x6),
            Text(titre.toUpperCase(),
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: p.textMute)),
          ],
        ),
        const SizedBox(height: AppSpacing.x4),
        if (membres.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
            child: Text('—',
                style: TextStyle(fontSize: 13, color: p.textFaint)),
          )
        else
          for (final m in membres) _ligneMembre(m, ent, tousEntrepots),
      ],
    );
  }

  Widget _ligneMembre(
      EntrepriseMembreInfo m, Entrepot ent, List<Entrepot> tousEntrepots) {
    final p = context.palette;
    final estChef = m.role == 'chef_entrepot';
    final jours = m.joursAvantExpiration;
    final (statutLabel, statutColor) = switch (m.statut) {
      'actif' => ('actif', AppColors.emerald),
      'revoque' => (
          jours == null ? 'révoqué' : 'révoqué · J-$jours',
          AppColors.amber
        ),
      _ => ('expiré', AppColors.red),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Icon(Icons.person_outline, size: 18, color: p.textMute),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.nomAffiche,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: p.ink, fontWeight: FontWeight.w600)),
                // Si un nom est défini, on montre l'email en petit dessous
                // (pratique pour distinguer deux homonymes). Sinon rien.
                if (m.displayName != null && m.displayName!.trim().isNotEmpty)
                  Text(m.email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: p.textFaint)),
                Text(estChef ? 'Chef d\'entrepôt' : 'Chauffeur',
                    style: TextStyle(fontSize: 12, color: p.textMute)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x8, vertical: 2),
            decoration: BoxDecoration(
              color: statutColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(statutLabel,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statutColor)),
          ),
          // Actions réservées au chef d'entreprise (admin). Lecture seule
          // pour les chefs d'entrepôt / chauffeurs.
          if (widget.peutMuter)
            PopupMenuButton<String>(
              tooltip: 'Actions',
              enabled: !_busy,
              icon: Icon(Icons.more_vert, size: 20, color: p.textMute),
              onSelected: (v) => _onAction(v, m, ent, tousEntrepots),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'role',
                  child: Text(estChef
                      ? 'Rétrograder en chauffeur'
                      : 'Promouvoir chef d\'entrepôt'),
                ),
                if (tousEntrepots.length > 1)
                  const PopupMenuItem(
                      value: 'move', child: Text('Déplacer vers un entrepôt')),
                const PopupMenuItem(
                    value: 'revoke', child: Text('Révoquer l\'employé')),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _onAction(String action, EntrepriseMembreInfo m, Entrepot ent,
      List<Entrepot> tousEntrepots) async {
    switch (action) {
      case 'role':
        final nouveauRole = m.role == 'chef_entrepot' ? 'employe' : 'chef_entrepot';
        await _run(() async {
          await ref.read(cloudSyncServiceProvider).setEmployeEntrepot(
                entrepriseId: _entrepriseId,
                userId: m.userId,
                entrepotId: ent.cloudId,
                role: nouveauRole,
              );
          if (mounted) {
            context.showSuccess(nouveauRole == 'chef_entrepot'
                ? '${m.email} est maintenant chef d\'entrepôt'
                : '${m.email} est maintenant chauffeur');
          }
        });
      case 'move':
        await _deplacer(m, ent, tousEntrepots);
      case 'revoke':
        await _revoquer(m);
    }
  }

  Future<void> _deplacer(EntrepriseMembreInfo m, Entrepot actuel,
      List<Entrepot> tousEntrepots) async {
    final cibles = tousEntrepots.where((e) => e.cloudId != actuel.cloudId).toList();
    final cible = await showDialog<Entrepot>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Déplacer ${m.email} vers…'),
        children: [
          for (final e in cibles)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(e),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
                child: Text(e.nom),
              ),
            ),
        ],
      ),
    );
    if (cible == null) return;
    await _run(() async {
      // Conserve son rôle actuel dans le nouvel entrepôt.
      await ref.read(cloudSyncServiceProvider).setEmployeEntrepot(
            entrepriseId: _entrepriseId,
            userId: m.userId,
            entrepotId: cible.cloudId,
            role: m.role,
          );
      if (mounted) context.showSuccess('${m.email} déplacé vers ${cible.nom}');
    });
  }

  Future<void> _revoquer(EntrepriseMembreInfo m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Révoquer cet employé ?'),
        content: Text(
          '${m.email} perdra l\'accès au carnet partagé. L\'accès est coupé '
          'progressivement : définitif après 30 jours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(cloudSyncServiceProvider).revokeEmploye(
            entrepriseId: _entrepriseId,
            userId: m.userId,
          );
      if (mounted) context.showSuccess('${m.email} révoqué');
    });
  }
}
