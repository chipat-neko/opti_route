import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/cloud_error_humanizer.dart';
import '../../data/database.dart';
import '../../data/navigation_service.dart';
import '../../data/tournee_pdf_service.dart';
import '../../data/tournee_text_share_service.dart';
import '../../providers/database_providers.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Handlers d'export / partage extraits de [TourneeDuJourScreen]
/// (refactor jalon 2026-05-17 phase 2). Memes conventions que
/// [CloudTourneeActions] : methodes statiques, params context/ref/
/// tournee.
/// ════════════════════════════════════════════════════════════════
class ExportTourneeActions {
  ExportTourneeActions._();

  /// Exporte la tournee complete en PDF + ouvre le selecteur natif
  /// de partage. Inclut le cout carburant + profil entreprise si
  /// configures dans les Parametres.
  static Future<void> exportPdf({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stops = await ref
          .read(stopsRepositoryProvider)
          .getByTournee(tournee.id);
      final service = TourneePdfService();
      // Calcule le cout carburant pour l'inclure dans le PDF si la
      // tournee a une distance.
      double? cout;
      if (tournee.distanceTotaleM != null &&
          tournee.distanceTotaleM! > 0) {
        cout = await ref
            .read(parametresRepositoryProvider)
            .estimerCoutCarburant(
              distanceMeters: tournee.distanceTotaleM!,
            );
      }
      // Profil entreprise (optionnel) : ajoute un footer "nom + SIRET +
      // slogan" en bas de chaque page du PDF.
      final paramsRepo = ref.read(parametresRepositoryProvider);
      final entrepriseNom = await paramsRepo.getEntrepriseNom();
      final entrepriseSiret = await paramsRepo.getEntrepriseSiret();
      final entrepriseSlogan = await paramsRepo.getEntrepriseSlogan();
      await service.exportAndShare(
        tournee: tournee,
        stops: stops,
        coutCarburantEur: cout,
        entrepriseNom: entrepriseNom,
        entrepriseSiret: entrepriseSiret,
        entrepriseSlogan: entrepriseSlogan,
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'export PDF : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Genere un PDF par coequipier present dans la tournee (Moi + chaque
  /// affecte). Lance N partages successifs.
  static Future<void> exportPdfPerCoequipier({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stops = await ref
          .read(stopsRepositoryProvider)
          .getByTournee(tournee.id);
      // Set des cles : null + ids presents
      final keys = <int?>{};
      for (final s in stops) {
        keys.add(s.coequipierId);
      }
      if (keys.isEmpty) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Aucun arret a exporter.')),
        );
        return;
      }
      if (keys.length == 1) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'Tous les arrets ont la meme affectation. Utilise '
              '"Exporter en PDF" classique.',
            ),
          ),
        );
        return;
      }

      // Resolution noms coequipiers
      final coRepo = ref.read(coequipiersRepositoryProvider);
      final coequipiers = await coRepo.getAllActifs();
      final byId = {for (final c in coequipiers) c.id: c};

      final paramsRepo = ref.read(parametresRepositoryProvider);
      final entrepriseNom = await paramsRepo.getEntrepriseNom();
      final entrepriseSiret = await paramsRepo.getEntrepriseSiret();
      final entrepriseSlogan = await paramsRepo.getEntrepriseSlogan();
      double? cout;
      if (tournee.distanceTotaleM != null &&
          tournee.distanceTotaleM! > 0) {
        cout = await paramsRepo.estimerCoutCarburant(
          distanceMeters: tournee.distanceTotaleM!,
        );
      }

      final service = TourneePdfService();
      for (final key in keys) {
        final nom = key == null
            ? 'Moi'
            : (byId[key]?.nom ?? 'Coequipier #$key');
        await service.exportForCoequipier(
          tournee: tournee,
          allStops: stops,
          coequipierIdOrNull: key,
          coequipierNom: nom,
          coutCarburantEur: cout,
          entrepriseNom: entrepriseNom,
          entrepriseSiret: entrepriseSiret,
          entrepriseSlogan: entrepriseSlogan,
        );
      }
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${keys.length} PDF generes (1 par coequipier).',
          ),
          backgroundColor: AppColors.emerald,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur a l\'export PDF equipe : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Partage la tournee sous forme de texte court via le selecteur
  /// natif Android (WhatsApp, SMS, mail, etc.). Utilise les arrets
  /// dans leur ordre actuel.
  static Future<void> shareText({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final stops = await ref
          .read(stopsRepositoryProvider)
          .getByTournee(tournee.id);
      final service = TourneeTextShareService(
        parametres: ref.read(parametresRepositoryProvider),
      );
      await service.shareAsText(
        tournee: tournee,
        stops: stops,
      );
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur au partage : ${humanizeAnyError(e)}')),
      );
    }
  }

  /// Affiche un selecteur de coequipier puis genere un text-share
  /// filtre sur ses arrets affectes. Si le coequipier a un numero,
  /// tente WhatsApp puis SMS via url_launcher. Sinon fallback share
  /// natif.
  static Future<void> shareToCoequipier({
    required BuildContext context,
    required WidgetRef ref,
    required Tournee tournee,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final p = context.palette;
    final coequipiers =
        await ref.read(coequipiersRepositoryProvider).getAllActifs();
    if (!context.mounted) return;
    if (coequipiers.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Aucun coequipier. Ajoute-en dans Parametres > Mon equipe.',
          ),
        ),
      );
      return;
    }

    final picked = await showModalBottomSheet<Coequipier>(
      context: context,
      backgroundColor: p.cream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.r22),
        ),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x18,
            vertical: AppSpacing.x14,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Partager a',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: AppSpacing.x12),
              for (final c in coequipiers)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: colorFromTag(
                      c.colorTag,
                      defaultColor: AppColors.creamSoft,
                    ),
                    child: Text(
                      _coequipierInitials(c.nom),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  title: Text(c.nom),
                  subtitle: c.telephone != null && c.telephone!.isNotEmpty
                      ? Text(c.telephone!)
                      : null,
                  onTap: () => Navigator.of(context).pop(c),
                ),
            ],
          ),
        ),
      ),
    );

    if (picked == null || !context.mounted) return;

    try {
      final allStops = await ref
          .read(stopsRepositoryProvider)
          .getByTournee(tournee.id);
      final stopsLui =
          allStops.where((s) => s.coequipierId == picked.id).toList();
      if (stopsLui.isEmpty) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'Aucun arret affecte a ${picked.nom}. Affecte-lui des '
              'arrets depuis la bottom sheet d\'un arret.',
            ),
          ),
        );
        return;
      }

      final service = TourneeTextShareService(
        parametres: ref.read(parametresRepositoryProvider),
      );
      final text = await service.formatPlainText(
        tournee: tournee,
        stops: stopsLui,
      );
      final preamble =
          'Tes arrets pour ${tournee.nom} (${stopsLui.length}) :\n\n';

      // Si le coequipier a un telephone, on tente WhatsApp d'abord
      // (le scheme `whatsapp://` ouvre l'app si installee), puis SMS.
      // Sinon fallback share natif (Share.share).
      final tel = picked.telephone?.replaceAll(RegExp(r'\D'), '');
      if (tel != null && tel.isNotEmpty) {
        final waUri = Uri.parse(
          'https://wa.me/33${tel.startsWith('0') ? tel.substring(1) : tel}'
          '?text=${Uri.encodeComponent(preamble + text)}',
        );
        final ok = await NavigationService.tryLaunch(waUri);
        if (!ok) {
          // Fallback SMS
          final smsUri = Uri.parse(
            'sms:${picked.telephone}'
            '?body=${Uri.encodeComponent(preamble + text)}',
          );
          await NavigationService.tryLaunch(smsUri);
        }
      } else {
        // Pas de tel : share natif
        await service.shareAsText(
          tournee: tournee,
          stops: stopsLui,
        );
      }
    } catch (e) {
      if (!context.mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Erreur au partage : ${humanizeAnyError(e)}')),
      );
    }
  }

  static String _coequipierInitials(String nom) {
    final parts = nom.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
