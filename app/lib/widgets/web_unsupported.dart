import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Écran/section affiché à la place d'une feature qui dépend de
/// capacités natives indisponibles sur le web (caméra, fichiers locaux,
/// GPS embarqué, partage natif...). Évite un crash : on informe l'user
/// au lieu de planter. Utilisé via un garde `if (kIsWeb)`.
///
/// Le multi-tenant, le carnet et les stats restent pleinement
/// utilisables sur web ; seules ces features mobiles sont masquées.
class WebUnsupportedScreen extends StatelessWidget {
  const WebUnsupportedScreen({
    super.key,
    required this.titre,
    required this.message,
  });

  /// Titre de l'AppBar (ex : « Scanner un bordereau »).
  final String titre;

  /// Explication courte de pourquoi c'est indisponible sur navigateur.
  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: Text(titre)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.x22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.devices_outlined, size: 48, color: p.textMute),
              const SizedBox(height: AppSpacing.x16),
              Text(
                'Disponible sur l\'application',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, color: p.textMute, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
