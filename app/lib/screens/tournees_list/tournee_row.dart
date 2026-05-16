import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/cloud_sync_service.dart';
import '../../data/database.dart';
import '../../providers/database_providers.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';
import '../tournee_du_jour_screen.dart';
import '../tournee_form_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// Widgets d'une ligne de tournee dans la liste principale.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `tournees_list_screen.dart` (772 lignes initiales) :
/// - [TourneeRow]   : la row complete (Dismissible + Material + InkWell
///                    + actions bottom sheet sur long press)
/// - [StatutBadge]  : pastille colore "B/O/E/T" selon le statut
/// - [DefautCoBadge]: mini badge "→ Lucas" si la tournee a un
///                    coequipier par defaut (mode chef)
class TourneeRow extends ConsumerWidget {
  const TourneeRow({super.key, required this.tournee});

  final Tournee tournee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final dateFormat = DateFormat('EEE d MMM', 'fr');
    final isTerminee = tournee.statut == 'terminee';
    final hasStats = isTerminee &&
        tournee.distanceTotaleM != null &&
        tournee.dureeTotaleS != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Dismissible(
        key: ValueKey('tournee-${tournee.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.r14),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x22),
          child: const Icon(Icons.delete_outline, color: AppColors.red),
        ),
        confirmDismiss: (_) => _confirmDelete(context, tournee),
        onDismissed: (_) async {
          await ref.read(tourneesRepositoryProvider).delete(tournee.id);
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Tournee "${tournee.nom}" supprimee')),
          );
        },
        child: Material(
          color: p.paper,
          borderRadius: BorderRadius.circular(AppRadius.r14),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.r14),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => TourneeDuJourScreen(tournee: tournee),
              ),
            ),
            onLongPress: () => _showActions(context, ref),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.x14),
              child: Row(
                children: [
                  StatutBadge(statut: tournee.statut),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tournee.nom,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: p.ink,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              dateFormat.format(tournee.date),
                              style: TextStyle(
                                fontSize: 12,
                                color: p.textMute,
                              ),
                            ),
                            // Mini badge "→ Lucas" si la tournee a un
                            // coequipier par defaut (mode chef).
                            if (tournee.coequipierDefautId != null)
                              DefautCoBadge(
                                coequipierId: tournee.coequipierDefautId!,
                              ),
                          ],
                        ),
                        if (hasStats) ...[
                          const SizedBox(height: AppSpacing.x6),
                          Text(
                            '${(tournee.distanceTotaleM! / 1000).toStringAsFixed(1)} km · ${_formatDuration(tournee.dureeTotaleS!)}',
                            style: appMonoStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.emerald,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Indicateur sync cloud : icone discrete emerald
                  // visible uniquement si la tournee a deja ete poussee
                  // au moins une fois (cloud_id != null). Indique a
                  // l'utilisateur que cette tournee est sauvegardee
                  // hors du telephone.
                  if (tournee.cloudId != null) ...[
                    const Icon(
                      Icons.cloud_done_outlined,
                      size: 16,
                      color: AppColors.emerald,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Icon(
                    Icons.chevron_right,
                    color: p.textFaint,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Bottom sheet d'actions sur une tournee (long press) : Editer la
  /// fiche / Dupliquer en nouveau template / (la suppression reste sur
  /// le swipe lateral comme avant).
  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final p = context.palette;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.x18,
            AppSpacing.x14,
            AppSpacing.x18,
            AppSpacing.x18,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.x14),
                  decoration: BoxDecoration(
                    color: p.inkLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                tournee.nom,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.x14),
              // Bouton "Pousser au cloud" : visible uniquement si la
              // build a les credentials Supabase. Libelle adaptatif
              // selon si la tournee est deja sync (cloudId != null) ou
              // non. Icone emerald pour matcher l'indicateur de la card.
              if (ref.watch(cloudConfiguredProvider)) ...[
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.paper,
                    foregroundColor: p.ink,
                    minimumSize: const Size(0, 52),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    await _pushToCloud(context, ref, messenger);
                  },
                  icon: Icon(
                    tournee.cloudId == null
                        ? Icons.cloud_upload_outlined
                        : Icons.cloud_sync_outlined,
                    color: AppColors.emerald,
                  ),
                  label: Text(
                    tournee.cloudId == null
                        ? 'Pousser au cloud'
                        : 'Synchroniser au cloud',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: AppSpacing.x8),
              ],
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.paper,
                  foregroundColor: p.ink,
                  minimumSize: const Size(0, 52),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  navigator.push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          TourneeFormScreen(initial: tournee),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
                label: const Text(
                  'Modifier la fiche tournee',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: AppSpacing.x8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  // Tournee deja marquee template -> CTA visible
                  // (lime, plus engageant). Sinon -> simple copie
                  // ponctuelle (paper, plus neutre).
                  backgroundColor:
                      tournee.isTemplate ? AppColors.lime : p.paper,
                  foregroundColor: p.ink,
                  minimumSize: const Size(0, 52),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () async {
                  // Date picker : demande au user pour quelle date il
                  // veut creer la nouvelle tournee. Par defaut, le
                  // lendemain de la tournee source (cas le plus
                  // frequent : "je refais la meme demain").
                  final defaultDate = DateTime.now().isAfter(tournee.date)
                      ? DateTime.now().add(const Duration(days: 1))
                      : tournee.date.add(const Duration(days: 7));
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: defaultDate,
                    firstDate: DateTime.now()
                        .subtract(const Duration(days: 30)),
                    lastDate: DateTime.now()
                        .add(const Duration(days: 365)),
                    locale: const Locale('fr', 'FR'),
                    helpText: tournee.isTemplate
                        ? 'Date de la nouvelle tournee'
                        : 'Date de la copie',
                  );
                  if (pickedDate == null) return;
                  if (!context.mounted) return;
                  Navigator.of(sheetContext).pop();
                  try {
                    final newId = await ref
                        .read(tourneesRepositoryProvider)
                        .duplicate(tournee.id, targetDate: pickedDate);
                    if (!context.mounted) return;
                    final newTournee = await ref
                        .read(tourneesRepositoryProvider)
                        .getById(newId);
                    if (!context.mounted || newTournee == null) return;
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Duplique en "${newTournee.nom}"',
                        ),
                        backgroundColor: AppColors.emerald,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                    navigator.push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            TourneeDuJourScreen(tournee: newTournee),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    messenger.showSnackBar(
                      SnackBar(content: Text('Erreur duplication : $e')),
                    );
                  }
                },
                icon: Icon(tournee.isTemplate
                    ? Icons.add_box_outlined
                    : Icons.content_copy_outlined),
                label: Text(
                  tournee.isTemplate
                      ? 'Creer une tournee depuis ce template'
                      : 'Dupliquer cette tournee',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: AppSpacing.x8),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: p.paper,
                  foregroundColor: p.ink,
                  minimumSize: const Size(0, 52),
                  alignment: Alignment.centerLeft,
                ),
                onPressed: () async {
                  Navigator.of(sheetContext).pop();
                  await ref
                      .read(tourneesRepositoryProvider)
                      .toggleTemplate(tournee.id);
                  if (!context.mounted) return;
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        tournee.isTemplate
                            ? 'Plus marquee comme template'
                            : 'Marquee comme template recurrent',
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                icon: Icon(
                  tournee.isTemplate ? Icons.star : Icons.star_border,
                  color: tournee.isTemplate
                      ? AppColors.amber
                      : p.ink,
                ),
                label: Text(
                  tournee.isTemplate
                      ? 'Retirer du Templates'
                      : 'Marquer comme template',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              // Partager le template via JSON + share natif (visible
              // uniquement si la tournee est marquee template, sinon
              // c'est rarement pertinent).
              if (tournee.isTemplate) ...[
                const SizedBox(height: AppSpacing.x8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: p.paper,
                    foregroundColor: p.ink,
                    minimumSize: const Size(0, 52),
                    alignment: Alignment.centerLeft,
                  ),
                  onPressed: () async {
                    Navigator.of(sheetContext).pop();
                    try {
                      await ref
                          .read(templateShareServiceProvider)
                          .shareTemplate(tournee.id);
                    } catch (e) {
                      if (!context.mounted) return;
                      messenger.showSnackBar(
                        SnackBar(content: Text('Erreur partage : $e')),
                      );
                    }
                  },
                  icon: const Icon(Icons.ios_share),
                  label: const Text(
                    'Partager le template (JSON)',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Pousse la tournee + ses stops + coequipiers references vers
  /// Supabase. Affiche une SnackBar de chargement puis success / error
  /// avec le message FR de [CloudSyncException]. Pas de Navigator
  /// interaction ici : on a deja fait .pop() du bottom sheet avant
  /// l'appel.
  Future<void> _pushToCloud(
    BuildContext context,
    WidgetRef ref,
    ScaffoldMessengerState messenger,
  ) async {
    final service = ref.read(cloudSyncServiceProvider);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Sync en cours...'),
        duration: Duration(seconds: 10),
      ),
    );
    try {
      await service.pushTournee(tournee.id);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Tournee synchronisee au cloud'),
          backgroundColor: AppColors.emerald,
        ),
      );
    } on CloudSyncException catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  static String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h == 0) return '${m}min';
    return '${h}h${m.toString().padLeft(2, '0')}';
  }

  Future<bool?> _confirmDelete(BuildContext context, Tournee t) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette tournee ?'),
        content: Text(
          '"${t.nom}" et tous ses arrets seront supprimes definitivement.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

/// Pastille carree colore avec une lettre selon le statut de la
/// tournee : B (brouillon), O (optimisee), E (en cours), T (terminee).
class StatutBadge extends StatelessWidget {
  const StatutBadge({super.key, required this.statut});

  final String statut;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    // Couleurs alignees sur les tokens du handoff :
    // - active : ink + halo lime
    // - terminee : emerald
    // - optimisee : creamSoft + ink
    // - brouillon (default) : paper + outline ink
    final (letter, bg, fg, border) = switch (statut) {
      'optimisee' =>
        ('O', p.creamSoft, p.ink, p.inkLine),
      'en_cours' => ('E', p.ink, AppColors.lime, null),
      'terminee' => ('T', AppColors.emerald, p.paper, null),
      _ => ('B', p.paper, p.ink, p.inkLine),
    };
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.r10),
        border: border != null ? Border.all(color: border, width: 1.5) : null,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Mini badge "→ Lucas" affiche a cote de la date d'une tournee qui
/// a un coequipier par defaut. Sert au chef d'equipe a identifier
/// d'un coup d'oeil quelle tournee est preparee pour qui.
class DefautCoBadge extends ConsumerWidget {
  const DefautCoBadge({super.key, required this.coequipierId});

  final int coequipierId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(coequipiersByIdProvider)[coequipierId];
    if (c == null) return const SizedBox.shrink();
    final color = colorFromTag(c.colorTag, defaultColor: AppColors.creamSoft);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.x6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(AppRadius.r8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.arrow_forward,
              size: 10,
              color: AppColors.ink,
            ),
            const SizedBox(width: 3),
            Text(
              c.nom,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
