import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/database.dart';
import '../../theme/app_tokens.dart';

// ════════════════════════════════════════════════════════════════
// Alertes du scan colis (carte #315) — re-livraison + mauvais arret.
// ════════════════════════════════════════════════════════════════
//
// Regle produit : ces alertes PREVIENNENT, elles ne BLOQUENT jamais.
// Le livreur est sur le terrain et a souvent une raison legitime
// (colis reexpedie, numero de suivi recycle par le transporteur, deux
// colis pour le meme immeuble...). Consequence concrete :
//   - l'action mise en avant est toujours celle qui fait avancer ;
//   - un dismiss (back / tap hors du dialog) equivaut a continuer.
//
// Les fonctions de mise en forme sont pures et exposees pour pouvoir
// etre testees sans pomper de widget.

/// Choix du livreur quand le code scanne appartient a un AUTRE arret
/// que celui attendu. Pas de valeur "annuler" : on ne verrouille pas.
enum WrongStopChoice {
  /// Basculer sur l'arret suggere (celui qui porte vraiment ce code).
  basculer,

  /// Garder l'arret attendu et rattacher le colis quand meme.
  continuer,
}

/// Libelle court d'un arret : nom client s'il est renseigne, sinon
/// l'adresse (normalisee si geocodee, brute sinon).
String scanStopLabel(Stop stop) {
  final nom = (stop.nomClient ?? '').trim();
  if (nom.isNotEmpty) return nom;
  final normalisee = (stop.adresseNormalisee ?? '').trim();
  return normalisee.isNotEmpty ? normalisee : stop.adresseBrute;
}

/// Phrase qui dit CE QUI a ete detecte et QUAND, du point de vue du
/// livreur :
/// - « Livre aujourd'hui a 09:12 chez Dupont » (cas frequent : l'arret
///   a ete valide plus tot dans la tournee EN COURS -- annoncer ca
///   comme une livraison "des 30 derniers jours" serait trompeur) ;
/// - « Livre hier a 17:40 chez Dupont » ;
/// - « Livre le 3 juin a 14:05 chez Dupont » au-dela.
/// Si l'horodatage manque (donnee ancienne ou remontee du cloud sans
/// `livreLe`), on tombe sur « Deja livre chez Dupont ».
///
/// [now] rend la phrase deterministe pour les tests ; par defaut
/// l'heure courante.
///
/// Necessite `initializeDateFormatting('fr')` (fait dans `main()`).
String relivraisonSummary(Stop dejaLivre, {DateTime? now}) {
  final chez = scanStopLabel(dejaLivre);
  final quand = dejaLivre.livreLe;
  if (quand == null) return 'Deja livre chez $chez';
  final heure = DateFormat('HH:mm', 'fr').format(quand);
  final jours = _joursDecart(quand, now ?? DateTime.now());
  if (jours == 0) return 'Livre aujourd\'hui a $heure chez $chez';
  if (jours == 1) return 'Livre hier a $heure chez $chez';
  final jour = DateFormat('d MMMM', 'fr').format(quand);
  return 'Livre le $jour a $heure chez $chez';
}

/// Nombre de jours CALENDAIRES entre [quand] et [reference] (0 = meme
/// jour). On compare des dates nues, pas des durees de 24 h : une
/// livraison faite hier a 23 h doit dire « hier », pas « aujourd'hui ».
/// Passage par `DateTime.utc` pour que les changements d'heure d'ete ne
/// donnent pas des journees de 23 ou 25 h.
int _joursDecart(DateTime quand, DateTime reference) {
  final a = DateTime.utc(quand.year, quand.month, quand.day);
  final b = DateTime.utc(reference.year, reference.month, reference.day);
  return b.difference(a).inDays;
}

/// Adresse a afficher en 2e ligne d'un encart, ou null quand le libelle
/// principal EST deja l'adresse (arret sans nom client) — inutile de la
/// repeter.
String? _adresseSecondaire(Stop stop) {
  if ((stop.nomClient ?? '').trim().isEmpty) return null;
  return stop.adresseNormalisee ?? stop.adresseBrute;
}

