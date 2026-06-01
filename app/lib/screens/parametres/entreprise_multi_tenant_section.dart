import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud/cloud_membres_entreprise_sync.dart'
    show EntrepriseMembreInfo;
import '../../data/cloud_error_humanizer.dart';
import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/snack.dart';
import 'parametres_widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// Section « Mon entreprise » des Paramètres (multi-tenant, carte #364).
/// ════════════════════════════════════════════════════════════════
///
/// Permet au chef de **créer son entreprise** puis d'y **ajouter des
/// entrepôts**. Source de vérité = Supabase (RLS) ; l'affichage lit le
/// miroir local Drift, rafraîchi par un pull au montage.
///
/// États :
///   - pas connecté au cloud → invite à se connecter (section juste en
///     dessous dans les Paramètres) ;
///   - connecté, aucune entreprise → CTA « Créer mon entreprise » ;
///   - connecté, ≥ 1 entreprise → carte par entreprise (nom + SIRET +
///     liste des entrepôts + bouton « Ajouter un entrepôt » si admin).
///
/// **Permissions** : pour ce jalon, « admin » = créateur de l'entreprise
/// (`entreprise.createdBy == userId`). Les rôles chef_entrepot / employé
/// arriveront avec la gestion des employés (#366).
class EntrepriseMultiTenantSection extends ConsumerStatefulWidget {
  const EntrepriseMultiTenantSection({super.key});

  @override
  ConsumerState<EntrepriseMultiTenantSection> createState() =>
      _EntrepriseMultiTenantSectionState();
}

