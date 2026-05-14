# Checklist de tests — opti_route v2.5.0+2023 — 2026-05-14

Liste exhaustive de tout ce qu'il faut tester avant de merger la PR #94
et livrer la version sur le Xiaomi de Noah.

---

## 🧪 1. App Android (APK release sur Xiaomi)

### 1.1 Démarrage et sécurité

- [ ] **Cold start propre** : tape sur l'icone → splash cream → HomeScreen
  apparait sans loop infini ni crash (regression `libsqlite3.so`)
- [ ] **LockScreen biometrique** : Paramètres → Sécurité → activer PIN
  4 chiffres → activer biométrie → swipe-out de l'app → rouvrir →
  LockScreen apparait → empreinte/face deverrouille → HomeScreen
- [ ] **LockScreen fallback PIN** : si bio échoue 3×, bouton "Utiliser
  le PIN" → saisie 4-6 chiffres → deverrouille
- [ ] **Auto-lock après inactivité** : si configuré, vérifier que
  l'app reverrouille après 5 min (ou la durée configurée)

### 1.2 Notifications

- [ ] **Test notif 2 min** : Paramètres → Notifications → "Test : notif
  dans 2 min" → verrouiller écran → attendre 2 min → notif apparait
  avec vibration + son
- [ ] **Rappel veille de tournée** : créer une tournée pour demain →
  Paramètres > Notifications activer "Rappel veille" → vérifier que
  la notif arrive à l'heure paramétrée la veille
- [ ] **Notif fin de tournée** : marquer une tournée comme terminée →
  notif récap (X livrés, Y échecs, Z minutes)
- [ ] **Notif arrêts oubliés** : pause une tournée avec stops à_livrer →
  notif "N arrêts oubliés"
- [ ] **Notif backup auto réussi** : configurer auto-backup hebdo →
  forcer un backup via FAB "Backup maintenant" → notif "Sauvegarde
  auto reussie · X MB" avec importance low (pas de vibration)
- [ ] **Mode "ne pas déranger"** : configurer quiet hours 22h-06h →
  forcer backup à 23h → la notif ne doit PAS apparaître pendant le
  créneau

### 1.3 Tournées et arrêts

- [ ] **Création tournée** : "+" depuis liste → nom + date + point de
  depart → sauvegarder
- [ ] **Ajout arrêt avec autocomplete** : tape une rue → choisir une
  suggestion BAN → vérifier coords lat/lng pré-remplies (invisibles
  côté UI selon `feedback_geocoding_ui.md`)
- [ ] **Ajout arrêt mode hors-ligne** : couper le wifi/4G → saisir une
  adresse → bouton "Continuer hors-ligne" → bandeau jaune "GPS manquant"
- [ ] **Re-géocodage auto au retour connectivité** : remettre le wifi →
  le bandeau jaune disparait, les coords sont remplies automatiquement
- [ ] **Scan bordereau MESEXP** : photographier un bordereau type
  MESEXP → carte verte "Detection auto" → "Utiliser ces infos" → arrêt
  pré-rempli
- [ ] **Scan bordereau Colissimo** : photographier une étiquette
  Colissimo (tracking 6A/6L) → détection automatique
- [ ] **Scan bordereau Chronopost** : photographier une étiquette
  Chronopost (tracking XR/XE...FR) → détection automatique
- [ ] **OCR rotations auto** : photographier un bordereau **à
  l'envers** → l'app détecte le score qualité bas → retente avec
  90/180/270 → carte verte
- [ ] **Validation BAN post-OCR** : scanner un bordereau avec une
  ville mal orthographiée → BAN corrige → chip "Adresse validée BAN"

### 1.4 Optimisation tournée

- [ ] **Optimisation simple** : tournée avec 3+ arrêts → bouton
  "Optimiser" → ordre des stops change → distance/durée affichées
- [ ] **Optimisation respecte priorités** : marquer un stop "En 1er" +
  un autre "En dernier" → optimiser → ces 2 stops sont en bonne
  position
- [ ] **Bouton optimiser grisé sans clé ORS** : effacer la clé ORS dans
  Paramètres → bouton devient grisé avec tooltip explicatif
- [ ] **Quota ORS** : si on dépasse 500 optimisations/jour → message
  d'erreur explicite

### 1.5 Mode tournée en cours

