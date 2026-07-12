# Audit RLS Supabase — opti_route (carte #152)

**Date** : 2026-05-28
**Source auditée** : [`docs/supabase-schema.sql`](supabase-schema.sql) (schéma + policies appliqués au projet `wipxgcnpiaecpcipqnpl`)
**Objet** : garantir l'isolation des données entre utilisateurs / équipes en Phase 2 (cloud Supabase), avant toute publication grand public.

> Ce document est l'audit demandé par la carte Trello #152. Il ne modifie
> pas le schéma : il **confirme** l'état des policies, répond aux risques
> listés, pointe les angles morts et fournit des tests SQL « deny » à
> exécuter manuellement dans le SQL Editor Supabase avec deux comptes.

---

## 1. Verdict en une ligne

✅ **L'isolation est correcte.** Chaque ligne porte un `user_id` ; le RLS est activé sur **toutes** les tables `public` exposées, plus `storage.objects`. Aucune policy `USING (true)` non justifiée. Le partage d'équipe (jalon 3.A) est borné par la table `tournee_membres` via des fonctions `SECURITY DEFINER` qui évitent la récursion 42P17. Trois angles morts mineurs (non bloquants) sont listés en §5.

---

## 2. Matrice policies (table × opération × qui)

`auth.uid()` = l'utilisateur connecté. `membre` = présent dans `tournee_membres` pour la tournée. `owner` = `role = 'owner'`.

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `coequipiers` | `user_id = auth.uid()` | idem | idem | idem |
| `tournees` | membre de la tournée | `user_id = auth.uid()` | membre | **owner only** |
| `stops` | membre (via `tournee_id`) | `user_id = auth.uid()` ET membre | membre | **owner only** |
| `saved_destinations` (carnet) | `user_id = auth.uid()` | idem | idem | idem |
| `tournee_membres` | ses propres adhésions | ❌ (trigger / RPC) | ❌ (aucune policy) | quitter soi-même OU owner éjecte un member |
| `tournee_invitations` | owner créateur | idem | idem | idem |
| `storage.objects` (bucket `preuves`) | dossier `<auth.uid()>/` | idem | idem | idem |

Garde-fous serveur complémentaires (au-delà du RLS) :
- **Trigger anti-vol `user_id`** sur `tournees` et `stops` : tout UPDATE qui changerait `user_id` lève `USER_ID_IMMUTABLE`. Empêche un member de « voler » la tournée du chef en re-poussant avec son propre `user_id`.
- **`WITH CHECK` = `USING`** sur toutes les policies `FOR ALL` : impossible de réassigner une de ses lignes à un autre user.
- **`accept_invitation(code)`** et **`list_tournee_members(tournee_id)`** : `SECURITY DEFINER` avec contrôle d'autorisation interne (`AUTH_REQUIRED`, `NOT_A_MEMBER`, code expiré/utilisé).

---

## 3. Réponses aux risques de la carte

> **« Un coéquipier Y peut-il voir les tournées d'une autre équipe Z ? »**
Non. `SELECT` sur `tournees`/`stops` passe par `user_is_member_of(id)`, qui interroge `tournee_membres`. Y n'est membre que des tournées où on l'a explicitement ajouté (trigger owner ou `accept_invitation`). Une tournée d'une équipe Z où Y n'est pas membre est invisible.