class _EntrepriseMultiTenantSectionState
    extends ConsumerState<EntrepriseMultiTenantSection> {
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    // Pull best-effort après le 1er frame : récupère une entreprise
    // créée sur un autre appareil ou via invitation. Silencieux.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pullSilencieux());
  }

  Future<void> _pullSilencieux() async {
    if (ref.read(cloudUserProvider).asData?.value == null) return;
    try {
      await ref.read(cloudSyncServiceProvider).pullMesEntreprises();
    } catch (_) {
      // Best-effort : le miroir local reste affiché tel quel.
    }
  }

  /// Exécute une action cloud avec gestion busy + erreurs humanisées.
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
  }

  Future<void> _supprimerEntreprise(Entreprise e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette entreprise ?'),
        content: Text(
          'L\'entreprise « ${e.nom} », ses entrepôts, ses employés et les '
          'invitations en cours seront supprimés définitivement. Cette '
          'action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(cloudSyncServiceProvider).deleteEntreprise(e.cloudId);
      ref.invalidate(mesEntreprisesProvider);
      if (mounted) context.showSuccess('Entreprise « ${e.nom} » supprimée');
    });
  }

  Future<void> _quitterEntreprise(Entreprise e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter cette entreprise ?'),
        content: Text(
          'Tu n\'auras plus accès au carnet partagé de « ${e.nom} ». Tu '
          'pourras la rejoindre à nouveau avec un code d\'invitation.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(cloudSyncServiceProvider).leaveEntreprise(e.cloudId);
      ref.invalidate(mesEntreprisesProvider);
      if (mounted) context.showSuccess('Tu as quitté « ${e.nom} »');
    });
  }

  Future<void> _creerEntreprise() async {
    // Le super admin (Noah) est dispensé du code maître (#374) : on lui
    // évite le champ. En cas d'échec réseau, on demande le code par défaut
    // (c'est le serveur qui tranche de toute façon).
    bool isAdmin = false;
    try {
      isAdmin = await ref.read(cloudSyncServiceProvider).isSuperAdmin();
    } on Object {
      isAdmin = false;
    }
    if (!mounted) return;
    final res = await showDialog<_EntrepriseFormResult>(
      context: context,
      builder: (_) => _EntrepriseFormDialog(requiresCode: !isAdmin),
    );
    if (res == null) return;
    await _run(() async {
      await ref
          .read(cloudSyncServiceProvider)
          .createEntreprise(nom: res.nom, siret: res.siret, code: res.code);
      if (mounted) context.showSuccess('Entreprise « ${res.nom} » créée');
    });
  }

  Future<void> _ajouterEntrepot(String entrepriseId) async {
    final res = await showDialog<_EntrepotFormResult>(
      context: context,
      builder: (_) => const _EntrepotFormDialog(),
    );
    if (res == null) return;
    await _run(() async {
      await ref.read(cloudSyncServiceProvider).createEntrepot(
            entrepriseId: entrepriseId,
            nom: res.nom,
            adresse: res.adresse,
          );
      if (mounted) context.showSuccess('Entrepôt « ${res.nom} » ajouté');
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final user = ref.watch(cloudUserProvider).asData?.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Mon entreprise'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Crée ton entreprise pour partager ton carnet d\'adresses avec '
          'tes employés et organiser tes entrepôts.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x12),
        if (user == null)
          const _InfoLigne(
            icon: Icons.cloud_off_outlined,
            texte: 'Connecte ton compte cloud (section ci-dessous) pour '
                'créer ou rejoindre une entreprise.',
          )
        else
          _contenuConnecte(user.id),
      ],
    );
  }

  Widget _contenuConnecte(String userId) {
    final async = ref.watch(mesEntreprisesProvider);
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) =>
          _InfoLigne(icon: Icons.error_outline, texte: humanizeCloudError(e)),
      data: (entreprises) {
        if (entreprises.isEmpty) return _etatVide();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in entreprises) _carteEntreprise(e, userId),
          ],
        );
      },
    );
  }

  Widget _etatVide() {
    return Align(
      alignment: Alignment.centerLeft,
      child: FilledButton.icon(
        onPressed: _busy ? null : _creerEntreprise,
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Créer mon entreprise'),
      ),
    );
  }

  Widget _carteEntreprise(Entreprise e, String userId) {
    final p = context.palette;
    final isAdmin = e.createdBy == userId;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x12),
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
              Icon(Icons.business, size: 20, color: p.ink),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Text(
                  e.nom,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                  ),
                ),
              ),
              if (isAdmin) const _BadgeAdmin(),
              // Menu sortie : Supprimer (admin) ou Quitter (membre).
              PopupMenuButton<String>(
                tooltip: 'Options',
                enabled: !_busy,
                icon: Icon(Icons.more_vert, size: 20, color: p.textMute),
                onSelected: (v) {
                  if (v == 'delete') _supprimerEntreprise(e);
                  if (v == 'leave') _quitterEntreprise(e);
                },
                itemBuilder: (_) => [
                  if (isAdmin)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Supprimer l\'entreprise'),
                    )
                  else
                    const PopupMenuItem(
                      value: 'leave',
                      child: Text('Quitter l\'entreprise'),
                    ),
                ],
              ),
            ],
          ),
          if (e.siret != null) ...[
            const SizedBox(height: AppSpacing.x4),
            Text('SIRET ${e.siret}',
                style: TextStyle(fontSize: 12, color: p.textMute)),
          ],
          const Divider(height: AppSpacing.x22),
          _listeEntrepots(e.cloudId, isAdmin),
          const Divider(height: AppSpacing.x22),
          _listeMembres(e, isAdmin),
        ],
      ),
    );
  }

  Widget _listeEntrepots(String entrepriseId, bool isAdmin) {
    final p = context.palette;
    final async = ref.watch(entrepotsParEntrepriseProvider(entrepriseId));
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.x8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) =>
          _InfoLigne(icon: Icons.error_outline, texte: humanizeCloudError(e)),
      data: (entrepots) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entrepots.isEmpty)
              Text(
                'Aucun entrepôt pour l\'instant.',
                style: TextStyle(fontSize: 12.5, color: p.textMute),
              )
            else
              for (final ent in entrepots) _ligneEntrepot(ent),
            if (isAdmin) ...[
              const SizedBox(height: AppSpacing.x8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed:
                      _busy ? null : () => _ajouterEntrepot(entrepriseId),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un entrepôt'),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _ligneEntrepot(Entrepot ent) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x6),
      child: Row(
        children: [
          Icon(Icons.warehouse_outlined, size: 18, color: p.textMute),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ent.nom,
                    style: TextStyle(color: p.ink, fontWeight: FontWeight.w600)),
                if (ent.adresse != null)
                  Text(ent.adresse!,
                      style: TextStyle(fontSize: 12, color: p.textMute)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Membres / employés (carte #366) ──────────────────────────────

  Widget _listeMembres(Entreprise e, bool isAdmin) {
    final p = context.palette;
    final async = ref.watch(entrepriseMembresProvider(e.cloudId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.groups_outlined, size: 18, color: p.ink),
            const SizedBox(width: AppSpacing.x8),
            Text('Employés',
                style: TextStyle(fontWeight: FontWeight.w700, color: p.ink)),
          ],
        ),
        const SizedBox(height: AppSpacing.x8),
        async.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.x8),
            child: LinearProgressIndicator(),
          ),
          error: (err, _) => _InfoLigne(
              icon: Icons.error_outline, texte: humanizeCloudError(err)),
          data: (membres) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (membres.isEmpty)
                  Text('Aucun employé pour l\'instant.',
                      style: TextStyle(fontSize: 12.5, color: p.textMute))
                else
                  for (final m in membres) _ligneMembre(e, m, isAdmin),
                if (isAdmin) ...[
                  const SizedBox(height: AppSpacing.x8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _inviterMembre(e),
                      icon: const Icon(Icons.person_add_alt_1_outlined,
                          size: 18),
                      label: const Text('Inviter un employé'),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _ligneMembre(
      Entreprise e, EntrepriseMembreInfo m, bool isAdmin) {
    final p = context.palette;
    final jours = m.joursAvantExpiration;
    final (statutLabel, statutColor) = switch (m.statut) {
      'actif' => ('actif', AppColors.emerald),
      'revoque' => (
          jours == null ? 'révoqué' : 'révoqué · J-$jours',
          AppColors.amber
        ),
      _ => ('expiré', AppColors.red),
    };
    final roleLabel = switch (m.role) {
      'admin_entreprise' => 'Admin',
      'chef_entrepot' => 'Chef entrepôt',
      'membre' => 'Membre',
      _ => m.role,
    };
    final sousTitre = [
      roleLabel,
      if (m.entrepotNom != null) m.entrepotNom!,
    ].join(' · ');
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
                Text(m.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: p.ink, fontWeight: FontWeight.w600)),
                Text(sousTitre,
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
          // Révoquer : admin uniquement, pas sur soi-même, pas sur un
          // membre déjà révoqué/expiré.
          if (isAdmin && m.statut == 'actif' && m.role != 'admin_entreprise')
            IconButton(
              tooltip: 'Révoquer',
              icon: const Icon(Icons.person_remove_outlined, size: 20),
              onPressed: _busy ? null : () => _revoquerMembre(e, m),
            ),
        ],
      ),
    );
  }

  Future<void> _inviterMembre(Entreprise e) async {
    final entrepots =
        ref.read(entrepotsParEntrepriseProvider(e.cloudId)).asData?.value ??
            const [];
    final res = await showDialog<_InviteResult>(
      context: context,
      builder: (_) => _InviteDialog(entrepots: entrepots),
    );
    if (res == null) return;
    await _run(() async {
      final sync = ref.read(cloudSyncServiceProvider);
      if (res.parMail) {
        final r = await sync.inviteEmployeByMail(
          entrepriseId: e.cloudId,
          entrepotId: res.entrepotId,
          email: res.email!,
          roleTarget: res.roleTarget,
        );
        if (mounted) {
          if (r.emailSent) {
            context.showSuccess('Invitation envoyée à ${res.email}');
          } else {
            context.showError('Mail non parti (config Brevo ?) — '
                'communique le code ci-dessous à la main');
          }
          // Filet de sécurité : on montre le code même quand le mail est
          // parti (il peut tomber en spam / tarder).
          await _afficherCode(r.code, validite: '7 jours');
        }
      } else {
        final code = await sync.inviteEmployeByCode(
          entrepriseId: e.cloudId,
          entrepotId: res.entrepotId,
          roleTarget: res.roleTarget,
        );
        if (mounted) await _afficherCode(code);
      }
      ref.invalidate(entrepriseMembresProvider(e.cloudId));
    });
  }

  /// Affiche le code généré dans un dialog copiable (72h de validité).
  Future<void> _afficherCode(String code, {String validite = '72 h'}) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Code d\'invitation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Donne ce code à ton employé. Il le saisira dans '
                '« Rejoindre une équipe ». Valable $validite.'),
            const SizedBox(height: AppSpacing.x16),
            SelectableText(
              code,
              style: const TextStyle(
                  fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: 4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              ctx.showInfo('Code copié');
            },
            child: const Text('Copier'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _revoquerMembre(Entreprise e, EntrepriseMembreInfo m) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Révoquer cet employé ?'),
        content: Text(
          '${m.email} perdra l\'accès au carnet partagé. L\'accès est '
          'coupé progressivement : définitif après 30 jours (tu peux '
          'réactiver avant).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Révoquer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _run(() async {
      await ref.read(cloudSyncServiceProvider).revokeEntrepriseMember(
            entrepriseId: e.cloudId,
            userId: m.userId,
            entrepotId: m.entrepotId,
          );
      if (mounted) context.showSuccess('Employé révoqué');
      ref.invalidate(entrepriseMembresProvider(e.cloudId));
    });
  }
}

