# Nuit autonome 01→02/06/2026 — sécurité, robustesse & écrans

Branche : `fix/securite-nuit-0602` (23 commits, 41 fichiers, +2631 / −96).
État : `flutter analyze` clean, **2251 tests verts** (2206 au départ).
**Pas mergée sur `main`** — en attente de revue + GO de Noah.

Ce document résume ce que contient la branche et **ce qu'il faut redéployer**
après merge. Détails additionnels sur Trello (cartes #408, #409 + récaps nuit).

---

## ⚠️ Checklist de redéploiement (À FAIRE après merge)

Le code Flutter ne suffit pas : deux fixes vivent côté serveur.

1. **SQL** — rejouer `docs/supabase-schema-multi-tenant.sql` (rejouable d'un
   bloc). Changement clé : `accept_entreprise_invitation` exige désormais que
   l'email d'une invitation **nominative** corresponde au compte connecté
   (`EMAIL_MISMATCH`). Les invitations **par code partageable** (email null)
   restent ouvertes.
2. **Edge Functions** — redéployer :
   - `npx supabase functions deploy invite_employee` (code CSPRNG au lieu de
     `Math.random()`).
   - `npx supabase functions deploy cron_lockout_revoked` (comparaison du
     `CRON_SECRET` à temps constant).
   - `npx supabase functions deploy ocr-enhance` (clé Gemini en en-tête, plus
     en query string).
3. **Vérif post-déploiement** : une invitation Brevo ne s'accepte plus qu'avec
   l'email destinataire (sinon message « Connecte-toi avec l'adresse qui a
   reçu l'invitation »). Le flux « rejoindre par code » est inchangé.

> ℹ️ La feature **tracking** n'est pas déployée → la reco sécu #409 (code 4
> chars énumérable) est à traiter **avant** sa mise en prod, pas urgent.

---

## Sécurité (durcissements)

- **Escalade / RLS** (lot 1) : `ins_inv` (chef ne peut inviter qu'en
  chef_entrepot/employe), `revoke_employe` refuse explicitement un admin
  (`CANNOT_REVOKE_ADMIN`, plus d'échec silencieux).
- **Flux d'invitation** : code CSPRNG côté Edge Function + vérification email
  anti-détournement côté RPC (cf checklist). → carte #408.
- **Edge Functions** : `CRON_SECRET` comparé à temps constant (anti timing
  attack), clé Gemini en en-tête `x-goog-api-key`.
- **Fuite d'infos (information disclosure)** : `scrubSecrets` masque
  JWT / `Bearer` / `apikey=…` dans tout message d'erreur affiché (SnackBar,
  Diagnostic) ; les 2 derniers SnackBar affichant `$e` brut passent par le
  humanizer ; fallback des erreurs d'invitation scrubbé.
- **PII** : `maskEmailForDisplay` (masquage email) extrait en fonction pure +
  verrouillé par tests anti-fuite.
- **Audits menés, RAS** : aucun secret commité (ni dans l'historique) ;
  fonctions SQL `SECURITY DEFINER` vérifient toutes les permissions (pas
  d'auto-escalade, pas de fuite cross-tenant).

## Robustesse (parsing d'API externes)

Même classe de bug corrigée partout : décodage **UTF-8** explicite
(`utf8.decode(bodyBytes)`, fin du mojibake des accents) + **casts défensifs**
(`is` au lieu de `as`, conversions num/String tolérantes) pour qu'une donnée
malformée d'une station/coord/POI ne fasse plus planter tout le résultat.

- Géocodeurs BAN / Photon / Recherche-Entreprises (+ bornes lat/lon).
- `GeoUtils.isValidLatLon` (rejette 999 / NaN / Infinity) appliqué aux
  géocodeurs **et** au parser vCard (`GEO:`).
- `fuel_price_service`, `overpass_poi`, `route_service` (ORS, + UTF-8 sur les
  instructions turn-by-turn).
- Vérifiés sains (numériques / réponse validée) : `weather`, `osrm`,
  `openroute_optimization`.

## Écrans ajoutés (lecture seule, additifs)

- **Nos offres** : comparatif des 4 plans (vitrine « Passer premium »), prix en
  placeholder, aucune logique de paiement. Entrée dans le drawer.
- **Diagnostic** : récap technique factuel pour le support (version, état
  cloud, rôle), email masqué, bouton copier. Entrée dans Paramètres → Aide.
- **Questions fréquentes (FAQ)** : 10 Q/R dépliables sur le fonctionnement réel
  de l'app. Entrée dans Paramètres → Aide.
- **Drawer** réorganisé en sections + scroll-safe.

## Tests

+~45 tests sur la nuit (2206 → 2251), notamment : entrées hostiles sur les
géocodeurs, codes d'invitation (CSPRNG/format/dispersion), scrub de secrets,
masquage PII anti-fuite, robustesse fuel/overpass/route, bornes vCard, smoke
des nouveaux écrans.

---

## En attente de décision de Noah (NON fait volontairement)

- Refonte UI globale (#401) — design à cadrer.
- Plans / forfaits #381 (sous-cartes #388-392) — le bridage pourrait bloquer
  les comptes de test, attend un GO.
- Reco sécu tracking #409 (allonger le code) — choix produit.
- Cartes « feature agent » #399-406 (idées générées) — à valider/refuser.
