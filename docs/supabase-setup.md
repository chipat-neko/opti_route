# Configuration Supabase — Phase 2 backend

## Jalon 1 (actuel) — Auth seule

L'app embarque le SDK `supabase_flutter` mais il faut fournir 2 variables
au build pour activer le mode cloud. Sans elles, `SupabaseService.isConfigured`
est `false` et toute l'app fonctionne normalement en local-only.

### Créer le projet Supabase

1. https://supabase.com/dashboard → **New Project** (free tier).
2. **Region** : choisir `eu-west-3` (Paris) ou `eu-central-1` (Frankfurt)
   pour rester en zone UE (RGPD).
3. **Database password** : généré + stocké dans un gestionnaire de mots
   de passe perso. Pas dans le repo.
4. Une fois le projet créé, aller dans **Settings → API** et noter :
   - `Project URL` (ex: `https://abcd1234.supabase.co`)
   - `anon public key` (commence par `eyJ...`)

### Configurer l'envoi d'email OTP

1. Dans le dashboard Supabase → **Authentication → Providers → Email**
2. Activer **Enable Email provider**.
3. Activer **Enable email confirmations**.
4. **Email OTP length** : passer de `8` (défaut) à `6` pour matcher
   l'UI de l'app (`maxLength: 6` sur le champ code).
5. **Templates email** (Authentication → Emails) : remplacer les
   deux templates « Confirm sign up » ET « Magic Link » pour exposer
   le code au lieu d'un lien (qui pointe par défaut sur
   `localhost:3000` et casse). Coller dans les deux :
   ```html
   <h2>Ton code de connexion opti_route</h2>
   <p>Tape ce code dans l'app pour te connecter :</p>
   <p style="font-size: 32px; font-weight: bold; letter-spacing: 4px;
             padding: 16px; background: #f5f3ee; text-align: center;
             border-radius: 8px; font-family: monospace;">
     {{ .Token }}
   </p>
   <p style="color: #666; font-size: 12px;">
     Code valide 1 heure. Si tu n'as pas demandé ce mail, ignore-le.
   </p>
   ```
   Note : `Confirm sign up` est utilisé au **1er** sign-in d'un email,
   `Magic Link` est utilisé pour les sign-ins **suivants** (user déjà
   présent dans `auth.users`). Les deux doivent être édités.
6. Free tier : ~30 emails / heure global, ~4 OTP / heure par email.
   En cas de `email rate limit exceeded` pendant les tests : supprimer
   le user dans Authentication → Users (reset par-user) ou attendre
   30-60 min.

### Builder l'app avec les credentials

```sh
flutter build apk --release \
  --dart-define=SUPABASE_URL=https://abcd1234.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsIn...
```

Ou pour le dev :

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://abcd1234.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsIn...
```

Astuce : créer un script `tool/run-cloud.sh` (gitignored) qui injecte
les variables, ou utiliser `--dart-define-from-file=cloud.env.json`.

### Tester le flow

1. Ouvrir l'app, **Paramètres → Compte cloud → Connecter mon compte**.
2. Taper son email, **Envoyer le code**.
3. Vérifier la boîte mail (et les spams) → code à 6 chiffres.
4. Le saisir, **Vérifier** → retour aux Paramètres avec l'email affiché
   et un bouton **Déconnecter**.

### Sécurité

- Le `anon public key` n'est PAS un secret : il est destiné à être
  embarqué dans le client. Les permissions sont contrôlées par les
  Row-Level Security policies côté Supabase (à venir au jalon 2).
- Ne JAMAIS embarquer la `service role key` (admin) dans l'app — elle
  contourne RLS.

## Jalon 2.A — Schema cloud + RLS

Sous-jalon foundation : créer les 4 tables Postgres (`tournees`,
`stops`, `coequipiers`, `saved_destinations`) avec Row Level Security
pour que chaque user ne voie que ses propres données. **Aucun code
Dart** dans ce sous-jalon, juste du SQL côté Supabase.

### Exécuter le schema

1. Dashboard Supabase → **SQL Editor** → **New query**.
2. Coller le contenu de [`docs/supabase-schema.sql`](supabase-schema.sql)
   (~200 lignes, idempotent).
3. Cliquer **Run** (Ctrl + Entrée). Doit afficher
   `Success. No rows returned.`
4. Vérifier dans **Table Editor** : les 4 tables `coequipiers`,
   `tournees`, `stops`, `saved_destinations` doivent apparaître avec
   une icône cadenas (RLS activée).

### Vérifier la RLS

Dans SQL Editor, lancer :

```sql
-- Liste les tables et leur statut RLS
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname='public'
ORDER BY tablename;
```

Résultat attendu : `rowsecurity = true` sur les 4 lignes.

```sql
-- Liste les policies
SELECT tablename, policyname, cmd
FROM pg_policies
WHERE schemaname='public'
ORDER BY tablename;
```

Résultat attendu : 4 policies `owner_all_*`, `cmd = ALL`.

### Test fumée d'insertion (optionnel, depuis le SQL editor)

Le SQL editor s'exécute avec le rôle `postgres` (bypass RLS) donc on
ne peut pas tester la RLS depuis là. Le vrai test sera fait depuis
l'app Flutter au sous-jalon 2.B (`CloudSyncService`).

Pour un test rapide « le schema accepte bien une INSERT » :

```sql
-- À PURGER après test (DELETE en fin)
INSERT INTO tournees (user_id, nom, date, point_depart_lat,
                      point_depart_lng, point_depart_label)
