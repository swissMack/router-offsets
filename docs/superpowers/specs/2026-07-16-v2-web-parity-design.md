# RouterOffsets v2 — Web-App Parity Design

**Date:** 2026-07-16
**Status:** Approved (pending spec review)
**Supersedes/extends:** `2026-07-16-ios-app-design.md` (the metric-only v1 port)

## Goal

Evolve the native SwiftUI app to full feature parity with the **current** web app
(`index.html`, the v2 upload now on `main`). The v1 port matched an older web app; the
web app has since gained imperial units, a forward/reverse mode, depth/corner helpers, a
"My Kit" filter, saved setups, unit-toggle tables, and dynamic inlay highlights.

The authoritative source of all logic is `index.html` (lines cited throughout). Core
offset math is unchanged from v1.

## Decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Feature scope | **All** of: imperial + dual-unit, forward/reverse + depth + corners, My Kit filter, saved setups |
| Custom sizes | **Include** a "Custom…" entry (value + mm/in) for bush & cutter |
| App layout | **5th "Kit" tab**; saved setups live on the Calculator tab |
| Default unit | **Metric is the default everywhere** (bush m24, cutter m8, mm inputs, Metric chart); imperial is opt-in |
| Testing | Pure logic via `swift test` parity; UI compile-gated + on-device smoke |
| Persistence | `UserDefaults` (mirrors web `localStorage`) |

## Data Model & Formatting

Ported from `index.html:265-296`.

### Units & sizes
```swift
enum UnitSystem: String, Codable { case metric = "m", imperial = "i" }

struct Size: Identifiable, Hashable, Codable {
    let id: String        // "m24" or "i5-16"
    let mm: Double
    let label: String     // "24 mm" or "5/16″"
    let system: UnitSystem
    static func metric(_ v: Double) -> Size
    static func imperial(_ n: Int, _ d: Int) -> Size   // mm = 25.4 * n/d; label per web (d==1 → n″)
}
```
- `mm2in = 25.4`
- **Bush catalog** (`index.html:269`): metric `[10,12,14,16,18,20,24,30]`; imperial `[5/16, 3/8, 7/16, 1/2, 5/8, 3/4, 1/1]″`
- **Cutter catalog** (`index.html:270`): metric `[4,5,6,7,8,10,12]`; imperial `[1/8, 3/16, 1/4, 5/16, 3/8, 1/2, 5/8, 3/4]″`
- `Offsets.bushes: [[Size]]` = `[metricBushes, imperialBushes]`; likewise `cutters`. Plus `allBushes`, `allCutters` (flattened), and `byId(_:)` lookup.

### Formatting (ported verbatim)
- `fmtN(_ mm: Double) -> Double` — round to 2 dp (`index.html:284`).
- `fracIn(_ mm: Double) -> String` — nearest 1/64″, reduce fraction, whole+fraction, `≈` prefix when off by >0.0005″, `0″` when zero (`index.html:285-293`).
- `both(_ mm: Double) -> String` — `"{fmtN} mm · {fracIn}″"` (`index.html:294`).
- `toMM(_ v: Double, _ u: UnitSystem) -> Double` — imperial × 25.4 (`index.html:295`).

### Core math (unchanged from v1, `index.html:280-281`)
- `impossible(bMM, cMM) = (bMM - cMM) <= 2` (2 mm bore clearance, both units).
- `offset(scenario, bMM, cMM) = isDiff ? (b-c)/2 : (b+c)/2`.
- `Scenario` enum unchanged (femHole/femPlug/maleHole/malePlug; isDiff/sign/piece/rel/formula).

### Inlay pairing (now per-unit-set, `index.html:483-496`)
```swift
struct InlayPair { let mm: Double; let holes: [(Size, Size)]; let plugs: [(Size, Size)]; let count: Int }
func pairOffsets(_ unit: UnitSystem) -> [InlayPair]   // offsets achievable by BOTH (B−C)/2 and (B+C)/2 within one unit set, keyed to 4 dp, sorted asc
func topPairs(_ unit: UnitSystem) -> [Double]          // the 3 highest-count pair offsets (highlight colours)
```

## State & Persistence

