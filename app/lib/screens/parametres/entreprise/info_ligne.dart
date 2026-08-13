import 'package:flutter/material.dart';

import '../../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Ligne d'information (icône + texte muté) pour les états vides /
/// déconnecté / erreur de la section « Mon entreprise » (F27).
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `entreprise_multi_tenant_section.dart`. Sert aussi bien
/// au message « connecte ton compte cloud » qu'au rendu d'une erreur
/// déjà humanisée par `humanizeCloudError`.
class InfoLigne extends StatelessWidget {
  const InfoLigne({super.key, required this.icon, required this.texte});

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
