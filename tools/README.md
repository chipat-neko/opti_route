# Pipeline ML classifier OCR bordereaux (Option A)

Scripts pour entraîner un classifier qui prédit la classe (NOM / RUE /
CP_VILLE / TEL / REF / PARASITE) de chaque ligne OCR d'un bordereau.

## Étapes

```
1. batch_eval_test.dart                     -> tools/data/training_data.csv (lignes OCR + positions)
2. tools/labelize_via_gemini.py             -> tools/data/training_data_labeled_gemini.csv (+ classes)
3. tools/train_classifier.py                -> features.json (+ report + onnx d'archive)
4. tools/export_forest_json.py              -> app/assets/ml/bordereau_classifier.json
5. app/lib/data/bordereau_ml/classifier.dart-> inference Flutter (pur Dart)
```

## 1. Generer training_data.csv

```bash
cd app
flutter test integration_test/bordereau_batch_eval_test.dart -d <device-id> --dart-define-from-file=cloud.env.json
adb pull /data/data/com.optiroute.opti_route/app_flutter/training_data.csv ../tools/data/
```

Output : ~1500-2000 lignes OCR (68 images x ~20-30 lignes/image).

Format :
```csv
image,block_id,line_idx,line_text,left,top,right,bottom,block_width,block_height
page_01.jpg,0,0,"GARAGE LANCTIN DAMIEN",100,200,500,250,400,50
page_01.jpg,0,1,"31 RUE ARISTIDE BRIAND",100,250,500,300,400,50
...
```

## 2. Labelliser via Gemini (Edge Function Supabase deja deployee)

```bash
python tools/labelize_via_gemini.py tools/data/training_data.csv tools/data/training_data_labeled_gemini.csv
```

Le script appelle l'Edge Function `ocr-enhance` pour CHAQUE image
groupee (1 requete par image, pas par ligne). Gemini renvoie pour chaque
ligne sa classe :
- `NOM_CLIENT` : nom du destinataire/ramasse
- `RUE` : adresse de rue (avec numero)
- `CP_VILLE` : code postal + ville
- `TEL` : numero de telephone
- `REF` : numero de reference / tracking
- `PARASITE` : header tableau, transporteur, conditions generales

Cout estime : 68 requetes Gemini < 1500/jour free tier = gratuit.

Toi tu valides 50-100 lignes au hasard et tu corriges (~20 min).

## 3. Entrainer le classifier

```bash
pip install -r tools/requirements.txt
python tools/train_classifier.py tools/data/training_data_labeled_gemini.csv
```

Output :
- `app/assets/ml/features.json` — description des 20 features +
  liste des mots-cles (TEL_KW, RUE_KW, etc.) pour que le code Dart
  reproduise EXACTEMENT le meme vecteur de features
- `tools/_classifier_report.txt` — accuracy, classification report,
  confusion matrix, importances
- `tools/_bordereau_classifier.onnx` — artefact d'archive (gitignore),
  PAS embarque dans l'app

Modele : Random Forest 100 arbres, depth=12, class_weight=balanced.
Rapide, leger, robuste, pas besoin de scaling des features.

**Important** : le code Dart d'inference DOIT reproduire bit-a-bit les
features definies dans `train_classifier.py` (cf. fonction
`compute_features`). `features.json` sert de specs : si on change un
mot-cle Python, regenerer le modele et synchroniser
`app/lib/data/bordereau_ml/features.dart`. Le test
`test/data/bordereau_ml_features_sync_test.dart` echoue en CI tant que
la synchro n'est pas faite.

## 4. Export JSON + embarquement Flutter

```bash
python tools/export_forest_json.py
```

Re-entraine (meme seed, memes donnees) et exporte les arbres en JSON
compact vers `app/assets/ml/bordereau_classifier.json` (~2 MB, asset
declare dans pubspec). L'inference est 100 % Dart
(`app/lib/data/bordereau_ml/classifier.dart`) : pas de dependance
onnxruntime. Re-committer le JSON apres chaque re-entrainement.

## Iteration

Quand Noah corrige des scans dans l'app, on enregistre les lignes
corrigees dans `tools/data/corrections.csv`. Periodique re-training du modele avec
ces corrections en plus du dataset initial.
