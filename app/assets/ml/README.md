# Modeles ML embarques

## bordereau_classifier.onnx

Random Forest classifier qui predit la classe d'une ligne OCR
extraite d'un bordereau de transport.

**Genere par** : `python tools/train_classifier.py training_data_labeled.csv`

**Consomme par** : `app/lib/data/bordereau_parser_ml.dart` via
`onnxruntime` Flutter plugin.

**Specs features** : voir `features.json` (description des 20 features
et listes de mots-cles a reproduire en Dart).

## features.json

Specs partagees Python <-> Dart pour calculer le vecteur de features
de maniere identique des 2 cotes.

Toute modification de la liste des mots-cles DOIT :
1. Etre faite dans `tools/train_classifier.py`
2. Regenerer le modele
3. Etre repercutee dans `bordereau_parser_ml.dart`
