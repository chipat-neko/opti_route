import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../data/cloud_error_humanizer.dart';
import '../data/database.dart';
import '../data/dispute_file.dart';
import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';
import '../widgets/snack.dart';

/// Sortie du dossier vers le monde exterieur (menu de partage natif).
/// Injectable pour que les widget tests verifient la regle "aucun
/// partage sans confirmation" sans toucher au channel natif.
typedef DossierShareFn = Future<void> Function({
  required String text,
  required String subject,
});

/// Partage reel : menu natif Android (WhatsApp, mail, Drive...). Meme
/// appel que le reste du projet (`SharePlus.instance.share`).
Future<void> _partageNatif({
  required String text,
  required String subject,
}) async {
  await SharePlus.instance.share(ShareParams(text: text, subject: subject));
}

/// Ecran "Dossier litige" d'un arret (carte #311).
///
/// Affiche le texte opposable produit par [DisputeFile.compose] et son
/// empreinte SHA-256. Ouvert depuis la feuille d'actions d'un arret,
/// uniquement quand l'arret a un statut definitif (livre ou echec).
///
/// Deux regles de vie privee, tranchees par le proprietaire :
/// 1. la generation et l'affichage sont libres (tout reste dans l'app) ;
/// 2. RIEN ne sort de l'app sans un dialog de confirmation qui enonce
///    ce que le document contient (nom, adresse, position GPS, photo).
///    Il n'y a volontairement aucune copie presse-papiers "au cas ou" :
///    le texte est selectionnable, l'utilisateur copie s'il le veut.
///
/// La lecture du fichier photo se fait ICI (le module reste pur) : ses
/// octets sont passes a `compose` pour que le hash couvre aussi l'image.
/// Fichier absent = le dossier le dit noir sur blanc.
class DossierLitigeScreen extends StatefulWidget {
  const DossierLitigeScreen({
    super.key,
    required this.stop,
    this.shareFn,
  });

  final Stop stop;

  /// Surcharge du partage (tests). En prod : menu natif share_plus.
  final DossierShareFn? shareFn;

  @override
  State<DossierLitigeScreen> createState() => _DossierLitigeScreenState();
}

class _DossierLitigeScreenState extends State<DossierLitigeScreen> {
  late final Future<DisputeFile> _dossier = _composer();

  Future<DisputeFile> _composer() async {
    final bytes = await _lirePhoto(widget.stop);
    return DisputeFile.compose(stop: widget.stop, photoBytes: bytes);
  }

  /// Octets de la photo preuve locale, ou null si l'arret n'en a pas /
  /// si le fichier a disparu du stockage. Best-effort : une photo
  /// illisible ne doit pas empecher de sortir le dossier.
  static Future<List<int>?> _lirePhoto(Stop stop) async {
    final path = stop.preuvePhotoPath;
    if (path == null || path.isEmpty) return null;
    try {
      final file = File(path);
      if (!await file.exists()) return null;
      return await file.readAsBytes();
    } on FileSystemException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.cream,
      appBar: AppBar(title: const Text('Dossier litige')),
      body: FutureBuilder<DisputeFile>(
        future: _dossier,
        builder: (context, snap) {
          // Sans cette branche, une erreur inattendue (photo illisible
          // autrement qu'en FileSystemException, memoire...) laisserait
          // un spinner tourner indefiniment sans rien dire.
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.x22),
                child: Text(
                  'Dossier illisible : ${humanizeAnyError(snap.error!)}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: p.ink, height: 1.35),
                ),
              ),
            );
          }
          final dossier = snap.data;
          if (dossier == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _DossierBody(
            dossier: dossier,
            onPartager: () => _onPartager(dossier),
          );
        },
      ),
    );
  }

  /// Confirmation OBLIGATOIRE avant toute sortie du document.
  Future<void> _onPartager(DisputeFile dossier) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirme = await _confirmerPartage(context, widget.stop, dossier);
    if (!confirme) return;
    final partager = widget.shareFn ?? _partageNatif;
    try {
      await partager(
        text: dossier.body,
        subject: 'Dossier litige arret ${widget.stop.id}',
      );
    } catch (e) {
      messenger.showError('Partage impossible : ${humanizeAnyError(e)}');
    }
  }
}

