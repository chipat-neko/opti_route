# Crash reporting — opti_route

Politique courante : **pas de SDK tiers** (Sentry, Crashlytics, Bugsnag…). On utilise **Android Vitals**, le système intégré de Play Console qui collecte les ANR / crashes natifs **sans permission supplémentaire ni dépendance dans l'APK**.

## Pourquoi pas Sentry / Crashlytics

1. **Pas de CB** : philosophie projet (cf `docs/plan_free.md`). Sentry free tier est OK mais demande la création d'un compte cloud externe.
2. **Privacy policy** : on a écrit "aucun crash reporting cloud" dans `docs/legal/privacy-policy.md`. Ajouter Sentry = modifier la promesse.
3. **Pas de dépendance** : sentry_flutter ajoute ~1.5 MB à l'APK + 2 plugins natifs + une dépendance réseau.
4. **Pas de permission** : pas besoin de demander `INTERNET` pour autre chose que les APIs existantes (BAN / ORS / Photon).

## Android Vitals : ce que Google fournit gratuitement

Play Console → onglet **Qualité → Android Vitals** une fois l'app publiée. Tu trouves automatiquement :

- **Plantages** (crashes natifs Dart + Java) avec stack trace dé-obfusquée si on upload le ProGuard mapping
- **ANR** (Application Not Responding) : freezes > 5s
- **Démarrages lents** (cold start > 5s, warm start > 2s)
- **Consommation batterie** (wake locks, alarmes)
- **Statistiques par device / API level**

Données collectées **par Google**, pas par toi — donc la promesse "pas de tracker dans l'app" reste vraie. Les utilisateurs ont déjà consenti à Android Vitals via Google Play.

## Comment activer

**Rien à coder**. Android Vitals se déclenche automatiquement dès que :
1. L'app est publiée sur Play Store (même en internal testing).
2. Les utilisateurs ont accepté les diagnostics Android (par défaut activé chez 95% des utilisateurs Android).

## Améliorer la dé-obfuscation des stack traces

Pour que les stack traces Dart soient lisibles dans Android Vitals, il faut **uploader le mapping** lors du build release :

```powershell
cd d:\opti_route\app
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
```

Puis dans Play Console → Test interne → release → Symbols → upload le contenu de `build/symbols/`.

Sans cette étape, les crashes Dart apparaîtront sous forme de symboles obfusqués `_$abc()` au lieu des vrais noms de fonctions.

## Logs locaux pour le debug terrain

Pour les bugs qui n'arrivent **pas** en crash mais en mauvais comportement (ex : géocodage qui rate, OCR qui se trompe), on log déjà via `debugPrint` avec des tags identifiables :

- `OCRDUMP` : dumps OCR ML Kit (cf `docs/journal-de-bord.md`)
- `GEOCODE` : résultats géocodage cascade
- `OPTI` : payloads ORS

Pour les capturer pendant une vraie tournée, brancher le tel sur le PC :

```powershell
adb logcat -s flutter:V | Out-File -FilePath bug-2026-05-XX.log
```

Puis trier les lignes pertinentes après coup.

## Quand re-considérer Sentry / Crashlytics

Si dans 6 mois on a :
- 100+ utilisateurs réels
- Plusieurs bug reports remontés par mail qu'on n'arrive pas à reproduire en dev
- Besoin de breadcrumbs (séquence d'actions avant crash) que Android Vitals ne donne pas

Alors **considérer Sentry** (free tier 5k events/mois) en l'ajoutant proprement :
1. Modifier la privacy policy pour mentionner Sentry + son traitement
2. Demander consentement explicite dans Paramètres (toggle "Aider à améliorer l'app via Sentry")
3. Build avec DSN via `--dart-define`
4. Documenter le DSN comme secret CI

Tant qu'on est à <100 utilisateurs, Android Vitals suffit largement.
