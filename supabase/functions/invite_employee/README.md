# Edge Function `invite_employee`

Invite un employé ou un chef d'entrepôt à rejoindre une entreprise / un
entrepôt. Fait partie de l'épopée multi-tenant (#361, cartes #363 + #60).

> **Refonte « Option B » (2026-06-01)** — On n'envoie **plus** de magic
> link Supabase (qui imposait la version web connectée au cloud). À la
> place, la fonction **génère un code à 6 chiffres** et l'envoie par email
> via **Brevo** (API transactionnelle). L'employé saisit ce code dans
> l'app. Marche sur toutes les plateformes (mobile / PC) sans dépendre du
> web.

## Flux réel

1. Le **chef d'entrepôt ou l'admin** (connecté, `verify_jwt = true`)
   appelle la fonction avec son JWT.
2. La fonction vérifie le token puis les **permissions** du caller dans
   l'entreprise / l'entrepôt cible :
   - inviter un `chef_entrepot` → réservé à `admin_entreprise` ;
   - inviter un `employe` → `admin_entreprise` **ou** `chef_entrepot` de
     l'entrepôt visé.
3. Elle génère un **code à 6 chiffres** (CSPRNG `crypto.getRandomValues`,
   rejection sampling anti-biais) et **insère l'invitation** dans
   `entreprise_invitations` (statut `pending`, `expires_at = now + 7 jours`).
4. Elle envoie un **email via Brevo** (API transactionnelle) contenant le
   code et la marche à suivre.
5. L'employé ouvre l'app, se **connecte par OTP** avec cette adresse
   email, va dans **« Rejoindre une équipe »** et saisit le code →
   RPC `accept_entreprise_invitation(code)`.

## Requête

```
POST /functions/v1/invite_employee
Authorization: Bearer <JWT du chef/admin>
Content-Type: application/json
```

### Body attendu

```json
{
  "email": "marc@example.com",
  "entreprise_id": "<uuid>",
  "entrepot_id": "<uuid|null>",
  "role": "employe"
}
```

| Champ | Type | Détail |
|---|---|---|
| `email` | `string` | Email de l'invité (normalisé en minuscules). |
| `entreprise_id` | `string` (UUID) | Entreprise cible. |
| `entrepot_id` | `string` (UUID) \| `null` | Entrepôt cible, ou `null` pour une invitation au niveau entreprise. |
| `role` | `'chef_entrepot'` \| `'employe'` | Rôle attribué à l'invité. |

### Réponse (`201`)

```json
{
  "invitation_id": "<uuid>",
  "email": "marc@example.com",
  "code": "048213",
  "expires_at": "2026-07-19T10:00:00.000Z",
  "email_sent": true,
  "email_error": null
}
```

| Champ | Détail |
|---|---|
| `invitation_id` | `cloud_id` de la ligne `entreprise_invitations`. |
| `email` | Email invité (normalisé). |
| `code` | Code à 6 chiffres à communiquer à l'invité. |
| `expires_at` | Expiration de l'invitation (J+7). |
| `email_sent` | `true` si Brevo a accepté l'envoi, sinon `false`. |
| `email_error` | Message d'erreur si l'envoi a échoué, sinon `null`. |

> **Note — l'envoi du mail peut échouer sans bloquer.** Le `code` est
> **toujours** renvoyé dans la réponse, même si `email_sent = false` (clé
> Brevo manquante, expéditeur non vérifié, spam, quota, etc.). Dans ce cas
> le chef / admin peut **communiquer le code manuellement** à l'employé.

### Codes d'erreur

| Statut | Cas |
|---|---|
| `400` | JSON invalide ou body non conforme (email, UUID, role). |
| `401` | Header `Authorization` manquant ou JWT invalide. |
| `403` | Le caller n'a pas les permissions pour ce rôle / cet entrepôt. |
| `405` | Méthode autre que `POST`. |
| `500` | Échec de l'insertion de l'invitation. |

## Secrets requis

À configurer dans **Dashboard → Edge Functions → Secrets** :

| Secret | Fourni par | Détail |
|---|---|---|
| `SUPABASE_URL` | Supabase (auto) | URL du projet. |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase (auto) | Clé service role (bypass RLS côté serveur, jamais exposée au client). |
| `BREVO_API_KEY` | Toi | Clé API v3 Brevo (Brevo → Settings → SMTP & API → API Keys). |
| `BREVO_SENDER_EMAIL` | Toi | Adresse **expéditeur vérifiée** dans Brevo. |
| `BREVO_SENDER_NAME` | Toi (optionnel) | Nom d'expéditeur affiché (défaut : `opti_route`). |

Si `BREVO_API_KEY` **ou** `BREVO_SENDER_EMAIL` est absent, l'invitation est
quand même créée et le code renvoyé, mais `email_sent = false`.

## Déploiement

`verify_jwt = true` (auth obligatoire) : ne pas utiliser `--no-verify-jwt`.

```bash
npx supabase functions deploy invite_employee
```

## Test manuel

```bash
TOKEN="<JWT d'un admin_entreprise ou chef_entrepot>"
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "marc@example.com",
    "entreprise_id": "<uuid>",
    "entrepot_id": "<uuid|null>",
    "role": "employe"
  }' \
  https://<project-ref>.supabase.co/functions/v1/invite_employee
```

Attendu : `201` avec le `code` à transmettre à l'invité.

## Fichiers

- `index.ts` — handler HTTP : auth, permissions, insertion, envoi Brevo.
- `lib.ts` — unités pures testables (`validateBody`, `genCode`,
  `roleLabel`, `escapeHtml`, `buildEmailHtml`).
- Tests : `supabase/functions/_tests/invite_employee_test.ts`.