VALUES (
  (SELECT id FROM auth.users LIMIT 1),  -- prend le 1er user
  'Test schema',
  now(),
  48.85, 2.35, 'Paris test'
)
RETURNING id;

-- Vérifier
SELECT id, nom, date FROM tournees WHERE nom = 'Test schema';

-- Cleanup
DELETE FROM tournees WHERE nom = 'Test schema';
```

## Jalon 2.E — Migrations incrémentales + Storage bucket

Le SQL [`docs/supabase-schema.sql`](supabase-schema.sql) a été enrichi
avec les sections 7 (migrations incrémentales) et 8 (bucket Storage
`preuves` + RLS storage.objects). À chaque livraison de jalon qui
modifie le schema cloud, **ré-exécuter le fichier complet** dans le
SQL Editor — c'est idempotent (`ADD COLUMN IF NOT EXISTS`,
`INSERT ... ON CONFLICT DO NOTHING`, `DROP POLICY IF EXISTS`).

Procédure : SQL Editor → coller le fichier complet → Run. Doit afficher
`Success. No rows returned`.

### Vérifier le bucket Storage

```sql
SELECT id, name, public FROM storage.buckets WHERE id='preuves';
```
Attendu : 1 ligne `preuves / preuves / false`.

```sql
SELECT policyname, cmd FROM pg_policies
  WHERE schemaname='storage' AND tablename='objects'
  AND policyname LIKE '%preuves%'
  ORDER BY policyname;
```
Attendu : 4 lignes (`owner_select_preuves`, `owner_insert_preuves`,
`owner_update_preuves`, `owner_delete_preuves`).

### Test de l'upload depuis l'app

Une fois le SQL exécuté, build l'app + push une tournée qui a au moins
un stop avec photo preuve. Vérifier dans le dashboard Supabase →
**Storage** → bucket `preuves` → tu dois voir un dossier `<ton_uuid>/`
contenant les `<stop_uuid>.jpg` uploadées.

## Jalon 2.D-1c — Last-write-wins fin via `updated_at`

Modification de la fonction `set_updated_at()` (section 1 du SQL) pour
préserver le timestamp source du device qui a poussé la modif (au lieu
de l'écraser systématiquement à `now()` au moment du push). Sert au
pull last-write-wins : les autres devices comparent leur
`local.updated_at` au timestamp source pour décider d'écraser ou de
skip leur version locale.

Action requise : ré-exécuter le SQL complet (idempotent grâce à
`CREATE OR REPLACE FUNCTION`).

### Vérifier la nouvelle fonction

```sql
SELECT prosrc FROM pg_proc
  WHERE proname = 'set_updated_at' AND pronamespace = 'public'::regnamespace;
```
Attendu : la définition doit contenir
`IF NEW.updated_at IS NULL OR NEW.updated_at = OLD.updated_at THEN`.
Si c'est juste `NEW.updated_at = now();`, c'est l'ancienne version —
ré-exécuter le SQL.

### Tester le last-write-wins (device A + device B)

1. Sur device A : modifier une tournée déjà sync → push (auto-push 5s).
2. Sur device B (qui a déjà la même tournée localement, valeur
   ancienne) : ouvrir l'app + faire « Re-télécharger depuis le cloud ».
3. Vérifier : la tournée se met à jour avec les modifs de A. La
   SnackBar doit afficher `... (N ignoré(s))` si d'autres rows cloud
   étaient plus vieilles que les rows locales.

## Jalons suivants (à venir)

- **Jalon 3** : sync bi-directionnel chef ↔ coéquipiers via Supabase
  Realtime channels.
- **Jalon 4** : ETA SMS auto destinataire via Twilio (séparé de
  Supabase, ~$0.0075 / SMS).
- **Jalon 5** : backup cloud chiffré.
