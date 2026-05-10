import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/app_tokens.dart';

/// Ecran "Mentions legales" accessible depuis Parametres. Affiche en
/// 2 onglets :
/// - **Confidentialite** : qu'est-ce qui est stocke, ou, et qui le
///   recoit (BAN / SIRENE / Photon / ORS).
/// - **Conditions d'utilisation** : limitations, quotas, responsabilite.
///
/// Les textes sont embarques en dur dans l'app (constantes ci-dessous)
/// pour fonctionner hors-ligne et ne pas dependre d'un hebergement.
/// Les versions sources sont aussi dans `docs/legal/*.md`.
class MentionsLegalesScreen extends StatelessWidget {
  const MentionsLegalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mentions legales'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Confidentialite'),
              Tab(text: 'Conditions d\'utilisation'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _MarkdownPage(content: _privacyText),
            _MarkdownPage(content: _cguText),
          ],
        ),
      ),
    );
  }
}

class _MarkdownPage extends StatelessWidget {
  const _MarkdownPage({required this.content});

  final String content;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.x18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _renderSimpleMarkdown(content),
      ),
    );
  }

  /// Rendu minimal du markdown : on ne supporte que les en-tetes
  /// (`#`, `##`, `###`), les paragraphes, les listes `-` et l'italique
  /// `*texte*`. Pas de package markdown -> moins de deps.
  static List<Widget> _renderSimpleMarkdown(String md) {
    final widgets = <Widget>[];
    for (final block in md.split('\n\n')) {
      final trimmed = block.trim();
      if (trimmed.isEmpty) continue;
      if (trimmed.startsWith('# ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x6),
          child: Text(
            trimmed.substring(2),
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
        ));
      } else if (trimmed.startsWith('## ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.x14,
            bottom: AppSpacing.x6,
          ),
          child: Text(
            trimmed.substring(3),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.emerald,
            ),
          ),
        ));
      } else if (trimmed.startsWith('### ')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(
            top: AppSpacing.x10,
            bottom: AppSpacing.x4,
          ),
          child: Text(
            trimmed.substring(4),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ));
      } else if (trimmed.startsWith('- ') ||
          trimmed.split('\n').every((l) => l.trim().startsWith('- '))) {
        // Liste
        for (final line in trimmed.split('\n')) {
          final item = line.trim().substring(2);
          widgets.add(Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.x8,
              bottom: AppSpacing.x4,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(
                  child: Text(
                    _stripInlineFormatting(item),
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.ink,
                    ),
                  ),
                ),
              ],
            ),
          ));
        }
      } else if (trimmed.startsWith('*') && trimmed.endsWith('*')) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x10),
          child: Text(
            trimmed.substring(1, trimmed.length - 1),
            style: appMonoStyle(
              fontSize: 11,
              color: AppColors.textMute,
            ),
          ),
        ));
      } else {
        widgets.add(Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.x10),
          child: Text(
            _stripInlineFormatting(trimmed),
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.ink,
            ),
          ),
        ));
      }
    }
    return widgets;
  }

  /// Retire les marqueurs `**bold**` et `*italic*` (on n'a pas de
  /// support typo riche dans ce rendu simplifie). Conserve juste le
  /// texte.
  static String _stripInlineFormatting(String s) {
    return s
        .replaceAll(RegExp(r'\*\*(.+?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.+?)\*'), r'$1')
        .replaceAll(RegExp(r'`(.+?)`'), r'$1');
  }
}

// ─── Contenus ──────────────────────────────────────────────────────

