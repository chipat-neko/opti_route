# Edge Functions multi-tenant (carte #363)

Trois Edge Functions Supabase liées à l'épopée multi-tenant #361 :

1. **`invite_employee`** — Envoie un mail magic link pour inviter un employé
2. **`accept_invitation`** — Appelée par l'app au boot quand l'utilisateur revient sur le lien magic
3. **`cron_lockout_revoked`** — Job planifié (cron J+1 → 3h UTC) qui expire les `revoked` après 30 jours

## Pré-requis

- Schéma SQL multi-tenant déployé (`docs/supabase-schema-multi-tenant.sql`)
- Supabase CLI installé : `npm i -g supabase`
- Logged in : `supabase login`
- Linked au projet : `supabase link --project-ref <ref>`

## Déploiement

```bash
# Depuis la racine du repo
supabase functions deploy invite_employee
supabase functions deploy accept_invitation
supabase functions deploy cron_lockout_revoked --no-verify-jwt
```

## Variables d'environnement (Supabase Dashboard → Edge Functions → Secrets)

| Variable | Pour | Valeur exemple |
|---|---|---|
| `APP_INVITE_REDIRECT_URL` | invite_employee | `https://chipat-neko.github.io/opti_route/` |
| `CRON_SECRET` | cron_lockout_revoked | Random 32 chars (`openssl rand -hex 32`) |

`SUPABASE_URL` et `SUPABASE_SERVICE_ROLE_KEY` sont fournis automatiquement par Supabase.

## Mail templates (Supabase Dashboard → Authentication → Email Templates → "Invite user")

Customiser :
- **Subject** : `Tu es invité sur opti_route`
- **Body** : 
```html
<h2>Bienvenue sur opti_route !</h2>
<p>Tu as été invité à rejoindre une entreprise/entrepôt.</p>
<p><a href="{{ .ConfirmationURL }}">Accepter l'invitation</a></p>
<p>Ce lien expire dans 7 jours.</p>
```

## Cron Supabase (Dashboard → Database → Cron)

```sql
-- Tous les jours à 03:00 UTC, expire les revoked > 30j
select cron.schedule(
  'cron_lockout_revoked_daily',
  '0 3 * * *',
  $$
    select net.http_post(
      url := 'https://<project-ref>.supabase.co/functions/v1/cron_lockout_revoked',
      headers := jsonb_build_object('X-Cron-Secret', '<your CRON_SECRET>')
    );
  $$
);
```

## Tests manuels

### Test invite_employee

```bash
TOKEN="<JWT d'un admin_entreprise>"
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "marc@example.com",
    "entreprise_id": "<uuid>",
    "entrepot_id": "<uuid>",
    "role": "employe"
  }' \
  https://<project>.supabase.co/functions/v1/invite_employee
```

Attendu : `201 { "invitation_id": "...", "email": "...", "expires_at": "..." }`

### Test accept_invitation

Marc reçoit le mail, clique le lien, atterrit sur l'app qui détecte `?invitation_id=` et appelle :

```bash
TOKEN="<JWT de Marc>"
curl -X POST \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"invitation_id": "<uuid>"}' \
  https://<project>.supabase.co/functions/v1/accept_invitation
```

Attendu : `200 { "entreprise_id": "...", "entrepot_id": "...", "role": "employe" }`

Marc est maintenant dans `entreprise_users` (membre) + `entrepot_users` (employe).

### Test cron_lockout_revoked manuel

```bash
curl -X POST \
  -H "X-Cron-Secret: <secret>" \
  https://<project>.supabase.co/functions/v1/cron_lockout_revoked
```

Attendu : `200 { "entreprise_users_expired": N, ... }`

## Sécurité

- `invite_employee` et `accept_invitation` : JWT obligatoire, check email match
- `cron_lockout_revoked` : protégé par CRON_SECRET partagé
- Toutes les fonctions utilisent SERVICE_ROLE_KEY côté serveur pour bypass RLS — la clé n'est JAMAIS exposée au client
- Validation stricte des inputs (UUID, format email, role enum)
- Les FK et UNIQUE constraints en DB empêchent les insertions doublons

## Limites connues

- Pas de rate limiting (Edge Functions Supabase n'en propose pas natif). Un attaquant pourrait spammer `invite_employee` pour épuiser le quota mail 100/j Supabase. À surveiller post-déploiement.
- Le mail template par défaut Supabase n'est pas brandé. Customisation manuelle dans Dashboard.
- `inviteUserByEmail` peut échouer silencieusement si user existe déjà — l'invitation reste pending et le user devra se reconnecter pour la voir.
