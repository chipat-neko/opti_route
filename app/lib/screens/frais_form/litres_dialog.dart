import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;

import '../../theme/app_tokens.dart';

/// Dialog "Combien de litres ?" qui calcule le montant en direct
/// (litres × prix Diesel station). Retourne le nb de litres saisi,
/// ou null si l'utilisateur annule (le caller laisse alors le montant
/// vide pour saisie manuelle). Carte Trello #39 V4.
///
/// Sert apres la selection d'une station Diesel dans le BottomSheet :
/// le caller pre-remplit le libelle puis demande combien de litres ont
/// ete mis pour calculer le montant final EUR = litres × prix.
///
/// Default 50L (typique plein vehicule utilitaire).
Future<double?> promptForLitres(
  BuildContext context, {
  required double pricePerLitre,
}) async {
  final ctrl = TextEditingController(text: '50');
  var currentMontant = pricePerLitre * 50;
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSt) {
        return AlertDialog(
          title: const Text('Combien de litres ?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: ctrl,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                decoration: const InputDecoration(
                  labelText: 'Litres',
                  suffixText: 'L',
                  hintText: '50',
                ),
                onChanged: (v) {
                  final l = double.tryParse(v.replaceAll(',', '.'));
                  setSt(() {
                    currentMontant = (l ?? 0) * pricePerLitre;
                  });
                },
              ),
              const SizedBox(height: AppSpacing.x12),
              Text(
                'Prix Diesel : '
                '${pricePerLitre.toStringAsFixed(3)} EUR/L',
                style: TextStyle(
                  fontSize: 12,
                  color: context.palette.textMute,
                ),
              ),
              const SizedBox(height: AppSpacing.x4),
              Text(
                'Montant : ${currentMontant.toStringAsFixed(2)} EUR',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emerald,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Annuler'),
            ),
            FilledButton(
              onPressed: () {
                final l = double.tryParse(
                  ctrl.text.replaceAll(',', '.'),
                );
                Navigator.of(ctx).pop(l);
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    ),
  );
  ctrl.dispose();
  return result;
}
