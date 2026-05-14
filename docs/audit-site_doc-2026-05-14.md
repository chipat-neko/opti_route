# Audit cohérence `site_doc/` ↔ app — 2026-05-14

Audit des 15 pages HTML statiques du site vitrine (`site_doc/`) pour
détecter les divergences avec l'état réel de l'app (v2.4.4+2022).

## Corrigé dans ce commit

| Page              | Section       | Diff                                                    |
|-------------------|---------------|---------------------------------------------------------|
| `install-apk.html`| Variantes APK | Tailles obsolètes (60/55/98 MB) -> réelles (39/12/57 MB) |
| `features.html`   | Sécurité      | "Backup manuel CSV+vCard" -> ajoute PIN+biométrie, backup zip portable, restore differé, auto-backup hebdo/mensuel |

## Cohérent (rien à changer)

| Page                | État                                                    |
|---------------------|---------------------------------------------------------|
| `index.html`        | Liste des écrans à jour                                  |
| `changelog.html`    | Entrée v2.3.0+2016 ajoutée au commit `e5e6baa`           |
| `roadmap.html`      | Plan à long terme, OK                                    |
| `dashboard.html`    | Outil CSV, indépendant de l'app                          |
| `entreprise.html`   | Calculateur ROI, indépendant                             |
| `faq.html`          | Réponses générales                                       |
| `guide-csv.html`    | Format CSV stable                                        |
| `gallery.html`      | Screenshots (à régénérer manuellement si on veut)        |
| `mentions-legales.html` | Mentions légales                                    |
| `404.html`          | Page d'erreur                                            |

## Améliorations suggérées (non bloquantes)

### features.html

- **Section OCR** : mentionner explicitement la Phase A faite
  (rotations re-OCR, tolerance Levenshtein, validateur BAN). Ajouter
  une ligne "Instrumentation OCRSTATS exportable en CSV" qui vient
  d'être ajoutée dans cette session.
- **Section Stats** : potentiellement ajouter une mention de la
  facturation (cumul euros, tarif/km/colis/arret) qui est dans le
  mode chef d'équipe.

### install-apk.html

- L'APK universel (~57 MB) **ne marche pas** actuellement à cause d'un
  bug Gradle splits ABI qui n'inclut pas `libsqlite3.so` dans le
  universal. Recommander **arm64-v8a** ou **armeabi-v7a** selon le
  device, **pas universal**. Ou rebuild universal sans splits.

### gallery.html

- Les screenshots datent probablement de versions antérieures
  (avant le refactor massif et l'ajout backup / Mes backups / OCR
  stats). À régénérer quand on aura le temps.

### roadmap.html

- Vérifier que la roadmap reflète l'état actuel : OCR Phase A est
  marquée comme faite dans le code mais l'instrumentation baseline
  vient juste d'être ajoutée -- mettre à jour la roadmap pour
  pointer vers Phase B (pré-traitement image) comme prochain
  chantier OCR.

## Méthode d'audit utilisée

1. `grep -rin "backup\|biom\|PIN\|version" site_doc/` -> identifier les
   mentions sensibles à l'évolution
2. Cross-check avec `git log` + état actuel des fichiers `lib/`
3. Comparer avec le code de chaque feature mentionnée

## A relancer

Cet audit est valable au **2026-05-14**. À refaire après chaque session
qui touche aux features visibles (sécurité, backup, OCR, exports) ou
qui modifie la taille de l'APK build.
