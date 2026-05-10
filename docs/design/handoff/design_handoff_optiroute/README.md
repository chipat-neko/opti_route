# Handoff — OptiRoute (App livreur Android)

## Overview
OptiRoute is a mobile delivery-driver app concept (Android-first) that lets a courier add many addresses, optimize the delivery route to avoid revisiting the same area, and execute the tour with map view, turn-by-turn navigation, and stop-by-stop tracking. The proof-of-delivery itself happens **outside the app** (paper sheets with signature + stamp, plus the carrier's own app) — OptiRoute only records *Livré* (delivered) or *Échec* (failed).

## About the Design Files
The files in this bundle are **design references created in HTML/React (JSX)** — prototypes showing intended look and behaviour, **not production code to copy directly**. They render through Babel-in-the-browser and use stylised SVG placeholders (no real map tiles, no routing engine, no SDKs).

The task is to **recreate these designs in the target codebase's environment**. For an Android-native build that means Kotlin + Jetpack Compose using Material 3, with a real map SDK and a real route-optimization service. For cross-platform, Flutter or React Native are reasonable fits. Use the codebase's existing patterns and component library; lift only the visual decisions (tokens, layouts, copy) from the HTML.

## Fidelity
**High-fidelity.** Final colors, typography, spacing, copy and interaction states are decided. Pixel-perfect recreation is the goal.

## Screens (6)
All artboards are **412 × 892 px** (default Android frame; ~828 px content area between status bar and gesture nav).

### 01 · Carte en cours (`screen-map.jsx`)
Live tour map view.
- **Background:** stylised SVG roadmap (river, parks, highway, major+minor roads, building dots) — replace with the real map SDK in production.
- **Top:** floating search pill (52 px, radius 26) with menu icon, placeholder *"Rechercher une adresse…"*, voice button (40×40, ink fill, lime icon). Below: *Tournée #142 · en cours · 09:34* status chip (ink fill, white text, lime dot with halo).
- **Right rail (top 150 px):** vertical FAB stack — layers, locate, alerts (44 px circles, paper bg, soft shadow).
- **Bottom sheet:** rounded-top (28 px radius), drag handle, progress strip *07/24 · 17 restants* (lime fill), stop heading with index chip "07" (ink, mono), address title 18 px / 700, recipient row in cream-soft container with phone button, dual CTA (*Détails* outlined / *Démarrer la navigation* ink+lime).
- **Pins on map:** done = emerald with ✓; active = ink + animated lime halo; pending = paper with ink number.

### 02 · Liste de la tournée (`screen-list.jsx`)
Sortable list of all stops.
- Header: back / date kicker (*Mardi 12 mai*) / filter, big title *Tournée #142* (28/800), subtitle.
- Stat tile row in a paper card (radius 18): **24 Arrêts · 38.4 km · 2h41 Restant** (mono numerals).
- Optimised banner (ink card, lime icon tile, *−12.4 km · −47 min*, lime *−24%* chip).
- Segmented filter pills (*Tous · 24 / À faire · 17 / Faits · 6 / Échec · 1*).
- Stop rows: drag handle, status chip (done = emerald ✓, active = ink with lime numeral, pending = paper outlined), address 15/600, sub mono 12, optional tags (Fragile = peach, Avant 11h = amber, Pro = cream-soft, Signature = ink). Active row has 3 px lime left rail and `#FFFDF4` bg.
- FAB *Ajouter un arrêt* (ink + lime, bottom-right).
- Bottom action bar: bolt button (outlined) + ink CTA *Reprendre la tournée*.

### 03 · Navigation guidée (`screen-navigation.jsx`)
Dark-mode turn-by-turn.
- Dark map (`#1B2520` land, `#13313F` water, `#3A4540` roads with `#5A6862` dashed lane markings).
- Top maneuver card (ink, radius 22): big arrow icon (lime), *120 m* mono in lime, *Tournez à droite sur rue du Faubourg St-Antoine*.
- "Then" hint chip below-left, speed-limit roundel (white circle, red 4 px ring, *50* mono) below-right.
- Hazard banner (amber): *Travaux signalés · 800 m*.
- Bottom HUD card (paper, radius 22): **09:38 Arrivée · 4 min Restant · 0.4 km Distance** + red square stop button. Quick actions row underneath: Signaler / Mute / 2D / Détails (translucent ink pills with blur).

### 04 · Ajouter des arrêts (`screen-add.jsx`)
Multi-method input.
- Header close + *Tournée #142* kicker, title *Ajouter des arrêts*.
- Search field (56 px, ink 1.5 px outline, radius 16) with caret animation, lime voice button.
- Suggestion row underneath highlights the matched substring.
- 2×2 grid of input methods: **Scanner étiquette** (dark/featured), **Photo bordereau**, **Coller une liste**, **Dicter** — radius 18, icon tile + title + sub.
- Pending stops list (3 chips with pin icon, address, sub, close button).
- Bottom CTA bar: *3 nouveaux arrêts · +5.2 km estimé* + ink+lime *Optimiser & insérer* button.

### 05 · Optimiser l'itinéraire (`screen-optimize.jsx`)
Before/after comparison.
- Header back / *Étape 2 / 3* kicker / Aide.
- Title *Itinéraire optimisé* + 1-line description.
- Two side-by-side mini-maps (radius 16, ink border): **Avant** (faint zigzag route) / **Après** (clean lime loop, *−24%* badge).
- Hero gain card (ink + lime): mono *−47 min · −12.4 km*.
- Comparison table (paper card, radius 16, divided rows): Distance / Durée / Demi-tours / Carburant / CO₂ — each row shows before (struck-through), after (bold), delta chip (emerald-soft for gains).
- Constraint chips: *Avant 11h · 3 arrêts*, *Fragile en haut*, *Sens unique*, *Éviter A86*, *Retour dépôt 12:30*.
- Bottom CTAs: *Réajuster* outlined / *Appliquer cet ordre* ink+lime.

### 06 · Détail arrêt (`screen-delivery.jsx`)
One client, N sender sheets, two-button outcome.
- Hero map snippet (160 px) with route into pin "7", back button overlay, *Arrêt 07/24* badge.
- Address card overlapping map (margin-top -28): kicker *Client*, address 20/800, sub line, ink "07" chip; **Code accès** strip in lime with mono code *4521A*.
- **Feuilles à livrer** section: top summary *3 expéditeurs · 6 colis · 7.2 kg*. Then 3 sheet cards stacked, each:
  - Header strip (active = ink+lime, idle = cream-soft+mute) — *Feuille · expéditeur N/3* + ref code (mono).
  - Body: kicker *Expéditeur* + sender name; 3-column stat grid (Colis / Poids kg / Contact — when contact is absent the cell is dashed border + "—").
  - Status pill: *En cours* (ink+lime) or *À faire* (cream-soft+mute).
- Note card (paper, dashed ink-line border): *Consigne du livreur*.
- Bottom action bar: **Échec** (60 px, red 1.5 outline, paper bg, flex 1) + **Livré** (60 px, emerald fill, white, 16/800, flex 1.6, soft emerald shadow). These are the only outcomes — no signature/photo/scan capture.

## Interactions & Behavior
- Map screen: tap a pin to open a stop sheet; the bottom sheet should be draggable to a half/full state.
- List screen: long-press + drag handle to reorder; swipe row to mark done/fail (not in mock — design TBD).
- Navigation: maneuver card updates as the route progresses; the speed-limit roundel turns red when over the limit (not visualised in this mock).
- Add stops: voice and scan flows feed into the pending chip list; tapping *Optimiser & insérer* triggers the optimization service and lands on screen 05.
- Optimization: tapping *Appliquer cet ordre* writes the new order to the tour.
- Detail: *Livré* and *Échec* are the only state-change actions. *Échec* should open a follow-up reason picker (not in this mock — recommend a small bottom sheet with: absent / refusé / adresse introuvable / autre).
- All chips with `tag` semantic (Fragile, Avant 11h, Pro, Signature, etc.) come from the order data.

## State Management
Suggested data model:
```ts
type Tour = {
  id: string;            // "#142"
  date: string;          // "2026-05-12"
  depot: string;
  stops: Stop[];         // ordered after optimization
};

type Stop = {
  id: string;
  index: number;
  address: { line1: string; line2?: string; postal: string; city: string; accessCode?: string };
  geo: { lat: number; lng: number };
  status: "pending" | "active" | "done" | "fail";
  etaArrival?: string;   // "09:38"
  distanceFromPrev?: number; // km
  driverNote?: string;
  sheets: Sheet[];       // 1+ per stop (one per carrier/expéditeur)
  contact?: { name?: string; phone?: string };
};

type Sheet = {
  id: string;
  sender: string;        // "Chronopost · La Poste"
  refCode: string;
  contact?: { name?: string };
  packages: number;
  weightKg: number;
};

type TourMetrics = {
  totalKm: number; totalDurationMin: number;
  optimizedFromKm: number; optimizedFromMin: number;  // for the "−24%" badge
  uTurns: number; fuelL: number; co2Kg: number;
  constraints: string[];
};
```

State transitions:
- `pending → active` when driver taps *Démarrer la navigation*.
- `active → done` on *Livré*.
- `active → fail` on *Échec* (with reason).
- Reorder via drag rewrites `stops[].index`.

## Design Tokens
Source of truth: `tokens.jsx`.

```js
// Surfaces
cream:        '#F5F3EE'   // app background
creamSoft:    '#EFEAE0'   // tile background, recipient row
paper:        '#FFFFFF'
ink:          '#0E1410'   // primary surface dark / text
inkSoft:      '#1A211C'
inkLine:      '#E3DED1'   // dividers, dashed borders
divider:      'rgba(14,20,16,0.08)'

// Brand
emerald:      '#0E7C5A'   // success / Livré CTA
emeraldDark:  '#0A5C43'
emeraldSoft:  '#D5EBE0'
lime:         '#B8F24A'   // accent — active route, CTA fg on dark
limeDark:     '#86C72A'
amber:        '#F2A341'   // warnings, time-window pills
red:          '#D9483B'   // failure / stop / Échec

// Map (placeholder palette)
mapLand:      '#EAE6DD'
mapLandAlt:   '#E0DAC9'
mapWater:     '#C4D8E5'
mapPark:      '#D6E2C7'
mapRoad:      '#FFFFFF'
mapHwy:       '#F8DCA0'
mapStroke:    '#D4CCB8'

// Text
text:         '#0E1410'
textMute:     '#5C6660'
textFaint:    '#8A9089'
```

Typography:
- **UI:** Manrope 400/500/600/700/800 (Google Fonts)
- **Numerics / mono:** JetBrains Mono 400/500/600/700

Spacing scale (px): 4, 6, 8, 10, 12, 14, 16, 18, 22, 28.
Radius scale (px): 6, 8, 10, 12, 14, 16, 18, 22, 26, 28 (pill = height/2).
Shadow: `0 6px 20px rgba(14,20,16,0.08)` for paper cards · `0 4px 14px rgba(14,20,16,0.14)` for FABs · `0 -10px 40px rgba(14,20,16,0.10)` for bottom sheets.

## Production Concerns (non-design but needed)
- **Map SDK:** Mapbox / MapLibre (open-source) / Google Maps SDK. The placeholder SVG is for design only.
- **Route optimization (TSP/VRP):** Google OR-Tools as a backend service, OSRM/GraphHopper for self-hosted, or Mapbox Optimization API / HERE Tour Planning. Constraints listed in screen 05 (time windows, package fragility, return-to-depot) need to be modelled server-side.
- **Turn-by-turn:** Mapbox Navigation SDK or HERE Navigate. The maneuver card UI (screen 03) is fed by the SDK's step events.
- **Address ingestion:** OCR for "Photo bordereau" (Google ML Kit Text Recognition / AWS Textract), barcode/QR for "Scanner étiquette", paste-list parsing (regex + geocoding service), voice via Android `SpeechRecognizer`.
- **Offline:** the app must continue to display the tour and accept Livré/Échec when offline; sync queue when network returns.

## Files in this bundle
- `OptiRoute App.html` — entry point that loads all JSX files via Babel.
- `OptiRoute App (standalone).html` — same, bundled into one self-contained file (works offline, double-click to open).
- `tokens.jsx` — colors, fonts, icon set.
- `map.jsx` — SVG map tiles, route polyline, pin marker, vehicle marker.
- `screen-map.jsx`, `screen-list.jsx`, `screen-add.jsx`, `screen-optimize.jsx`, `screen-navigation.jsx`, `screen-delivery.jsx` — one per artboard.
- `design-canvas.jsx`, `android-frame.jsx`, `tweaks-panel.jsx` — scaffolding components.

## Suggestions for next iterations
- Failure-reason picker bottom sheet (after *Échec*).
- End-of-tour summary screen (km, time, deliveries, failures, CO₂).
- Onboarding (3 screens: scan a sheet → review tour → start).
- Supervisor / dispatcher web view (out of scope here).
- Offline indicator + sync queue UI.
