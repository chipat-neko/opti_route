# Edge Function `track` — suivi colis destinataire (#81)

Résout un code de suivi court (`https://optr.ro/abcd`) en données de
tracking pour la page destinataire [`site_doc/suivi.html`](../../../site_doc/suivi.html)
(déployée par la CI sur GitHub Pages sous `/opti_route/site/suivi.html`).

## Déploiement (à faire par Noah)

```bash
# 1. Appliquer le schema (table tracking_codes) — une seule fois.
#    Copier schema.sql dans le SQL editor Supabase et exécuter.

# 2. Déployer la function (publique, pas de JWT).
npx supabase functions deploy track --no-verify-jwt
```

La function utilise `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` (déjà
injectés automatiquement dans l'environnement des Edge Functions, rien
à configurer).

## Test après déploiement

```bash
curl "https://wipxgcnpiaecpcipqnpl.supabase.co/functions/v1/track?code=abcd"
```

Retourne `404` si le code n'existe pas (normal tant qu'aucun code n'a
été poussé), ou le JSON de tracking sinon.

## Reste à brancher côté app

`TrackingCodesRepository.generateForStop` est actuellement **local-only**.
Pour que la function ait des données, il faut pousser le code au cloud
au moment de la génération :

```dart
// Après l'INSERT Drift local, push vers Supabase :
await client.from('tracking_codes').insert({
  'code': tc.code,
  'stop_id': stopCloudId, // le cloud_id du stop (pas l'id local)
});
```

Le stop doit donc déjà avoir un `cloudId` (= avoir été poussé au cloud).

## Limites MVP actuelles

- **Position live livreur** : `livreur_lat/lng` retournent `null` tant
  que `live_presence` (jalon 3.C) n'est pas branché. La page tombe sur
  la position de destination.
- **ETA** : `eta_time` retourne `null` (calcul serveur des segments à
  faire). La page masque alors le bloc heure.
- **Page front** : `suivi.html` fetch cette function avec un fallback
  mock si l'endpoint répond une erreur (démo reste fonctionnelle).
