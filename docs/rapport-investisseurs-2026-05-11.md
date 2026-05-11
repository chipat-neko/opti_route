# opti_route

*Plateforme mobile d'optimisation de tournées pour chauffeurs-livreurs et flottes professionnelles — rapport produit, 11 mai 2026*

## Synthèse exécutive

opti_route est une application Android destinée à deux publics complémentaires.

Le premier public est l'indépendant : chauffeur-livreur en auto-entreprise, coursier urbain, livreur rural. L'application lui apporte un outil mobile complet, gratuit et fonctionnant sans abonnement, là où les solutions de marché actuelles facturent entre cinquante et plus de deux cents euros par mois.

Le second public est l'entreprise de transport, en particulier la petite et moyenne flotte (de cinq à cinquante véhicules), aujourd'hui mal servie par les outils trop coûteux ou trop complexes. Pour ce public, un mode équipe en cours de développement permet à un chef d'équipe de gérer plusieurs véhicules, plaques d'immatriculation, et tournées nommées librement (T1, T2, T13, ou tout autre code choisi par l'équipe).

Le produit existe en version fonctionnelle et testée. Il est en phase de pré-publication Play Store. La première publication peut intervenir dans les semaines qui viennent.

Le projet a démarré le 9 avril 2026. Au 11 mai 2026, environ un mois de développement intensif a été nécessaire pour amener le produit à son état actuel : trois piliers fonctionnels complets (optimisation, carnet client, scan OCR de bordereaux), une suite de cent dix-neuf tests automatisés, et l'intégralité de la documentation de publication.

## Problème adressé

Le chauffeur-livreur, qu'il soit indépendant ou salarié d'une petite flotte, fait face à plusieurs tensions structurelles dans son quotidien.

L'organisation de la tournée est encore largement manuelle. Le livreur reçoit une liasse de bordereaux le matin, parfois cinquante ou plus, et doit décider seul de l'ordre dans lequel les traiter. Un mauvais classement représente plusieurs dizaines de kilomètres et une à deux heures perdues par jour. Sur une année, le coût direct en carburant et en temps non facturé devient significatif.

La saisie des arrêts dans les outils logistiques existants reste laborieuse. Pour un bordereau classique, il faut taper le nom du destinataire, l'adresse complète, le code postal, la ville, le nombre de colis. Un livreur qui traite cinquante arrêts par jour consacre trente à quarante-cinq minutes à cette ressaisie répétitive et source d'erreurs.

Les solutions de marché existantes ciblent principalement les grandes flottes professionnelles. Elles facturent des abonnements indexés sur le nombre de véhicules, exigent une carte bancaire à l'inscription, et imposent une remontée systématique des données sur des serveurs centralisés. Ce modèle est inadapté au livreur indépendant comme aux petites flottes qui n'ont ni le budget récurrent, ni le souhait de transmettre leurs données clients à un tiers commercial.

Le livreur, qu'il soit indépendant ou en équipe, a peu de levier pour conserver et exploiter sa connaissance terrain. Les adresses des clients livrés régulièrement, leurs particularités (code d'accès, étage, fenêtres horaires), les raisons d'échec récurrentes, tout cela disparaît à la fin de la journée sauf à être consigné dans un carnet papier ou un tableur informel.

## Proposition de valeur

opti_route répond à ces tensions par une réponse intégrée et locale, déclinée pour l'indépendant comme pour l'équipe.

Sur l'organisation de la tournée, l'application calcule l'ordre optimal des arrêts en quelques secondes en s'appuyant sur OpenRouteService, un service européen alimenté par OpenStreetMap utilisant le moteur d'optimisation VROOM. Le livreur peut ensuite réordonner manuellement les arrêts pour corriger les sens uniques mal mappés ou intégrer des contraintes que le solveur ne modélise pas (places de stationnement, demi-tours impossibles pour un fourgon).

Sur la saisie des arrêts, l'application intègre un scanner OCR. Une photo du bordereau suffit pour extraire automatiquement le nom du destinataire, l'adresse complète, le nombre de colis et le téléphone éventuel. Le traitement OCR est effectué sur le téléphone, sans appel cloud, et fonctionne donc même sans réseau.

