# Signing config release — procédure

> Comment générer la keystore Android nécessaire pour publier opti_route sur le Play Store, et la connecter au build Gradle.

L'app est actuellement signée avec les **clés debug** d'Android par défaut, ce qui est **pas publiable** sur le Play Store. Cette procédure crée une keystore propre une bonne fois pour toutes et la branche au build release.

## 1. Générer la keystore

Sur la machine de Noah (Windows, terminal PowerShell ou Git Bash), avec le JDK 17 déjà installé (Android Studio l'embarque) :

```bash
keytool -genkey -v \
  -keystore d:/opti_route/app/android/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

`keytool` est dans `${ANDROID_STUDIO}/jbr/bin/` ou dans le JDK système.

Réponses aux questions :
- Mot de passe keystore : **choisis-en un fort et note-le quelque part**. Tu en auras besoin à chaque release. Le perdre = ne plus pouvoir publier de mise à jour Play Store sous le même bundle ID.
- CN/OU/O/L/ST/C : tes infos (ou laisse vide si privé). Le CN apparaîtra dans le certificat.
- Mot de passe alias : peut être le même que le keystore.

Fichier généré : `app/android/upload-keystore.jks` (déjà gitignored).

**Backup immédiat** de ce fichier `.jks` quelque part hors du repo (Drive privé, clé USB...). Pas de doublon = pas de récupération possible.

## 2. Créer `key.properties`

Crée `app/android/key.properties` (déjà gitignored) avec :

```
storePassword=MOT_DE_PASSE_KEYSTORE
keyPassword=MOT_DE_PASSE_ALIAS
keyAlias=upload
storeFile=upload-keystore.jks
```

`storeFile` est **relatif au dossier `android/app/`** (où vit le `build.gradle.kts`).

## 3. Vérifier que ça compile

```bash
cd app
flutter build apk --release
flutter build appbundle --release
```

Si la keystore est bien lue, l'output contient :

```
Built build/app/outputs/bundle/release/app-release.aab (signed with upload key)
```

Si tu vois encore `Signing with the debug keys`, c'est que le `key.properties` n'est pas trouvé. Vérifie son emplacement et son orthographe.

## 4. Pour publier

L'AAB à uploader sur Play Console est `app/build/app/outputs/bundle/release/app-release.aab`.

Le SHA-1 du certificat (utile pour configurer Firebase, App Links, etc.) :

```bash
keytool -list -v -keystore app/android/upload-keystore.jks -alias upload
```

## Récupération en cas de perte

Si tu perds la keystore, Google Play offre **Play App Signing** (un service qui re-signe les uploads avec une clé Google détenue par eux). Active-le **dès le premier upload** : il te permettra de générer une nouvelle upload-keystore si tu perds celle-ci, sans rupture pour les utilisateurs existants.

Sans Play App Signing + perte de keystore = obligation de republier sous un nouveau bundle ID (donc nouvelle app, perte des utilisateurs existants).
