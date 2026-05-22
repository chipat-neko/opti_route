# Architecture opti_route

Document d'onboarding pour developpeurs (et reference pour Noah). Decrit
l'architecture, les conventions, et les flows critiques.

Derniere mise a jour : 2026-05-22 (Sprint 3.D refactor).

## Stack

| Couche | Technologie |
|---|---|
| **UI** | Flutter (Material) avec Riverpod 3 pour la gestion d'etat |
| **DB locale** | Drift 2.33 (SQLite) - schema v34 |
| **Backend cloud** (optionnel) | Supabase (Auth + Storage + Edge Functions) |
| **OCR** | Google ML Kit Text Recognition (on-device, gratuit) |
| **Code-barre** | mobile_scanner 7 (camera live) |
| **Routing** | OpenRouteService API + flutter_map (OSM) |
| **Geocoding** | API BAN (gratuit, ~30k req/jour) + cache local |

## Disposition des dossiers

```
opti_route/
├── app/                          # Application Flutter
│   ├── lib/
│   │   ├── data/                 # Services + repos + tables Drift
│   │   │   ├── tables/           # Definitions Drift (1 fichier/table)
│   │   │   ├── *_repository.dart # CRUD pur sur 1 table
│   │   │   ├── *_service.dart    # Logique metier composee
│   │   │   ├── *.g.dart          # Genere par drift_dev (ne pas editer)
│   │   │   ├── bordereau_*       # Pipeline OCR bordereaux
│   │   │   └── ocr_*             # Pipeline OCR generique
│   │   ├── providers/            # Riverpod providers (orchestration DI)
│   │   ├── screens/              # Ecrans (1 fichier/ecran principal)
│   │   │   └── <ecran>/          # Sous-widgets quand l'ecran est gros
│   │   ├── widgets/              # Widgets reutilises cross-screens
│   │   └── theme/                # Tokens design + palettes
│   ├── test/                     # Tests unit + widget + integration
│   └── integration_test/         # Tests e2e (camera, ML Kit reel)
├── docs/                         # Site web statique + design handoff
│   ├── website/                  # GitHub Pages (chipat-neko.github.io)
│   ├── design/                   # Tokens + maquettes Claude Design
│   └── supabase-schema.sql       # Schema cloud Postgres
├── supabase/                     # Edge Functions + config Supabase
│   └── functions/<name>/         # 1 dossier/function
└── bordereaux_test/              # Photos test OCR + scripts analyse (gitignore)
```

## Pattern d'architecture : Data / Provider / UI

```
┌─────────────────────────────────────────────────────────────────┐
│  UI (screens/, widgets/)                                        │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ ConsumerStatefulWidget / ConsumerWidget                    │ │
│  │   ref.watch(xxxProvider) -> AsyncValue<T> / Stream<T> / T  │ │
│  │   ref.read(xxxRepositoryProvider).method()                 │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│  Providers (providers/)                                         │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ final xxxRepositoryProvider = Provider<XxxRepository>(    │ │
│  │   (ref) => XxxRepository(ref.watch(appDatabaseProvider))  │ │
│  │ );                                                         │ │
│  │ final xxxStreamProvider = StreamProvider<List<T>>(...)     │ │
│  └────────────────────────────────────────────────────────────┘ │
└───────────────────────────────┬─────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────┐
│  Data (data/)                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │ XxxRepository : CRUD pur sur 1 table Drift                 │ │
│  │ XxxService    : logique composee (lit/ecrit plusieurs       │ │
│  │                   tables, fait du calcul, appelle des APIs) │ │
│  │ AppDatabase   : singleton Drift, gere migrations            │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
```

**Regle d'or** : un screen NE FAIT PAS de SQL direct. Il passe par un
repository via un provider. Cela rend les screens testables sans DB.

## Convention de nommage

- `XxxTable` (dans `tables/`) : definition Drift d'une table
- `XxxRepository` : CRUD CRUD CRUD basique sur 1 table
- `XxxService` : logique metier qui compose plusieurs repos
- `xxxProvider` : Riverpod provider exposant un service ou un stream
- `XxxScreen` : ecran principal (Scaffold + AppBar)
- `_XxxSection`, `_XxxRow` : widgets prives a un screen
- `XxxWidget` : widget reutilise (dans `widgets/`)
- `kXxx` : constante globale (cf `app_constants.dart`)

## Pipeline OCR bordereaux (Sprint 1 + 2 refactor)