/// Alerte « ce colis a deja ete livre recemment ». Retourne true si le
/// livreur veut rattacher le colis quand meme (choix par defaut, y
/// compris sur dismiss), false s'il prefere ne rien rattacher et
/// continuer a scanner.
///
/// [now] rend le libelle de date deterministe pour les tests.
Future<bool> askConfirmRelivraison(
  BuildContext context, {
  required Stop dejaLivre,
  DateTime? now,
}) async {
  final choix = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final p = ctx.palette;
      return AlertDialog(
        title: const Text('Colis deja livre ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pas de "dans les 30 derniers jours" ici : la fenetre de
            // recherche est bien de 30 j, mais le cas le plus frequent
            // est un arret valide il y a 10 minutes dans la tournee en
            // cours. La date exacte est dans l'encart juste dessous.
            const Text(
              'Ce numero de suivi a deja ete marque livre :',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.x10),
            _AlertCard(
              accent: AppColors.amber,
              icon: Icons.history,
              title: relivraisonSummary(dejaLivre, now: now),
              subtitle: _adresseSecondaire(dejaLivre),
            ),
            const SizedBox(height: AppSpacing.x10),
            Text(
              'Ca peut etre normal : colis reexpedie, ou numero reutilise '
              'par le transporteur.',
              style: TextStyle(fontSize: 12, color: p.textMute, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Ne pas rattacher'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Continuer quand meme'),
          ),
        ],
      );
    },
  );
  // Dismiss (back / tap hors du dialog) = on continue : l'alerte
  // informe, elle ne verrouille pas le livreur.
  return choix ?? true;
}

/// Alerte « ce code-barre est celui d'un autre arret ». On propose de
/// BASCULER sur l'arret suggere (action mise en avant) plutot que de
/// refuser le scan. Retourne [WrongStopChoice.continuer] sur dismiss.
Future<WrongStopChoice> askWrongStopChoice(
  BuildContext context, {
  required Stop expected,
  required Stop suggested,
}) async {
  final choix = await showDialog<WrongStopChoice>(
    context: context,
    builder: (ctx) {
      final p = ctx.palette;
      return AlertDialog(
        title: const Text('Colis d\'un autre arret ?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce code-barre est rattache a un autre arret de la tournee, '
              'pas a ${scanStopLabel(expected)} :',
              style: const TextStyle(fontSize: 13),
            ),
            const SizedBox(height: AppSpacing.x10),
            _AlertCard(
              accent: AppColors.emerald,
              icon: Icons.swap_horiz,
              title: scanStopLabel(suggested),
              subtitle: _adresseSecondaire(suggested),
            ),
            const SizedBox(height: AppSpacing.x10),
            Text(
              'Tu peux basculer sur cet arret, ou garder '
              '${scanStopLabel(expected)} si tu sais pourquoi.',
              style: TextStyle(fontSize: 12, color: p.textMute, height: 1.3),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(ctx).pop(WrongStopChoice.continuer),
            child: const Text('Garder l\'arret'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(WrongStopChoice.basculer),
            child: const Text('Basculer'),
          ),
        ],
      );
    },
  );
  return choix ?? WrongStopChoice.continuer;
}

/// Encart colore d'un dialog d'alerte : meme grammaire visuelle que le
/// bandeau consignes client de `StopActionSheet` (fond accent a 18 %,
/// bordure accent, texte `palette.ink`). Aucune couleur en dur.
class _AlertCard extends StatelessWidget {
  const _AlertCard({
    required this.accent,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final Color accent;
  final IconData icon;
  final String title;

  /// Ligne secondaire (adresse). Omise quand le titre porte deja
  /// l'adresse (arret sans nom client) pour ne pas la repeter.
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.r10),
        border: Border.all(color: accent, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: p.ink),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: p.ink,
                    height: 1.3,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(fontSize: 12, color: p.ink, height: 1.3),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