### CalculatorState (extended `@Observable`)
```swift
enum CalcMode { case forward, reverse }
enum SizeChoice: Hashable { case standard(id: String); case custom }

scenario: Scenario = .femHole
bushChoice: SizeChoice = .standard("m24")     // metric default
cutterChoice: SizeChoice = .standard("m8")
bushCustom: Double = 0;  bushCustomUnit: UnitSystem = .metric
cutterCustom: Double = 0; cutterCustomUnit: UnitSystem = .metric
template: Double = 60;   templateUnit: UnitSystem = .metric
depth: Double? = nil;    depthUnit: UnitSystem = .metric
mode: CalcMode = .forward
selectedTab: Int = 0
```
- Computed `bushMM`/`cutterMM` (Double?) resolve the choice against the catalog or the custom value.
- `func load(_ setup: SavedSetup)` applies a saved configuration.

### AppModel (new `@Observable`, persisted to UserDefaults)
Holds all cross-cutting persisted state (mirrors web `store`, `index.html:298-315`):
```swift
kit: Set<String> = []                 // owned size ids   (UserDefaults key "kit")
kitFilterEnabled: Bool = false        // "only my kit"    (key "kitFilter")
setups: [SavedSetup] = []             // saved configs    (key "setups")
tableUnit: UnitSystem = .metric       // tables/inlay unit toggle (not persisted; resets to metric)

func kitActive(_ category: SizeCategory) -> Bool   // filter on AND ≥1 of that category ticked
func isVisible(_ category, _ size: Size) -> Bool    // for calculator pickers
func toggleKit(_ id: String); func clearKit()
func addSetup(_:); func deleteSetup(at:)
```
`SavedSetup: Codable` stores everything needed to restore the calculator (scenario, choices,
custom values/units, template+unit, depth+unit, mode) — `index.html:451-453`.

Two environment objects total: `CalculatorState` (per-session config) + `AppModel`
(persisted cross-cutting state).

## UI — by tab

### Calculator (tab 0)
Ported from `index.html:132-196, 340-381`.
- **Scenario** picker (unchanged).
- **Bush / Cutter** pickers: grouped **Metric** / **Imperial** sections + **Custom…**. Selecting Custom reveals a value field + mm/in unit picker. When the kit filter is active, non-kit sizes are hidden (`index.html:315-328`).
- **Mode** segmented control: forward (*have template → size result*) / reverse (*want result → size template*) (`index.html:163-166`). The dimension label switches ("Template opening / disc Ø" ↔ "Target {piece} Ø", `index.html:349`).
- **Template Ø** input + mm/in unit; **Cut depth (optional)** input + mm/in unit (`index.html:167-184`).
- **Result** (`index.html:357-378`):
  - Impossible → red warning (both units).
  - Offset in both units + formula.
  - Forward: piece Ø = `template + sign·2·offset` (both units) or "template too small".
  - Reverse: template = `target − sign·2·offset` (both units) or "not achievable".
  - **Corners tip** line: internal corner radius ≥ cutter radius `both(C/2)`; bush won't follow template corners tighter than `both(B/2)`.
  - **Depth tip** line (when depth > 0): pass count `max(1, ceil(depth/(C/2)))`, depth-per-pass.
- **★ Save this setup** button → names via alert → appends to `AppModel.setups`.
- **Saved setups**: horizontal chip row; tap loads, swipe/long-press deletes (`index.html:440-473`).
- Native `Canvas` **DiagramView** unchanged (offset label mm), fed the resolved bush/cutter mm.

### Kit (tab 3, new)
Ported from `index.html:198-208, 422-438`.
- "**Only show my kit**" toggle (binds `AppModel.kitFilterEnabled`).
- Wrapping grid of **bush** chips and **cutter** chips (metric + imperial), highlighted when owned; tap toggles ownership.
- **Clear kit** button (confirm).
- Changing kit/filter refreshes calculator, tables, inlay reactively (via shared `AppModel`).

