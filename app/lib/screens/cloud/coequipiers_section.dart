import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_sync_service.dart';
import '../../data/database.dart';
import '../../data/supabase_service.dart';
import '../../providers/supabase_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Coequipiers" affichee dans l'ecran d'une tournee partagee
/// (sous-jalon 3.B). Visible seulement si :
/// - la tournee a un cloudId (= deja pushee au cloud)
/// - count >= 2 (au moins 1 coequipier en plus du owner)
/// ════════════════════════════════════════════════════════════════
///
/// Liste les membres avec leur email + role (owner / member) + date
/// de join. Actions disponibles :
/// - Owner : peut "Ejecter" chaque member (DELETE row tournee_membres)
/// - Tout user : peut "Quitter" sa propre row (sauf si owner)
class CoequipiersSection extends ConsumerStatefulWidget {
  const CoequipiersSection({super.key, required this.tournee});

  final Tournee tournee;

  @override
  ConsumerState<CoequipiersSection> createState() =>
      _CoequipiersSectionState();
}

class _CoequipiersSectionState extends ConsumerState<CoequipiersSection> {
  Future<List<TourneeMembreInfo>>? _membersFuture;

  @override
  void initState() {
    super.initState();
    _membersFuture = _load();
  }

  Future<List<TourneeMembreInfo>> _load() {
    return ref.read(cloudSyncServiceProvider).listTourneeMembers(
          widget.tournee.id,
        );
  }

  void _reload() {
    setState(() {
      _membersFuture = _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cloudId = widget.tournee.cloudId;
    if (cloudId == null) return const SizedBox.shrink();
    return FutureBuilder<List<TourneeMembreInfo>>(
      future: _membersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) {
          // Erreur silencieuse : on ne polluera pas l'ecran tournee
          // avec un message d'erreur de cloud. Le user voit juste pas
          // la section.
          return const SizedBox.shrink();
        }
        final members = snapshot.data ?? const [];
        if (members.length < 2) {
          // Pas encore partagee (just owner = perso).
          return const SizedBox.shrink();
        }
        return _SectionContent(
          tournee: widget.tournee,
          members: members,
          onChanged: _reload,
        );
      },
    );
  }
}

class _SectionContent extends ConsumerWidget {
  const _SectionContent({
    required this.tournee,
    required this.members,
    required this.onChanged,
  });

  final Tournee tournee;
  final List<TourneeMembreInfo> members;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final myUserId = SupabaseService.instance.currentUser?.id;
    final iAmOwner = members.any(
      (m) => m.userCloudId == myUserId && m.isOwner,
    );
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x14,
        vertical: AppSpacing.x8,
      ),
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: p.paper,
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: p.inkLine, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.groups_outlined,
                size: 18,
                color: AppColors.emerald,
              ),
              const SizedBox(width: 6),
              Text(
                'Coequipiers (${members.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          for (final m in members)
            _MemberRow(
              tournee: tournee,
              member: m,
              isMe: m.userCloudId == myUserId,
              iAmOwner: iAmOwner,
              onChanged: onChanged,
            ),
        ],
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  const _MemberRow({
    required this.tournee,
    required this.member,
    required this.isMe,
    required this.iAmOwner,
    required this.onChanged,
  });

  final Tournee tournee;
  final TourneeMembreInfo member;
  final bool isMe;
  final bool iAmOwner;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: member.isOwner
                ? AppColors.emeraldSoft
                : p.creamSoft,
            foregroundColor: member.isOwner ? AppColors.emerald : p.ink,
            child: Icon(
              member.isOwner ? Icons.shield_outlined : Icons.person_outline,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.email + (isMe ? ' (moi)' : ''),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.ink,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  member.isOwner ? 'Chef' : 'Coequipier',
                  style: TextStyle(fontSize: 10, color: p.textMute),
                ),
              ],
            ),
          ),
          if (iAmOwner && !isMe && !member.isOwner)
            IconButton(
              tooltip: 'Ejecter ce coequipier',
              icon: const Icon(Icons.person_remove_outlined,
                  size: 18, color: AppColors.red),
              onPressed: () => _confirmKick(context, ref),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmKick(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ejecter ce coequipier ?'),
        content: Text(
          '${member.email} perdra l\'acces a cette tournee et a tous ses '
          'arrets. Tu pourras le reinviter via un nouveau code 6 chiffres.',
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
            child: const Text('Ejecter'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(cloudSyncServiceProvider)
          .kickMember(tournee.id, member.userCloudId);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${member.email} ejecte'),
          backgroundColor: AppColors.emerald,
        ),
      );
      onChanged();
    } on CloudSyncException catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }
}
