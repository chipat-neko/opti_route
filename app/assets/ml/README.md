# Modeles ML embarques

## bordereau_classifier.json

Random Forest (100 arbres) qui predit la classe d'une ligne OCR
extraite d'un bordereau de transport (NOM_CLIENT / RUE / CP_VILLE /
TEL / REF / PARASITE).

**Genere par** : `python tools/export_forest_json.py` (re-entraine
depuis `training_data_labeled_gemini.csv` avec seed fixe et exporte les
arbres en JSON compact).

**Consomme par** : `app/lib/data/bordereau_ml/classifier.dart`
(inference 100 % Dart, pas de dependance onnxruntime).

> L'export `.onnx` produit par `tools/train_classifier.py` est un
> artefact d'entrainement (tools/_bordereau_classifier.onnx, gitignore)
> — il n'est PAS embarque dans l'app (audit 2026-06-11 : il gonflait
> l'APK de 1,5 MB sans etre utilise).

## features.json

Specs partagees Python <-> Dart pour calculer le vecteur de features de
maniere identique des 2 cotes (mots-cles, regex, ponctuation). Regenere
par `tools/train_classifier.py` a chaque entrainement.

Toute modification de la liste des mots-cles DOIT :
1. Etre faite dans `tools/train_classifier.py` (source de verite)
2. Regenerer le modele (`train_classifier.py` puis
   `export_forest_json.py`)
3. Etre repercutee dans `app/lib/data/bordereau_ml/features.dart`

Le test `test/data/bordereau_ml_features_sync_test.dart` compare les
constantes Dart a ce fichier : la CI echoue tant que l'etape 3 n'est
pas faite.
