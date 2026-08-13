# Handoff — actions PC et console

> État au 2026-08-13. Ce qui reste de l'audit v2 et qui ne peut pas être fait depuis une machine sans Flutter : d'un côté ce qui demande le PC principal, de l'autre ce qui passe par une console web (Supabase, GitHub).

Les actions PC automatisables sont regroupées dans [`scripts/handoff-pc.ps1`](../scripts/handoff-pc.ps1). Ce document couvre le reste, et sert de contrôle après exécution du script.

---

## A. PC principal

### A1. Régénérer `database.g.dart` ⚠️ bloquant local

**Pourquoi** : la purge #532 a retiré les tables `tracking_codes` et `sheets` et fait passer `schemaVersion` à 52, mais le `.g.dart` committé date d'avant — il contient encore ~140 références à ces tables. La CI régénère (le `build_runner` a été ajouté aux trois workflows de build), **pas** `flutter run` en local : la machine de dev casse donc au démarrage.

```powershell
cd app
dart run build_runner build --delete-conflicting-outputs
```

**Vérifier** : `Select-String app/lib/data/database.g.dart -Pattern 'TrackingCodes'` ne doit plus rien renvoyer. Puis committer le `.g.dart`.

### A2. Activer F15 — *après* A1 seulement

Une fois le `.g.dart` régénéré **et committé**, ajouter dans `ci.yml`, juste après l'étape `build_runner` :

```yaml
      - name: Verifie que le code genere committe est a jour
        run: git diff --exit-code -- app/lib/**/*.g.dart
```

Lancé avant A1, ce check échouerait immédiatement — c'est pour ça qu'il n'est pas encore en place.

### A3. `pubspec.lock` puis `--enforce-lockfile`

`wakelock_plus` manque au lock, ce qui empêche de figer les versions en CI.

```powershell
cd app
flutter pub get     # met le lock à jour
```

Committer `pubspec.lock`, **puis** remplacer `flutter pub get` par `flutter pub get --enforce-lockfile` dans `ci.yml`, `deploy-web.yml` et `build-windows.yml`.

### A4. Déplacer la keystore hors de l'arbre

Automatisé par le script (étape 3), avec vérification SHA-256 avant suppression de l'original.

> Rappel : `upload-keystore.jks` et `key.properties` n'ont **jamais** été committés — `git log --all --full-history -- "*.jks" "*key.properties"` ne renvoie rien, et ils sont gitignorés deux fois. **La clé n'est pas compromise**, aucune rotation n'est nécessaire. Le déplacement est du durcissement, pas une réparation.

Après déplacement, un build release doit afficher : `Signing release : key.properties lu depuis <chemin>`.

### A5. Validation sur device — trois comportements non testables en CI

