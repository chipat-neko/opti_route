# Screenshots Play Store — opti_route

Liste des captures à fournir pour la fiche Play Console. À prendre depuis ton téléphone en mode **vertical** (portrait), résolution native (Play Console les redimensionne).

## Exigences techniques Play Console

- **Format** : PNG ou JPEG, 24 bits, sans transparence
- **Dimensions** : entre 320×320 et 3840×3840 px
- **Ratio** : 16:9 ou 9:16 recommandé (ton tel fait probablement 9:19.5, c'est OK)
- **Nombre min** : 2 captures (mais on en fournit 5-7 pour mieux convertir)
- **Pas de mockups de mauvaise qualité** : prendre les captures **dans l'app vraie**, pas dans un device frame Photoshop

## Procédure de capture

1. Sur ton tel : démarre l'app `opti_route`.
2. Pour chaque écran ci-dessous : prends le screenshot natif Android (volume bas + power, ou geste 3 doigts selon ton skin).
3. Les screenshots se rangent dans `Pictures/Screenshots/` ou similaire.
4. Transfère sur le PC (USB / Drive Desktop / mail-toi-meme).
5. Dépose-les dans `docs/play_store/screenshots/` du repo (à créer).

## 1. Tournée du jour (le hero shot)

**Pourquoi** : c'est l'écran principal, celui qui montre tout d'un coup — la liste des arrêts avec leur statut, le chrono, la stat row.

**Setup à préparer** :
- 1 tournée optimisée du jour avec ~8 arrêts
- 3 arrêts marqués livrés (vert), 1 en échec (rouge), le reste à livrer
- Tournée en cours (statut `en_cours`), pour avoir le bandeau "Avancement"
- Au moins 1 arrêt avec un ETA affiché (la pill "Arrivée vers HH:MM")

**Frame à capturer** : l'écran complet incluant l'AppBar et 4-5 cards d'arrêts visibles.

## 2. Vue carte mode en cours

**Pourquoi** : montre la maturité de l'app (cartographie, polyline d'itinéraire, pins colorés). Différenciant vs concurrents qui n'ont que des listes.

**Setup** :
- Tournée optimisée avec trace dispo (= polyline visible en vert)
- 5-8 pins arrêts dont quelques verts (livrés) + lime/blanc (à livrer)
- Pin "moi" (cercle bleu avec halo) visible quelque part

**Frame** : zoom dézoomé pour voir l'ensemble dépot → arrêts → dépot.

## 3. Carnet d'adresses

**Pourquoi** : valorise la fonction "mémoire client" qui fait gagner du temps à long terme.

**Setup** :
- 8-12 entrées visibles (clients réels ou inventés mais crédibles)
- 2 ou 3 marqués favoris (étoile à gauche)
- Quelques entrées avec une **couleur custom** différente (pastille colorée)
- Champ recherche vide

**Frame** : depuis le haut de l'écran (incluant l'AppBar + le champ de recherche).

## 4. Scan OCR d'un bordereau (résultat)

**Pourquoi** : feature très visuelle qui différencie l'app. Montre qu'on automatise le travail "scribe" du livreur.

**Setup** :
- Après scan d'un bordereau MESEXP valide
- Champs auto-remplis : nom client, adresse, code postal/ville, nb colis
- Score de confiance OK (carte verte, pas orange)

**Frame** : l'écran d'ajout d'arrêt avec les champs remplis post-OCR.

## 5. Stats avec bar chart

**Pourquoi** : preuve "ça marche, j'ai déjà bossé avec". Le graphique attire l'œil dans la galerie Play Store.

**Setup** :
- Avoir au moins 10 jours d'activité enregistrée
- Bar chart visible avec barres de hauteur variées

**Frame** : depuis le haut, le chart + au moins la card "7 derniers jours".

## 6. (Optionnel) Mode sombre

**Pourquoi** : si tu publies après V2.8 (mode sombre complet), c'est un argument fort pour les livreurs de nuit.

**Setup** : même que screenshot 1, mais bascule sur mode sombre dans Paramètres.

**Frame** : tournée du jour en sombre.

## 7. (Optionnel) Détail d'un arrêt (bottom sheet)

**Pourquoi** : montre le flow de validation terrain (boutons Livré / Échec + raison).

**Setup** : tap sur un arrêt non livré → la bottom sheet s'ouvre.

**Frame** : la bottom sheet visible, l'arrêt avec son adresse et le compteur de colis.

## Recommandation finale

**Minimum viable** : screenshots 1, 2, 3, 4, 5 (= 5 captures).

**Idéal pour conversion** : ajouter 6 et 7 (= 7 captures).

Garde **chaque capture nette, sans données embarrassantes** (vrais noms / adresses de clients). Pour les démos, invente des clients à partir d'adresses de mairies, écoles, ou lieux publics.

## Feature graphic (1024×500)

Play Console demande aussi une **bannière de présentation** affichée en haut de ta fiche. Recommandations :

- Format : PNG, 1024×500 px exactement
- Pas de texte essentiel (Google peut cropper)
- Visuel : pin lime + trace de route ink sur fond cream — réutilise les assets `assets/branding/source/`

À designer dans un outil (Figma, Photoshop, Canva). Si tu n'as pas le temps : un screenshot zoomé de la carte + un overlay "opti_route" suffit pour démarrer.
