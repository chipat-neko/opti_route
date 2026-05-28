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
