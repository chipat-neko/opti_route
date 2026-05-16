import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:share_plus/share_plus.dart';

import '../../theme/app_tokens.dart';

/// Dialog affiche apres `createInvitation()` reussi (jalon 3.A). Montre
/// le code 6 chiffres en gros + boutons Copier / Partager.
///
/// Le code expire apres 24h cote serveur. On ne le rappelle pas ici
/// pour ne pas alourdir l'UI — si Noah perd le code, il en regenere
/// un nouveau via le meme bouton.
class InvitationCodeDialog extends StatelessWidget {
  const InvitationCodeDialog({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final shareText =
        'Rejoins ma tournee opti_route avec ce code : $code\n'
        '(Parametres > Rejoindre une tournee, code valable 24h)';
    return AlertDialog(
      title: const Text('Code d\'invitation'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Donne ce code a ton coequipier. Il le saisit dans son '
            'app via Parametres > Rejoindre une tournee.',
            style: TextStyle(fontSize: 12, color: p.textMute, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.emeraldSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              code,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: AppColors.emerald,
                fontFamily: 'JetBrainsMono',
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Valable 24h, usage unique.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: p.textMute),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          icon: const Icon(Icons.copy, size: 18),
          label: const Text('Copier'),
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: code));
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Code copie')),
            );
          },
        ),
        TextButton.icon(
          icon: const Icon(Icons.share, size: 18),
          label: const Text('Partager'),
          onPressed: () {
            SharePlus.instance.share(ShareParams(text: shareText));
          },
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fermer'),
        ),
      ],
    );
  }
}