- [ ] **Démarrer tournée** : "Démarrer" → statut = en_cours → GPS live
  active → ProchainArretCard affiche le 1er stop
- [ ] **Naviguer vers un stop** : tap "Maps" / "Waze" → deep link vers
  l'app de navigation système
- [ ] **Marquer livré** : tap sur un stop → bottom sheet → "Livre" →
  sheet ferme → stop barré dans la liste
- [ ] **Marquer échec** : tap → "Echec" → choisir raison
  (absent/refuse/adresse_fausse/autre) → stop barré orange
- [ ] **Photo preuve** : action "Prendre photo preuve" → camera →
  photo sauve dans `app_documents/preuves/`
- [ ] **Déplacer stop entre tournées** : long press un stop → "Deplacer
  vers..." → choisir tournée cible → stop déplacé + invalidations
  des 2 tournées
- [ ] **Affecter stop à coéquipier** : si mode chef activé → bottom
  sheet → "Affecter à..." → choisir coéquipier → badge couleur
- [ ] **Pause tournée** : menu Plus → "Pause courte" → chrono arrêté
- [ ] **Reprise tournée** : menu Plus → "Reprendre" → chrono reprend
- [ ] **Terminer tournée** : "Arrêter" → notif récap → statut = terminee
- [ ] **Annuler dernier statut** : menu Plus → "Annuler dernier statut" →
  le dernier livré/échec repasse en à_livrer
- [ ] **Tout marquer livré** : menu Plus → "Tout marquer livré" →
  confirmation → tous les a_livrer passent en livré

### 1.6 Carnet d'adresses

- [ ] **Auto-remplissage** : valider un arrêt → vérifier qu'il apparait
  dans le carnet avec useCount = 1
- [ ] **Recherche** : barre de recherche → tape un nom → résultats
  filtrés
- [ ] **Filtre par couleur** : tap un chip couleur (lime/emerald/amber/
  red) → seules les entrées avec cette couleur affichées
- [ ] **Filtre par tag** : tap un chip tag libre → filtrage
- [ ] **Toggle favori** : tap sur la pastille (étoile) → bascule favori
- [ ] **Suppression swipe** : swipe à gauche sur une entrée → confirmation
  → suppression
- [ ] **Import CSV** : icone import → choisir un .csv → fusion intelligent
- [ ] **Export CSV** : icone export → "CSV" → share natif (Drive/mail)
- [ ] **Export vCard** : icone export → "vCard" → fichier .vcf importable
  dans Contacts Android

### 1.7 Sauvegarde / Restauration

- [ ] **Créer backup manuel** : Paramètres → Données → "Creer une
  sauvegarde" → share natif avec le .zip
- [ ] **Restaurer backup** : "Restaurer depuis un .zip" → confirmation
  forte → choisir fichier → dialog "Redémarre l'app" → killer l'app
  + relancer → données restaurées (vérifier nombre de tournées)
- [ ] **Auto-backup hebdo** : configurer "hebdo" → fermer/rouvrir l'app
  → vérifier qu'un .zip apparait dans le dossier
  `/Android/data/com.optiroute.opti_route/files/auto_backups/`
- [ ] **Page "Mes backups"** : Paramètres → "Mes backups" → liste des
  .zip avec date + taille
- [ ] **FAB "Backup maintenant"** : dans "Mes backups" → FAB → loader →
  nouvel item apparait en haut + snackbar "Backup cree" + notif
- [ ] **Partager backup depuis liste** : tap "Partager" sur un item →
  share natif
- [ ] **Restaurer depuis liste** : tap "Restaurer" → confirmation forte
  → dialog "Redémarre"
- [ ] **Supprimer backup** : tap "Supprimer" → confirmation → entrée
  disparait

### 1.8 Stats OCR (nouveau v2.5)

- [ ] **Stats vides initialement** : si jamais scanné, "Aucun scan
  enregistré" + pas de menu trailing
- [ ] **Stats s'accumulent** : scanner 3 bordereaux → revenir
  Paramètres → "Stats OCR" affiche "3 scans enregistrés"
- [ ] **Exporter CSV** : menu 3 points → "Exporter en CSV" → share
  natif avec le fichier `ocr_stats.csv` ouvrable dans Excel/Sheets
