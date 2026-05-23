# Pipeline ML classifier OCR bordereaux (Option A)

Scripts pour entraîner un classifier qui prédit la classe (NOM / RUE /
CP_VILLE / TEL / REF / PARASITE) de chaque ligne OCR d'un bordereau.

## Étapes

```
1. batch_eval_test.dart                    -> training_data.csv (lignes OCR + positions)
2. tools/labelize_via_gemini.py            -> training_data_labeled.csv (+ classes)
3. tools/train_classifier.py               -> model.onnx + features.json
4. app/lib/data/bordereau_parser_ml.dart   -> inference Flutter
```

## 1. Generer training_data.csv

```bash
cd app
flutter test integration_test/bordereau_batch_eval_test.dart -d <device-id> --dart-define-from-file=cloud.env.json
adb pull /data/data/com.optiroute.opti_route/app_flutter/training_data.csv
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
python tools/labelize_via_gemini.py training_data.csv training_data_labeled.csv
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
pip install scikit-learn pandas numpy onnx onnxruntime skl2onnx
python tools/train_classifier.py training_data_labeled.csv
```

Output :
- `app/assets/ml/bordereau_classifier.onnx` (~100-200 KB) — modele
  Random Forest serialise ONNX, embeddable dans l'APK
- `app/assets/ml/features.json` — description des 20 features +
  liste des mots-cles (TEL_KW, RUE_KW, etc.) pour que le code Dart
  reproduise EXACTEMENT le meme vecteur de features
- `tools/_classifier_report.txt` — accuracy, classification report,
  confusion matrix, importances

Modele : Random Forest 100 arbres, depth=12, class_weight=balanced.
Rapide, leger, robuste, pas besoin de scaling des features.

**Important** : le code Dart d'inference DOIT reproduire bit-a-bit les
features definies dans `train_classifier.py` (cf. fonction
`compute_features`). `features.json` sert de specs : si on change un
mot-cle Python, regenerer le modele et synchroniser le Dart.

## 4. Embarquement Flutter

```dart
// app/lib/data/bordereau_parser_ml.dart
class BordereauParserMl {
  Future<BordereauExtraction?> parseFromBlocksMl(List<OcrBlock> blocks) {
    // 1. Charger model.onnx (chached au demarrage)
    // 2. Pour chaque ligne, calculer features
    // 3. Predire la classe via onnxruntime
    // 4. Composer BordereauExtraction depuis lignes classifiees
  }
}
```

Ajouter `onnxruntime: ^1.4.x` au pubspec.yaml.

Brancher dans scan_bordereau_screen comme strategie #1, fallback sur
parseFromBlocksSpatial (existant) si MlClassifier echoue.

## Iteration

Quand Noah corrige des scans dans l'app, on enregistre les lignes
corrigees dans `corrections.csv`. Periodique re-training du modele avec
ces corrections en plus du dataset initial.
