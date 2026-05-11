# Fiche Play Store — opti_route

*Listing à coller dans Google Play Console une fois le compte développeur créé (25 USD une fois).*

---

## Informations générales

- **Nom de l'application** : `opti_route`
- **Sous-titre / Court résumé (80 car. max)** :
  > Optimise tes tournées de livraison, hors ligne, sans abonnement.
- **Catégorie** : Productivité
- **Catégorie secondaire** : Cartes et navigation
- **Public visé** : Tous publics
- **Type d'app** : Application
- **Tarification** : Gratuite, sans achats intégrés, sans publicité

---

## Description courte (80 caractères max)

> Optimise tes tournées de livraison, hors ligne, sans abonnement.

(79 caractères avec espaces — OK)

---

## Description longue (4000 caractères max)

```
opti_route est l'outil de planification de tournées que les chauffeurs-livreurs
indépendants attendaient : 100 % gratuit, sans abonnement, sans publicité,
sans carte de crédit.

══════════════════════════════════
TOURNÉES OPTIMISÉES EN UN TAP
══════════════════════════════════

Saisis tes arrêts, opti_route calcule le meilleur ordre de passage pour
minimiser la distance et le temps. Sous le capot : OpenRouteService et
VROOM, les mêmes algorithmes que les grandes flottes professionnelles.

• Profil Voiture/VUL ou Camion >3.5t (respecte les restrictions
  hauteur/poids et évite les centres piétonnisés)
• Capacité véhicule respectée par le solveur
• Évitement des péages
• Distance, durée et coût carburant estimé affichés avant le départ
• Tracé du parcours sur la carte (tuiles OpenStreetMap)
• Priorités "en premier" / "en dernier" / "éviter"
• Réordonnancement manuel par glisser-déposer

══════════════════════════════════
SCAN AUTOMATIQUE DES BORDEREAUX
══════════════════════════════════

Photographie un bordereau, opti_route lit l'adresse, le code postal, le
nom du destinataire et le nombre de colis. Reconnaissance hors ligne avec
ML Kit de Google — aucune photo n'est envoyée sur internet.

══════════════════════════════════
MODE TERRAIN
══════════════════════════════════

• Carte "Prochain arrêt" avec distance GPS live
• Bouton "Livré" / "Échec" par arrêt, avec motif
• Lancement direct Google Maps ou Waze
• Stepper colis pour ajuster sur place
• Notes auto-sauvegardées
• Édition des fenêtres horaires d'un tap
• Annulation du dernier statut (en cas d'erreur)
• Notifications de rappel locales programmables par tournée

══════════════════════════════════
ZONE RURALE SANS 4G ?
══════════════════════════════════

Mode "Saisie hors ligne" : tu tapes l'adresse à la main, l'arrêt est
créé sans GPS. De retour en zone couverte, un seul tap "Géolocaliser
hors-ligne" et tous les arrêts sont rattrapés en batch.

══════════════════════════════════
CARNET D'ADRESSES INTELLIGENT
══════════════════════════════════

Chaque arrêt validé est mémorisé. La prochaine fois que tu tapes le nom
du client, l'adresse remonte en un clic, avec le compteur de livraisons
déjà effectuées et la date du dernier passage. Notes pré-définies par
client (code interphone, instructions) reproposées automatiquement.

Filtre par couleur / favoris. Export CSV ou vCard pour sauvegarde ou
import dans les Contacts Android.

══════════════════════════════════
STATISTIQUES
══════════════════════════════════

7 jours / 30 jours / 12 mois : nombre de tournées, arrêts, distance
parcourue, durée, **coût carburant estimé**. Plus :
• Colis par jour de la semaine (barchart)
• Top 5 de tes clients les plus livrés
• Stats par client (depuis le carnet)

══════════════════════════════════
TES DONNÉES RESTENT CHEZ TOI
══════════════════════════════════

• Base SQLite sur ton téléphone, jamais sur un serveur opti_route
• Pas de compte à créer, pas de mot de passe à retenir
• OCR traité localement par ML Kit (Google), hors ligne
• Géocodage via les APIs publiques officielles (BAN — Base Adresse
  Nationale, SIRENE — INSEE, Photon — OpenStreetMap)
• Aucun analytics, aucune pub, aucune télémétrie

Désinstalle l'application = toutes les données effacées avec.

══════════════════════════════════
QUOI D'AUTRE
══════════════════════════════════

• Mode sombre pour la conduite de nuit
• Tournées récurrentes (templates dupliquables)
• Multi-tournées par jour
• Export PDF d'une tournée
• Onboarding au premier lancement

══════════════════════════════════

opti_route est développé par et pour les livreurs indépendants. Si tu as
une idée, un bug, un format de bordereau qu'on ne reconnaît pas : écris à
noah.trillon28@gmail.com — chaque message est lu.
```

(≈ 2900 caractères, marge confortable pour ajouts)

---

## Mots-clés (5 max recommandés, FR)

Play Store ne demande pas un champ mots-clés explicite (à la différence de l'App Store), mais ces termes doivent apparaître naturellement dans la description :

1. tournée livraison
2. optimisation itinéraire
3. chauffeur livreur
4. scan bordereau OCR
5. carnet adresses livraison

---

## Captures d'écran — recommandations (8 captures, 16:9 ou 9:16)

Résolution Play Console : entre 320 px et 3 840 px par côté. Ratio recommandé : **9:16 portrait** (téléphone tenu en main).

Ordre suggéré (ordre = importance pour le scroll horizontal) :

1. **Home avec tournée du jour** — montre la value prop principale
2. **Tournée optimisée sur la carte** — polyline + pins numérotés
3. **Bottom sheet d'arrêt** — boutons Maps/Waze + stepper colis + Livré/Échec
4. **Scan bordereau** — carte verte "Détection automatique" avec les champs extraits
5. **Carnet d'adresses** — preuve que les clients sont mémorisés
6. **Statistiques** — chiffres concrets (km, durée, nb tournées)
7. **Paramètres** — section "Apparence" qui montre le mode sombre
8. **Onboarding 1ère page** — promesse "100% gratuit, hors ligne"

Méthode pour capturer (déjà rodée) :
```powershell
"C:\Users\Noah\AppData\Local\Android\sdk\platform-tools\adb.exe" exec-out screencap -p > "d:/opti_route/docs/play_store/screenshots/01_home.png"
```

Faire les captures en mode **clair** d'abord (rendu par défaut Play Store), puis garder une ou deux versions sombres pour la 7e capture.

---

## Icône et bannière

- **Icône app** : 512×512 px, PNG transparent ou opaque, déjà en place dans `app/android/app/src/main/res/mipmap-*/` (PR `e4bd154`).
- **Bannière "feature graphic"** : 1024×500 px, JPG ou PNG sans alpha. **À créer** — proposer une scène cream/lime avec le logo opti_route au centre et le tagline "Optimise tes tournées".

---

## Étapes Play Console

1. Créer compte développeur sur play.google.com/console (25 USD, CB requise — bloque Noah).
2. Créer un nouveau projet "opti_route" (package `com.optiroute.opti_route`).
3. Coller cette fiche dans l'onglet "Présence sur le Play Store".
4. Uploader 8 captures + icône + bannière + AAB signé (cf. `docs/keystore-release.md`).
5. Remplir le questionnaire de notation (PEGI / contenu pour tous).
6. Lien vers la politique de confidentialité : héberger `docs/legal/privacy-policy.md` sur GitHub Pages (URL à coller).
7. Soumettre à examen — délai 24-72h en général pour un 1er audit Google.