/// Petit badge « Admin » affiché sur les entreprises dont l'utilisateur
/// courant est le créateur.
class _BadgeAdmin extends StatelessWidget {
  const _BadgeAdmin();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: AppSpacing.x8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Admin',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.emerald,
        ),
      ),
    );
  }
}

/// Ligne d'information (icône + texte muté) pour les états vides /
/// déconnecté / erreur.
class _InfoLigne extends StatelessWidget {
  const _InfoLigne({required this.icon, required this.texte});

  final IconData icon;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: p.textMute),
        const SizedBox(width: AppSpacing.x8),
        Expanded(
          child: Text(texte,
              style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4)),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Dialogs de saisie
// ════════════════════════════════════════════════════════════════

/// Résultat du dialog d'invitation (#366).
class _InviteResult {
  const _InviteResult({
    required this.parMail,
    required this.roleTarget,
    this.email,
    this.entrepotId,
  });
  final bool parMail; // true = mail magic link, false = code 6 chiffres
  final String roleTarget; // 'employe' | 'chef_entrepot'
  final String? email;
  final String? entrepotId;
}

/// Dialog « Inviter un employé » : méthode (code/mail), rôle, entrepôt
/// optionnel. UI simple/fonctionnelle (focus fonctions, pas le visuel).
class _InviteDialog extends StatefulWidget {
  const _InviteDialog({required this.entrepots});