Sur le modèle économique, l'application est gratuite pour la version indépendant et le restera. Les services externes utilisés (BAN, Recherche-Entreprises, OpenRouteService) ont tous un palier gratuit suffisant pour un usage individuel intensif. Aucune carte bancaire n'est requise pour utiliser le produit.

Sur la connaissance terrain, opti_route maintient automatiquement un carnet d'adresses local. Chaque arrêt validé enrichit ce carnet, qui propose ensuite des suggestions d'auto-complétion aux nouvelles saisies. Le livreur peut épingler ses clients critiques, leur attribuer des couleurs de repérage, et consulter des statistiques par client.

## Différenciateurs

Le produit présente plusieurs différenciateurs par rapport aux solutions de marché.

**Architecture local-first.** La base de données SQLite réside sur le téléphone de l'utilisateur. Aucune donnée commerciale ne transite par un serveur opti_route, car aucun serveur opti_route n'existe en version indépendant. Cette propriété est techniquement vérifiable et explicitement énoncée dans la politique de confidentialité. Elle constitue un argument fort pour la confiance utilisateur et pour la conformité RGPD.

**Aucun traceur commercial.** L'application n'intègre ni régie publicitaire, ni outil d'analyse tiers, ni identifiant publicitaire, ni cookies. Le suivi des plantages techniques est assuré par Android Vitals, intégré nativement à Google Play Console, sans SDK tiers dans le binaire.

**Scan OCR des bordereaux.** Différenciant fort vis-à-vis des concurrents généralistes. La plupart des solutions de planification attendent une saisie manuelle ou un import CSV fourni par un donneur d'ordres. opti_route accepte la matière première réelle du livreur indépendant : la liasse de bordereaux papier reçue chaque matin.

**Ergonomie pensée pour la conduite.** Typographie Manrope optimisée lecture, palette à fort contraste calibrée pour le plein soleil, mode plein écran disponible pour la consultation de carte au volant, mode sombre en cours de finalisation pour la conduite de nuit.

## Architecture technique

L'application est développée en Flutter (Dart), ce qui permet un portage iOS ultérieur à coût marginal et donne accès à un écosystème de packages mature.

La persistance des données est assurée par Drift, un ORM SQLite type-safe, avec un schéma actuellement à la version 15. Sept tables structurent les données : tournées, arrêts, paramètres utilisateur, scans de bordereaux, cache de géocodage, carnet d'adresses, historique de transitions de statut.

La gestion d'état utilise Riverpod, ce qui permet une séparation claire entre la couche de données et l'affichage, et facilite l'écriture de tests unitaires.

L'optimisation d'itinéraire est déléguée à OpenRouteService (API publique européenne). Le quota gratuit est de cinq cents requêtes par jour, ce qui couvre largement l'usage individuel le plus intensif.

Le géocodage procède par cascade en commençant par BAN (Base Adresse Nationale, donnée publique data.gouv.fr) pour les adresses postales. Si la requête commence par un nom d'entreprise, la cascade interroge d'abord Recherche-Entreprises (annuaire SIRENE public) pour matcher par enseigne. Photon (service Komoot basé sur OpenStreetMap) sert de fallback international.

La cartographie utilise flutter_map avec les tuiles OpenStreetMap. Un cache disque local conserve les tuiles déjà téléchargées, ce qui réduit la consommation de données et permet un usage partiellement hors-ligne.

L'OCR est confié à Google ML Kit Text Recognition. Le modèle est local au téléphone, aucun appel cloud n'est fait. Un parser dédié interprète le texte brut pour structurer les champs métier.

L'application est packagée en Android App Bundle pour la distribution Play Store, signée avec une keystore release dont la procédure de génération est documentée.

## Tests et qualité

La couverture de tests automatisés est de cent dix-neuf tests Dart au moment de la rédaction.

Cette base couvre les briques métier sensibles : optimisation et ordre des priorités, transitions de statut des arrêts, export et import CSV au format RFC 4180, calcul des statistiques cumulatives et journalières, parsing des bordereaux, géocodage SIRENE, cycle pause et reprise du chronomètre, calcul de l'estimation d'heure d'arrivée par arrêt.

Le pipeline d'intégration continue s'exécute automatiquement sur chaque révision via GitHub Actions. Il enchaîne la résolution des dépendances, la régénération du code Drift, l'analyse statique stricte et l'exécution complète de la suite de tests. Aucun avertissement n'est toléré.

