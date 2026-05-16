import 'package:flutter/material.dart';

import '../../data/database.dart';
import '../../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Menu "Plus" de l'app bar de [TourneeDuJourScreen].
/// ════════════════════════════════════════════════════════════════
///
/// Regroupe 11 actions secondaires accessibles depuis le bouton
/// "trois points" en haut a droite. Extrait de
/// `tournee_du_jour_screen.dart` pour alleger ce dernier (le menu
/// faisait ~150 lignes dans l'app bar, sans valeur d'avoir le code
/// inline puisque les actions delegate a des methodes de l'ecran).
///
/// **Pattern callback unique** : un seul `onAction(PlusAction)` au
/// lieu de 11 callbacks separes. Lisible cote consommateur, et le
/// switch des actions reste dans l'ecran parent qui a deja toute
/// la logique (state + ref + navigator + setStat...).
enum PlusAction {
  pauseShort,
  batchLivre,
  undoLast,
  retryGeocode,
  duplicatePlus7,
  shareText,
  shareToCoequipier,
  assignRest,
  exportPdf,
  exportPdfCo,
  prefetchTuiles,
  pushCloud,
  delete,
}

class PlusMenu extends StatelessWidget {
  const PlusMenu({
    super.key,
    required this.tournee,
    required this.onAction,
  });

  final Tournee tournee;
  final ValueChanged<PlusAction> onAction;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<PlusAction>(
      tooltip: 'Plus',
      onSelected: onAction,
      itemBuilder: (_) => [
        // L'option pause n'est visible que si la tournee est demarree
        // (sinon on ne peut pas mettre en pause quelque chose qui n'a
        // pas commence).
        if (tournee.statut == 'en_cours')
          PopupMenuItem(
            value: PlusAction.pauseShort,
            child: ListTile(
              leading: Icon(
                tournee.pauseeLe == null
                    ? Icons.pause_circle_outline
                    : Icons.play_circle_outline,
                color: AppColors.amber,
              ),
              title: Text(
                tournee.pauseeLe == null
                    ? 'Pause courte (pause dejeuner)'
                    : 'Reprendre la tournee',
              ),
              subtitle: const Text(
                'Met le chrono en pause sans arreter la tournee',
                style: TextStyle(fontSize: 11),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        const PopupMenuItem(
          value: PlusAction.batchLivre,
          child: ListTile(
            leading: Icon(Icons.done_all, color: AppColors.emerald),
            title: Text('Tout marquer livre'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.undoLast,
          child: ListTile(
            leading: Icon(Icons.undo, color: AppColors.amber),
            title: Text('Annuler dernier statut'),
            subtitle: Text(
              'Le dernier arret valide/echec',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.retryGeocode,
          child: ListTile(
            leading: Icon(Icons.gps_fixed),
            title: Text('Geolocaliser hors-ligne'),
            subtitle: Text(
              'Re-tente le GPS pour les arrets sans coords',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.duplicatePlus7,
          child: ListTile(
            leading: Icon(Icons.copy_outlined),
            title: Text('Refaire dans 7 jours'),
            subtitle: Text(
              'Duplique a la meme heure semaine prochaine',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.shareText,
          child: ListTile(
            leading: Icon(Icons.share_outlined),
            title: Text('Partager en texte'),
            subtitle: Text(
              'WhatsApp, SMS, mail...',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.shareToCoequipier,
          child: ListTile(
            leading: Icon(Icons.groups_outlined),
            title: Text('Partager a un coequipier'),
            subtitle: Text(
              'Envoie seulement ses arrets affectes',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.assignRest,
          child: ListTile(
            leading: Icon(Icons.assignment_ind_outlined),
            title: Text('Affecter le reste a...'),
            subtitle: Text(
              'Bulk : tous les arrets non affectes a un coequipier',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.exportPdf,
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf_outlined),
            title: Text('Exporter en PDF'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.exportPdfCo,
          child: ListTile(
            leading: Icon(Icons.picture_as_pdf),
            title: Text('Exporter PDF par coequipier'),
            subtitle: Text(
              'Fiche individuelle (un PDF par personne)',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.prefetchTuiles,
          child: ListTile(
            leading: Icon(Icons.cloud_download_outlined),
            title: Text('Telecharger pour hors-ligne'),
            subtitle: Text(
              'Tuiles carte de la zone (zone faible 4G)',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        PopupMenuItem(
          value: PlusAction.pushCloud,
          child: ListTile(
            leading: Icon(
              tournee.cloudId == null
                  ? Icons.cloud_upload_outlined
                  : Icons.cloud_sync_outlined,
              color: AppColors.emerald,
            ),
            title: Text(
              tournee.cloudId == null
                  ? 'Pousser au cloud'
                  : 'Synchroniser au cloud',
            ),
            subtitle: const Text(
              'Sauvegarde la tournee + ses arrets sur Supabase',
              style: TextStyle(fontSize: 11),
            ),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem(
          value: PlusAction.delete,
          child: ListTile(
            leading: Icon(Icons.delete_outline, color: AppColors.red),
            title: Text('Supprimer la tournee'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}
