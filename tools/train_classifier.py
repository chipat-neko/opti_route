"""Entraine un classifier Random Forest sur les lignes OCR labellisees
par Gemini et exporte en ONNX pour embarquer dans l'app Flutter.

Usage:
    python tools/train_classifier.py training_data_labeled.csv

Pre-requis :
    pip install scikit-learn pandas numpy onnx skl2onnx onnxruntime

Output :
    app/assets/ml/bordereau_classifier.onnx  (modele embeddable, ~100-200 KB)
    app/assets/ml/features.json              (specs pour reproduire les
                                              features cote Flutter)
    tools/_classifier_report.txt             (accuracy, confusion matrix)

Features extraites par ligne OCR (toutes deterministes, reproductibles
en Dart sans dependance externe) :
    - length          : nombre de caracteres
    - n_words         : nombre de mots
    - pct_upper       : % caracteres majuscules (sur les lettres)
    - pct_digit       : % caracteres chiffres
    - pct_punct       : % caracteres ponctuation
    - has_digit       : 0/1
    - has_at_sign     : 0/1 (email/handle)
    - starts_digit    : 0/1
    - ends_digit      : 0/1
    - n_digits        : nombre de chiffres
    - has_cp5         : 0/1 contient un code postal 5 chiffres
    - has_tel_kw      : 0/1 contient "tel"/"tél"/"port"/"mob"/"fax"
    - has_phone       : 0/1 match d'un pattern telephone
    - has_rue_kw      : 0/1 contient "rue"/"avenue"/"bd"/"boulevard"/
                       "impasse"/"chemin"/"route"/"allee"/"place"/
                       "rn"/"rd"/"zone"/"za"/"zi"
    - has_ref_kw      : 0/1 contient "fa"/"ref"/"tracking"/code-barres
                       like (long alphanum)
    - has_parasite_kw : 0/1 contient des mots header tableau (
                       "destinataire", "ramasse", "transporteur",
                       "expediteur", "colis", "poids", "regime",
                       "instruction", "fragile", "signature")
    - rel_y           : position verticale normalisee (top / max_top
                       par image) — debut/haut/bas du bordereau
    - rel_x           : position horizontale normalisee
    - block_height    : hauteur du block (proxy taille texte)
    - block_width     : largeur du block

Cibles (classes) :
    NOM_CLIENT, RUE, CP_VILLE, TEL, REF, PARASITE
"""
import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

try:
    import numpy as np
    import pandas as pd
    from sklearn.ensemble import RandomForestClassifier
    from sklearn.metrics import (
        accuracy_score,
        classification_report,
        confusion_matrix,
    )
    from sklearn.model_selection import train_test_split
    from skl2onnx import convert_sklearn
    from skl2onnx.common.data_types import FloatTensorType
except ImportError as e:
    print(f"Install deps: pip install scikit-learn pandas numpy onnx "
          f"skl2onnx onnxruntime ({e})")
    sys.exit(1)

ROOT = Path(__file__).parent.parent
ML_DIR = ROOT / 'app' / 'assets' / 'ml'
REPORT_FILE = ROOT / 'tools' / '_classifier_report.txt'

CLASSES = ['NOM_CLIENT', 'RUE', 'CP_VILLE', 'TEL', 'REF', 'PARASITE']

# Regex / mots-cles : SOURCE DE VERITE pour les features. Le code
# Dart doit reproduire EXACTEMENT cette liste (cf. features.json).
CP_PATTERN = re.compile(r'\b\d{5}\b')
PHONE_PATTERN = re.compile(
    r'(?:\+?33|0)\s*[1-9](?:[\s.\-]*\d{2}){4}'
)
TEL_KW = ['tel', 'tél', 'port', 'mob', 'fax', 'gsm']
RUE_KW = [
    'rue', 'avenue', 'av.', 'av ', 'bd', 'boulevard', 'impasse',
    'chemin', 'route', 'rte', 'allee', 'allée', 'place', 'rn', 'rd',
    'zone', 'za ', 'zi ', 'lotissement', 'lot.', 'cours', 'square',
    'quai', 'sentier', 'voie', 'parc', 'residence', 'résidence',
]
REF_KW = ['fa ', 'ref', 'tracking', 'n°', 'numero', 'numéro']
PARASITE_KW = [
    'destinataire', 'ramasse', 'transporteur', 'expediteur',
    'expéditeur', 'colis', 'poids', 'regime', 'régime', 'instruction',
    'fragile', 'signature', 'mesexp', 'colissimo', 'chronopost',
    'bordereau', 'livraison', 'enlevement', 'enlèvement',
    'code barre', 'code-barre',
]
PUNCT = set('.,;:!?-_/\\()[]{}"\'')


def compute_features(text, rel_y, rel_x, block_height, block_width):
    """Calcule le vecteur de features pour une ligne OCR."""
    # text peut etre NaN (float) si la ligne OCR est vide
    if text is None or (isinstance(text, float) and np.isnan(text)):
        text = ''
    t = str(text)
    tl = t.lower()
    length = len(t)
    n_words = len(t.split()) if t else 0
    letters = [c for c in t if c.isalpha()]
    digits = [c for c in t if c.isdigit()]
    punct = [c for c in t if c in PUNCT]
    pct_upper = (
        sum(1 for c in letters if c.isupper()) / len(letters)
        if letters else 0.0
    )
    pct_digit = len(digits) / length if length else 0.0
    pct_punct = len(punct) / length if length else 0.0
    return [
        float(length),
        float(n_words),
        float(pct_upper),
        float(pct_digit),
        float(pct_punct),
        1.0 if digits else 0.0,
        1.0 if '@' in t else 0.0,
        1.0 if t and t[0].isdigit() else 0.0,
        1.0 if t and t[-1].isdigit() else 0.0,
        float(len(digits)),
        1.0 if CP_PATTERN.search(t) else 0.0,
        1.0 if any(k in tl for k in TEL_KW) else 0.0,
        1.0 if PHONE_PATTERN.search(t) else 0.0,
        1.0 if any(k in tl for k in RUE_KW) else 0.0,
        1.0 if any(k in tl for k in REF_KW) else 0.0,
        1.0 if any(k in tl for k in PARASITE_KW) else 0.0,
        float(rel_y),
        float(rel_x),
        float(block_height),
        float(block_width),
    ]