> **« Un livreur révoqué peut-il encore SELECT sur les anciennes tournées ? »**
Non. La révocation = `DELETE` de sa ligne dans `tournee_membres` (policy `leave_or_kick_tournee_membres`, autorisée à l'owner pour un `member`). Dès la ligne supprimée, `user_is_member_of` renvoie `false` → plus aucun accès, immédiatement (le RLS est évalué à chaque requête, pas de cache).

> **« Les UPDATE/DELETE sont-ils bornés au owner ou seulement à tournee_membres ? »**
Différenciés volontairement :
- **UPDATE** = tout **membre** (un coéquipier doit pouvoir marquer un stop livré, ajouter une note, etc.).
- **DELETE** = **owner uniquement** (sur `tournees` ET `stops`). Un member ne peut pas détruire la tournée ou les arrêts du chef (perte de données catastrophique).

> **« Le bucket preuves a-t-il des policies lecture par chemin user_id/<uuid> ? »**
Oui. Les 4 policies (`select/insert/update/delete`) sur `storage.objects` exigent `bucket_id = 'preuves' AND auth.uid()::text = (storage.foldername(name))[1]`. Chaque user n'accède qu'à son sous-dossier `<uid>/`. Le bucket est `public = false`.

---

## 4. Analyse par table

- **`coequipiers`** — privé au propriétaire (`FOR ALL` `user_id = auth.uid()`). Volontaire : les coéquipiers sont une notion locale au chef, pas partagée. (Voir angle mort §5.3.)
- **`tournees` / `stops`** — policies *splittées* par opération + helpers `SECURITY DEFINER` (`user_is_member_of`, `user_is_owner_of`) pour éviter la récursion infinie PG (42P17) qui surviendrait si une policy lisait directement `tournee_membres`. Conception correcte et idiomatique.
- **`saved_destinations`** (carnet) — `FOR ALL` `user_id = auth.uid()`. Le carnet n'est **pas** partagé en équipe aujourd'hui ; #57 (auto-push) reste *scopé au propriétaire* (sync entre les devices du même user, pas entre users). Donc pas d'élargissement de surface RLS tant que #57 ne devient pas un *carnet d'équipe*.
- **`tournee_membres`** — pas de policy INSERT/UPDATE (mutations réservées au trigger owner + RPC `accept_invitation`, tous deux `SECURITY DEFINER`). SELECT limité à ses propres adhésions ; l'énumération des membres passe par la RPC `list_tournee_members` (avec check `NOT_A_MEMBER`).
- **`tournee_invitations`** — owner créateur uniquement ; le code est consommé via `accept_invitation` (qui bypass la RLS en `SECURITY DEFINER` mais valide expiration + usage unique).
- **`storage.objects` / `preuves`** — isolation par dossier `user_id`. Correct.

---

## 5. Angles morts / recommandations (non bloquants)

1. **Photo preuve d'un coéquipier invisible au chef** *(fonctionnel, pas une faille)*.
   Quand un *member* livre et uploade une photo, le fichier va dans `<member_uid>/...`. Le chef (owner) ne peut **pas** la lire (policy par dossier). Conséquence : sur une tournée partagée, la preuve prise par un coéquipier n'est pas visible côté chef via Storage.
   *Reco* : si on veut que le chef voie les preuves d'équipe, prévoir un chemin `<owner_uid>/<stop_uuid>.jpg` (le member uploade dans le dossier de l'owner — nécessite une policy d'écriture élargie « membre de la tournée du stop » au lieu de « mon propre dossier ») OU une URL signée générée serveur. À traiter avec #57/#71.

2. **`coequipier_id` non résolvable côté member** *(fonctionnel)*.
   Un `stop.coequipier_id` pointe vers un `coequipiers` du chef ; un member ne peut pas SELECT cette table (RLS owner-only) → il ne peut pas résoudre le nom du coéquipier depuis le cloud (l'app retombe sur le cache local si présent). Acceptable aujourd'hui ; à revoir si l'affectation devient un vrai workflow d'équipe.

3. **`tracking_codes` (lien 20 chars, #81/#141) hors périmètre de cet audit.**
   La table vit dans [`supabase/functions/track/schema.sql`](../supabase/functions/track/schema.sql) et est **publique par conception** (le destinataire final, non authentifié, doit lire le statut). À auditer séparément quand la fonction `track` sera déployée : vérifier qu'elle n'expose que le strict nécessaire (statut + ETA, pas l'adresse complète ni le téléphone), idéalement via une **vue** restreinte plutôt qu'un SELECT direct sur `stops`.

4. **Suggestion durcissement** : ajouter `SET search_path = public` est déjà fait sur les fonctions `SECURITY DEFINER` ✅. Penser à le garder sur toute future fonction `SECURITY DEFINER` (sinon risque d'injection via `search_path`).

---

## 6. Tests SQL « deny » (à exécuter manuellement)

Ces tests valident que le RLS bloque bien l'accès croisé. À lancer dans
**Supabase Dashboard > SQL Editor**. On simule un user en posant son JWT
claim via `request.jwt.claims` (ce que fait le pooler en prod) avec
`set local role authenticated` + `set local request.jwt.claims`.

Pré-requis : deux `auth.users` réels (user A et user B) et au moins une
tournée appartenant à A. Remplacer `<UID_A>` / `<UID_B>` / `<TOURNEE_DE_A>`.

```sql
-- TEST 1 — B ne voit PAS les tournées de A
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"<UID_B>","role":"authenticated"}';
  -- Attendu : 0 ligne (B n'est pas membre des tournées de A)
  select count(*) as visibles_par_b
    from public.tournees
    where user_id = '<UID_A>';
rollback;

-- TEST 2 — B ne peut PAS UPDATE un stop de A
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"<UID_B>","role":"authenticated"}';
  -- Attendu : UPDATE 0 (aucune ligne visible/modifiable)
  update public.stops set notes = 'pirate'
    where tournee_id = '<TOURNEE_DE_A>';
rollback;

-- TEST 3 — B ne peut PAS s'auto-ajouter comme membre d'une tournée de A
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"<UID_B>","role":"authenticated"}';
  -- Attendu : ERREUR (aucune policy INSERT sur tournee_membres)
  insert into public.tournee_membres (tournee_id, user_id, role)
    values ('<TOURNEE_DE_A>', '<UID_B>', 'member');
rollback;

-- TEST 4 — un member ne peut pas voler la tournée en changeant user_id
-- (à exécuter après avoir ajouté B comme member via accept_invitation)
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"<UID_B>","role":"authenticated"}';
  -- Attendu : ERREUR USER_ID_IMMUTABLE (trigger tournees_protect_user_id)
  update public.tournees set user_id = '<UID_B>'
    where id = '<TOURNEE_DE_A>';
rollback;

-- TEST 5 — un member ne peut pas DELETE la tournée du chef
begin;
  set local role authenticated;
  set local request.jwt.claims = '{"sub":"<UID_B>","role":"authenticated"}';
  -- Attendu : DELETE 0 (DELETE réservé à l'owner)
  delete from public.tournees where id = '<TOURNEE_DE_A>';
rollback;
```

### Requêtes d'inventaire (vérif rapide de l'état)

```sql
-- Toutes les tables public + storage doivent avoir rowsecurity = true
select schemaname, tablename, rowsecurity
  from pg_tables
  where schemaname in ('public','storage')
  order by rowsecurity, tablename;

-- Liste des policies (chercher d'éventuels USING(true) non justifiés)
select schemaname, tablename, policyname, cmd, qual
  from pg_policies
  where schemaname in ('public','storage')
  order by schemaname, tablename, cmd;
```

À l'issue de l'exécution, le résultat attendu : tous les `rowsecurity =
true`, et aucun `qual` à `true` sauf justification documentée (aucune au
2026-05-28).

---

## 7. Conclusion

Le modèle RLS d'opti_route est **sain pour une mise en production Phase 2** :
isolation par `user_id`, partage d'équipe borné par `tournee_membres`,
DELETE réservé à l'owner, Storage cloisonné par dossier, triggers anti-vol
`user_id`. Les trois angles morts (§5.1–5.3) sont **fonctionnels** (pas des
failles) et à traiter avec les cartes #57 (carnet équipe) / #71 (visualiser
preuve) / #81 (tracking public). À ré-auditer quand : (a) le carnet devient
partagé, (b) la fonction `track` est déployée, (c) toute nouvelle table
cloud est ajoutée.

---

## 8. Multi-tenant entreprise / entrepôt (addendum — épopées #361 / #381)

**Ajout postérieur à l'audit initial** (migrations
[`supabase/migrations/20260531000000_multi_tenant.sql`](../supabase/migrations/20260531000000_multi_tenant.sql)
et
[`supabase/migrations/20260604000000_plans_381a.sql`](../supabase/migrations/20260604000000_plans_381a.sql)).
Les §1–7 ci-dessus ne couvrent QUE les tables perso (tournées, carnet,
Storage). Cette section documente l'isolation RLS des tables du modèle
multi-tenant, comme appelé par le §7 (c).

### 8.1 Principe d'isolation

Un utilisateur ne voit et ne modifie **que les entreprises et entrepôts
dont il est membre *actif***. L'appartenance est portée par deux tables de
liaison, systématiquement filtrées sur `statut = 'actif'` :

- `entreprise_users` — rôle global : `admin_entreprise` | `membre`
- `entrepot_users` — rôle site (M:N user × entrepôt) : `chef_entrepot` | `employe`

Toutes les policies passent par des helpers `SECURITY DEFINER`
(`current_user_entreprise_ids()`, `current_user_entrepot_ids()`,
`is_admin_entreprise()`, `is_chef_entrepot()`, `is_chef_of_entreprise()`,
`is_super_admin()`). C'est **obligatoire** : une policy sur `entrepots` (ou
`entreprise_users`) qui lirait directement sa propre table déclenche la
récursion Postgres `42P17` (« infinite recursion detected in policy »). Le
helper `definer` s'exécute hors RLS et casse la boucle. Chaque fonction
porte `set search_path = public` (durcissement anti-détournement).

Une révocation = `statut = 'revoque'` + `revoked_at` (RPC `revoke_employe`).
Les helpers ne comptant que les lignes `'actif'`, l'accès tombe
**immédiatement** à la requête suivante (le RLS est évalué à chaque requête,
pas de cache).

### 8.2 Matrice policies

`admin` = `is_admin_entreprise(entreprise)`. `chef` = `is_chef_entrepot(entrepot)`.
`membre actif` = présent + `statut='actif'` dans la table de liaison.

| Table | SELECT | INSERT | UPDATE | DELETE |
|---|---|---|---|---|
| `entreprises` | membre actif OU `created_by` | ❌ `with check (false)` → RPC `create_entreprise` (code maître) | admin | admin |
| `entrepots` | membre entrepôt OU admin entreprise | admin OU chef d'un entrepôt de l'entreprise (via RPC `create_entrepot`) | admin OU chef de l'entrepôt | admin |
| `entreprise_users` | soi-même OU membre de l'entreprise | admin | admin | admin |
| `entrepot_users` | soi-même OU membre entrepôt OU admin entreprise | chef entrepôt OU admin entreprise | idem | idem |
| `entreprise_invitations` | `invited_by` OU membre de l'entreprise | `invited_by` ET (admin → tout rôle) OU (chef entrepôt → `chef_entrepot`/`employe` seulement) | ❌ (aucune) → RPC `accept_entreprise_invitation` | `invited_by` OU admin |
| `plans` | ✅ tous (`authenticated`, `using(true)`) | super admin | super admin | super admin |
| `app_config`, `app_admins` | ❌ RLS activé **sans policy** (accès uniquement via RPC `definer`) | ❌ | ❌ | ❌ |

### 8.3 Garde-fous serveur (au-delà du RLS)

- **Bootstrap œuf/poule** : le créateur d'une entreprise ne peut pas
  s'auto-insérer dans `entreprise_users` (la policy `ins_eu` exige déjà
  `admin`). Le trigger `handle_new_entreprise` (`SECURITY DEFINER`) l'inscrit
  `admin_entreprise` juste après l'INSERT.
- **Invitations par email (nominatives)** : `email` non null → l'invitation
  ne peut être acceptée QUE par le compte portant cet email (`EMAIL_MISMATCH`
  dans `accept_entreprise_invitation`). Sans ce garde, un code à 6 chiffres
  deviné laisserait rejoindre l'équipe — voire devenir admin. Les invitations
  **par code** (email null, lien partageable) ne sont volontairement pas
  concernées.
- **Anti-escalade de privilège** : un chef d'entrepôt ne peut inviter QUE
  `chef_entrepot`/`employe`, jamais `admin_entreprise` (policy `ins_inv`).
- **Création d'entreprise bridée** : l'INSERT direct est fermé
  (`with check (false)`) ; seule la RPC `create_entreprise` crée, en exigeant
  le **code maître** vérifié serveur (jamais exposé à l'app). Le super admin
  (`app_admins`) en est dispensé.
- **Révocation d'admin refusée** : `revoke_employe` lève `CANNOT_REVOKE_ADMIN`
  (évite l'échec silencieux 0-ligne où l'app croyait avoir révoqué).
- **`plans` en lecture seule** : catalogue lisible par tous les authentifiés
  (`using(true)` justifié : besoin d'afficher les paliers) ; écriture réservée
  au super admin. Aucune limite appliquée à ce stade (grandfathering
  `plan = 'illimite'` sur les comptes existants).

### 8.4 À ré-auditer

- Tests « deny » des accès croisés **entreprise A / entreprise B** (même
  méthode qu'au §6, avec deux comptes membres d'entreprises distinctes).
- Carnet partagé : la policy permissive `sd_select_extended_multi_tenant`
  **ajoute** la visibilité entreprise/entrepôt aux policies perso de
  `saved_destinations` — vérifier qu'aucune policy perso ne fait `using(true)`
  qui annulerait le cloisonnement.