## Fonctionnalités produit

Inventaire opérationnel regroupé par domaine. La description ci-dessous correspond à l'état au 11 mai 2026.

### Création et planification

L'utilisateur crée une tournée en saisissant un nom libre, une date et un point de départ géocodé. La capacité du véhicule en colis peut être renseignée pour activer une alerte si l'ensemble des arrêts la dépasse.

Les arrêts sont ajoutés manuellement ou par scan de bordereau. Chaque arrêt comporte une adresse, un nom client optionnel, un nombre de colis, une durée d'arrêt estimée, et optionnellement une fenêtre horaire.

Les arrêts peuvent être marqués "obligatoire en premier" ou "obligatoire en dernier" pour contraindre l'ordre dans le solveur. Un arrêt "à éviter si possible" voit sa priorité abaissée en cas de saturation.

### Optimisation

L'utilisateur déclenche l'optimisation par un bouton dédié. L'application transmet la liste des arrêts géolocalisés et reçoit en retour l'ordre optimal, la distance totale, la durée totale et le tracé géographique.

Le bouton est automatiquement désactivé si aucune modification structurelle n'a eu lieu depuis la dernière optimisation, ce qui évite la consommation inutile du quota. Le tracé est affiché sur la carte sous forme de polyline.

Après optimisation, le livreur peut intervenir manuellement par drag-and-drop. Cette possibilité est essentielle car l'optimiseur ne modélise pas toutes les contraintes terrain.

### Templates et multi-tournées

Une tournée existante peut être marquée comme template. Elle apparaît épinglée en haut de l'historique avec un bouton "Créer une tournée depuis ce template" qui duplique l'arborescence en remettant les statuts à zéro. Mécanisme conçu pour les tournées hebdomadaires récurrentes.

L'application permet de planifier plusieurs tournées sur la même date (matin et après-midi typiquement). Un bandeau facilite le switch entre tournées du jour.

### Exécution

Au démarrage de la tournée, le chronomètre s'enclenche. Un bouton de pause permet de suspendre le décompte. La durée des pauses est cumulée séparément, ce qui permet d'afficher le temps actif réel hors pauses. Donnée utile pour la facturation à l'heure ou l'analyse de productivité.

La liste des arrêts est filtrable par statut et triable par distance GPS. Une heure d'arrivée estimée est affichée pour chaque arrêt restant, calculée à partir de la distance haversine cumulée et d'une vitesse moyenne déduite des données ORS.

Au moment de la livraison, un tap sur l'arrêt ouvre une feuille de validation. L'utilisateur peut marquer livré, en échec avec choix d'une raison, ou revenir à l'état "à livrer". Une capture GPS est effectuée au moment de la validation et persistée comme preuve de passage en cas de litige.

L'édition rapide du nombre de colis et des notes est possible directement dans la feuille, sans ouvrir l'écran d'édition complet. La dictée vocale Android est rappelée à l'utilisateur (appui long sur la barre d'espace) pour une utilisation à une main.

Chaque transition de statut est enregistrée dans une table d'audit, ce qui constitue une piste exploitable en cas de litige client.

### Vue carte

Carte OpenStreetMap centrée sur la zone de la tournée. Dépôt en pin lime, arrêts en pins numérotés colorés selon le statut, tracé optimisé en polyline verte. Mode plein écran disponible pour la conduite.

Pendant l'exécution, un pin "moi" matérialisé par un cercle bleu avec halo indique la position GPS en temps réel. Ce pin n'est affiché que pendant les tournées actives.

### Carnet d'adresses

Chaque arrêt validé enrichit le carnet d'adresses local. La logique de dédoublonnage repose sur le nom client ou la proximité géographique (rayon d'environ cent dix mètres). Un compteur d'utilisations et la date de dernière visite sont maintenus par entrée.

Le livreur peut consulter et éditer le carnet. Un toggle favori remonte une entrée en haut indépendamment du nombre d'utilisations. Une couleur de repérage choisie parmi six personnalise la pastille de l'entrée.

Un panneau de statistiques par client affiche : nombre de livraisons réussies, nombre d'échecs, date de dernière visite, top trois des raisons d'échec.

