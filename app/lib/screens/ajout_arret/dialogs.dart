import 'package:flutter/material.dart';

import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Dialogs reutilises par [AjoutArretScreen].
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `ajout_arret_screen.dart` (767 lignes, 2e passe) pour
/// alleger le state widget principal. Stateless purs : retournent un
/// `Future<T?>` que le caller traite en setState.

/// Dialog "Saisie hors ligne" : champ texte multi-lignes pour saisir
/// une adresse a la main quand le geocodage n'est pas disponible.
/// Retourne la string saisie (potentiellement vide pour effacement),
/// ou null si l'utilisateur annule (back / Annuler).
Future<String?> showOfflineAddressDialog(
  BuildContext context, {
  String? initial,
}) {
  final ctrl = TextEditingController(text: initial ?? '');
  return showDialog<String>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Saisie hors ligne'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tape l\'adresse complete a la main. Le GPS sera '
              'manquant tant que tu n\'auras pas re-edite cet arret '
              'avec une connexion (re-selection depuis l\'autocomplete).',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
            const SizedBox(height: AppSpacing.x12),
            TextField(
              controller: ctrl,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Adresse',
                hintText: '12 rue des Lilas, 28100 Dreux',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(ctrl.text.trim()),
            child: const Text('Valider'),
          ),
        ],
      );
    },
  );
}