const _privacyText = '''
# Politique de confidentialite

*Derniere mise a jour : 10 mai 2026*

opti_route est une application d'optimisation de tournees de livraison a usage personnel. Elle a ete concue avec le principe "tout reste sur ton telephone".

## Donnees stockees localement

Tout ce que tu saisis ou que l'app calcule reste sur la memoire de ton telephone, dans une base SQLite locale. Aucune donnee n'est envoyee a un serveur opti_route — il n'y a d'ailleurs pas de serveur opti_route.

Concretement, sont stockes sur ton appareil :

- Les tournees creees (nom, date, point de depart)
- Les arrets (adresses, coordonnees GPS, nb colis, statut, notes)
- Le carnet d'adresses des clients deja livres
- Tes preferences (capacite vehicule, app de nav, etc.)
- Le cache des resultats de geocodage

Pour supprimer toutes ces donnees : desinstalle l'application. La base SQLite est supprimee avec.

## Services tiers utilises

opti_route interroge des APIs publiques gratuites pour fonctionner. Ces APIs ne recoivent que les requetes necessaires et aucune donnee personnelle sur toi.

- BAN (api-adresse.data.gouv.fr) : recherche d'adresse postale
- Recherche-Entreprises (recherche-entreprises.api.gouv.fr) : recherche d'entreprises
- Photon (photon.komoot.io) : recherche d'enseignes et marques
- OpenRouteService (openrouteservice.org) : optimisation et trace d'itineraire

OpenRouteService necessite une cle API personnelle que tu crees gratuitement sur leur site. Cette cle est stockee localement.

## Permissions Android demandees

- Internet : pour interroger les APIs
- Camera : pour scanner les bordereaux (OCR traite localement par ML Kit)
- Localisation : pour le mode "tournee en cours" (distance live jusqu'au prochain arret)

La permission de localisation est demandee uniquement quand tu demarres une tournee. Tu peux la revoquer a tout moment depuis les Parametres Android.

## Donnees partagees avec d'autres applications

Tu peux explicitement choisir de partager :

- Un export CSV de ton carnet via le selecteur de partage Android
- Un export PDF d'une tournee
- Une navigation Maps ou Waze (l'app externe est ouverte avec les coordonnees en parametre)

Aucun partage automatique.

## Pas de tracking, pas de pub

Aucune des choses suivantes : analytics, publicite, crash reporting cloud, push notifications, identifiants publicitaires, cookies.

## Contact

noah.trillon28@gmail.com
''';

const _cguText = '''
# Conditions generales d'utilisation

*Derniere mise a jour : 10 mai 2026*

## Objet

opti_route est une application Android d'optimisation de tournees de livraison, fournie gratuitement et sans garantie. En l'utilisant, tu acceptes les presentes conditions.

## Usage

L'application est destinee a un usage personnel ou professionnel de planification de tournees. Elle n'est pas un systeme critique de gestion de flotte : tu restes seul responsable de la bonne execution de tes livraisons.

## Limitations

- L'optimisation depend des donnees OpenStreetMap et d'OpenRouteService. Certaines routes peuvent etre inexactes, certains sens uniques mal mappes. Le drag-and-drop manuel te permet de corriger.
- Le scan OCR fonctionne sur les formats francais standards mais peut echouer sur des bordereaux abimes ou non testes. L'app affiche une carte orange en cas d'incertitude.
- L'app ne suit pas ta position GPS en arriere-plan. La localisation n'est utilisee que quand le mode "tournee en cours" est actif.

## Quotas des APIs gratuites

- OpenRouteService : 500 optimisations / jour. Au-dela, recompte le lendemain.
- BAN / Recherche-Entreprises / Photon : pas de quota strict.

Si tu epuises ton quota ORS, tu peux toujours utiliser l'app sans optimisation automatique (drag-and-drop manuel des arrets).

## Responsabilite

L'application est fournie "telle quelle". L'auteur ne peut etre tenu responsable de :

- Erreurs d'itineraire qui te feraient perdre du temps
- Donnees corrompues en cas de panne (pense a exporter ton carnet en CSV)
- Litiges avec tes clients

## Donnees personnelles

Voir l'onglet "Confidentialite" : aucune donnee n'est envoyee a un serveur opti_route, tout reste local.

## Contact

noah.trillon28@gmail.com
''';