L'import et l'export CSV au format RFC 4180 permettent la sauvegarde et la migration entre appareils. Un export PDF du carnet en annuaire imprimable est également disponible. Une bannière passive rappelle de sauvegarder si plus de quatorze jours se sont écoulés depuis le dernier export.

### Scan OCR

L'utilisateur photographie un bordereau. Le texte est extrait localement par ML Kit. Un parser dédié interprète la structure pour produire un arrêt prérempli.

Le format MESEXP, utilisé par de nombreux transporteurs français, est nativement supporté. Champs extraits : nom du destinataire, rue, code postal, ville, nombre de colis, téléphone si présent.

Le parser inclut des heuristiques pour tolérer les fautes d'OCR mineures, les photos prises tête-bêche, et la distinction expéditeur / destinataire.

Un score de confiance est calculé. Une carte orange signale les bordereaux ambigus pour lesquels l'utilisateur doit vérifier les champs avant validation.

Un parser dédié aux formats "collés sur les colis" est en cours de développement et sera ajouté avec les photos de référence du terrain.

### Statistiques

Un écran de statistiques cumulatives propose trois fenêtres de temps : sept derniers jours, trente derniers jours, trois cent soixante-cinq derniers jours. Pour chaque fenêtre : tournées planifiées et terminées, arrêts, colis livrés, distance, durée, taux de réussite.

Un mini graphique en barres affiche les colis livrés par jour sur les quatorze derniers jours. Barres en émeraude, barre du jour en lime, pastille rouge si la journée a comporté un échec.

### Notifications

Notifications locales planifiées. Un bouton de test permet de vérifier la chaîne complète. Un rappel quotidien optionnel à dix-neuf heures rappelle de vérifier la tournée du lendemain.

### Paramètres et administration

Configuration de la clé API OpenRouteService (saisie masquée), capacité véhicule par défaut, durée d'arrêt par défaut, application de navigation préférée.

Zone de maintenance : compteur d'optimisations consommées dans la journée, nettoyage des tournées de plus d'un an, vidage du cache des tuiles, vidage du cache du géocodage.

Choix du thème (système, clair, sombre) et accès aux mentions légales.

### Confidentialité et stockage

Toutes les données sont stockées en local dans une base SQLite. Aucun serveur central. La désinstallation supprime intégralement les données.

Permissions Android demandées : Internet, Caméra (scan bordereaux), Localisation (uniquement pendant tournée active), Notifications.

### Export et partage

Génération d'un PDF récapitulatif d'une tournée avec en-tête, statistiques et tableau des arrêts. Partage via le sélecteur natif (WhatsApp, mail, Drive).

Export CSV et PDF du carnet d'adresses. Toutes les actions de partage sont déclenchées explicitement par l'utilisateur.

## Mode équipe et gestion de flotte

Cette section décrit une fonctionnalité prioritaire de la roadmap moyen terme, particulièrement adaptée aux entreprises de transport.

Le mode équipe transforme opti_route en outil de gestion de flotte pour les TPE et PME du transport. Le chef d'équipe ouvre un compte central et invite ses chauffeurs. Chaque chauffeur installe l'application sur son téléphone, se connecte avec ses identifiants, et reçoit automatiquement ses tournées du jour.

L'équipe gère plusieurs véhicules. Chaque véhicule est identifié par sa plaque d'immatriculation, sa capacité utile, et éventuellement son chauffeur attitré. Les tournées sont nommées librement par l'équipe ou le chef d'équipe (par exemple T1, T2, T13, ou tout autre code de codification interne). Aucun nom n'est pré-rempli par l'application : l'équipe garde la main complète sur sa nomenclature.

Le chef d'équipe dispose d'un tableau de bord centralisé en lecture seule où il voit la progression de chaque tournée en temps réel, le pourcentage de livraisons effectuées, les éventuels échecs et leurs raisons, le temps actif de chaque chauffeur. Il peut intervenir pour rééquilibrer les tournées entre véhicules si un chauffeur a fini en avance ou qu'un autre est ralenti.

Les statistiques agrégées sont consultables au niveau de l'équipe : kilomètres totaux, taux de réussite global, top des causes d'échec, productivité par chauffeur, par véhicule, par jour de la semaine.

