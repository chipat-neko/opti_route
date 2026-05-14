import 'package:flutter/material.dart';

import '../../data/bordereau_extraction.dart';
import '../../theme/app_theme.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Cartes d'affichage des resultats du parser de bordereau.
/// ════════════════════════════════════════════════════════════════
///
/// Extrait de `scan_bordereau_screen.dart` (850 lignes initiales) pour
/// alleger l'ecran principal. 3 widgets statless :
/// - [AutoDetectionCard]      : carte lime "DETECTION AUTOMATIQUE"
///                              quand le parser a tout extrait
/// - [UncertainDetectionCard] : carte amber "DETECTION INCERTAINE"
///                              quand le parser hesite, invite a
///                              verifier manuellement les lignes
/// - [ExtractedRow]           : ligne label/valeur reutilisee par
///                              les 2 cartes ci-dessus

/// Carte verte (lime) affichee en haut quand le parser a reussi a
/// extraire au moins un champ. Permet a l'utilisateur de tout valider
/// en 1 tap via le bouton "Utiliser ces infos".
class AutoDetectionCard extends StatelessWidget {
  const AutoDetectionCard({
    super.key,
    required this.extraction,
    required this.onUse,
  });

  final BordereauExtraction extraction;
  final VoidCallback onUse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.lime,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.ink, size: 18),
              const SizedBox(width: AppSpacing.x8),
              Text(
                'DETECTION AUTOMATIQUE',
                style: appMonoStyle(
                  fontSize: 11,
                  color: AppColors.ink,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x10),
          if (extraction.nomDestinataire != null)
            ExtractedRow(
              label: 'CLIENT',
              value: extraction.nomDestinataire!,
              bold: true,
            ),
          if (extraction.rue != null)
            ExtractedRow(label: 'RUE', value: extraction.rue!),
          if (extraction.codePostal != null || extraction.ville != null)
            ExtractedRow(
              label: 'VILLE',
              value: [
                if (extraction.codePostal != null) extraction.codePostal!,
                if (extraction.ville != null) extraction.ville!,
              ].join(' '),
            ),
          if (extraction.nbColis != null)
            ExtractedRow(
              label: 'COLIS',
              value: '${extraction.nbColis}',
              mono: true,
            ),
          if (extraction.telephone != null)
            ExtractedRow(
              label: 'TEL',
              value: extraction.telephone!,
              mono: true,
            ),
          const SizedBox(height: AppSpacing.x12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onUse,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.ink,
                foregroundColor: AppColors.lime,
                minimumSize: const Size(0, 48),
              ),
              icon: const Icon(Icons.check),
              label: const Text('Utiliser ces infos'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte orange (amber) affichee quand le parser a trouve quelque
/// chose mais n'est pas confiant : il y a des champs detectes mais
/// soit incomplets, soit ambigus. On invite l'utilisateur a verifier
/// manuellement au lieu de pre-remplir automatiquement.
class UncertainDetectionCard extends StatelessWidget {
  const UncertainDetectionCard({super.key, required this.extraction});

  final BordereauExtraction extraction;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x14),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(AppRadius.r14),
        border: Border.all(color: AppColors.amber, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_outlined,
                color: p.ink,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.x8),
              Text(
                'DETECTION INCERTAINE',
                style: appMonoStyle(
                  fontSize: 11,
                  color: p.ink,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Text(
            'Le bordereau ne suit pas un format que je reconnais '
            'parfaitement. Verifie les bonnes lignes manuellement '
            'ci-dessous pour eviter une mauvaise adresse.',
            style: TextStyle(
              fontSize: 12.5,
              color: p.ink,
              height: 1.4,
            ),
          ),
          if (extraction.codePostal != null ||
              extraction.ville != null ||
              extraction.nbColis != null) ...[
            const SizedBox(height: AppSpacing.x10),
            Text(
              'Champs detectes (a verifier) :',
              style: appMonoStyle(
                fontSize: 10,
                color: p.ink.withValues(alpha: 0.7),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            if (extraction.codePostal != null || extraction.ville != null)
              ExtractedRow(
                label: 'VILLE?',
                value: [
                  if (extraction.codePostal != null) extraction.codePostal!,
                  if (extraction.ville != null) extraction.ville!,
                ].join(' '),
              ),
            if (extraction.nbColis != null)
              ExtractedRow(
                label: 'COLIS?',
                value: '${extraction.nbColis}',
                mono: true,
              ),
          ],
        ],
      ),
    );
  }
}

/// Ligne label/valeur reutilisee par [AutoDetectionCard] et
/// [UncertainDetectionCard]. Largeur fixe du label (56px) pour
/// alignement vertical des valeurs.
///
/// `bold` : renforce le poids du texte de la valeur (utilise pour
/// le nom du destinataire).
/// `mono` : utilise la police monospace (pour les numeros : colis,
/// telephone).
class ExtractedRow extends StatelessWidget {
  const ExtractedRow({
    super.key,
    required this.label,
    required this.value,
    this.bold = false,
    this.mono = false,
  });

  final String label;
  final String value;
  final bool bold;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    // ExtractedRow est toujours rendu sur fond accent fixe (lime ou
    // amber) donc texte ink fixe pour rester lisible dans les 2 modes.
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              label,
              style: appMonoStyle(
                fontSize: 10,
                color: AppColors.ink.withValues(alpha: 0.6),
                letterSpacing: 0.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Text(
              value,
              style: mono
                  ? appMonoStyle(
                      fontSize: 13,
                      color: AppColors.ink,
                      fontWeight:
                          bold ? FontWeight.w800 : FontWeight.w700,
                    )
                  : const TextStyle(
                      fontSize: 13,
                      color: AppColors.ink,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ).copyWith(
                      fontWeight:
                          bold ? FontWeight.w800 : FontWeight.w600,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