/// Dialog qui ENONCE le contenu personnel du document avant de le
/// laisser sortir. Retourne false si l'utilisateur annule ou ferme.
Future<bool> _confirmerPartage(
  BuildContext context,
  Stop stop,
  DisputeFile dossier,
) async {
  final p = context.palette;
  final nom = (stop.nomClient ?? '').trim();
  final gpsConnu = stop.livreLat != null && stop.livreLng != null;
  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      backgroundColor: p.paper,
      title: const Text('Partager ce dossier ?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Le document qui va sortir de l\'app contient des donnees '
              'personnelles :',
              style: TextStyle(fontSize: 13.5, color: p.ink, height: 1.35),
            ),
            const SizedBox(height: AppSpacing.x10),
            _ContenuLigne(
              icon: Icons.person_outline,
              label: 'Nom du client',
              valeur: nom.isEmpty ? 'non renseigne' : nom,
            ),
            _ContenuLigne(
              icon: Icons.place_outlined,
              label: 'Adresse de livraison',
              valeur: stop.adresseNormalisee ?? stop.adresseBrute,
            ),
            _ContenuLigne(
              icon: Icons.gps_fixed,
              label: 'Position GPS de passage',
              valeur: gpsConnu
                  ? '${stop.livreLat!.toStringAsFixed(5)}, '
                      '${stop.livreLng!.toStringAsFixed(5)}'
                  : 'aucune position enregistree',
            ),
            _ContenuLigne(
              icon: Icons.photo_camera_outlined,
              label: 'Photo preuve',
              valeur: switch (dossier.photoState) {
                DisputePhotoState.jointe =>
                  'chemin du fichier + empreinte de l\'image',
                DisputePhotoState.introuvable =>
                  'chemin du fichier (image absente du stockage)',
                DisputePhotoState.aucune => 'aucune photo',
              },
            ),
            const SizedBox(height: AppSpacing.x10),
            Text(
              'Une fois envoye, tu ne controles plus qui le lit.',
              style: TextStyle(
                fontSize: 12.5,
                color: p.textMute,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(false),
          child: const Text('Annuler'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogCtx).pop(true),
          child: const Text('Oui, partager'),
        ),
      ],
    ),
  );
  return ok ?? false;
}

class _ContenuLigne extends StatelessWidget {
  const _ContenuLigne({
    required this.icon,
    required this.label,
    required this.valeur,
  });

  final IconData icon;
  final String label;
  final String valeur;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: p.textMute),
          const SizedBox(width: AppSpacing.x8),
          // Text.rich (et non RichText) : garde le style du theme et
          // reste trouvable par les finders texte des widget tests.
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(fontSize: 13, color: p.ink, height: 1.3),
                children: [
                  TextSpan(
                    text: '$label : ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: valeur),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Corps de l'ecran une fois le dossier compose.
class _DossierBody extends StatelessWidget {
  const _DossierBody({
    required this.dossier,
    required this.onPartager,
  });

  final DisputeFile dossier;
  final VoidCallback onPartager;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.x16),
      children: [
        // Rappel de confidentialite : le dossier reste dans l'app tant
        // que l'utilisateur ne confirme pas un partage.
        const _Bandeau(
          icon: Icons.lock_outline,
          couleur: AppColors.emerald,
          texte: 'Ce dossier reste dans l\'app. Rien n\'est copie ni '
              'envoye tant que tu ne confirmes pas.',
        ),
        if (dossier.photoState == DisputePhotoState.introuvable) ...[
          const SizedBox(height: AppSpacing.x10),
          const _Bandeau(
            icon: Icons.warning_amber_outlined,
            couleur: AppColors.amber,
            texte: 'La photo preuve de cet arret est introuvable sur le '
                'telephone : la signature ne couvre que le texte.',
          ),
        ],
        const SizedBox(height: AppSpacing.x14),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: p.paper,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: p.divider),
          ),
          child: SelectableText(
            dossier.body,
            style: appMonoStyle(fontSize: 12, color: p.ink),
          ),
        ),
        const SizedBox(height: AppSpacing.x14),
        Container(
          padding: const EdgeInsets.all(AppSpacing.x14),
          decoration: BoxDecoration(
            color: p.creamSoft,
            borderRadius: BorderRadius.circular(AppRadius.r16),
            border: Border.all(color: p.inkLine),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'EMPREINTE SHA-256',
                style: appMonoStyle(
                  fontSize: 11,
                  color: p.textMute,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.x6),
              SelectableText(
                dossier.hash,
                style: appMonoStyle(fontSize: 12.5, color: p.ink),
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                dossier.coversPhoto
                    ? 'Couvre le texte ci-dessus ET les octets de la photo '
                        'preuve.'
                    : 'Couvre le texte ci-dessus. Aucune image n\'est '
                        'couverte.',
                style: TextStyle(fontSize: 12, color: p.textMute, height: 1.3),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.x18),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 52)),
          onPressed: onPartager,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Partager le dossier'),
        ),
        const SizedBox(height: AppSpacing.x8),
        Text(
          'Le partage demande une confirmation : le dossier contient le '
          'nom du client, son adresse, la position GPS de passage et la '
          'reference de la photo.',
          style: TextStyle(fontSize: 12, color: p.textMute, height: 1.35),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _Bandeau extends StatelessWidget {
  const _Bandeau({
    required this.icon,
    required this.couleur,
    required this.texte,
  });

  final IconData icon;
  final Color couleur;
  final String texte;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.r12),
        border: Border.all(color: couleur),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: couleur),
          const SizedBox(width: AppSpacing.x10),
          Expanded(
            child: Text(
              texte,
              style: TextStyle(fontSize: 12.5, color: p.ink, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