Cette extension préserve la philosophie local-first du produit individuel. La synchronisation entre les téléphones et le tableau de bord central s'effectue en mode chiffré, et l'équipe peut choisir un hébergement souverain (par exemple un serveur sous son contrôle) si elle ne souhaite pas dépendre d'un service tiers.

Cette feature ouvre l'application à un marché significativement plus large que l'individuel : les TPE et PME du transport français qui sont aujourd'hui mal servies par les outils du marché trop chers ou trop complexes.

## État du produit

Le produit est en phase de pré-publication Play Store. La quasi-totalité des fonctionnalités décrites en section "Fonctionnalités produit" sont codées et testées.

Trois branches de développement sont actuellement en attente de revue et de merge sur la branche principale du dépôt :

La première regroupe les améliorations ergonomiques de terrain : badge "en cours" multi-écrans, estimation d'heure d'arrivée par arrêt, copie d'adresse au presse-papier, fond teinté par statut, suite de tests dédiée.

La deuxième regroupe les nouveaux écrans : mini bar chart des quatorze derniers jours, pin "moi" live sur la carte, bannière de rappel de sauvegarde, rappel quotidien optionnel, bouton pause sur le chronomètre.

La troisième regroupe la documentation de publication Play Store : description, spécifications de captures d'écran, procédure de soumission pas-à-pas.

Au total, quinze commits sont prêts à être mergés. La suite de tests passe au complet (cent dix-neuf tests verts) et l'analyseur statique ne signale aucun problème.

L'icône de l'application et le splash screen sont finalisés. La palette s'articule autour des couleurs cream, ink, lime et emerald, avec la typographie Manrope pour le corps et JetBrains Mono pour les valeurs numériques.

La politique de confidentialité et les conditions générales d'utilisation sont rédigées en français et prêtes à être hébergées sur une page web publique.

## Roadmap

**Court terme (quatre à huit semaines).** Finalisation du mode sombre sur l'ensemble des écrans. Complétion du parser de bordereaux pour le format "collés sur les colis". Publication effective sur le Play Store en piste de test interne puis en production.

**Moyen terme (trois à six mois).** Développement du mode équipe et de la gestion de flotte décrits ci-dessus. Ajout d'un module de navigation turn-by-turn intégré (piste prioritaire : SDK Mapbox, plan gratuit cinquante mille chargements par mois) pour éviter à l'utilisateur de basculer entre opti_route et Google Maps ou Waze.

Ajout d'un mode hors-ligne complet avec pré-cache d'une zone définie (tuiles et routes), pour les livreurs intervenant en zones rurales mal couvertes par le réseau mobile.

**Long terme (six à douze mois).** Ouverture éventuelle d'une version freemium pour les utilisateurs souhaitant lever certaines limites : quotas API supérieurs, sauvegarde cloud chiffrée optionnelle, support multi-appareils. La fonctionnalité de base resterait gratuite et non dégradée.

Portage iOS, rendu peu coûteux par le choix de Flutter. La principale difficulté sera la régénération des assets aux dimensions iOS et la traversée du processus de validation App Store.

## Marché et concurrence

Le marché cible primaire de la version indépendant est le livreur français en exercice : auto-entrepreneur en livraison à domicile, coursier urbain et rural, chauffeur sous-traitant des grands transporteurs qui ne dispose pas d'outil métier fourni.

Le marché cible primaire de la version équipe est la TPE et PME du transport en France, segment qui regroupe plusieurs milliers d'entreprises avec une flotte de cinq à cinquante véhicules.

La concurrence directe se segmente en trois catégories.

Les solutions professionnelles haut de gamme (Onfleet, Routific, Locus) facturent entre cinquante et plus de deux cents euros par véhicule par mois. Elles ciblent les flottes structurées et imposent un onboarding payant. Trop chères et trop complexes pour le segment opti_route.

Les applications grand public (Google Maps, Waze) ne font pas d'optimisation de tournée multi-arrêts et n'ont pas de notion de carnet d'adresses client. Elles ne répondent pas au besoin réel du livreur.

Les solutions intermédiaires (Circuit, Speedy Route) sont positionnées sur du dix à vingt euros par mois et ciblent partiellement le segment indépendant. Elles conservent toutefois un modèle d'abonnement et une politique de données moins favorable que celle d'opti_route.