- [ ] **Format CSV** : ouvrir le CSV → header `timestamp,parser,
  confidence,rotation_deg,attempts,ban_validated,validation_score,
  duration_ms` + 3 lignes de données
- [ ] **Reset stats** : menu 3 points → "Reset" → confirmation forte →
  compteur revient à 0

### 1.9 Statistiques

- [ ] **Tournées du mois** : Stats → vérifier graphique mensuel
- [ ] **Top 5 clients** : carte "Top clients" → 5 noms ordonnés par
  useCount
- [ ] **Récap facturation** (mode chef) : tarif km + tarif colis +
  cout carburant → marge brute calculée
- [ ] **Export facturation PDF** : bouton "Exporter" → PDF généré

### 1.10 Paramètres

- [ ] **Thème clair/sombre** : toggle → change instantanément
- [ ] **Palette de couleur** : 4 presets (lime / ocean / terracotta /
  charbon) → change instantanément
- [ ] **Densité UI Large** : toggle → texte scaled x1.15
- [ ] **Contraste élevé** : toggle → text plus contrasté
- [ ] **Mode chef équipe** : toggle → débloque les menus Coéquipiers +
  Facturation
- [ ] **Cache géocodage purge** : Cache → "Vider le cache de geocodage"
  → reset
- [ ] **Cache tuiles purge** : "Vider le cache des cartes" → reset
- [ ] **Nettoyer tournées > 1 an** : si applicable → confirmation +
  suppression

### 1.11 Refactors massifs session (regression)

Smoke tests rapides sur les 7 écrans refactorés :

- [ ] [`tournee_du_jour_screen`](app/lib/screens/tournee_du_jour_screen.dart)
  : ouvrir une tournée, vérifier que l'écran rend correctement
  (Body + PlusMenu + FABs + tous les sous-widgets)
- [ ] [`onboarding_screen`](app/lib/screens/onboarding_screen.dart) :
  effacer les données app → relancer → walkthrough 5 pages
- [ ] [`tournees_list_screen`](app/lib/screens/tournees_list_screen.dart)
  : liste avec templates / en cours / terminées, swipe pour supprimer,
  long press pour menu
- [ ] [`scan_bordereau_screen`](app/lib/screens/scan_bordereau_screen.dart)
  : scanner un bordereau, vérifier carte verte/orange + sélection
  manuelle des lignes
- [ ] [`parametres_screen`](app/lib/screens/parametres_screen.dart) :
  scroll complet, toutes les sections rendent
- [ ] [`ajout_arret_screen`](app/lib/screens/ajout_arret_screen.dart) :
  champs adresse, priorité, fenêtre horaire, colis, durée
- [ ] [`carnet_adresses_screen`](app/lib/screens/carnet_adresses_screen.dart)
  : filtres, recherche, tile, swipe delete

---

## 🌐 2. Site vitrine `site_doc/`

Test sur navigateur de bureau (Chrome/Firefox/Edge) ET mobile (Chrome
Android).

### 2.1 Pages principales

- [ ] **`index.html`** : hero + features cards → tous les liens internes
  cliquables, hover states fonctionnent
- [ ] **`features.html`** : 9 sections (geocodage, optim, scan, carnet,
  tournees, equipe, stats, parametres, **sécurité avec PIN+biométrie
  + backup zip + auto-backup**) → contenu à jour avec v2.5
- [ ] **`changelog.html`** : v2.3.0+2016 en latest (vert) + historique
  v1.x → lisible, dates correctes
- [ ] **`roadmap.html`** : sections phase 1/2/3 → cohérent avec où on
  en est
- [ ] **`dashboard.html`** : sera testé en 2.4
- [ ] **`entreprise.html`** : calculateur ROI → saisir des valeurs,
  vérifier calculs
- [ ] **`faq.html`** : 12+ Q/R, expand/collapse marche
- [ ] **`gallery.html`** : **11 shots** (les 3 nouveaux : LockScreen,
  Mes backups, Stats OCR rendent correctement)
- [ ] **`guide-csv.html`** : exemple CSV format, lien vers dashboard
- [ ] **`install-apk.html`** : **tailles APK corrigées** (39/12/57 MB)
- [ ] **`mentions-legales.html`** : RGPD, conditions
- [ ] **`404.html`** : nav vers une URL bidon → page d'erreur stylée

### 2.2 Header / Footer (toutes pages)

