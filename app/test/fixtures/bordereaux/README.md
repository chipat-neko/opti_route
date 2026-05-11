# Fixtures bordereaux OCR

Ce dossier contient les **dumps OCR de bordereaux reels** utilises comme cas de test pour le parser. Chaque dump est un fichier `.txt` contenant les lignes telles que retournees par Google ML Kit Text Recognition (cf logs `OCRDUMP` via `adb logcat -s flutter:V | grep OCRDUMP` sur le tel).

## Structure

```
fixtures/bordereaux/
├── README.md                          (ce fichier)
├── mesexp/
│   ├── classique-1.txt                (1 bordereau MESEXP standard)
│   ├── tete-beche-1.txt               (photo prise a l'envers)
│   └── froisse-1.txt                  (papier abime)
└── colis/
    ├── (a remplir des que Noah transfere les photos colis)
```

## Convention de nommage

`<format>/<situation>-<numero>.txt` ou :
- `<format>` : `mesexp` / `colis` / `chronopost` / etc.
- `<situation>` : `classique`, `tete-beche`, `froisse`, `faible-luminosite`, `partiel` (bordereau coupe), etc.
- `<numero>` : incrementer si plusieurs exemples de la meme situation.

## Comment generer un dump

Sur le telephone, avec l'app installee :

1. `adb logcat -c` (clear)
2. Scanner le bordereau via l'app.
3. `adb logcat -s flutter:V > dump.log`
4. Filtrer `OCRDUMP` -> chaque ligne = un texte ML Kit.
5. Coller dans un `.txt` dans le dossier approprie.

## Utilisation dans les tests

Les tests `bordereau_parser_test.dart` et `bordereau_format_detector_test.dart` peuvent charger ces fixtures via `File('test/fixtures/bordereaux/...').readAsLinesSync()` et verifier que le parser produit le bon resultat.

## Privacy

Les fixtures **doivent etre anonymisees** : remplacer les noms reels de clients par des noms d'entreprises publiques (mairies, ecoles, marques connues). Pas de donnees personnelles reelles dans le repo.
