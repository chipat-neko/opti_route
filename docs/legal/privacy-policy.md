# Politique de confidentialité — opti_route

*Dernière mise à jour : 10 mai 2026*

opti_route est une application d'optimisation de tournées de livraison à usage personnel. Elle a été conçue avec le principe **« tout reste sur ton téléphone »**. Cette politique décrit en français simple les données traitées par l'app.

## Données stockées localement (et nulle part ailleurs)

Tout ce que tu saisis ou que l'app calcule reste **sur la mémoire de ton téléphone**, dans une base SQLite locale. Aucune donnée n'est envoyée à un serveur opti_route — il n'y a d'ailleurs pas de serveur opti_route.

Concrètement, sont stockés sur ton appareil :

- Les tournées créées (nom, date, point de départ).
- Les arrêts (adresses, coordonnées GPS, nb colis, statut de livraison, notes).
- Le carnet d'adresses des clients déjà livrés.
- Tes préférences (capacité véhicule par défaut, app de nav préférée, etc.).
- Le cache des résultats de géocodage (pour éviter de re-interroger les APIs).

Pour supprimer toutes ces données : désinstalle l'application Android. La base SQLite est supprimée avec.

## Services tiers utilisés

opti_route interroge des **APIs publiques gratuites** pour fonctionner. Ces APIs ne reçoivent que les **requêtes nécessaires** (recherche d'adresse, calcul d'itinéraire) et **aucune donnée personnelle** sur toi.

| Service | Utilisé pour | Données envoyées |
|---|---|---|
| **BAN** (api-adresse.data.gouv.fr) | Recherche d'adresse postale | Le texte que tu tapes |
| **Recherche-Entreprises** (recherche-entreprises.api.gouv.fr) | Recherche d'entreprises par nom | Le nom d'entreprise tapé |
| **Photon** (photon.komoot.io) | Recherche d'enseignes / marques | Le texte que tu tapes |
| **OpenRouteService** (openrouteservice.org) | Optimisation de tournée + tracé d'itinéraire | Liste des coordonnées de tes arrêts (sans nom ni autre info) |

OpenRouteService nécessite une **clé API personnelle** que tu crées gratuitement sur leur site. Cette clé est stockée localement sur ton téléphone.

## Permissions Android demandées

| Permission | Pourquoi |
|---|---|
| **Internet** | Pour interroger les APIs de géocodage et d'optimisation |
| **Caméra** | Pour scanner les bordereaux de livraison (texte traité **localement** par Google ML Kit, jamais envoyé) |
| **Localisation** | Pour le mode « tournée en cours » qui affiche la distance live jusqu'au prochain arrêt |

La permission de localisation est demandée **uniquement** quand tu démarres une tournée. Tu peux la révoquer à tout moment depuis les Paramètres Android — l'app fonctionnera sans mode GPS live.

## Données partagées avec d'autres applications

Tu peux explicitement choisir de partager :

- Un **export CSV de ton carnet d'adresses** via le sélecteur de partage Android (Drive, mail…).
- Un **export PDF d'une tournée** via le sélecteur de partage Android.
- Une **navigation Maps ou Waze** : opti_route ouvre l'app externe avec les coordonnées de l'arrêt en paramètre d'URL.

Ces partages sont déclenchés **uniquement par toi** via les boutons dédiés. Aucun partage automatique.

## Pas de tracking, pas de pub, pas de monétisation

opti_route n'intègre **aucune** des choses suivantes : analytics, publicité, crash reporting cloud, push notifications, identifiants publicitaires, fingerprinting, cookies. Aucune donnée n'est collectée à des fins commerciales.

## Contact

Pour toute question : noah.trillon28@gmail.com
