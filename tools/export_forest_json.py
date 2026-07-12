"""Re-export le RandomForest en JSON compact Dart-friendly.

Sortie : app/assets/ml/bordereau_classifier.json
Inferenceur Dart trivial (50 lignes), 0 dep ONNX runtime.

Usage : python tools/export_forest_json.py
"""
import json
import sys
from collections import Counter
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split

ROOT = Path(__file__).parent.parent
sys.path.insert(0, str(ROOT / 'tools'))

from train_classifier import (
    FEATURE_NAMES, CLASSES, compute_features,
)

INPUT_CSV = ROOT / 'tools' / 'data' / 'training_data_labeled_gemini.csv'
OUT_JSON = ROOT / 'app' / 'assets' / 'ml' / 'bordereau_classifier.json'

print(f'Loading {INPUT_CSV}...')
df = pd.read_csv(INPUT_CSV, encoding='utf-8')
df = df[df['class'].isin(CLASSES)].copy()
print(f'  {len(df)} lines, classes {Counter(df["class"])}')

# Features positionnelles relatives par image
img_max_top = df.groupby('image')['top'].transform('max').replace(0, 1)
img_max_left = df.groupby('image')['left'].transform('max').replace(0, 1)
df['rel_y'] = df['top'] / img_max_top
df['rel_x'] = df['left'] / img_max_left

X = np.array([
    compute_features(
        row['line_text'], row['rel_y'], row['rel_x'],
        row['block_height'], row['block_width'],
    )
    for _, row in df.iterrows()
], dtype=np.float32)
y = np.array(df['class'].tolist())

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42, stratify=y,
)

clf = RandomForestClassifier(
    n_estimators=100,
    max_depth=12,
    min_samples_leaf=2,
    random_state=42,
    n_jobs=-1,
    class_weight='balanced',
)
clf.fit(X_train, y_train)
acc = clf.score(X_test, y_test)
print(f'Trained. accuracy_test={acc:.3f}')

# Export chaque arbre en arrays compacts
trees = []
for tree_est in clf.estimators_:
    t = tree_est.tree_
    feature = [-1 if f == -2 else int(f) for f in t.feature]
    threshold = [float(x) for x in t.threshold]
    left = [int(x) for x in t.children_left]    # -1 pour leaf
    right = [int(x) for x in t.children_right]  # -1 pour leaf
    # t.value shape (n_nodes, 1, n_classes) -> on garde value[i][0]
    value = [[float(v) for v in row[0]] for row in t.value]
    trees.append({
        'feature': feature,
        'threshold': threshold,
        'left': left,
        'right': right,
        'value': value,
    })

out = {
    'version': 1,
    'n_features': len(FEATURE_NAMES),
    'feature_names': FEATURE_NAMES,
    'n_classes': len(clf.classes_),
    'classes': list(clf.classes_),
    'n_trees': len(trees),
    'trees': trees,
    'accuracy_test': float(acc),
}

OUT_JSON.parent.mkdir(parents=True, exist_ok=True)
with open(OUT_JSON, 'w') as f:
    json.dump(out, f, separators=(',', ':'))

size_kb = OUT_JSON.stat().st_size // 1024
print(f'\nExported : {OUT_JSON} ({size_kb} KB)')
print(f'Trees: {len(trees)}, accuracy: {acc:.3f}')