FEATURE_NAMES = [
    'length', 'n_words', 'pct_upper', 'pct_digit', 'pct_punct',
    'has_digit', 'has_at_sign', 'starts_digit', 'ends_digit',
    'n_digits', 'has_cp5', 'has_tel_kw', 'has_phone', 'has_rue_kw',
    'has_ref_kw', 'has_parasite_kw', 'rel_y', 'rel_x',
    'block_height', 'block_width',
]


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    input_csv = Path(sys.argv[1])
    if not input_csv.exists():
        print(f"Input not found: {input_csv}")
        sys.exit(1)

    df = pd.read_csv(input_csv, encoding='utf-8')
    print(f"Loaded {len(df)} lines from {input_csv.name}")

    # Filtrer lignes sans label utilisable
    df = df[df['class'].isin(CLASSES)].copy()
    print(f"After filter (classes valides) : {len(df)} lines")

    # Calcul rel_y / rel_x par image (top/left max par bordereau)
    img_max_top = df.groupby('image')['top'].transform('max').replace(0, 1)
    img_max_left = df.groupby('image')['left'].transform('max').replace(0, 1)
    df['rel_y'] = df['top'] / img_max_top
    df['rel_x'] = df['left'] / img_max_left

    # Construit la matrice X de features
    X = np.array([
        compute_features(
            row['line_text'], row['rel_y'], row['rel_x'],
            row['block_height'], row['block_width'],
        )
        for _, row in df.iterrows()
    ], dtype=np.float32)
    y = np.array(df['class'].tolist())
    print(f"Feature matrix : {X.shape}, classes : {Counter(y)}")

    # Split stratifie 80/20
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y,
    )

    # Random Forest : leger, robuste, pas besoin de scaling
    clf = RandomForestClassifier(
        n_estimators=100,
        max_depth=12,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1,
        class_weight='balanced',
    )
    clf.fit(X_train, y_train)

    # Evaluation
    y_pred = clf.predict(X_test)
    acc = accuracy_score(y_test, y_pred)
    report = classification_report(y_test, y_pred, digits=3)
    cm = confusion_matrix(y_test, y_pred, labels=CLASSES)
    print(f"\n=== Accuracy : {acc:.3f} ===")
    print(report)
    print("Confusion matrix (rows=true, cols=pred) :")
    print('       ' + '  '.join(f'{c[:6]:>6s}' for c in CLASSES))
    for i, row in enumerate(cm):
        print(f'{CLASSES[i][:6]:>6s} ' + '  '.join(f'{n:>6d}' for n in row))

    # Feature importances
    print("\nTop features :")
    importances = sorted(
        zip(FEATURE_NAMES, clf.feature_importances_),
        key=lambda x: -x[1],
    )
    for name, imp in importances[:10]:
        print(f'  {name:18s} : {imp:.3f}')

    # Export ONNX
    ML_DIR.mkdir(parents=True, exist_ok=True)
    initial_type = [('input', FloatTensorType([None, X.shape[1]]))]
    onx = convert_sklearn(
        clf,
        initial_types=initial_type,
        target_opset=15,
        options={id(clf): {'zipmap': False}},
    )
    onnx_path = ML_DIR / 'bordereau_classifier.onnx'
    with open(onnx_path, 'wb') as f:
        f.write(onx.SerializeToString())
    print(f"\nONNX : {onnx_path} ({onnx_path.stat().st_size // 1024} KB)")

    # Specs des features pour le code Dart
    features_spec = {
        'version': 1,
        'feature_names': FEATURE_NAMES,
        'classes': list(clf.classes_),
        'tel_kw': TEL_KW,
        'rue_kw': RUE_KW,
        'ref_kw': REF_KW,
        'parasite_kw': PARASITE_KW,
        'cp_pattern': CP_PATTERN.pattern,
        'phone_pattern': PHONE_PATTERN.pattern,
        'punct_chars': ''.join(sorted(PUNCT)),
        'accuracy': float(acc),
    }
    features_path = ML_DIR / 'features.json'
    with open(features_path, 'w', encoding='utf-8') as f:
        json.dump(features_spec, f, ensure_ascii=False, indent=2)
    print(f"Features spec : {features_path}")

    # Rapport detaille
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write(f"Training : {input_csv.name}\n")
        f.write(f"Samples  : {len(df)}\n")
        f.write(f"Accuracy : {acc:.3f}\n\n")
        f.write(report + '\n')
        f.write("Confusion matrix :\n")
        f.write('       ' + '  '.join(f'{c[:6]:>6s}' for c in CLASSES) + '\n')
        for i, row in enumerate(cm):
            f.write(
                f'{CLASSES[i][:6]:>6s} '
                + '  '.join(f'{n:>6d}' for n in row) + '\n'
            )
        f.write("\nTop features :\n")
        for name, imp in importances:
            f.write(f'  {name:18s} : {imp:.4f}\n')
    print(f"Report : {REPORT_FILE}")


if __name__ == '__main__':
    main()