  final List<Entrepot> entrepots;

  @override
  State<_InviteDialog> createState() => _InviteDialogState();
}

class _InviteDialogState extends State<_InviteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _parMail = false;
  String _role = 'employe';
  String? _entrepotId;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_parMail && !(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      _InviteResult(
        parMail: _parMail,
        roleTarget: _role,
        email: _parMail ? _emailCtrl.text.trim() : null,
        entrepotId: _entrepotId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Inviter un employé'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Méthode : code ou mail
            SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Code')),
                ButtonSegment(value: true, label: Text('Mail')),
              ],
              selected: {_parMail},
              onSelectionChanged: (s) => setState(() => _parMail = s.first),
            ),
            const SizedBox(height: AppSpacing.x12),
            // Rôle
            DropdownButtonFormField<String>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Rôle'),
              items: const [
                DropdownMenuItem(value: 'employe', child: Text('Employé')),
                DropdownMenuItem(
                    value: 'chef_entrepot', child: Text('Chef d\'entrepôt')),
              ],
              onChanged: (v) => setState(() => _role = v ?? 'employe'),
            ),
            const SizedBox(height: AppSpacing.x10),
            // Entrepôt optionnel
            DropdownButtonFormField<String?>(
              initialValue: _entrepotId,
              decoration:
                  const InputDecoration(labelText: 'Entrepôt (optionnel)'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Toute l\'entreprise')),
                for (final e in widget.entrepots)
                  DropdownMenuItem(value: e.cloudId, child: Text(e.nom)),
              ],
              onChanged: (v) => setState(() => _entrepotId = v),
            ),
            if (_parMail) ...[
              const SizedBox(height: AppSpacing.x10),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email de l\'employé',
                  hintText: 'marc@exemple.com',
                ),
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty || !s.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: _valider,
          child: Text(_parMail ? 'Envoyer' : 'Générer le code'),
        ),
      ],
    );
  }
}

