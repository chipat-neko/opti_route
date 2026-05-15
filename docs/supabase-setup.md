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
4. Templates par défaut OK pour démarrer. Personnalisable plus tard.
5. Free tier : 30 emails / heure (largement assez pour onboarding).

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

## Jalons suivants (à venir)

- **Jalon 2** : schéma `tournees` / `stops` / `coequipiers` côté
  Supabase avec RLS + migration des données locales au 1er login.
- **Jalon 3** : sync bi-directionnel chef ↔ coéquipiers via Supabase
  Realtime channels.
- **Jalon 4** : ETA SMS auto destinataire via Twilio (séparé de
  Supabase, ~$0.0075 / SMS).
- **Jalon 5** : backup cloud chiffré.

Voir `docs/plan-phase-2.md` (à écrire avant le jalon 2).
