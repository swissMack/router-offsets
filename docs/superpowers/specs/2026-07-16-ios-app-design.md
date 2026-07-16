# RouterOffsets — Native iOS App Design

**Date:** 2026-07-16
**Status:** Approved (pending spec review)

## Goal

Turn the existing `router-offsets` web PWA (a single `index.html` woodworking router
offset calculator) into a **native SwiftUI iOS app**, built with Xcode, that runs on the
owner's personal iPhone via free Apple ID sideloading.

This is a **rewrite**, not a web-view wrapper: the ~357 lines of math + SVG diagram are
reimplemented in Swift/SwiftUI. The existing web app stays in the repo untouched.

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Approach | Native SwiftUI rewrite | Genuinely native feel; logic is small enough to port cleanly |
| Distribution | Sideload to own iPhone (free Apple ID) | Personal use; no $99/yr developer account needed. Note: free-account apps expire every 7 days and must be re-run from Xcode. |
| Min iOS version | iOS 17.0 | Wide device support; `@Observable` + `Canvas` available |
| Project generation | XcodeGen (via Homebrew) + `project.yml` | Reliable, reproducible, easy to regenerate |
| Navigation | 4-tab `TabView` | More native than the web single-scroll page |
| Dependencies | None (first-party frameworks only) | Keep it simple |
| Toolchain (verified) | Xcode 26.5, iOS SDK 26.5, Swift 6.3 | Confirmed installed |

## Architecture

**Logic/UI split.** All computation lives in a pure, UI-free Swift file (`Offsets.swift`),
a faithful port of the JavaScript model. Views only render. This makes the math
**unit-testable for parity** against the original web app's tables.

**Single source of truth.** One `@Observable` state object (`CalculatorState`) holds the
current scenario + bush + cutter + template selections. It is injected via the SwiftUI
environment so any view (e.g. a tapped table cell) can update the shared selection.

## Components

Mirrors the four sections of the original web app.

| File | Purpose | Ports from (`index.html`) |
|---|---|---|
| `RouterOffsetsApp.swift` | `@main` app entry; injects `CalculatorState` | — |
| `Models/Offsets.swift` | `BUSHES`, `CUTTERS`, scenario definitions, `offset()`, `impossible()`, inlay-pair finder — all pure functions/values | `:161`–`:215` |
| `Models/CalculatorState.swift` | Shared `@Observable` selection state + selected tab | — |
| `Views/ContentView.swift` | `TabView` root tying the four sections together | overall page layout |
| `Views/CalculatorView.swift` | Scenario/bush/cutter/template pickers; live offset + resulting size; embeds diagram | Calculator `:76` |
| `Views/TablesView.swift` | The four tappable bush×cutter offset grids; tap loads bush+cutter into `CalculatorState` and switches to the Calculator tab | Tables `:129` |
| `Views/InlayFinderView.swift` | List of bush/cutter combos where hole and plug share the same offset | Inlay `:112` |
| `Views/DiagramView.swift` | Native cross-section drawing via SwiftUI `Canvas`/`Shape` (replaces inline SVG) | `drawDiagram :218` |
| `Views/MathsView.swift` | The "how the maths works" formulas explainer | Maths `:144` |

### Data model detail (from the web app)

- `BUSHES = [10, 12, 14, 16, 18, 20, 24, 30]` (mm)
- `CUTTERS = [4, 5, 6, 7, 8, 10, 12]` (mm)
- Four scenarios (female/male template → hole/plug), each selecting one of two offset formulas:
  - `(B − C) / 2`  or  `(B + C) / 2`
- `impossible()` flags cells where the cutter is too large for the bush.
- Inlay finder highlights matching offsets (web app spotlights 8/9/10 mm).

The exact formula-per-scenario mapping and the inlay-match logic will be read directly
from `index.html:161`–`:290` during implementation to guarantee a faithful port.

## Data Flow

1. `CalculatorState` (environment `@Observable`) is the single source of truth.
2. `CalculatorView` reads/writes the selections; recomputes offset via pure `Offsets`
   functions on every change.
3. `TablesView` cell tap → sets `bush` + `cutter` on `CalculatorState`, sets selected tab
   to Calculator. The Calculator view updates reactively.
4. `DiagramView` derives its geometry purely from the current selection — no local state.

## Error / Edge Handling

- **Impossible combinations** (cutter ≥ bush bore, etc.): surfaced in the UI the same way
  the web app does — cells marked/disabled in tables; calculator shows a clear "not
  possible" state instead of a misleading number.
- All inputs are constrained to the fixed `BUSHES`/`CUTTERS` menus, so there is no free
  text to validate. Template diameter (if free-entry in the original) is validated to be
  positive.

## Testing

- **`Tests/OffsetsTests.swift`** — parity unit tests: for representative bush×cutter×scenario
  combinations, assert the Swift `offset()` output matches the known values the web app's
  tables produce. Include impossible-combination cases and inlay-pair cases.
- Manual smoke test: build to iPhone, exercise each tab.

## Project Setup

- **XcodeGen** installed via `brew install xcodegen`.
- **`project.yml`** (checked into repo) defines a single iOS app target:
  - Bundle ID placeholder: `com.tarik.routeroffsets` (owner repoints to their free Apple
    ID team in Xcode's Signing & Capabilities tab).
  - Deployment target iOS 17.0; automatic code signing.
- Run `xcodegen generate` → produces `RouterOffsets.xcodeproj`.
- **App icon:** reuse existing `icons/` art, packaged into an `AppIcon` asset catalog.
  Modern Xcode wants a single 1024×1024; the largest existing asset is 512×512, so it will
  be upscaled (slightly soft) with a note that a crisp 1024 can be dropped in later.

## Out of Scope

- App Store submission / paid developer account.
- iPad-specific layout tuning (universal build is fine; iPhone is the target).
- Changing or deleting the existing web PWA — it stays in the repo.
- Any new features beyond what the web app already does.

## Repo Layout (added)

```
router-offsets/
├── index.html, sw.js, ...          # existing web PWA (untouched)
├── project.yml                     # XcodeGen spec
├── ios/                            # new SwiftUI sources
│   ├── RouterOffsetsApp.swift
│   ├── Models/{Offsets,CalculatorState}.swift
│   ├── Views/{ContentView,CalculatorView,TablesView,InlayFinderView,DiagramView,MathsView}.swift
│   ├── Assets.xcassets/            # AppIcon + colors
│   └── Tests/OffsetsTests.swift
└── docs/superpowers/specs/2026-07-16-ios-app-design.md
```
(Exact folder names finalized in the implementation plan.)