| Item | Quoi vérifier |
|---|---|
| **F6b** (#516) | Le repli sur alarme inexacte quand Android 12+/14+ refuse l'alarme exacte : les rappels doivent toujours partir. |
| **F20** (#517) | Reprise du GPS au retour au premier plan : pas de flash, pas de perte de la dernière position, transition `inactive` correcte. |
| **F25** (#518 + #534) | Recalcul des métriques après réorganisation d'arrêts, **et** le cas ajouté depuis : réorganiser pendant qu'une requête OSRM est en vol — la demande doit être rejouée, plus jamais perdue. |
| **F28 / #539** | Le bandeau de proximité : apparaît à moins de 80 m d'un arrêt à livrer, disparaît sinon. |

### A6. Reste de fond, non entamé

- **F24** — virtualiser la liste des arrêts (`CustomScrollView` + `SliverReorderableList`), à re-tester au drag-and-drop sur device.
- **F17** — transactions autour des backfills v25/v29/v32 (tests natif **et** web requis).
- **F8b** — mocks `MethodChannel` (geolocator, mobile_scanner, flutter_tts, wakelock_plus) puis smoke tests des écrans scan / tournée / navigation.
- **F37** — tenter le dé-pin de `receive_sharing_intent` (le forçage Java 17 global date d'après le pin) ; surveiller les bindings sqlite3 face au `.so` 0.5.41.

---

## B. Console Supabase

### B1. Finir la purge du tracking colis

La suppression est faite côté app et côté repo (#532), pas côté prod.

```bash
npx supabase functions delete track
```

Puis appliquer une migration de nettoyage :

```sql
drop table if exists tracking_codes;
drop table if exists sheets;
```

⚠️ **Ne pas toucher** à `stops.tracking_numbers` ni aux regex de `bordereau_patterns` : c'est le **scan de colis**, bien vivant.

### B2. Redéployer les 3 Edge Functions — sinon le CORS de #535 ne sert à rien

Le durcissement CORS est dans le repo mais **aucun workflow ne déploie les Edge Functions** ; la CI ne fait que `deno test`. Tant que ce n'est pas lancé, la prod répond toujours `Access-Control-Allow-Origin: *`.

```bash
npx supabase functions deploy accept_invitation
npx supabase functions deploy invite_employee
npx supabase functions deploy cron_lockout_revoked
```

**Vérifier** ensuite qu'un appel depuis une origine inconnue ne reçoit plus d'en-tête `Access-Control-Allow-Origin`, et qu'un appel **sans** en-tête `Origin` (app mobile) passe toujours.

### B3. Vérifier le `jobname` pg_cron **avant** de rejouer la migration F31

La migration `20260813000000_cron_lockout_revoked.sql` désinscrit puis réinscrit un job nommé `cron_lockout_revoked`. Si le job existant en prod porte un autre nom, elle en créerait un **second** — donc une double exécution quotidienne.

```sql
select jobid, jobname, schedule, command from cron.job;
```

- Même nom → la migration est idempotente, rien à faire de plus.
- Nom différent → adapter le `unschedule` de la migration **avant** de l'appliquer.

Vérifier aussi que les secrets Vault `project_url` et `cron_secret` existent : sans eux le job échoue au runtime (visible dans `cron.job_run_details`), la migration se contentant d'un `raise warning`.

### B4. Supprimer l'Edge Function `accept_invitation` (F34)

Flux mort : l'app utilise la **RPC SQL** homonyme.

⚠️ **Ne pas supprimer la RPC** — seulement l'Edge Function, puis sa section dans `supabase/config.toml` et ses fichiers du repo.

---

## C. Console GitHub

### C1. Secrets de signature Android (facultatif)

Sans eux, `build-android.yml` produit un AAB signé avec les clés debug — utilisable pour tester, **pas** publiable. Avec eux, l'artefact est directement uploadable sur la Play Console.

| Secret | Contenu |
|---|---|
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | mot de passe de la keystore |
| `ANDROID_KEY_PASSWORD` | mot de passe de l'alias (souvent le même) |
| `ANDROID_KEY_ALIAS` | `upload` |

Le workflow écrit ces fichiers dans `RUNNER_TEMP`, jamais dans l'arbre du repo, et les supprime en fin de job.

---

## D. Décisions en suspens

- **T0.1 — repo public avec les fixtures PII** : décision prise le 2026-08-13 de **garder tel quel**. Les 68 scans clients de `app/assets/test_bordereaux/` restent lisibles publiquement. Le strip PII des builds livrés reste actif et, depuis #533, vérifié par un garde-fou qui fait échouer le build si un AAB contient encore des fixtures.
- **26 modules à brancher (F28)** : le triage complet est disponible, avec pour chacun son rôle, le coût de branchement et les pièges. `proximity_checker` a été branché (#539). Les mieux placés ensuite : `scan_duplicate_check` (évite de relivrer un colis), `dispute_file` (dossier litige opposable), `failure_heatmap` (échecs par code postal × heure).
- Quatre modules sont **inachevés** et ne doivent pas être branchés en l'état : `parking_spots` (in-memory, table Drift à créer), `cold_chain` (`sortByExpiry` est un no-op), `end_of_day_depot` (stub qui ignore son paramètre), `time_loss_heatmap` (structurellement inerte : il exige des ETA que `computeEtas` ne produit que pour les stops `à_livrer`).
