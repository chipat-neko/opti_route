import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/notifications_service.dart';
import '../../theme/app_tokens.dart';
import 'parametres_widgets.dart';

/// ════════════════════════════════════════════════════════════════
/// Section "Notifications" — test + annulation des rappels locaux.
/// ════════════════════════════════════════════════════════════════
///
/// Les notifications locales (rappels de tournee) sont 100% device
/// via `flutter_local_notifications`. Deux actions :
///   - Test : programme une notif dans 120 secondes (verifier que le
///     systeme delivre bien meme app fermee / ecran eteint)
///   - Annuler tous les rappels programmes (utile en vacances)
class NotificationsSection extends ConsumerStatefulWidget {
  const NotificationsSection({super.key});

  @override
  ConsumerState<NotificationsSection> createState() =>
      _NotificationsSectionState();
}

class _NotificationsSectionState extends ConsumerState<NotificationsSection> {
  bool _saving = false;

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

  Future<void> _cancelAll() async {
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

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ParametresSectionTitle('Notifications'),
        const SizedBox(height: AppSpacing.x10),
        Text(
          'Les notifications locales (rappels de tournee) sont gerees '
          'par le telephone, pas par un serveur. Aucune CB requise.',
          style: TextStyle(fontSize: 12.5, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x10),
        OutlinedButton.icon(
          onPressed: _saving ? null : _testNotification,
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Test : notif dans 2 min'),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          'Programme une notification de test 120 secondes apres le '
          'tap. Ferme l\'app ou eteins l\'ecran pour verifier que la '
          'notif arrive bien.',
          style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
        ),
        const SizedBox(height: AppSpacing.x10),
        OutlinedButton.icon(
          onPressed: _saving ? null : _cancelAll,
          icon: const Icon(Icons.notifications_off_outlined),
          label: const Text('Annuler tous les rappels programmes'),
        ),
        const SizedBox(height: AppSpacing.x6),
        Text(
          'Coupe les rappels de toutes les tournees + la notif de test '
          'si elle est encore en attente. Pratique en vacances pour pas '
          'etre reveille par un rappel programme la semaine derniere.',
          style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
        ),
      ],
    );
  }
}
