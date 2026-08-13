import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud/cloud_membres_entreprise_sync.dart'
    show EntrepriseMembreInfo;
import '../../data/cloud_error_humanizer.dart';
import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';
import '../../widgets/snack.dart';
import 'entreprise/entreprise_card.dart';
import 'entreprise/entreprise_confirm_dialogs.dart';
import 'entreprise/entreprise_form_dialogs.dart';
import 'entreprise/entreprise_invitation_dialogs.dart';
import 'entreprise/info_ligne.dart';
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
///
/// **Découpage (F27)** : ce fichier ne garde que l'état et les *actions*
/// cloud (busy + erreurs humanisées). Le rendu et les formulaires sont
/// dans `entreprise/` :
///   - `entreprise_card.dart` : la carte d'une entreprise, qui calcule
///     `isAdmin` et le propage aux sous-listes ;
///   - `entrepots_list.dart` / `membres_list.dart` : les deux listes ;
///   - `entreprise_badges.dart` / `info_ligne.dart` : petits widgets ;
///   - `entreprise_form_dialogs.dart`, `entreprise_invitation_dialogs
///     .dart`, `entreprise_confirm_dialogs.dart` : les dialogs.
class EntrepriseMultiTenantSection extends ConsumerStatefulWidget {
  const EntrepriseMultiTenantSection({super.key});

  @override
  ConsumerState<EntrepriseMultiTenantSection> createState() =>
      _EntrepriseMultiTenantSectionState();
}

class _EntrepriseMultiTenantSectionState
    extends ConsumerState<EntrepriseMultiTenantSection> {
  bool _busy = false;

  /// Vrai tant que le 1er pull cloud n'est pas terminé. Évite d'afficher
  /// l'état « Créer / Rejoindre » (trompeur) à un employé invité pendant
  /// que ses entreprises/entrepôts arrivent du cloud (latence serveur).
  bool _pullEnCours = true;

  @override
  void initState() {
    super.initState();
    // Pull best-effort après le 1er frame : récupère une entreprise
    // créée sur un autre appareil ou via invitation. Silencieux.
    WidgetsBinding.instance.addPostFrameCallback((_) => _pullSilencieux());
  }

  Future<void> _pullSilencieux() async {
    if (ref.read(cloudUserProvider).asData?.value == null) {
      if (mounted) setState(() => _pullEnCours = false);
      return;
    }
    try {
      await ref.read(cloudSyncServiceProvider).pullMesEntreprises();
    } catch (_) {
      // Best-effort : le miroir local reste affiché tel quel.
    } finally {
      if (mounted) setState(() => _pullEnCours = false);
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
    final ok = await EntrepriseConfirmDialogs.supprimerEntreprise(context, e);
    if (ok != true) return;
    await _run(() async {
      await ref.read(cloudSyncServiceProvider).deleteEntreprise(e.cloudId);
      ref.invalidate(mesEntreprisesProvider);
      if (mounted) context.showSuccess('Entreprise « ${e.nom} » supprimée');
    });
  }

  Future<void> _quitterEntreprise(Entreprise e) async {
    final ok = await EntrepriseConfirmDialogs.quitterEntreprise(context, e);
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
    final res = await showDialog<EntrepriseFormResult>(
      context: context,
      builder: (_) => EntrepriseFormDialog(requiresCode: !isAdmin),
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
    final res = await showDialog<EntrepotFormResult>(
      context: context,
      builder: (_) => const EntrepotFormDialog(),
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
          const InfoLigne(
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
          InfoLigne(icon: Icons.error_outline, texte: humanizeCloudError(e)),
      data: (entreprises) {
        // Pendant le 1er pull cloud, ne pas montrer « Créer / Rejoindre »
        // si la liste locale est encore vide : un employé invité verrait
        // un faux message l'invitant à créer une entreprise (latence).
        if (entreprises.isEmpty && _pullEnCours) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.x12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (entreprises.isEmpty) return _etatVide();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final e in entreprises)
              EntrepriseCard(
                entreprise: e,
                userId: userId,
                busy: _busy,
                onSupprimer: () => _supprimerEntreprise(e),
                onQuitter: () => _quitterEntreprise(e),
                onAjouterEntrepot: () => _ajouterEntrepot(e.cloudId),
                onInviterMembre: () => _inviterMembre(e),
                onRevoquerMembre: (m) => _revoquerMembre(e, m),
              ),
          ],
        );
      },
    );
  }

  Widget _etatVide() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.icon(
          onPressed: _busy ? null : _creerEntreprise,
          icon: const Icon(Icons.add_business_outlined),
          label: const Text('Créer mon entreprise'),
        ),
        const SizedBox(height: AppSpacing.x8),
        OutlinedButton.icon(
          onPressed: _busy ? null : _rejoindreParCode,
          icon: const Icon(Icons.groups_outlined, size: 18),
          label: const Text('Rejoindre avec un code'),
        ),
      ],
    );
  }

  /// Rejoindre une entreprise/entrepôt avec un code d'invitation (donné
  /// par le chef). Même flux que l'onboarding « Qui es-tu ? » mais
  /// accessible à tout moment depuis les Paramètres.
  Future<void> _rejoindreParCode() async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const RejoindreCodeDialog(),
    );
    if (code == null) return;
    await _run(() async {
      final sync = ref.read(cloudSyncServiceProvider);
      await sync.acceptEntrepriseInvitationByCode(code);
      await sync.pullMesEntreprises();
      ref.invalidate(mesEntreprisesProvider);
      if (mounted) context.showSuccess('Bienvenue dans l\'équipe !');
    });
  }

  // ─── Membres / employés (carte #366) ──────────────────────────────

  Future<void> _inviterMembre(Entreprise e) async {
    final entrepots =
        ref.read(entrepotsParEntrepriseProvider(e.cloudId)).asData?.value ??
            const [];
    final res = await showDialog<InviteResult>(
      context: context,
      builder: (_) => InviteDialog(entrepots: entrepots),
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
          await CodeEmployeDialog.show(context, r.code, validite: '7 jours');
        }
      } else {
        final code = await sync.inviteEmployeByCode(
          entrepriseId: e.cloudId,
          entrepotId: res.entrepotId,
          roleTarget: res.roleTarget,
        );
        if (mounted) await CodeEmployeDialog.show(context, code);
      }
      ref.invalidate(entrepriseMembresProvider(e.cloudId));
    });
  }

  Future<void> _revoquerMembre(Entreprise e, EntrepriseMembreInfo m) async {
    final ok = await EntrepriseConfirmDialogs.revoquerMembre(context, m);
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