```
┌──────────┐    ┌──────────────┐    ┌──────────────┐    ┌──────────┐
│ ImagePic │───▶│ ImagePrepro  │───▶│ OcrService   │───▶│ Parser   │
│ ker      │    │ cessService  │    │ (ML Kit)     │    │ MESEXP/  │
│          │    │ (enhance +   │    │              │    │ Chrono/  │
│          │    │  detectBlur) │    │              │    │ Colissi  │
└──────────┘    └──────────────┘    └──────────────┘    └────┬─────┘
                                                              │
              ┌────────────────────────────┬─────────────────▼─────┐
              │                            │                       │
       ┌──────▼──────┐         ┌──────────▼─────────┐    ┌────────▼──────┐
       │ Bordereau   │         │ BordereauText      │    │ Bordereau     │
       │ Patterns    │         │ Filters            │    │ FormatDetector│
       │ (regex)     │         │ (helpers exclude)  │    │ (enlev/livr)  │
       └─────────────┘         └────────────────────┘    └───────────────┘
                                                              │
                          ┌──────────────────────────────────▼─────┐
                          │   BordereauExtraction (model)          │
                          │   - nomDestinataire, rue, cp, ville     │
                          │   - format (enlevement / livraison)    │
                          │   - confidence (high / low / none)     │
                          │   - source (parserLocal / clientMemory │
                          │                / llmGemini)            │
                          └─────────────────────┬──────────────────┘
                                                │
              ┌─────────────────────────────────▼─────────────────┐
              │                                                   │
       ┌──────▼─────────┐  ┌──────────────────┐  ┌───────────────▼───────┐
       │ ClientMemory   │  │ OcrLlmEnhance    │  │  AutoDetectionCard    │
       │ Service        │  │ Service          │  │  (UI : carte verte    │
       │ (fuzzy carnet) │  │ (Gemini)         │  │   avec badge source)  │
       └────────────────┘  └──────────────────┘  └───────────────────────┘
```

### Modules cles (apres refactor Sprint 1 + 2)

| Fichier | Role |
|---|---|
| [bordereau_patterns.dart](app/lib/data/bordereau_patterns.dart) | Regex centralisees (CP, ville, tel, rues, tracking, etc) |
| [bordereau_text_filters.dart](app/lib/data/bordereau_text_filters.dart) | Helpers de rejet (labels, rues, villes, transporteurs) |
| [bordereau_format_detector.dart](app/lib/data/bordereau_format_detector.dart) | Detection ENLEVEMENT vs LIVRAISON |
| [bordereau_parser.dart](app/lib/data/bordereau_parser.dart) | Orchestration + parseFromBlocks (ciblage bbox) |
| [chronopost_bordereau_parser.dart](app/lib/data/chronopost_bordereau_parser.dart) | Specifique etiquettes Chronopost |
| [colissimo_bordereau_parser.dart](app/lib/data/colissimo_bordereau_parser.dart) | Specifique etiquettes Colissimo / La Poste |
| [ocr_service.dart](app/lib/data/ocr_service.dart) | ML Kit text recognition + rotations 0/90/180/270 |
| [image_preprocess_service.dart](app/lib/data/image_preprocess_service.dart) | EXIF + contraste + crop + detectBlur (Sprint 2.C) |
| [client_memory_service.dart](app/lib/data/client_memory_service.dart) | Fuzzy match carnet adresses (Sprint 2.A) |
| [ocr_llm_enhance_service.dart](app/lib/data/ocr_llm_enhance_service.dart) | Edge Function Gemini (PR #202, pas deployee) |

## Migrations Drift

Schema actuel : **v34**. Toute modification de table = augmenter `schemaVersion`
+ ajouter un bloc `if (from < N)` dans `onUpgrade`. Voir
[database.dart](app/lib/data/database.dart) pour les patterns.

**Reglee critique** : SQLite refuse les `DEFAULT` non-constants dans `ADD
COLUMN`. Solution : `DEFAULT 0` + `UPDATE` manuel pour le backfill. Cf bloc
v32 dans database.dart.

## Backend cloud (optionnel)

Le projet fonctionne 100% offline par defaut. Le cloud (Supabase) est
**opt-in** :

| Build | Comportement |
|---|---|
| Sans `--dart-define-from-file=cloud.env.json` | Mode local-only, section "Sync cloud" cachee |
| Avec credentials | Auth + sync tournees/coequipiers + Edge Function OCR |

**Tables sync** (cf `Tournees.cloudId`, `Stops.cloudId`, etc) : UUID v4
genere local au 1er push, sert d'idempotence. Last-write-wins via
`updatedAt`.

## Tests

| Type | Couverture |
|---|---|
| **Unit (data)** | 73% (48/66 fichiers testes) ✅ |
| **Integration** | 2 fichiers : `tournee_flow_test`, `bordereau_scan_flow_test` |
| **Integration_test (camera reelle)** | `bordereau_batch_eval_test` (38 images) |
| **Widget** | 3% (3/81 ecrans testes) ❌ axes amelioration prioritaire |

Lancer tous les tests :
```bash
cd app
flutter test
```

Lancer un batch eval OCR sur device reel :
```bash
flutter test integration_test/bordereau_batch_eval_test.dart -d <device-id> --dart-define-from-file=cloud.env.json
```

## Conventions Git

- Trunk-based : branche `main` toujours deployable
- PRs feature : `feat/`, `fix/`, `refactor/`, `chore/`
- Conventional Commits : `feat(scope): description`
- Jamais de push direct sur `main`
- Squash merge par defaut

## Build

| Commande | Output |
|---|---|
| `flutter build apk --release` | APK sans cloud, mode local-only |
| `flutter build apk --release --dart-define-from-file=cloud.env.json` | APK avec Supabase actif |
| `flutter test` | Tests unit + widget |
| `flutter analyze` | Lint statique (doit etre 0 issue) |

## Ressources

- **Audit complet 2026-05-22** : voir le rapport dans la conversation
  qui a genere ce fichier (Sprint 3.D)
- **Plan OCR 85% win rate** : `docs/plan-ocr-85pct.md`
- **Schema cloud** : `docs/supabase-schema.sql`
- **Memory Claude** : `~/.claude/projects/d--opti-route/memory/`
