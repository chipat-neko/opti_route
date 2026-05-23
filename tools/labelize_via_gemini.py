"""Labellise les lignes OCR d'un bordereau via l'Edge Function Gemini
deja deployee (Supabase ocr-enhance).

Usage:
    python tools/labelize_via_gemini.py training_data.csv training_data_labeled.csv

Pre-requis : variable d'env SUPABASE_URL et SUPABASE_ANON_KEY (ou
lecture depuis app/cloud.env.json).

Format input  : image,block_id,line_idx,line_text,left,top,right,bottom,...
Format output : input + class (NOM_CLIENT / RUE / CP_VILLE / TEL / REF / PARASITE)

Note : 1 requete Gemini par IMAGE (pas par ligne). Gemini reçoit
toutes les lignes d'une image en bulk et renvoie un mapping
{line_idx: class}.
"""
import csv
import json
import sys
import time
from collections import defaultdict
from pathlib import Path

try:
    import requests
except ImportError:
    print("Install requests: pip install requests")
    sys.exit(1)

ROOT = Path(__file__).parent.parent
ENV_FILE = ROOT / 'app' / 'cloud.env.json'

CLASSES = [
    'NOM_CLIENT',  # nom destinataire / ramasse
    'RUE',          # adresse rue (avec ou sans numero)
    'CP_VILLE',     # code postal + ville (ou juste l'un)
    'TEL',          # numero de telephone
    'REF',          # numero reference / tracking / facture
    'PARASITE',     # header tableau, transporteur, conditions, label, etc.
]


def load_env():
    """Lit Supabase config depuis cloud.env.json."""
    if not ENV_FILE.exists():
        print(f"Missing {ENV_FILE}")
        sys.exit(1)
    with open(ENV_FILE) as f:
        return json.load(f)


def build_prompt(lines_with_idx):
    """Construit le prompt Gemini : on lui donne toutes les lignes et il
    renvoie un mapping idx -> classe."""
    listing = '\n'.join(f'{i}: "{txt}"' for i, txt in lines_with_idx)
    return f"""Tu es un classificateur de lignes OCR de bordereaux de transport
francais (MESEXP, Colissimo, Chronopost). Pour chaque ligne, attribue
UNE classe parmi :

- NOM_CLIENT : nom du destinataire / ramasse (ex "GARAGE LANCTIN DAMIEN")
- RUE       : adresse de rue avec ou sans numero (ex "31 RUE ARISTIDE BRIAND", "RN 23 AVENUE DE PARIS", "Le bourg")
- CP_VILLE  : code postal + ville OU juste l'un des 2 (ex "28190 COURVILLE SUR EURE", "28190", "LUCE")
- TEL       : numero de telephone (ex "0612345678", "tel: 02 37 84 44 41")
- REF       : numero de reference / tracking / facture (ex "FA280000440358", "270521/6552AGNCMVZ04L")
- PARASITE  : header de tableau, label section, transporteur, conditions generales, code regime, ZA, instruction, etc.

Lignes :
{listing}

Reponds en JSON strict (rien d'autre, pas de markdown) sous la forme :
{{"0": "PARASITE", "1": "NOM_CLIENT", "2": "RUE", ...}}

Toutes les lignes doivent etre classees."""


def call_gemini(supabase_url, anon_key, prompt):
    """Appelle l'Edge Function ocr-enhance avec un prompt custom.

    Note : l'Edge Function actuelle attend `ocr_text`. On va lui
    passer le prompt complet en `ocr_text` ; elle va faire son propre
    appel Gemini. Si on veut vraiment du custom, il faut soit modifier
    l'Edge Function, soit appeler Gemini directement avec une cle API.
    """
    # Pour ce script, on appelle Gemini DIRECTEMENT avec la cle qu'on
    # va lire en local (cloud.env.json doit avoir GEMINI_API_KEY).
    # Si pas dispo, fallback : utiliser supabase_url avec le prompt.
    raise NotImplementedError(
        "Appel direct Gemini API necessite GEMINI_API_KEY. "
        "Soit la mettre dans cloud.env.json, soit modifier l'Edge Function "
        "pour accepter un prompt custom."
    )