### Tables (tab 1)
Ported from `index.html:231-243, 475-523`.
- **Metric ⇄ Imperial** segmented control (binds `AppModel.tableUnit`).
- Four tables render the selected unit's size set; cells show that unit's offset (mm value or `fracIn` without the ″ in-cell, matching web `index.html:514`).
- Female tables highlight the **top-3 dynamic** pair offsets (colours blue/orange/purple by rank) with a **dynamic legend** (`index.html:499-504, 510-512`).
- Non-kit cells **dimmed** when kit filter active (`index.html:513`).
- Tap a possible cell → loads scenario+bush+cutter into the calculator and jumps to Calculator tab.

### Inlay (tab 2)
Ported from `index.html:210-229, 550-584`.
- Template input + mm/in unit.
- Target-offset picker sourced from `pairOffsets(tableUnit)` filtered by kit (`inlayPairsFiltered`); "— none with current kit —" when empty.
- Result: perfect-fit size in both units (when `template > 2·offset`), else warning; hole & plug setup lists (labels in the unit's format).

### Maths (tab 4)
Extend the existing explainer with the web's added **Corners** and **Depth of cut**
paragraphs (`index.html:253-254`). Keep worked example.

## Testing

`Tests/OffsetsTests` gains parity cases (pure logic only):
- `Size.metric/.imperial` ids, mm, labels (e.g. `imperial(5,16).mm ≈ 7.9375`, label `"5/16″"`; `imperial(1,1).label == "1″"`).
- `fracIn`: `fracIn(25.4) == "1″"`, `fracIn(7.9375) == "5/16″"`, an inexact value gets the `≈` prefix, `fracIn(0) == "0″"`.
- `both(24) == "24 mm · 15/16″"` (verify against web output).
- `pairOffsets(.metric)` contains the expected offsets with correct hole/plug members; `topPairs(.metric)` returns 3 offsets ordered by descending count.
- `toMM(1, .imperial) == 25.4`.

Plus on-device smoke per phase.

## Phasing (each phase builds, runs on device, and is committed)

1. **Sizes & formatting model** — `Size`, `UnitSystem`, catalogs, `fracIn`/`both`/`toMM`, `pairOffsets`/`topPairs`, `SizeChoice`; full `swift test` coverage. **Additive only:** the new types are added alongside the existing Double-based `Offsets.bushes/cutters/offset/impossible/inlayPairs`, which stay untouched so the current app compiles and runs unchanged. The old APIs are migrated away in later phases (phase 2 for the calculator, phase 4 for tables/inlay) and removed once no caller remains.
2. **Calculator: imperial + custom** — grouped pickers with Metric/Imperial + Custom entry; dual-unit results; template unit picker.
3. **Calculator: mode + depth + corners** — forward/reverse segmented control, depth→passes, corners tip.
4. **Tables + Inlay** — unit toggle, dynamic top-3 highlights, dynamic legend; inlay unit-aware.
5. **My Kit tab + filtering + persistence** — `AppModel` kit/filter, Kit tab, dimming/hiding across calculator/tables/inlay.
6. **Saved setups + persistence** — save/load/delete on the Calculator tab; Maths explainer additions.

## Out of Scope
- Changing the web PWA (`index.html` stays the source of truth).
- iCloud sync of kit/setups (local `UserDefaults` only).
- App Store submission.

## Repo Impact (added/changed under `ios/`)
```
ios/Models/Sizes.swift        # Size, UnitSystem, catalogs, formatting (NEW, in swift-test package)
ios/Models/Offsets.swift      # extended: per-unit pairs/topPairs; keeps Scenario
ios/Models/CalculatorState.swift  # extended: choices, units, mode, depth
ios/Models/AppModel.swift     # NEW: kit, filter, setups, tableUnit (persisted)
ios/Views/CalculatorView.swift    # pickers, mode, depth, corners, setups
ios/Views/KitView.swift       # NEW tab
ios/Views/TablesView.swift    # unit toggle, dynamic highlights, dimming
ios/Views/InlayFinderView.swift   # unit/kit-aware
ios/Views/MathsView.swift     # corners/depth paragraphs
ios/Views/ContentView.swift   # 5 tabs
Package.swift                 # add Sizes.swift to logic target
Tests/OffsetsTests/…          # parity cases for sizes/formatting/pairs
```
(Exact names finalized in the plan.)
