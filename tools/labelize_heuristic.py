"""Labelise les lignes OCR par regex + position spatiale, sans LLM.

Usage:
    python tools/labelize_heuristic.py tools/data/training_data.csv \
        tools/data/training_data_labeled.csv

Strategie :
1. Pass 1 (regex strict) : TEL, CP_VILLE, REF, RUE -> label sur
   evidence claire (regex match).
2. Pass 2 (heuristique nom) : lignes restantes avec
   MAJUSCULES + 2 mots + pas de chiffres au debut -> NOM_CLIENT.
3. Pass 3 (parasite par defaut) : tout le reste -> PARASITE,
   avec boost de confidence pour mots-cles header/transporteur.

Precision attendue : ~85% (vs ~95% Gemini). Suffisant pour entrainer
un Random Forest qui apprend a generaliser sur les patterns spatiaux.

Sortie : meme format que labelize_via_gemini.py (input + class).
"""
import csv
import re
import sys
from collections import Counter

CLASSES = ['NOM_CLIENT', 'RUE', 'CP_VILLE', 'TEL', 'REF', 'PARASITE']

# Patterns regex
PHONE_PATTERN = re.compile(
    r'(?:\+?33|0)\s*[1-9](?:[\s.\-]*\d{2}){4}'
)
TEL_KW_PATTERN = re.compile(
    r'^\s*(?:tel|tél|t[ée]l\.|port|mob|fax|gsm)[\s:.]',
    re.IGNORECASE,
)
CP_PATTERN = re.compile(r'\b\d{5}\b')
CP_VILLE_PATTERN = re.compile(
    r'^\s*\d{5}\s+[A-Z][A-Z\s\-]+',
)
REF_PATTERNS = [
    re.compile(r'^FA\d{6,}', re.IGNORECASE),
    re.compile(r'^[A-Z]{2,}\d{6,}[A-Z\d]*$'),  # tracking
    re.compile(r'\b\d{10,}\b'),  # long numero
]
# Header de tableau "Ref. exp." / "Ref. dest." -> PARASITE pas REF
REF_HEADER_PATTERN = re.compile(
    r'^\s*ref\.?\s*(?:exp|dest|client|exped)',
    re.IGNORECASE,
)
RUE_PATTERN = re.compile(
    r'^\s*\d+\s*(?:bis|ter|quater)?\s+'
    r'(?:rue|avenue|av\.?|bd|boulevard|impasse|chemin|ch\.|'
    r'route|rte|all[ée]e|place|cours|square|quai|sentier|voie|'
    r'parc|r[ée]sidence|residence|fbg|faubourg|lotissement|lot\.|'
    r'ruelle)\b',
    re.IGNORECASE,
)
RUE_NO_NUM_PATTERN = re.compile(
    r'^\s*(?:rue|avenue|av\.?|bd|boulevard|impasse|chemin|route|rte|'
    r'all[ée]e|place|cours|quai|ruelle)\s+(?:de\s|du\s|des\s|le\s|'
    r'la\s|les\s|[a-zA-Z])',
    re.IGNORECASE,
)
RN_RD_PATTERN = re.compile(r'^\s*(?:rn|rd|n)\s*\d+\b', re.IGNORECASE)
LIEU_DIT_PATTERN = re.compile(
    r'^\s*(?:le\s+bourg|le\s+lieu[\s-]?dit|hameau|domaine\s+de)',
    re.IGNORECASE,
)
ZONE_PATTERN = re.compile(
    r'^\s*(?:za|zi|zac|zone\s+(?:artisanale|industrielle|d[\'\s]activit))',
    re.IGNORECASE,
)

PARASITE_KW = [
    'destinataire', 'à enlever chez', 'a enlever chez', 'ramasse',
    'expediteur', 'expéditeur', 'transporteur', 'commissionnaire',
    'conditions', 'décret', 'decret', 'signature', 'cachet',
    'instruction', 'fragile', 'marchandise', 'expédition',
    'expedition', 'régime', 'regime', 'remise', 'colis', 'poids',
    'délai', 'delai', 'tarif', 'siret', 'tva', 'mesexp',
    'colissimo', 'chronopost', 'bordereau', 'livraison',
    'enlevement', 'enlèvement', 'code barre', 'code-barre',
    'code à barre', 'lieu de livraison', 'lieu de chargement',
    'date', 'heure', 'période', 'periode', 'vol /', 'vol/',
    'u.m.', 'um', 'art.', 'art ', 'article', 'recevables',
    'reserves', 'réserves', 'recommandée', 'recommandee',
    'jours suivants', 'integral', 'intégral', 'commerce',
    'parties', 'défaut', 'defaut', 'applicables', 'arrivee',
    'arrivée', 'depart', 'départ', 'eure et', 'eure-et-',
    'nom, signature', 'nom signature', 'sont applicables',
    'demande)', 'remisse', 'ref. exped', 'ref. dest',
    'contact', 'suivi', 'envoi', 'expedit', 'destinata',
    'commissionnaire', 'avenant', 'cgv', 'cgu', 'à enlever',
    'a enlever', 'la remise', 'la remisse', 'ferte bernard',  # ex header
    'transports :', 'transports:', 'cnaufrt',
    # Headers tableau qui apparaissent souvent
    'masse', 'm3', 'kg', 'm³', 'volume', 'qté', 'qte', 'qty',
    'cdt', 'unite', 'unité', 'reference',
    # Mentions footer
    'capital', 's.a.s', 'sarl', 'tel:', 'fax:', 'rcs',
]
PARASITE_KW_RE = re.compile(
    r'(?:' + '|'.join(re.escape(k) for k in PARASITE_KW) + r')',
    re.IGNORECASE,
)