def call_gemini_direct(api_key, prompt, max_retries=4):
    """Appel direct Gemini API (necessite GEMINI_API_KEY).

    Free tier Gemini 2.5 Flash :
    - 15 req/min, 1500 req/jour, 1M tokens/min
    Retry avec backoff exponentiel sur 429 (rate limit).
    maxOutputTokens 8192 pour les pages riches (>50 lignes).
    """
    url = (
        'https://generativelanguage.googleapis.com/v1beta/models/'
        f'gemini-2.5-flash:generateContent?key={api_key}'
    )
    body = {
        'contents': [{'parts': [{'text': prompt}]}],
        'generationConfig': {
            'temperature': 0,
            'maxOutputTokens': 8192,
            'responseMimeType': 'application/json',
        },
    }
    last_err = None
    for attempt in range(max_retries):
        resp = requests.post(url, json=body, timeout=60)
        if resp.status_code == 429:
            wait = 15 * (2 ** attempt)  # 15s, 30s, 60s, 120s
            print(f'(429, retry in {wait}s)', end=' ', flush=True)
            time.sleep(wait)
            continue
        if resp.status_code != 200:
            raise Exception(f'Gemini {resp.status_code}: {resp.text[:200]}')
        try:
            data = resp.json()
            text = data['candidates'][0]['content']['parts'][0]['text']
            text = text.strip()
            if text.startswith('```'):
                text = text.lstrip('`').lstrip('json').strip()
                if text.endswith('```'):
                    text = text[:-3].strip()
            return json.loads(text)
        except (KeyError, json.JSONDecodeError) as e:
            last_err = e
            # JSON tronque ou structure inattendue -> on log et raise
            raise Exception(
                f'Parse Gemini reponse: {e}; '
                f'extrait: {resp.text[:300]}'
            )
    raise Exception(f'Gemini : {max_retries} retries epuises ({last_err})')


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    input_csv = sys.argv[1]
    output_csv = sys.argv[2]

    env = load_env()
    api_key = env.get('GEMINI_API_KEY')
    if not api_key:
        print("Missing GEMINI_API_KEY in cloud.env.json")
        print("Ajoute la cle dans cloud.env.json (gitignored par defaut).")
        sys.exit(1)

    # Lire input et grouper par image
    by_image = defaultdict(list)
    with open(input_csv, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            by_image[row['image']].append(row)

    print(f"Total : {sum(len(v) for v in by_image.values())} lignes / "
          f"{len(by_image)} images")

    # Pour chaque image, batch-call Gemini
    all_labeled = []
    for img_idx, (image, rows) in enumerate(by_image.items(), 1):
        # Liste (line_global_idx, line_text) pour ce bordereau
        # On utilise un idx local 0..N pour le prompt, on garde mapping
        # vers l'idx global dans le CSV.
        lines_with_idx = [(i, r['line_text']) for i, r in enumerate(rows)]
        prompt = build_prompt(lines_with_idx)
        print(f"  [{img_idx}/{len(by_image)}] {image} : "
              f"{len(rows)} lignes -> appel Gemini...", end=' ')
        try:
            labels = call_gemini_direct(api_key, prompt)
        except Exception as e:
            print(f"FAIL: {e}")
            # Marquer comme UNKNOWN pour ne pas perdre les lignes
            labels = {str(i): 'UNKNOWN' for i in range(len(rows))}
        print(f"OK ({len(labels)} labels)")

        for i, row in enumerate(rows):
            classe = labels.get(str(i), 'UNKNOWN')
            if classe not in CLASSES and classe != 'UNKNOWN':
                classe = 'PARASITE'  # fallback
            row['class'] = classe
            all_labeled.append(row)

        # Rate limit Gemini free tier : 15 RPM => 4.5s/req min
        time.sleep(4.5)

    # Ecrit output
    fieldnames = list(all_labeled[0].keys())
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_labeled)
    print(f"\n=== Output : {output_csv} ({len(all_labeled)} lignes) ===")

    # Stats par classe
    from collections import Counter
    counts = Counter(r['class'] for r in all_labeled)
    print("Repartition :")
    for cls, n in counts.most_common():
        pct = 100 * n / len(all_labeled)
        print(f"  {cls:12s} : {n:5d} ({pct:.1f}%)")


if __name__ == '__main__':
    main()
