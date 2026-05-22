# Edge Function `ocr-enhance` — Boost OCR via Gemini Flash

Booste l'extraction du parser bordereau MESEXP local en envoyant le
texte OCR brut a **Gemini Flash 2.5** (Google AI). Free tier : **1500
req/jour** — largement assez pour Noah (50-100 bordereaux/jour). Cout
au-dela : ~0.30€/mois pour 100 scans/jour.

## Procedure de deploiement (a faire une seule fois)

### 1. Creer une cle API Gemini (gratuit)

1. Va sur https://aistudio.google.com/app/apikey
2. Connecte-toi avec ton compte Gmail
3. Clique "Create API Key" → choisir un projet (ou "Create new project")
4. Copie la cle (commence par `AIza...`)

### 2. Installer Supabase CLI (si pas deja fait)

```powershell
# Via npm (Windows / Mac / Linux)
npm install -g supabase

# Ou via Scoop sur Windows
scoop install supabase
```

### 3. Se connecter et linker le projet

```powershell
cd d:/opti_route
supabase login  # ouvre le browser, accepte
supabase link --project-ref wipxgcnpiaecpcipqnpl
```

### 4. Configurer le secret Gemini

```powershell
supabase secrets set GEMINI_API_KEY=AIzaSyXXXXXXXXXXXXXXXXXXXXXX
```

Le secret est stocke chiffre cote Supabase, jamais expose dans l'APK.

### 5. Deployer la function

```powershell
supabase functions deploy ocr-enhance
```

La function devient accessible a :
`https://wipxgcnpiaecpcipqnpl.supabase.co/functions/v1/ocr-enhance`

Avec `verify_jwt = true` (cf [config.toml](../../config.toml)), seuls
les utilisateurs connectes a l'app peuvent l'appeler — protection
anti-abus du quota Gemini.

## Test rapide

```powershell
# Recupere ton JWT depuis Supabase dashboard > Auth > Users > ton compte
curl -X POST https://wipxgcnpiaecpcipqnpl.supabase.co/functions/v1/ocr-enhance `
  -H "Authorization: Bearer <TON_JWT>" `
  -H "Content-Type: application/json" `
  -d '{"ocr_text": "GARAGE LANCTIN DAMIEN\n31 RUE ARISTIDE BRIAND\n28190 COURVILLE SUR EURE", "format_hint": "enlevement"}'
```

Reponse attendue :
```json
{
  "nom_destinataire": "GARAGE LANCTIN DAMIEN",
  "rue": "31 RUE ARISTIDE BRIAND",
  "code_postal": "28190",
  "ville": "COURVILLE SUR EURE",
  "nb_colis": null,
  "telephone": null,
  "format": "enlevement",
  "confidence": "high",
  "source": "gemini"
}
```

## Monitoring du quota Gemini

Tu peux verifier ta conso sur https://aistudio.google.com/app/usage
ou les logs Supabase via `supabase functions logs ocr-enhance`.

## Comportement cote app

L'app fait OCR + parser local en PREMIER (offline-first, resultat
instantane). En parallele, elle appelle cette function. Si Gemini
repond avec un resultat MEILLEUR (confidence superieure OU plus de
champs remplis), l'UI bascule sur ce resultat et affiche le badge
"DETECTION IA" au lieu de "DETECTION AUTOMATIQUE".

Si la function timeout (5s), erreur, quota depasse ou pas de reseau,
l'app garde silencieusement le resultat du parser local.