Le positionnement d'opti_route combine la qualité fonctionnelle des solutions professionnelles avec le modèle gratuit et la philosophie local-first des outils grand public. Cette combinaison n'est, à ma connaissance, pas occupée par un acteur établi en France.

## Modèle économique

À court et moyen terme, la version indépendant est entièrement gratuite, sans publicité, sans collecte de données. Le coût marginal par utilisateur supplémentaire est nul pour l'éditeur, puisque chaque utilisateur final crée sa propre clé OpenRouteService.

Plusieurs pistes de monétisation non intrusives sont envisageables à plus long terme, déclenchées uniquement si une base utilisateur significative se constitue.

Un palier "pro" payant facultatif (cinq à dix euros par mois) débloquerait des fonctionnalités à coût d'infrastructure pour l'éditeur : sauvegarde cloud chiffrée, synchronisation multi-appareils, quotas API rehaussés via une clé partagée.

Le mode équipe (version flotte) serait facturé à l'entreprise utilisatrice, avec un tarif indexé sur le nombre de véhicules. Les retours préliminaires sur le segment TPE et PME du transport suggèrent une zone de tarification acceptable entre cinq et quinze euros par véhicule par mois, à confirmer par des entretiens utilisateurs ciblés.

Un partenariat avec des transporteurs ou des éditeurs de logiciels métier complémentaires (comptabilité, facturation auto-entrepreneur) pourrait financer le développement de connecteurs spécifiques, facturés au partenaire et non à l'utilisateur final.

Ces pistes sont mentionnées à titre exploratoire. Aucune n'est en chantier actif. La priorité immédiate est la publication du produit gratuit et la constitution d'une base utilisateur fidèle.

## Genèse du projet

Le projet a démarré le 9 avril 2026 à l'initiative de CALOTE Noah, chauffeur-livreur en exercice. La douleur du quotidien — l'organisation manuelle des tournées, la ressaisie des bordereaux, l'absence d'outil abordable pour l'indépendant — est à la source du produit.

L'ensemble de la conception, du développement, du design graphique et de la documentation a été réalisé par CALOTE Noah en environ un mois de travail intensif. Le rythme est rendu possible par le choix d'une stack mature (Flutter, Drift, Riverpod), par une discipline de tests automatisés permettant d'avancer sans peur de régression, et par une approche pragmatique consistant à livrer rapidement des versions fonctionnelles puis à itérer.

L'auteur reste seul sur le développement et le support utilisateur. Cette limite pourrait devenir critique en cas de croissance utilisateur rapide. L'ouverture du projet à un développeur additionnel est envisageable à moyen terme.

## Annexe — limites connues

Cette section liste honnêtement les limites actuelles du produit, pour ne pas survendre.

Le mode sombre n'est complet qu'à environ soixante-dix pourcent des écrans. Certains éléments restent figés en clair. Un refactor complet est planifié pour la phase de pré-publication finale.

L'optimisation d'itinéraire ne modélise pas tous les détails du terrain (places de stationnement, demi-tours fourgon, sens uniques mal renseignés dans OpenStreetMap). Le mécanisme de drag-and-drop manuel a été ajouté précisément pour pallier ces limites.

Le scan OCR fonctionne bien sur le format MESEXP. D'autres formats nécessitent un travail d'extension dédié, en attente des photos de référence du terrain.

Le quota d'optimisations OpenRouteService est de cinq cents par jour sur le plan gratuit. Largement suffisant pour un usage individuel intensif, mais potentiellement contraignant pour la version équipe en montée en puissance. Une bascule vers un plan payant ORS ou vers une infrastructure VROOM auto-hébergée serait envisageable à ce moment-là.

L'application est aujourd'hui exclusivement Android. Le portage iOS est techniquement faisable mais demande un compte développeur Apple (cent dollars par an, contrairement aux vingt-cinq dollars unique d'Android) et un effort de validation supplémentaire.

## Contact

CALOTE Noah — noah.trillon28@gmail.com

Le code source de l'application est conservé en dépôt privé pour protéger la propriété intellectuelle. Un accès en lecture seule peut être accordé sur demande à des investisseurs ou partenaires sérieux, sous accord de confidentialité.
