"""Labellise les lignes OCR d'un bordereau via Gemini 2.5 Flash.

Usage:
    python tools/labelize_via_gemini.py training_data.csv training_data_labeled_gemini.csv [--max N]

Pre-requis : GEMINI_API_KEY dans app/cloud.env.json.

Format input  : image,block_id,line_idx,line_text,left,top,right,bottom,...
Format output : input + class (NOM_CLIENT / RUE / CP_VILLE / TEL / REF / PARASITE)

Note : 1 requete Gemini par IMAGE (pas par ligne). Gemini recoit
toutes les lignes d'une image en bulk et renvoie un mapping
{line_idx: class}.

Reprise automatique : si le CSV output existe deja avec des images
labellisees, on les skip et on continue depuis la suivante.

--max N : limite le nombre d'images traitees ce run (utile si quota
Gemini limite a 20/jour, on fait 18 par jour x 4 jours).
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


def load_already_done(output_csv):
    """Si output_csv existe deja, retourne (set des images deja labellisees,
    liste des rows deja ecrites). Sert a reprendre apres interruption."""
    p = Path(output_csv)
    if not p.exists():
        return set(), []
    done_images = set()
    done_rows = []
    with open(output_csv, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            done_images.add(row['image'])
            done_rows.append(row)
    return done_images, done_rows


def main():
    args = sys.argv[1:]
    max_images = None
    if '--max' in args:
        i = args.index('--max')
        max_images = int(args[i + 1])
        del args[i:i + 2]
    if len(args) != 2:
        print(__doc__)
        sys.exit(1)
    input_csv, output_csv = args

    env = load_env()
    api_key = env.get('GEMINI_API_KEY')
    if not api_key:
        print("Missing GEMINI_API_KEY in cloud.env.json")
        sys.exit(1)

    # Lire input et grouper par image
    by_image = defaultdict(list)
    with open(input_csv, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            by_image[row['image']].append(row)

    # Reprise : on ne re-labellise pas les images deja faites
    done_images, done_rows = load_already_done(output_csv)
    remaining = [(img, rows) for img, rows in by_image.items()
                 if img not in done_images]

    print(f"Total : {sum(len(v) for v in by_image.values())} lignes / "
          f"{len(by_image)} images")
    print(f"Deja labellisees : {len(done_images)} images "
          f"({len(done_rows)} lignes)")
    print(f"A traiter : {len(remaining)} images")
    if max_images is not None:
        remaining = remaining[:max_images]
        print(f"Limite a {max_images} images ce run")

    # Pour chaque image, batch-call Gemini.
    # On detecte 3 echecs 429 consecutifs = quota daily epuise -> stop.
    all_labeled = list(done_rows)
    consecutive_429 = 0
    for img_idx, (image, rows) in enumerate(remaining, 1):
        lines_with_idx = [(i, r['line_text']) for i, r in enumerate(rows)]
        prompt = build_prompt(lines_with_idx)
        print(f"  [{img_idx}/{len(remaining)}] {image} : "
              f"{len(rows)} lignes -> appel Gemini...",
              end=' ', flush=True)
        try:
            labels = call_gemini_direct(api_key, prompt)
            consecutive_429 = 0
        except Exception as e:
            err_msg = str(e)
            is_429 = ('429' in err_msg
                      or 'RESOURCE_EXHAUSTED' in err_msg
                      or 'retries epuises' in err_msg)
            if is_429:
                consecutive_429 += 1
                print(f"QUOTA 429 ({consecutive_429}/3)")
                if consecutive_429 >= 3:
                    print(f"\n=== Quota daily Gemini epuise. "
                          f"Stop apres {img_idx - 1} images ce run. "
                          f"Relance demain pour continuer (quota reset PT 00:00). "
                          f"===")
                    break
                # Skip cette image (pas d'UNKNOWN, on la fera demain)
                continue
            print(f"FAIL non-429: {e}")
            labels = {str(i): 'UNKNOWN' for i in range(len(rows))}

        for i, row in enumerate(rows):
            classe = labels.get(str(i), 'UNKNOWN')
            if classe not in CLASSES and classe != 'UNKNOWN':
                classe = 'PARASITE'
            row['class'] = classe
            all_labeled.append(row)

        # Save apres chaque image pour pas perdre le travail en cas d'interrupt
        save_output(output_csv, all_labeled)
        print(f"OK ({len(labels)} labels, {len(all_labeled)} total)")

        # Rate limit Gemini free tier : 15 RPM => 4.5s/req min
        time.sleep(4.5)

    save_output(output_csv, all_labeled)
    print_stats(all_labeled, output_csv, len(by_image))


def save_output(output_csv, all_labeled):
    if not all_labeled:
        return
    fieldnames = list(all_labeled[0].keys())
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(all_labeled)


def print_stats(all_labeled, output_csv, total_images):
    if not all_labeled:
        return
    images_done = len({r['image'] for r in all_labeled})
    print(f"\n=== Output : {output_csv} ({len(all_labeled)} lignes / "
          f"{images_done}/{total_images} images) ===")
    from collections import Counter
    counts = Counter(r['class'] for r in all_labeled)
    print("Repartition :")
    for cls, n in counts.most_common():
        pct = 100 * n / len(all_labeled)
        print(f"  {cls:12s} : {n:5d} ({pct:.1f}%)")


if __name__ == '__main__':
    main()
