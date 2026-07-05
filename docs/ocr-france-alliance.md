# OCR — bordereaux « France Alliance » (analyse + vérité terrain)

Échantillon de 23 étiquettes **collées sur les colis** (lot `v2`, 2026-06-06),
réseau **France Alliance** (Eure-et-Loir 28 + Sarthe 72), destinataires =
professionnels (garages, carrosseries, SARL). **≠ format MESEXP.**

## Constat clé : ~4 gabarits différents (pas un seul format)
| # | Transporteur / émetteur | Mise en page | Indices de détection |
|---|---|---|---|
| A | **ALLIANCE PR** (pièces/pneus auto) | label couleur, bandeaux verticaux `EXPEDITEUR` / `DESTINATAIRE` à gauche, bloc article à droite, code-barres vertical | « ALLIANCE PR », « Code Client », « No DMS/OL », « PVP » |
| B | **CSG / Seigneurie Gauthier** (peinture) | label blanc, `COLIS x/y` en tête, `EXPEDITEUR` (g) / `DESTINATAIRE` (d) côte à côte | « SEIGNEURIE GAUTHIER », « COLIS x/y », « N° de COMMANDE » |
| C | **GETTYGO / FRANCE ALLIANCE RESEAU** | label blanc, nom+tél en haut, `COLIS 1/N`, `BL:` / `Ref:` | « FRANCE ALLIANCE RESEAU », « GETTYGO », « BL : » |
| D | **FA28 TRANSPORTS / BEAUCERONNE** | label blanc, `EXPEDITEUR` (g) / `DESTINATAIRE` (d), `No Colis` | « FA28 TRANSPORTS », « No Colis », « QBEAUCERON… » |

Point commun exploitable : presque tous ont l'ancre **`DESTINATAIRE`** + un
**CP 5 chiffres + VILLE** (souvent `28xxx`) + parfois un **téléphone**
(`0X XX XX XX XX`) + un **nb de colis** (`COLIS x/y` ou `x/N`). Le format C n'a
pas le mot « DESTINATAIRE » : le destinataire est le **bloc du haut**.

## Verdict OCR (reconnaissance brute, ML Kit)
👍 Favorable : texte **imprimé net** → bien plus fiable que du manuscrit.
⚠️ Pièges sur les photos : **orientation** (plusieurs à l'envers/90°),
**bords coupés** (label qui dépasse → « EXPEDITEUR » → « XPEDITEUR »),
reflets sur plastique. En scan caméra réel, ML Kit corrige l'orientation ;
le cadrage reste à soigner.

## Verdict parser actuel
❌ Le parser MESEXP **ne convient pas** (structure totalement différente).

## Différence métier
MESEXP = 1 feuille récap par tournée. Ici = **1 étiquette par colis** →
workflow **scan colis** : on scanne chaque étiquette, l'app **regroupe par
destinataire** (nom+adresse) en arrêts, et `COLIS x/y` donne le total attendu.

## Vérité terrain (13/23 lues — les 10 restantes : série 04/06, format B,
## mêmes destinataires multi-colis LEDUC SARL, à compléter au câblage harness)

| fichier | fmt | destinataire | adresse | cp | ville | tél | colis | réf |
|---|---|---|---|---|---|---|---|---|
| 20260526_070852 | A | *…S AUTO* (début coupé) | RUE EDOUARD BRANLY | 28190 | ST GEORGES SUR EURE | | | client 5260-0 |
| 20260526_071717 | C | GARAGE DU CENTRE | 12 RUE RAYMOND BATAILLE | 28190 | ST GEORGES SUR EURE | 0237267502 | 1/N | 003031150311 |
| 20260602_060623 | A | GGE CAILLON | LA HURIE | 28240 | ST VICTOR DE BUTHON | | | FF601WY |
| 20260603_081724 | D | SARL SNCE LEROY | 20 LA TUILERIE | 28190 | CHUISNES | 0237232868 | | 0303603-1 |
| 20260603_125001 | A | CARROSSERIE DE LA COLLINE | 10 RUE DE BEAUCE ZAC DE L EOLIE | 28190 | COURVILLE SUR EURE | | | CM739BA |
| 20260603_125006 | A | CS - AUTO SARL | 21 RUE MAURICE DUMAIS ZAC DE L…IENNE | 28190 | COURVILLE SUR EURE | | | 1JQ617RO2 |
| 20260603_125016 | A | CARROSSERIE DE LA COLLINE | 10 RUE DE BEAUCE ZAC DE L EOLIE | 28190 | COURVILLE SUR EURE | | | CM739BA |
| 20260603_125020 | A | GB MECA AUTO | 6 RUE DES CARREAUX | 28190 | CHUISNES | | | 1JQ687BSE |
| 20260603_125029 | D | COOK INOV | PARC D ACTIVITES L AULNAY | 28400 | NOGENT LE ROTROU | 0237527259 | 2/N | 0545803-0 |
| 20260603_125034 | D | COOK INOV | PARC D ACTIVITES L AULNAY | 28400 | NOGENT LE ROTROU | 0237527259 | 1/N | 0545803-0 |
| 20260604_161605 | B | LEDUC SARL | RUE DE SULLY | 28400 | NOGENT-LE-ROTROU | 0661786771 | 1/11 | 28B27268001 |
| 20260604_161607 | B | LEDUC SARL | RUE DE SULLY | 28400 | NOGENT-LE-ROTROU | 0661786771 | 6/11 | 28B27268001 |
| 20260604_161634 | B | LEDUC SARL | RUE DE SULLY | 28400 | NOGENT-LE-ROTROU | | 2/5 | 45A42374401 |

## Recommandation
Plutôt que 4 profils rigides, un **parser « France Alliance » générique et
tolérant** : (1) détecter le transporteur via mots-clés (table ci-dessus),
(2) localiser le bloc destinataire (ancre `DESTINATAIRE`, sinon bloc haut),
(3) extraire nom (recoller les noms sur 2 lignes) + rue + `CP VILLE` + tél +
`COLIS x/y`, (4) ignorer le bloc `EXPEDITEUR`. Le moteur spatial
`parseFromBlocksSpatial` existe déjà et aide via la position des blocs.

**Méthode** : la table ci-dessus sert de spec + jeu de tests. Le parser
(logique pure Dart) est **testable hors device** en lui injectant le texte
OCR simulé → on mesure l'exactitude avant de tester ML Kit sur appareil.
