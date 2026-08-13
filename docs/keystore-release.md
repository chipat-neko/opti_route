# Signing config release — procédure

> Où vit la keystore Android de publication, comment le build Gradle la trouve, et quoi vérifier avant d'envoyer un AAB au Play Store.

## 0. État actuel (en un coup d'œil)

- La keystore **existe** : `upload-keystore.jks`, alias `upload`, accompagnée d'un `key.properties` qui contient les mots de passe **en clair**.
- Ces deux fichiers sont **gitignored** — deux fois plutôt qu'une : [`app/.gitignore`](../app/.gitignore) et [`app/android/.gitignore`](../app/android/.gitignore). Ils n'ont **jamais** été commités (vérifiable : `git log --all --full-history -- "*.jks" "*key.properties"` ne renvoie rien).
- Ils vivent en revanche encore **dans l'arbre du repo** (`app/android/app/upload-keystore.jks`, `app/android/key.properties`), ce qui reste exposé à un `git add -f`, un zip du dossier ou une sauvegarde de disque. La section 2 explique comment les déplacer sans rien casser.

## 1. Générer la keystore (si tu repars de zéro)

Sur une machine avec le JDK 17 (Android Studio l'embarque) :

```bash
keytool -genkey -v \
  -keystore "$USERPROFILE/keystores/opti_route/upload-keystore.jks" \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

`keytool` est dans `${ANDROID_STUDIO}/jbr/bin/` ou dans le JDK système.

Réponses aux questions :

- Mot de passe keystore : **fort, et noté dans un gestionnaire de mots de passe**. Le perdre = ne plus pouvoir publier de mise à jour sous le même bundle ID (sauf Play App Signing, voir plus bas).
- CN/OU/O/L/ST/C : tes infos, ou vide si tu préfères. Le CN apparaît dans le certificat.
- Mot de passe alias : peut être le même que celui de la keystore.

**Backup immédiat** du `.jks` sur un support distinct (Drive privé chiffré, clé USB rangée ailleurs). Pas de doublon = pas de récupération possible.

## 2. Emplacement des fichiers : hors de l'arbre du repo

L'emplacement recommandé est `~/keystores/opti_route/` (soit `%USERPROFILE%\keystores\opti_route\` sous Windows) :

```
~/keystores/opti_route/
├── key.properties
└── upload-keystore.jks
```

avec un `key.properties` de la forme :

```
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=upload-keystore.jks
```

Le build Gradle ([`app/android/app/build.gradle.kts`](../app/android/app/build.gradle.kts)) cherche le `key.properties` dans cet ordre, **premier trouvé gagne** :

| # | Emplacement | Usage |
|---|---|---|
| 1 | `$OPTIROUTE_KEY_PROPERTIES` (chemin complet du fichier) | CI, machine atypique |
| 2 | `~/keystores/opti_route/key.properties` | **recommandé** |
| 3 | `app/android/key.properties` | historique, encore supporté |

`storeFile` peut être absolu, ou relatif. S'il est relatif, il est cherché d'abord **à côté du `key.properties` retenu**, puis dans `app/android/app/` (l'ancienne convention). Les deux dispositions fonctionnent donc, ce qui permet de migrer une machine à la fois.

Au lancement d'un build release, Gradle affiche la ligne :

```
Signing release : key.properties lu depuis <chemin>
```

C'est le moyen le plus simple de vérifier quel fichier a réellement été pris.

### Migrer une machine

```bash
mkdir -p ~/keystores/opti_route
mv app/android/app/upload-keystore.jks ~/keystores/opti_route/
mv app/android/key.properties          ~/keystores/opti_route/
```

Puis relance un build release et vérifie la ligne `Signing release :` ci-dessus. Ne supprime rien tant que tu n'as pas confirmé qu'un `.jks` de secours existe ailleurs.

Si aucune configuration n'est trouvée, le build release retombe sur les **clés debug** (bien pour tester, **impubliable** sur le Play Store) — le message `Signing with the debug keys` apparaît alors dans la sortie.

## 3. Confidentialité : strip des fixtures avant tout build livré

⚠️ **À ne pas oublier avant un AAB Play Store.**

`app/assets/test_bordereaux/` (~24 Mo) contient des **scans de bordereaux clients réels** (noms, adresses, téléphones). Ces fixtures ne servent qu'au batch eval OCR (`integration_test/bordereau_batch_eval_test.dart`). Sans strip, elles sont **embarquées dans l'artefact distribué** et extractibles de l'APK/AAB.

Les chemins de build déjà protégés :

| Chemin | Strip |
|---|---|
| `deploy-web.yml`, `build-windows.yml`, job `build-web` de `ci.yml` | `sed -i '/test_bordereaux/d' pubspec.yaml` |
| `scripts/build-and-install.ps1` (APK, et AAB avec `-Bundle`) | strip + restauration dans un `finally` |
| `.github/workflows/build-android.yml` (`workflow_dispatch`) | idem `sed` |

**Ne construis donc pas l'AAB à la main.** Utilise l'un de ces deux chemins :

```powershell
# Depuis la racine du repo — strip + build + restauration du pubspec
pwsh scripts/build-and-install.ps1 -Bundle
```

ou déclenche le workflow **Build Android (AAB)** depuis l'onglet Actions de GitHub (`workflow_dispatch`), qui produit l'AAB en artefact.

Si tu builds tout de même manuellement, retire la ligne `- assets/test_bordereaux/` du `pubspec.yaml` avant, et remets-la après.

## 4. Vérifier que la signature est bonne

```bash
cd app
flutter build appbundle --release
```

La sortie doit contenir :

```
Built build/app/outputs/bundle/release/app-release.aab (signed with upload key)
```

Si tu vois `Signing with the debug keys`, c'est que le `key.properties` n'a pas été trouvé : relis la ligne `Signing release :` (ou son absence) et la table de résolution ci-dessus.

Le SHA-1 du certificat (utile pour Firebase, App Links…) :

```bash
keytool -list -v -keystore ~/keystores/opti_route/upload-keystore.jks -alias upload
```

## 5. Publier

L'AAB à envoyer sur la Play Console est `app/build/app/outputs/bundle/release/app-release.aab`.

Avant l'upload, vérifie que les fixtures ne sont pas dedans :

```bash
unzip -l app/build/app/outputs/bundle/release/app-release.aab | grep test_bordereaux
```

Cette commande ne doit **rien** renvoyer.

## Récupération en cas de perte

Google Play propose **Play App Signing** : Google détient la clé de signature finale et re-signe les uploads. Active-le **dès le premier upload** — il permet de régénérer une upload-key perdue sans rupture pour les utilisateurs déjà installés.

Sans Play App Signing, perdre la keystore oblige à republier sous un nouveau bundle ID (nouvelle app, perte de la base installée).