def classify(text):
    """Renvoie la classe pour un texte de ligne OCR."""
    t = (text or '').strip()
    if not t or len(t) < 2:
        return 'PARASITE'

    # TEL prioritaire (avant CP car telephones contiennent des 5 chiffres)
    if PHONE_PATTERN.search(t) or TEL_KW_PATTERN.match(t):
        return 'TEL'

    # CP_VILLE : 5 chiffres dans la ligne (heuristique large)
    if CP_PATTERN.search(t):
        # Si c'est un CP collé à une ville/MAJUSCULES => CP_VILLE
        # Si juste un numero perdu (siret, ref) -> deja capture par TEL/REF
        # Cas typiques : "28190 COURVILLE SUR EURE", "28190", "CP 28190"
        # Mais aussi "FA56000447" qui contient 5 chiffres -> exclus
        # On exclut si la ligne ressemble plus a un REF.
        is_ref = any(p.search(t) for p in REF_PATTERNS)
        if not is_ref:
            return 'CP_VILLE'

    # Header tableau "Ref. exp." -> PARASITE, exclu de REF
    if REF_HEADER_PATTERN.match(t):
        return 'PARASITE'

    # REF : numero facture/tracking
    if any(p.search(t) for p in REF_PATTERNS):
        return 'REF'

    # RUE : numero + mot-cle rue
    if RUE_PATTERN.match(t) or RN_RD_PATTERN.match(t):
        return 'RUE'
    if RUE_NO_NUM_PATTERN.match(t):
        return 'RUE'
    if LIEU_DIT_PATTERN.match(t):
        return 'RUE'
    if ZONE_PATTERN.match(t):
        return 'RUE'

    # PARASITE : mot-cle header/conditions explicite
    if PARASITE_KW_RE.search(t):
        return 'PARASITE'

    # NOM_CLIENT : MAJUSCULES dominantes, 2+ mots, pas de chiffres
    # au debut, longueur raisonnable
    letters = [c for c in t if c.isalpha()]
    if not letters:
        return 'PARASITE'
    pct_upper = sum(1 for c in letters if c.isupper()) / len(letters)
    n_words = len(t.split())
    starts_digit = t[0].isdigit() if t else False
    has_many_digits = sum(1 for c in t if c.isdigit()) / len(t) > 0.3

    if (pct_upper >= 0.7 and n_words >= 2 and not starts_digit
            and not has_many_digits and 4 <= len(t) <= 50):
        return 'NOM_CLIENT'

    # Cas limite : un seul mot MAJUSCULES long (ex "AUTODISTRIBUTION")
    if (pct_upper >= 0.8 and n_words == 1 and len(t) >= 8
            and not has_many_digits):
        return 'NOM_CLIENT'

    return 'PARASITE'


def main():
    if len(sys.argv) != 3:
        print(__doc__)
        sys.exit(1)
    input_csv = sys.argv[1]
    output_csv = sys.argv[2]

    rows = []
    with open(input_csv, encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            row['class'] = classify(row['line_text'])
            rows.append(row)

    fieldnames = list(rows[0].keys())
    with open(output_csv, 'w', newline='', encoding='utf-8') as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"=== Output : {output_csv} ({len(rows)} lignes) ===")
    counts = Counter(r['class'] for r in rows)
    print("Repartition :")
    for cls in CLASSES:
        n = counts.get(cls, 0)
        pct = 100 * n / len(rows) if rows else 0
        print(f"  {cls:12s} : {n:5d} ({pct:.1f}%)")

    # Echantillons pour Noah a verifier
    print()
    print("=== Echantillons par classe (5/classe) ===")
    by_class = {c: [] for c in CLASSES}
    for r in rows:
        by_class[r['class']].append(r['line_text'])
    for cls in CLASSES:
        samples = by_class[cls][:5]
        print(f"\n  [{cls}]")
        for s in samples:
            print(f"    {s[:80]}")


if __name__ == '__main__':
    main()
