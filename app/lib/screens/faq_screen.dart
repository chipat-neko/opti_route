import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

/// ════════════════════════════════════════════════════════════════
/// Écran « Questions fréquentes » (FAQ) — aide intégrée.
/// ════════════════════════════════════════════════════════════════
///
/// 100 % statique et en LECTURE SEULE : une liste de questions/réponses
/// dépliables (ExpansionTile) sur le fonctionnement réel de l'app. Sert
/// d'aide hors-ligne, utile pour Noah comme pour un nouveau coéquipier
/// qui prend le téléphone. Accessible depuis Paramètres → Aide.
///
/// Les réponses ne décrivent QUE des fonctionnalités existantes (pas de
/// promesse de feature à venir) pour ne pas induire en erreur.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      appBar: AppBar(title: const Text('Questions fréquentes')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.x16),
        children: [
          Text(
            'Les réponses aux questions les plus courantes sur l\'application. '
            'Touche une question pour dérouler la réponse.',
            style: TextStyle(fontSize: 13.5, color: p.textMute, height: 1.5),
          ),
          const SizedBox(height: AppSpacing.x16),
          for (final item in _faq) _carteQuestion(context, item),
        ],
      ),
    );
  }

  Widget _carteQuestion(BuildContext context, _FaqItem item) {
    final p = context.palette;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.x12),
      decoration: BoxDecoration(
        color: p.creamSoft,
        borderRadius: BorderRadius.circular(AppRadius.r14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Retire les lignes de séparation par défaut de l'ExpansionTile
        // pour un rendu plus propre dans la carte.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Icon(item.icon, color: AppColors.emerald),
          title: Text(
            item.question,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(
            AppSpacing.x16,
            0,
            AppSpacing.x16,
            AppSpacing.x16,
          ),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.reponse,
              style: TextStyle(fontSize: 13.5, color: p.textMute, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  const _FaqItem(this.icon, this.question, this.reponse);
  final IconData icon;
  final String question;
  final String reponse;
}

const List<_FaqItem> _faq = [
  _FaqItem(
    Icons.add_location_alt_outlined,
    'Comment ajouter un arrêt à ma tournée ?',
    'Depuis la tournée du jour, utilise le bouton « + » : tu peux saisir une '
        'adresse (la recherche te propose des suggestions), scanner un '
        'bordereau, ou coller plusieurs adresses d\'un coup (collage en '
        'masse). L\'adresse est géocodée automatiquement, tu n\'as jamais à '
        'saisir de coordonnées GPS.',
  ),
  _FaqItem(
    Icons.alt_route_outlined,
    'Comment optimiser l\'ordre de ma tournée ?',
    'Une fois tes arrêts ajoutés, lance l\'optimisation : l\'app calcule un '
        'ordre de passage qui réduit la distance/durée totale. Tu peux fixer '
        'des arrêts en premier ou en dernier, et l\'optimiseur range les '
        'autres entre les deux. L\'optimisation avancée utilise une clé ORS '
        '(voir question suivante).',
  ),
  _FaqItem(
    Icons.vpn_key_outlined,
    'C\'est quoi la clé ORS et comment l\'obtenir ?',
    'ORS (openrouteservice) est le service qui calcule les itinéraires réels '
        'par la route. La clé gratuite s\'obtient sur openrouteservice.org '
        '(inscription gratuite), puis se colle dans Paramètres → ORS. Sans '
        'clé, l\'app reste utilisable avec un calcul de distance simplifié.',
  ),
  _FaqItem(
    Icons.document_scanner_outlined,
    'Comment scanner un bordereau ?',
    'Depuis l\'ajout d\'arrêt, choisis « Scanner ». Prends en photo le '
        'bordereau : l\'app lit le texte (OCR) et pré-remplit le destinataire, '
        'l\'adresse et le nombre de colis. Vérifie toujours les champs '
        'détectés avant de valider, l\'OCR peut se tromper sur un bordereau '
        'abîmé ou mal cadré.',
  ),
  _FaqItem(
    Icons.cloud_off_outlined,
    'L\'application fonctionne-t-elle sans internet ?',
    'Oui. opti_route est « hors-ligne d\'abord » : tes tournées, ton carnet '
        'd\'adresses et tes frais sont stockés sur le téléphone et restent '
        'accessibles sans réseau. La synchronisation cloud (optionnelle) et '
        'l\'optimisation en ligne nécessitent une connexion.',
  ),
  _FaqItem(
    Icons.sync_problem_outlined,
    'Pourquoi mes données ne se synchronisent pas dans le cloud ?',
    'Vérifie d\'abord que tu es connecté à un compte cloud (Paramètres → '
        'Compte cloud) et que tu as du réseau. L\'écran Diagnostic (Aide → '
        'Diagnostic) indique si le cloud est configuré et connecté. Si un '
        'message d\'erreur apparaît, il est traduit en clair ; en cas de '
        'doute, copie le Diagnostic avant de contacter le support.',
  ),
  _FaqItem(
    Icons.group_add_outlined,
    'Comment inviter un employé ou rejoindre une équipe ?',
    'Un responsable invite un membre depuis la gestion de l\'équipe : par '
        'email (un code à 6 chiffres est envoyé) ou en partageant un code. '
        'Pour rejoindre, va dans Paramètres → « Rejoindre une équipe » et '
        'saisis le code. Une invitation par email ne peut être acceptée que '
        'par l\'adresse à laquelle elle a été envoyée.',
  ),
  _FaqItem(
    Icons.local_gas_station_outlined,
    'Comment sont gérés le carburant et mes frais ?',
    'Le prix du carburant peut être pré-rempli automatiquement à partir des '
        'prix publics près de chez toi (data.gouv.fr). Tu saisis tes frais '
        '(carburant, péages, etc.) dans l\'écran Frais ; ils alimentent tes '
        'récapitulatifs. Tu peux aussi repérer les stations les moins chères '
        'autour de ta position.',
  ),
  _FaqItem(
    Icons.lock_outline,
    'Mes données sont-elles privées et sécurisées ?',
    'Tes données restent sur ton téléphone par défaut. Si tu actives le '
        'cloud, l\'accès est cloisonné par entreprise/entrepôt : un membre ne '
        'voit que ce qui le concerne. Tu peux aussi protéger l\'app par un '
        'code PIN (Paramètres → Sécurité).',
  ),
];
