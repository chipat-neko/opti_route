# Guide utilisateur opti_route

*Version au 11/05/2026 — pour Noah (et futurs livreurs indépendants).*

## Premier lancement

Au premier ouverture, opti_route te demande :
1. Une **clé API OpenRouteService** (gratuite, 500 optimisations/jour,
   sans CB). Crée-la sur `openrouteservice.org/dev/#/signup`.
2. La permission **Notifications** (Android 13+) pour les rappels de
   tournée.
3. La permission **Localisation** (à la première tournée démarrée).

Tu peux skipper l'onboarding et configurer plus tard depuis
**Paramètres**.

---

## Créer une tournée

1. Sur l'écran d'accueil : tape **+ Créer ma tournée**.
2. Remplis :
   - **Nom** (ex: "Tournée mardi matin")
   - **Date**
   - **Adresse de départ** (autocomplete BAN — tape la rue, sélectionne)
   - **Capacité véhicule** : nombre maximum de colis (0 = illimité)
   - **Profil véhicule** : Voiture/VUL (défaut) ou Camion >3.5t
   - **Éviter péages** : toggle
   - **Rappel** (optionnel) : programme une notif locale

3. Tape **Créer la tournée**. Tu arrives sur l'écran "Tournée du jour".

---

## Ajouter des arrêts

Plusieurs façons :

### Saisie classique
- Tape le **+** flottant → ouvre l'écran d'ajout
- Tape l'adresse dans l'autocomplete (BAN, SIRENE pour les entreprises,
  Photon pour les enseignes)
- Sélectionne une suggestion
- Renseigne nb colis, fenêtre horaire (optionnel), priorité, notes
- **Enregistrer** ou **+ Ajouter un autre** pour enchaîner

### Scanner un bordereau (OCR)
- Bouton **Scanner** dans l'écran d'ajout
- Photographie le bordereau (caméra ou galerie)
- ML Kit lit le texte localement (aucun envoi internet)
- Une carte verte "Détection automatique" propose les infos extraites
  (rue, ville, CP, nb colis, nom client). Tape **Utiliser ces infos**

### Saisie hors-ligne (zone sans 4G)
- Bouton **Hors ligne** dans l'écran d'ajout
- Saisie texte pure, sans géocodage
- L'arrêt apparaît avec un badge **GPS manquant**
- De retour en zone couverte, tape **Géolocaliser hors-ligne** dans
  le menu Plus de la tournée → re-tente le géocodage en batch

---

## Optimiser la tournée

1. Tape **Optimiser** (bouton actif quand tu as au moins 2 arrêts
   géolocalisés et qu'aucune optim n'est à jour)
2. VROOM via ORS calcule le meilleur ordre (~500 ms)
3. La distance + durée + cout carburant estimé s'affichent
4. La carte trace le polyline

### Priorités
- **En 1er** : forcer un arrêt au début (utile : dépot point relais)
- **En dernier** : forcer un arrêt à la fin
- **À éviter** : VROOM le saute si l'overflow le force
- **Flexible** (défaut) : VROOM choisit

Tape sur l'icône priorité d'un arrêt pour changer + reordonner les
"En 1er" / "En dernier" entre eux (dialog dédié).

---

## Mode tournée en cours

1. Tape **Démarrer** (FAB lime). Permission GPS demandée.
2. La carte **Prochain arrêt** apparaît : nom + adresse + distance GPS
   live + boutons Maps/Waze + bouton **Livré** gros vert.
3. Tape une row d'arrêt pour ouvrir la **bottom sheet** :
   - Stepper +/- colis
   - Édition notes (auto-save debounce 600ms)
   - Édition fenêtre horaire (tap = TimePicker)
   - Maps / Waze
   - **Marquer livré** (vert) ou **Marquer échec** (rouge, demande
     raison)
4. Pour annuler le dernier statut posé par erreur : menu Plus →
   **Annuler dernier statut**

### Tout marquer livré
Menu Plus → **Tout marquer livré**. Pratique pour un dépôt
d'entreprise où on livre 10 colis en une fois.

---

## Partage et export

### Texte court (WhatsApp, SMS, mail)
Menu Plus → **Partager en texte**. Format :
```
Tournée "Mardi matin"
mardi 12 mai 2026
8 arrêts - 23 colis - 45.0 km / 1h30 - ~6,48 EUR

1. CALOTE Noah
   12 rue des Lilas, 28100 Dreux
   3 colis - avant 12:00
2. ...
```

### PDF récap
Menu Plus → **Exporter en PDF**. Génère un PDF avec carte + arrêts.

### Refaire la semaine prochaine
Menu Plus → **Refaire dans 7 jours**. Duplique avec +7 jours, reset
les statuts. SnackBar avec **Ouvrir** pour basculer dessus.

---

## Carnet d'adresses

Auto-rempli à chaque arrêt validé. Tu peux :
- Rechercher (insensible aux accents)
- Filtrer par couleur ou favoris (chips en haut)
- Marquer un client **favori** (étoile)
- Choisir une **couleur custom** (lime/emerald/amber/red/cream/ink)
- Ajouter des **notes pré-définies** (code interphone, instructions).
  Pré-remplies à la prochaine création d'arrêt pour ce client.
- **Exporter** en CSV (tableur) ou vCard (import Contacts Android)
- **Importer** un CSV (Drive, autre téléphone)

---

## Statistiques

Drawer → **Statistiques**. Affiche :
- **3 fenêtres** : 7 jours / 30 jours / 1 an. Chacune : nb tournées,
  arrêts, colis livrés, distance, durée, taux de réussite, **coût
  carburant estimé**.
- **Colis par jour de la semaine** (30 derniers jours) : barchart
- **Top 5 clients** (par nombre de livraisons)
- **Pull-to-refresh** pour relancer les calculs

---

## Paramètres

- **Clé API ORS** : pour réactiver l'optimisation
- **Valeurs par défaut** : capacité, durée d'arrêt, app de nav par
  défaut (Maps/Waze)
- **Carburant** : prix EUR/L + consommation L/100km (calcul du coût
  estimé)
- **Cache** : voir taille, purger tuiles cartes, purger géocodage,
  nettoyer tournées > 1 an
- **Notifications** : test, annuler tous les rappels
- **Apparence** : Auto / Clair / **Sombre** (conduite de nuit)
- **Mentions légales** : Privacy + CGU embarqués

---

## Aucune donnée ne quitte ton téléphone

- Base SQLite locale (cf. mentions légales)
- OCR sur appareil via Google ML Kit
- APIs publiques uniquement pour la géocodage (BAN, SIRENE, Photon,
  ORS) — elles ne reçoivent que la requête courante, jamais ton
  historique
- Pas de compte, pas de mot de passe, pas d'analytics, pas de pub