class _EntrepriseFormResult {
  const _EntrepriseFormResult(this.nom, this.siret, this.code);
  final String nom;
  final String? siret;
  final String? code;
}

class _EntrepriseFormDialog extends StatefulWidget {
  const _EntrepriseFormDialog({required this.requiresCode});

  /// Code maître (#374) exigé, sauf pour le super admin.
  final bool requiresCode;

  @override
  State<_EntrepriseFormDialog> createState() => _EntrepriseFormDialogState();
}

class _EntrepriseFormDialogState extends State<_EntrepriseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _siretCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _siretCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState?.validate() ?? false) {
      final siret = _siretCtrl.text.trim();
      final code = _codeCtrl.text.trim();
      Navigator.of(context).pop(
        _EntrepriseFormResult(
          _nomCtrl.text.trim(),
          siret.isEmpty ? null : siret,
          code.isEmpty ? null : code,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Créer mon entreprise'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'entreprise',
                hintText: 'Ex : CALOTE Transports',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: AppSpacing.x8),
            TextFormField(
              controller: _siretCtrl,
              keyboardType: TextInputType.number,
              maxLength: 14,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'SIRET (optionnel)',
                hintText: '14 chiffres',
              ),
              validator: (v) {
                final s = v?.trim() ?? '';
                if (s.isEmpty) return null;
                return s.length == 14 ? null : '14 chiffres, ou laisse vide';
              },
            ),
            if (widget.requiresCode) ...[
              const SizedBox(height: AppSpacing.x8),
              TextFormField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Code d\'activation',
                  hintText: '6 chiffres fournis par le responsable',
                ),
                validator: (v) {
                  if (!widget.requiresCode) return null;
                  return (v == null || v.trim().isEmpty) ? 'Code requis' : null;
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _valider, child: const Text('Créer')),
      ],
    );
  }
}

class _EntrepotFormResult {
  const _EntrepotFormResult(this.nom, this.adresse);
  final String nom;
  final String? adresse;
}

class _EntrepotFormDialog extends StatefulWidget {
  const _EntrepotFormDialog();

  @override
  State<_EntrepotFormDialog> createState() => _EntrepotFormDialogState();
}

class _EntrepotFormDialogState extends State<_EntrepotFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();

  @override
  void dispose() {
    _nomCtrl.dispose();
    _adresseCtrl.dispose();
    super.dispose();
  }

  void _valider() {
    if (_formKey.currentState?.validate() ?? false) {
      final adresse = _adresseCtrl.text.trim();
      Navigator.of(context).pop(
        _EntrepotFormResult(
          _nomCtrl.text.trim(),
          adresse.isEmpty ? null : adresse,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un entrepôt'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nomCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nom de l\'entrepôt',
                hintText: 'Ex : Dépôt Chartres',
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
            ),
            const SizedBox(height: AppSpacing.x8),
            TextFormField(
              controller: _adresseCtrl,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Adresse (optionnelle)',
                hintText: 'Ex : 12 rue des Lilas, 28000 Chartres',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _valider, child: const Text('Ajouter')),
      ],
    );
  }
}