- [ ] **Navigation desktop** : tous les liens du header marchent
- [ ] **Navigation mobile** : hamburger menu → menu déroulant
- [ ] **Toggle dark mode** : bouton soleil/lune → bascule + persistance
  via localStorage
- [ ] **Footer** : lien GitHub fonctionne, © CALOTE Noah 2026

### 2.3 Accessibilité

- [ ] **Tab navigation** : Tab depuis le début → focus visible sur tous
  les éléments interactifs (cf `:focus-visible` global ajouté il y a
  quelques sessions)
- [ ] **Lecteur d'écran** : NVDA/TalkBack annonce correctement les
  sections + headings
- [ ] **`aria-live`** : sur dashboard, après upload CSV, l'annonce
  audio remonte
- [ ] **Contraste WCAG AA** : pas de texte gris < 4.5:1 sur fond cream

### 2.4 Dashboard CSV

- [ ] **Upload CSV** : drag-and-drop ou click → fichier accepté
- [ ] **Parsing** : nombre de lignes affiché, colonnes détectées
- [ ] **Charts Chart.js** : barchart + pie chart rendent
- [ ] **Persistance localStorage** : reload de la page → CSV reste
  chargé, bouton "Recharger le dernier CSV"
- [ ] **Format CSV invalide** : upload un fichier non-CSV → erreur
  explicite, pas de crash

### 2.5 Site Flutter Web (`opti_route_web/`)

- [ ] **Compile et démarre** : `flutter build web` produit
  `app/build/web/` sans erreur (côté CI Linux au merge)
- [ ] **Hors-ligne au cold start** : grâce aux fonts bundled,
  l'écran initial rend sans réseau (les tuiles carte resteront vides
  sans internet, normal)
- [ ] **Toutes les routes** : naviguer dans les écrans principaux,
  pas de crash JS

---

## 🚀 3. CI / Déploiement

### 3.1 GitHub Actions

- [ ] **Workflow `deploy-web.yml` se déclenche au merge sur main** :
  vérifier l'onglet Actions
- [ ] **Build Flutter Web** : étape "Build Flutter Web" passe verte
- [ ] **Tests Flutter** : si on ajoute un step `flutter test` au
  workflow, **578 verts** attendus (validation des 8 widget_smoke_test
  reactives au commit `35525be`)
- [ ] **Deploy Pages** : étape "Deploy to GitHub Pages" passe verte
  (nécessite Settings → Pages → Source "GitHub Actions" activé
  préalablement)
- [ ] **Site live** : https://chipat-neko.github.io/opti_route/ →
  charge et affiche l'app Flutter Web

### 3.2 PR #94

- [ ] **Diff lisible** : tous les fichiers de la branche sont visibles
- [ ] **Pas de conflit** avec main (sera vérifié au merge button)
- [ ] **Description PR** correcte avec les 3 chantiers résumés

---

## 📊 4. Tests automatiques côté CLI

- [ ] **`flutter analyze`** : 0 issue (déjà OK au build, à reverifier
  hors VSCode si possible)
- [ ] **`flutter test`** : **578 verts** attendu (570 actuels + 8
  widget_smoke_test reactives). Bloqué côté Windows par le lock
  sqlite3.dll de l'Analyzer VSCode ; faisable hors-VSCode ou via CI
  Linux
- [ ] **`dart fix --dry-run`** : "Nothing to fix"
- [ ] **`flutter pub outdated`** : aucun bump direct safe disponible
  (latlong2 0.10 et share_plus 13 restent bloqués upstream)

---

## ✅ 5. Validation finale

Si tous les blocs ci-dessus passent, l'état est :

- ✅ App fonctionnelle en release sur Xiaomi
- ✅ Site vitrine à jour
- ✅ CI Linux valide les tests
- ✅ Site Flutter Web déployé sur GitHub Pages
- ✅ Branche `feat/vague-A-mode-terrain` peut être mergée et fermée

## 🐛 Si un test échoue

1. **Logcat** : `adb logcat -s flutter:V AndroidRuntime:E` pendant le
   reproductible
2. **Capture l'erreur** : copier la stack trace dans un commit
   `fix:` ciblé sur la branche
3. **Re-test** : refaire le test échoué après le fix
4. **Si bloqué** : reverter le commit suspect + ouvrir une issue dans
   le repo
