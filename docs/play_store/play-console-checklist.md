# Procédure publication Play Store — opti_route

Check-list complète à dérouler **dans l'ordre** pour publier opti_route sur le Play Store. Compte ~2-4 heures de travail effectif (hors délais de validation Google).

## Étape 0 — Pré-requis

- [ ] **Compte développeur Google** : 25 $ une fois (paiement unique, pas d'abo). Création : https://play.google.com/console/signup
  - C'est le **seul moment où la CB sort**. 25 $ ≈ 23 € au cours actuel. Pas de renouvellement.
- [ ] **Keystore release** créée : voir `docs/keystore-release.md`. Backup en sécurité (1Password / disque externe). Sans cette keystore, tu ne peux plus jamais re-uploader une mise à jour signée.

## Étape 1 — Hébergement de la politique de confidentialité

Google **exige** une URL publique pour ta politique de confidentialité. Le fichier `docs/legal/privacy-policy.md` est déjà rédigé, il faut l'héberger.

### Option A — GitHub Pages (recommandé, gratuit, 5 min)

1. Va sur https://github.com/chipat-neko/opti_route/settings/pages
2. Source : **Deploy from a branch**
3. Branch : **main**, Folder : **/docs**
4. Save → attendre 1-2 minutes l'activation
5. URL finale : `https://chipat-neko.github.io/opti_route/legal/privacy-policy.html`
   - Note : GitHub Pages rend automatiquement le `.md` en `.html` via Jekyll
6. Vérifie l'URL dans un navigateur incognito avant de la mettre dans Play Console.

### Option B — Gist public (alternative rapide)

1. https://gist.github.com → New gist
2. Filename : `privacy-policy.md`
3. Coller le contenu de `docs/legal/privacy-policy.md`
4. Create **public gist** → noter l'URL

## Étape 2 — Build de l'APK signé en release

Sur ton PC (la machine où la keystore est) :

```powershell
cd d:\opti_route\app
flutter clean
flutter pub get
flutter build appbundle --release
```

Sortie : `build/app/outputs/bundle/release/app-release.aab` (Android App Bundle, le format Play Store)

**Vérification** :
- Taille typique : 30-50 MB
- Si la keystore release n'est pas trouvée, Gradle utilise la debug keystore et Play Console refuse → vérifie `android/key.properties`

## Étape 3 — Créer la fiche Play Console

### 3.1 — Nouvelle application

1. Play Console → Toutes les applications → **Créer une application**
2. Nom : `opti_route`
3. Langue par défaut : Français (France)
4. Type : Application
5. Gratuit ou payant : **Gratuite**
6. Cocher : conformité aux règles, lois US sur l'export, etc.
7. → Créer

### 3.2 — Fiche du Store principale

Onglet **Présence sur le Play Store → Fiche du Store principale**.

À remplir depuis `docs/play_store/description-fr.md` :
- [ ] Titre
- [ ] Description courte
- [ ] Description longue
- [ ] Catégorie : Productivité
- [ ] Tags : ajouter "logistique", "livraison", "productivité"
- [ ] Coordonnées dev : email noah.trillon28@gmail.com
- [ ] URL politique de confidentialité : celle de l'étape 1
- [ ] **Icône** : le PNG 512×512 à fournir (régénérable depuis `assets/branding/source/`)
- [ ] **Feature graphic** : 1024×500 (cf. `docs/play_store/screenshots.md`)
- [ ] **Captures d'écran téléphone** : 5-7 selon `docs/play_store/screenshots.md`

### 3.3 — Classification du contenu

Onglet **Stratégie → Classification du contenu**. Lance le questionnaire :
- Pas de violence, sexe, contenu sensible
- Pas d'achats in-app
- Pas de pub
- Ne collecte pas de données utilisateur

Résultat attendu : classification **Tous publics (Everyone)**.

### 3.4 — Sécurité des données

Onglet **Stratégie → Sécurité des données**. Réponses à donner :

| Question | Réponse |
|---|---|
| Données collectées ou partagées ? | **Non** |
| Données stockées sur le téléphone uniquement ? | Oui (cocher) |
| Données chiffrées en transit ? | Oui (les APIs externes sont en HTTPS) |
| L'utilisateur peut supprimer ses données ? | Oui (désinstallation) |

### 3.5 — Audience cible

Onglet **Stratégie → Audience cible et contenu**.
- Tranches d'âge cible : **18 ans et plus**
- L'app n'attire pas spécifiquement les enfants
- Pas de fonctionnalité ne respectant pas les règles famille

### 3.6 — Détails de l'application

- Catégorie : **Productivité**
- Application gouvernementale : Non
- L'app contient des annonces : **Non**

## Étape 4 — Internal testing track

Avant le release public, **toujours passer par l'internal testing** pour vérifier que le bundle marche sur Play Store réel sans planter.

1. Play Console → **Test et publication → Tests internes → Créer une release**
2. Upload `app-release.aab` généré à l'étape 2
3. Notes de version (FR) :
   ```
   Version initiale d'opti_route.
   
   Optimisation de tournée + carnet d'adresses + scan OCR des bordereaux.
   100% local, pas de CB, pas de pub.
   ```
4. Ajouter les **testeurs internes** (toi-même + 1-2 amis livreurs s'ils acceptent) via leur email Google
5. Submit → Google valide en 2-24 h
6. Les testeurs reçoivent un lien type `https://play.google.com/apps/internaltest/...` → ils installent depuis là (pas via Play Store public)
7. **Tester 2-3 jours** : faire une vraie tournée, valider tout (scan, GPS, validation arrêts, export PDF...).

## Étape 5 — Production release

Quand l'internal testing valide :

1. Play Console → **Test et publication → Production → Créer une release**
2. Promouvoir le bundle internal vers production (pas besoin de re-upload)
3. Sélectionner les pays : **France** uniquement au début (élargir plus tard)
4. Notes de version (les mêmes que pour internal)
5. Soumettre

**Délai validation Google** : 3-7 jours typiquement (peut être plus long pour une première publication).

## Étape 6 — Post-publication

- [ ] Tester l'installation depuis le Play Store sur un appareil neuf (pas le tien)
- [ ] Vérifier que la fiche s'affiche bien (screenshots, description, icône)
- [ ] Surveiller les premiers retours utilisateurs / crash rapports dans Play Console
- [ ] Tag git la version : `git tag v1.0.0 && git push --tags`

## Mises à jour ultérieures

Pour chaque release suivante :

1. Bump `pubspec.yaml` : `version: 1.0.X+Y`
2. `flutter build appbundle --release`
3. Upload dans Play Console → Internal testing → nouvelle release
4. Tester 1-2 jours sur internal
5. Promouvoir en production

## Ce qui peut bloquer la 1re soumission

- **Privacy policy URL inaccessible** : Google va rejeter. Vérifie en mode incognito.
- **Icône floue ou de mauvaise taille** : 512×512 PNG sans transparence, contenu lisible à petite taille.
- **Screenshots fakes (mockups Photoshop)** : Google peut rejeter, prendre des vraies captures.
- **Permissions Android sans justification** : si on demande GPS / Caméra dans le manifest, Play Console questionne. La politique de confidentialité justifie déjà ces usages.
- **Description trop "spammy"** : éviter "MEILLEURE APP DE LIVRAISON" et autres tournures vendeuses agressives.

## Ressources

- Documentation officielle : https://support.google.com/googleplay/android-developer
- Forum dev FR : https://groups.google.com/g/android-developers-fr
