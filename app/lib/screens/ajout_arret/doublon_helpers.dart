import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/database.dart';
import '../../data/geo_utils.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// Retourne le Stop deja present dans [tourneeId] qui ressemble a
/// l'adresse passee, soit par coords (< 30 m haversine), soit par
/// adresse brute identique (case-insensitive). Null si pas de
/// doublon detecte.
///
/// Extrait de `ajout_arret_screen.dart` (carte Trello #165).
Future<Stop?> findPossibleDoublon(
  WidgetRef ref, {
  required int tourneeId,
  required double lat,
  required double lng,
  required String adresse,
}) async {
  final repo = ref.read(stopsRepositoryProvider);
  final stops = await repo.getByTournee(tourneeId);
  final adresseLower = adresse.toLowerCase().trim();
  for (final s in stops) {
    if (s.adresseBrute.toLowerCase().trim() == adresseLower) return s;
    if (s.lat != null && s.lng != null) {
      if (GeoUtils.areClose(
        lat1: lat,
        lon1: lng,
        lat2: s.lat!,
        lon2: s.lng!,
        thresholdMeters: 30,
      )) {
        return s;
      }
    }
  }
  return null;
}

/// Dialog "Doublon possible" : affiche les details du Stop ressemblant
/// et demande confirmation. Retourne true si l'utilisateur veut
/// quand meme creer le nouvel arret.
Future<bool> askConfirmDoublon(
  BuildContext context, {
  required Stop doublon,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Doublon possible ?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Un arret tres proche existe deja dans cette tournee :',
            style: TextStyle(fontSize: 13),
          ),
          const SizedBox(height: AppSpacing.x10),
          Container(
            padding: const EdgeInsets.all(AppSpacing.x10),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.r10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (doublon.nomClient != null &&
                    doublon.nomClient!.isNotEmpty)
                  Text(
                    doublon.nomClient!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                    ),
                  ),
                Text(
                  doublon.adresseBrute,
                  style: const TextStyle(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          child: const Text('Ajouter quand meme'),
        ),
      ],
    ),
  );
  return result == true;
}
