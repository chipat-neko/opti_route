import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// Visualisation full-screen d'une photo preuve. Affiche [Image.file]
/// avec pinch-to-zoom (InteractiveViewer), centree sur fond ink pour
/// maximiser le contraste / la lisibilite du contenu (livreur peut
/// vouloir verifier qu'il a bien capture l'adresse / le destinataire /
/// le colis dans la photo).
///
/// Le path local provient de [Stop.preuvePhotoPath], qui pointe soit
/// sur :
/// - une photo prise localement (`app_documents/preuves/<id>.jpg`)
/// - une photo telechargee du cloud (`app_documents/preuves/cloud_<id>.jpg`)
///   via le download au pull (sous-jalon 2.E-2).
///
/// Gestion graceful du fichier introuvable (path obsolete / photo
/// supprimee manuellement par Noah depuis un file manager) : affiche
/// un placeholder + bouton retour, pas de crash.
class PreuvePhotoViewerScreen extends StatelessWidget {
  const PreuvePhotoViewerScreen({
    super.key,
    required this.photoPath,
  });

  final String photoPath;

  @override
  Widget build(BuildContext context) {
    final file = File(photoPath);
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.paper,
        title: const Text('Photo preuve'),
        iconTheme: const IconThemeData(color: AppColors.paper),
      ),
      body: FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.data != true) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.x22),
                child: Text(
                  'Photo introuvable. Elle a peut-etre ete supprimee '
                  'manuellement, ou la sync cloud n\'a pas encore '
                  'telecharge le fichier.',
                  style: TextStyle(color: AppColors.paper),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4,
            child: Center(
              child: Image.file(file, fit: BoxFit.contain),
            ),
          );
        },
      ),
    );
  }
}
