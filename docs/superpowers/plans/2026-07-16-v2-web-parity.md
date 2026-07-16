# RouterOffsets v2 (Web Parity) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring the native SwiftUI app to full parity with the current web app (`index.html`): imperial + dual-unit, forward/reverse calculator mode, depth/corner helpers, My Kit filter, saved setups, unit-toggle tables, and dynamic inlay highlights.

**Architecture:** Additive pure-logic layer (`Sizes.swift` + extended `Offsets.swift`) shared by the `swift test` package and the app. Two `@Observable` environment objects: `CalculatorState` (per-session config) and `AppModel` (persisted kit/setups + tables unit). 5-tab `TabView`. Everything ports from `index.html` (in the repo — read the cited lines).

**Tech Stack:** SwiftUI, Observation, Foundation; XcodeGen; SwiftPM for tests. No third-party deps.

## Global Constraints

- **Authoritative source:** `index.html` at repo root. Every ported behavior cites its lines; when in doubt, match the web output exactly.
- **Metric is the default everywhere:** bush `m24`, cutter `m8`, template/depth/custom unit `mm`, tables unit Metric. Imperial is opt-in.
- **Core math unchanged:** `impossible(b,c)=(b-c)<=2` (mm), `offset = isDiff ? (b-c)/2 : (b+c)/2`. `Scenario` isDiff/sign/piece/rel/formula as in v1 `ios/Models/Offsets.swift`.
- **Constants:** `mm2in = 25.4`. Bush metric `[10,12,14,16,18,20,24,30]`, imperial `[5/16,3/8,7/16,1/2,5/8,3/4,1/1]″`. Cutter metric `[4,5,6,7,8,10,12]`, imperial `[1/8,3/16,1/4,5/16,3/8,1/2,5/8,3/4]″`.
- **No third-party dependencies.** iOS 17.0. Units in mm internally; display converts.
- **Do not modify the web PWA** (`index.html`, `sw.js`, etc.) — read-only reference.
- **Persistence:** `UserDefaults` keys `"kit"` (`[String]` JSON), `"kitFilter"` (Bool), `"setups"` (`[SavedSetup]` JSON). `tableUnit` NOT persisted (resets to metric each launch).
- **Commit style:** `git commit --no-gpg-sign` (GPG hangs in this env). Generated `RouterOffsets.xcodeproj` stays gitignored; run `xcodegen generate` after adding files.
- **Logic tests:** `swift test` (from repo root, no simulator).
- **App build gate:** `xcodebuild -project RouterOffsets.xcodeproj -scheme RouterOffsets -destination 'generic/platform=iOS Simulator' -quiet build` → `** BUILD SUCCEEDED **`.

## File Structure

```
ios/Models/Sizes.swift            NEW  — UnitSystem, Size, catalogs, fracIn/fmtN/both/toMM  (in swift-test package)
ios/Models/Offsets.swift          EDIT — keep v1 APIs; add SizeCategory, pairOffsets/topPairs (per-unit), SizeChoice
ios/Models/CalculatorState.swift  EDIT — SizeChoice, custom values/units, template/depth+units, mode
ios/Models/AppModel.swift         NEW  — tableUnit (p4); kit+filter (p5); setups (p6); UserDefaults persistence
ios/Views/CalculatorView.swift    EDIT — grouped/custom pickers, dual-unit, mode, depth, corners, setups
ios/Views/KitView.swift           NEW  — My Kit tab (p5)
ios/Views/TablesView.swift        EDIT — unit toggle, dynamic top-3, kit dimming
ios/Views/InlayFinderView.swift   EDIT — unit/kit-aware
ios/Views/MathsView.swift         EDIT — corners + depth paragraphs (p6)
ios/Views/ContentView.swift       EDIT — 5 tabs (p5)
Package.swift                     EDIT — add Sizes.swift to logic target
Tests/OffsetsTests/…              EDIT — parity for sizes/formatting/pairs
```

---

# PHASE 1 — Sizes & formatting model (additive, TDD)

## Task 1: Size type, catalogs, formatting

**Files:**
- Create: `ios/Models/Sizes.swift`
- Modify: `Package.swift` (add `Sizes.swift` to the `RouterOffsetsLogic` target `sources`)
- Test: `Tests/OffsetsTests/SizesTests.swift`

**Interfaces produced:**
- `enum UnitSystem: String, Codable { case metric = "m", imperial = "i" }`
- `struct Size: Identifiable, Hashable, Codable { let id: String; let mm: Double; let label: String; let system: UnitSystem; static func metric(_:Double)->Size; static func imperial(_ n:Int,_ d:Int)->Size }`
- `enum Catalog { static let bushes: [[Size]]; static let cutters: [[Size]]; static let allBushes: [Size]; static let allCutters: [Size]; static func size(id:)->Size? }`
- Free funcs: `fmtN(_:Double)->Double`, `fracIn(_:Double)->String`, `both(_:Double)->String`, `toMM(_:Double,_:UnitSystem)->Double`, `mm2in: Double`.

- [ ] **Step 1: Add Sizes.swift to the test package**

Edit `Package.swift` target `RouterOffsetsLogic` sources:
```swift
        .target(name: "RouterOffsetsLogic", path: "ios/Models", sources: ["Offsets.swift", "Sizes.swift"]),
```

- [ ] **Step 2: Write failing tests**

`Tests/OffsetsTests/SizesTests.swift`:
```swift
import XCTest
@testable import RouterOffsetsLogic

final class SizesTests: XCTestCase {
    func testMetricFactory() {
        let s = Size.metric(24)
        XCTAssertEqual(s.id, "m24"); XCTAssertEqual(s.mm, 24); XCTAssertEqual(s.label, "24 mm"); XCTAssertEqual(s.system, .metric)
    }
    func testImperialFactory() {
        let s = Size.imperial(5, 16)
        XCTAssertEqual(s.id, "i5-16"); XCTAssertEqual(s.mm, 25.4 * 5 / 16, accuracy: 1e-9)
        XCTAssertEqual(s.label, "5/16″"); XCTAssertEqual(s.system, .imperial)
        XCTAssertEqual(Size.imperial(1, 1).label, "1″")   // whole inch
    }
    func testCatalogs() {
        XCTAssertEqual(Catalog.bushes[0].map(\.mm), [10,12,14,16,18,20,24,30])
        XCTAssertEqual(Catalog.cutters[0].count, 7)
        XCTAssertEqual(Catalog.bushes[1].count, 7)   // imperial bushes
        XCTAssertEqual(Catalog.cutters[1].count, 8)  // imperial cutters
        XCTAssertEqual(Catalog.size(id: "m24")?.mm, 24)
        XCTAssertEqual(Catalog.size(id: "i1-2")?.mm, 12.7, accuracy: 1e-9)
    }
    func testFracIn() {
        XCTAssertEqual(fracIn(25.4), "1″")
        XCTAssertEqual(fracIn(25.4 * 5 / 16), "5/16″")
        XCTAssertEqual(fracIn(0), "0″")
        XCTAssertTrue(fracIn(8).hasPrefix("≈"))   // 8 mm is not an exact 1/64"
    }
    func testBothAndToMM() {
        XCTAssertEqual(both(24), "24 mm · 15/16″")   // matches web output for 24 mm
        XCTAssertEqual(toMM(1, .imperial), 25.4, accuracy: 1e-9)
        XCTAssertEqual(toMM(60, .metric), 60)
        XCTAssertEqual(fmtN(8.005), 8.01, accuracy: 1e-9)
    }
}
```
(Note: confirm `both(24)`'s `15/16″` by hand: 24/25.4 = 0.9449″; ×64 = 60.47 → 60/64 = 15/16, inexact → the web prints `≈ 15/16″`. So `both(24) == "24 mm · ≈ 15/16″"`. **Use that exact string in the assertion** — verify against the web before finalizing.)

- [ ] **Step 3: Run tests, verify RED**

Run: `swift test`  → FAIL (`Size`/`Catalog`/`fracIn` undefined).

- [ ] **Step 4: Implement `ios/Models/Sizes.swift`**

```swift
import Foundation

let mm2in = 25.4

enum UnitSystem: String, Codable { case metric = "m", imperial = "i" }

struct Size: Identifiable, Hashable, Codable {
    let id: String
    let mm: Double
    let label: String
    let system: UnitSystem

    static func metric(_ v: Double) -> Size {
        Size(id: "m\(fmtId(v))", mm: v, label: "\(fmtN(v)) mm", system: .metric)
    }
    static func imperial(_ n: Int, _ d: Int) -> Size {
        Size(id: "i\(n)-\(d)", mm: mm2in * Double(n) / Double(d),
             label: d == 1 ? "\(n)″" : "\(n)/\(d)″", system: .imperial)
    }
    private static func fmtId(_ v: Double) -> String {
        v == v.rounded() ? String(Int(v)) : String(v)
    }
}

enum Catalog {
    static let bushes: [[Size]] = [
        [10,12,14,16,18,20,24,30].map(Size.metric),
        [(5,16),(3,8),(7,16),(1,2),(5,8),(3,4),(1,1)].map { Size.imperial($0.0, $0.1) }
    ]
    static let cutters: [[Size]] = [
        [4,5,6,7,8,10,12].map(Size.metric),
        [(1,8),(3,16),(1,4),(5,16),(3,8),(1,2),(5,8),(3,4)].map { Size.imperial($0.0, $0.1) }
    ]
    static let allBushes: [Size] = bushes.flatMap { $0 }
    static let allCutters: [Size] = cutters.flatMap { $0 }
    static func size(id: String) -> Size? {
        allBushes.first { $0.id == id } ?? allCutters.first { $0.id == id }
    }
}

/// Round to 2 dp, drop trailing zeros (matches web `fmtN` display via Math.round(n*100)/100).
func fmtN(_ n: Double) -> String {
    let r = (n * 100).rounded() / 100
    if r == r.rounded() { return String(Int(r)) }
    var s = String(format: "%.2f", r)
    while s.hasSuffix("0") { s.removeLast() }
    if s.hasSuffix(".") { s.removeLast() }
    return s
}

/// Nearest 1/64", reduced; "≈ " prefix when not exact; "0″" for zero.  Ports index.html:285-293.
func fracIn(_ mmv: Double) -> String {
    let inches = mmv / mm2in
    var n = Int((inches * 64).rounded())
    var d = 64
    let approx = abs(inches - Double(n) / 64) > 0.0005 ? "≈ " : ""
    if n == 0 { return "0″" }
    while n % 2 == 0 && d > 1 { n /= 2; d /= 2 }
    let w = n / d
    n -= w * d
    let whole = w != 0 ? "\(w)\(n != 0 ? " " : "")" : ""
    let frac = n != 0 ? "\(n)/\(d)" : ""
    return approx + whole + frac + "″"
}

func both(_ mmv: Double) -> String { "\(fmtN(mmv)) mm · \(fracIn(mmv))" }

func toMM(_ v: Double, _ u: UnitSystem) -> Double { u == .imperial ? v * mm2in : v }
```
(`fmtN` returns `String` here — the web uses it as a display value; the test `fmtN(8.005)==8.01` in Step 2 expects a Double. **Reconcile:** change the test to `XCTAssertEqual(fmtN(8.005), "8.01")` OR keep a numeric `fmtNv` helper. Decision: `fmtN` returns `String` for display; add `func fmtNv(_:Double)->Double` if a numeric rounding is needed. Update the Step-2 test to assert the `String` form.)

- [ ] **Step 5: Run tests, verify GREEN**

Run: `swift test` → all pass. Fix the `fmtN`/`both` string assertions against real output if needed.

- [ ] **Step 6: Confirm app still builds (additive change)**

Run: `xcodegen generate && xcodebuild -project RouterOffsets.xcodeproj -scheme RouterOffsets -destination 'generic/platform=iOS Simulator' -quiet build` → BUILD SUCCEEDED.

- [ ] **Step 7: Commit**
```bash
git add ios/Models/Sizes.swift Package.swift Tests/OffsetsTests/SizesTests.swift
git commit --no-gpg-sign -m "feat(v2): Size type, metric+imperial catalogs, dual-unit formatting"
```

## Task 2: Per-unit inlay pairing + SizeChoice

**Files:**
- Modify: `ios/Models/Offsets.swift` (add, keep v1 APIs)
- Test: `Tests/OffsetsTests/PairingTests.swift`

**Interfaces produced:**
- `enum SizeCategory { case bush, cutter }`
- `struct SizePair: Hashable { let bush: Size; let cutter: Size }`
- `struct InlayPairV2: Identifiable { let mm: Double; let holes: [SizePair]; let plugs: [SizePair]; let count: Int; var id: Double { mm } }`
- `func pairOffsets(_ unit: UnitSystem) -> [InlayPairV2]` — ports `index.html:483-493`
- `func topPairs(_ unit: UnitSystem) -> [Double]` — ports `index.html:494-496`
- `enum SizeChoice: Hashable { case standard(id: String); case custom }`

- [ ] **Step 1: Write failing tests**

`Tests/OffsetsTests/PairingTests.swift`:
```swift
import XCTest
@testable import RouterOffsetsLogic

final class PairingTests: XCTestCase {
    func testMetricPairOffsetsContainsEight() {
        let pairs = pairOffsets(.metric)
        XCTAssertEqual(pairs.map(\.mm), pairs.map(\.mm).sorted())      // ascending
        guard let eight = pairs.first(where: { $0.mm == 8 }) else { return XCTFail("no 8mm pair") }
        XCTAssertTrue(eight.holes.contains { $0.bush.id == "m24" && $0.cutter.id == "m8" }) // (24-8)/2
        XCTAssertTrue(eight.plugs.contains { $0.bush.id == "m10" && $0.cutter.id == "m6" }) // (10+6)/2
        XCTAssertEqual(eight.count, eight.holes.count + eight.plugs.count)
    }
    func testTopPairsAreThreeByDescendingCount() {
        let tops = topPairs(.metric)
        XCTAssertEqual(tops.count, 3)
        let counts = tops.map { off in pairOffsets(.metric).first { $0.mm == off }!.count }
        XCTAssertEqual(counts, counts.sorted(by: >))
    }
    func testImperialPairsExist() {
        XCTAssertFalse(pairOffsets(.imperial).isEmpty)
    }
}
```

- [ ] **Step 2: Run, verify RED** — `swift test` → FAIL (`pairOffsets` undefined).

- [ ] **Step 3: Append to `ios/Models/Offsets.swift`** (do NOT remove existing v1 declarations)

```swift
enum SizeCategory { case bush, cutter }

struct SizePair: Hashable { let bush: Size; let cutter: Size }

struct InlayPairV2: Identifiable {
    let mm: Double
    let holes: [SizePair]
    let plugs: [SizePair]
    let count: Int
    var id: Double { mm }
}

/// Offsets achievable by BOTH (B−C)/2 and (B+C)/2 within one unit set. Ports index.html:483-493.
func pairOffsets(_ unit: UnitSystem) -> [InlayPairV2] {
    let idx = unit == .metric ? 0 : 1
    let bs = Catalog.bushes[idx], cs = Catalog.cutters[idx]
    var holes: [String: [SizePair]] = [:]
    var plugs: [String: [SizePair]] = [:]
    for b in bs {
        for c in cs where !Offsets.impossible(bush: b.mm, cutter: c.mm) {
            let kd = String(format: "%.4f", (b.mm - c.mm) / 2)
            let ks = String(format: "%.4f", (b.mm + c.mm) / 2)
            holes[kd, default: []].append(SizePair(bush: b, cutter: c))
            plugs[ks, default: []].append(SizePair(bush: b, cutter: c))
        }
    }
    return holes.keys
        .filter { plugs[$0] != nil }
        .map { key in
            InlayPairV2(mm: Double(key)!, holes: holes[key]!, plugs: plugs[key]!,
                        count: holes[key]!.count + plugs[key]!.count)
        }
        .sorted { $0.mm < $1.mm }
}

/// The 3 highest-count pair offsets (the highlight colours). Ports index.html:494-496.
func topPairs(_ unit: UnitSystem) -> [Double] {
    pairOffsets(unit)
        .sorted { $0.count > $1.count }
        .prefix(3)
        .map { ($0.mm * 10000).rounded() / 10000 }
}

enum SizeChoice: Hashable { case standard(id: String); case custom }
```

- [ ] **Step 4: Run, verify GREEN** — `swift test` → all pass.

- [ ] **Step 5: Build app** — `xcodegen generate && xcodebuild … -quiet build` → SUCCEEDED.

- [ ] **Step 6: Commit**
```bash
git add ios/Models/Offsets.swift Tests/OffsetsTests/PairingTests.swift
git commit --no-gpg-sign -m "feat(v2): per-unit inlay pairing, topPairs, SizeChoice"
```

---

# PHASE 2 — Calculator: imperial + custom sizes

## Task 3: Extend CalculatorState for Size choices + units

**Files:**
- Modify: `ios/Models/CalculatorState.swift`

**Interfaces produced (added to `CalculatorState`):**
- `var bushChoice: SizeChoice = .standard(id: "m24")`, `var cutterChoice: SizeChoice = .standard(id: "m8")`
- `var bushCustom = 0.0`, `var bushCustomUnit: UnitSystem = .metric`, and cutter equivalents
- `var templateUnit: UnitSystem = .metric`
- computed `var bushMM: Double?`, `var cutterMM: Double?` (resolve choice → mm; custom via `toMM`; `nil` when custom value ≤ 0)
- Keep existing `scenario`, `template`, `selectedTab`. Remove the old `bush`/`cutter` Double stored props **only after** their callers are migrated (Task 4). For this task, add the new props alongside; leave `bush`/`cutter` in place so the file compiles.

- [ ] **Step 1: Add the new stored + computed properties**

In `ios/Models/CalculatorState.swift`, add inside the class:
```swift
    var bushChoice: SizeChoice = .standard(id: "m24")
    var cutterChoice: SizeChoice = .standard(id: "m8")
    var bushCustom: Double = 0
    var bushCustomUnit: UnitSystem = .metric
    var cutterCustom: Double = 0
    var cutterCustomUnit: UnitSystem = .metric
    var templateUnit: UnitSystem = .metric

    var bushMM: Double? { resolve(bushChoice, custom: bushCustom, unit: bushCustomUnit) }
    var cutterMM: Double? { resolve(cutterChoice, custom: cutterCustom, unit: cutterCustomUnit) }

    private func resolve(_ choice: SizeChoice, custom: Double, unit: UnitSystem) -> Double? {
        switch choice {
        case .standard(let id): return Catalog.size(id: id)?.mm
        case .custom: return custom > 0 ? toMM(custom, unit) : nil
        }
    }
```

- [ ] **Step 2: Build** — `xcodegen generate && xcodebuild … -quiet build` → SUCCEEDED (old `bush`/`cutter` still present; new props unused so far).

- [ ] **Step 3: Commit**
```bash
git add ios/Models/CalculatorState.swift
git commit --no-gpg-sign -m "feat(v2): CalculatorState size choices, custom values, units"
```

## Task 4: Calculator UI — grouped/custom pickers + dual-unit result

**Files:**
- Modify: `ios/Views/CalculatorView.swift`
- Modify: `ios/Models/CalculatorState.swift` (remove now-dead `bush`/`cutter` Double props)

**Consumes:** `Catalog`, `Size`, `SizeChoice`, `both`, `fmtN`, `toMM`, `CalculatorState.bushMM/cutterMM/*Choice/*Custom*`, `Offsets.impossible/offset`, `Scenario`.
**Produces:** a Calculator that uses `bushMM`/`cutterMM` and renders dual-unit results. DiagramView is fed `bushMM ?? 20`, `cutterMM ?? 8`.

- [ ] **Step 1: Replace bush/cutter pickers with grouped + custom**

Port the picker UX from `index.html:145-162, 317-338`. Requirements:
- A `Picker` for bush whose selection is `SizeChoice`. Options: a `Section`/group of Metric sizes (`Catalog.bushes[0]`), a group of Imperial sizes (`Catalog.bushes[1]`) — each tagged `.standard(id: size.id)` and labelled `size.label` — plus a `.custom`-tagged "Custom…" row. Use `.pickerStyle(.navigationLink)` so the grouped list is legible.
- When `bushChoice == .custom`, show a row: a `TextField(value: $state.bushCustom, format: .number)` (`.keyboardType(.decimalPad)`, `.focused`, `.selectAllOnEditing()`, and the shared `.keyboardDoneBar`) + a small `Picker` bound to `$state.bushCustomUnit` (mm/in).
- Same for cutter.

Concrete helper (add to the view) to build grouped picker content:
```swift
    @ViewBuilder private func sizeOptions(_ sets: [[Size]]) -> some View {
        Section("Metric")   { ForEach(sets[0]) { Text($0.label).tag(SizeChoice.standard(id: $0.id)) } }
        Section("Imperial") { ForEach(sets[1]) { Text($0.label).tag(SizeChoice.standard(id: $0.id)) } }
        Text("Custom…").tag(SizeChoice.custom)
    }
```
Bush picker:
```swift
                Picker("Guide bush Ø", selection: $state.bushChoice) { sizeOptions(Catalog.bushes) }
                if state.bushChoice == .custom {
                    HStack {
                        TextField("Custom Ø", value: $state.bushCustom, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                            .focused($fieldFocused).selectAllOnEditing()
                        Picker("", selection: $state.bushCustomUnit) {
                            Text("mm").tag(UnitSystem.metric); Text("in").tag(UnitSystem.imperial)
                        }.pickerStyle(.segmented).frame(width: 110)
                    }
                }
```
(Repeat for cutter with `Catalog.cutters`, `$state.cutterChoice`, `$state.cutterCustom`, `$state.cutterCustomUnit`. Consolidate `@FocusState private var fieldFocused: Bool` for all fields; keep `.keyboardDoneBar(isFocused: $fieldFocused)` on the Form.)

- [ ] **Step 2: Template field gains a unit picker**

Replace the template `LabeledContent` with a row holding the `TextField(value:$state.template)` plus a small segmented `Picker` bound to `$state.templateUnit` (mm/in), mirroring the custom-size row.

- [ ] **Step 3: Rewrite the Result section to use `bushMM`/`cutterMM` and dual units**

Port `index.html:350-374` (forward branch only for now; reverse arrives in Task 6). Replace the computed helpers:
```swift
    private var bushMM: Double? { state.bushMM }
    private var cutterMM: Double? { state.cutterMM }
    private var isImpossible: Bool { guard let b = bushMM, let c = cutterMM else { return false }; return Offsets.impossible(bush: b, cutter: c) }
    private var offset: Double? { guard let b = bushMM, let c = cutterMM, !isImpossible else { return nil }; return Offsets.offset(state.scenario, bush: b, cutter: c) }
```
Result rendering:
- `bushMM`/`cutterMM` nil → "Enter bush and cutter diameters."
- impossible → red: `"Impossible — a \(both(c)) cutter cannot pass a \(both(b)) guide bush."`
- else show `Offset: \(fmtN(o)) mm (\(fracIn(o)))`, formula line `offset = \(scenario.formula) = (\(fmtN(b)) \(scenario.isDiff ? "−" : "+") \(fmtN(c))) / 2 mm`, and (forward) piece Ø:
  - `let t = toMM(state.template, state.templateUnit)`; `let r = state.scenario.resultSize(template: t, offset: o)`
  - if `t > 0 && r > 0`: `"\(scenario.piece) Ø: \(both(r)) (\(scenario.rel))"` + formula
  - if `t > 0 && r <= 0`: red "Template too small — the offset consumes the whole opening."

- [ ] **Step 4: Feed DiagramView resolved mm**
```swift
                DiagramView(scenario: state.scenario, bush: bushMM ?? 20, cutter: cutterMM ?? 8,
                            offset: isImpossible ? nil : offset)
```

- [ ] **Step 5: Remove dead props** — delete the old `var bush`/`var cutter` Double stored properties from `CalculatorState.swift` now that no view reads them.

- [ ] **Step 6: Build** — `xcodegen generate && xcodebuild … -quiet build` → SUCCEEDED.

- [ ] **Step 7: Commit**
```bash
git add ios/Views/CalculatorView.swift ios/Models/CalculatorState.swift
git commit --no-gpg-sign -m "feat(v2): calculator imperial + custom sizes, dual-unit results"
```

---

# PHASE 3 — Calculator: forward/reverse mode + depth + corners

## Task 5: Mode + depth state

**Files:** Modify `ios/Models/CalculatorState.swift`

**Produces:** `enum CalcMode { case forward, reverse }` (top-level); `var mode: CalcMode = .forward`; `var depth: Double = 0`; `var depthUnit: UnitSystem = .metric`.

- [ ] **Step 1:** Add `enum CalcMode { case forward, reverse }` (file scope) and the three properties to `CalculatorState`.
- [ ] **Step 2: Build** → SUCCEEDED.
- [ ] **Step 3: Commit** `git commit --no-gpg-sign -m "feat(v2): calculator mode + depth state"`

## Task 6: Mode segmented control, reverse result, depth + corners tiplines

**Files:** Modify `ios/Views/CalculatorView.swift`

Port `index.html:163-166, 341-378`.

- [ ] **Step 1: Mode control** — add a segmented `Picker` bound to `$state.mode`: forward = "I have a template → size the result", reverse = "I want a result → size the template".
- [ ] **Step 2: Dynamic dimension label** — the template field label is `mode == .forward ? "Template opening / disc Ø" : "Target \(state.scenario.piece.lowercased()) Ø"`.
- [ ] **Step 3: Reverse result branch** — port `index.html:366-372`:
  - `let t = toMM(state.template, state.templateUnit)` (interpreted as the *target result* size in reverse).
  - `let template = t - state.scenario.sign * 2 * o`
  - if `template > 0`: `"Make the template: \(both(template))"` + formula `Template = \(scenario.piece) \(scenario.sign < 0 ? "+" : "−") 2×offset = \(fmtN(t)) \(scenario.sign < 0 ? "+" : "−") 2×\(fmtN(o)) mm`
  - else red: "Not achievable — this setup's offset is too large for that target size."
- [ ] **Step 4: Corners tipline** (always, when b & c valid & possible), port `index.html:374`:
  `"↳ Corners: internal corners of the cut will have a radius of at least \(both(c/2)) (cutter radius). Template internal corners tighter than \(both(b/2)) radius won't be followed by the bush."`
- [ ] **Step 5: Depth input + passes tipline** — add a depth `TextField(value:$state.depth)` + unit picker (like template). When `toMM(depth,depthUnit) > 0`, port `index.html:375-377`:
  `let dep = toMM(state.depth, state.depthUnit); let per = c/2; let n = max(1, Int(ceil(dep/per)))` →
  `"↳ Depth: \(both(dep)) deep with a \(both(c)) cutter → \(n) pass\(n>1 ? "es" : "") of \(both(dep/Double(n))) (rule of thumb: ≤ half the cutter Ø per pass in hardwood)."`
- [ ] **Step 6: Build** → SUCCEEDED.
- [ ] **Step 7: Commit** `git commit --no-gpg-sign -m "feat(v2): forward/reverse mode, depth passes, corners tip"`

---

# PHASE 4 — Tables + Inlay: unit toggle, dynamic highlights

## Task 7: AppModel with tableUnit; inject at root

**Files:**
- Create: `ios/Models/AppModel.swift`
- Modify: `ios/RouterOffsetsApp.swift`

**Produces:** `@Observable final class AppModel { var tableUnit: UnitSystem = .metric }` (kit/setups added in phases 5–6). Injected via `.environment(appModel)` alongside `CalculatorState`.

- [ ] **Step 1:** Create `AppModel.swift`:
```swift
import SwiftUI
import Observation

@Observable
final class AppModel {
    var tableUnit: UnitSystem = .metric
}
```
- [ ] **Step 2:** In `RouterOffsetsApp.swift` add `@State private var appModel = AppModel()` and `.environment(appModel)` on `ContentView()`.
- [ ] **Step 3: Build** → SUCCEEDED.
- [ ] **Step 4: Commit** `git commit --no-gpg-sign -m "feat(v2): AppModel with tables unit toggle"`

## Task 8: Tables — unit toggle, size sets, dynamic top-3 highlights, dynamic legend

**Files:** Modify `ios/Views/TablesView.swift`

Port `index.html:475-523`. Consumes `AppModel.tableUnit`, `Catalog`, `topPairs`, `Offsets.impossible/offset`, `fmtN`/`fracIn`, `CalculatorState.load`.

- [ ] **Step 1: Add a Metric/Imperial segmented Picker** bound to `@Environment(AppModel.self).tableUnit` (via `@Bindable`).
- [ ] **Step 2: Render the selected unit's size sets** — `let idx = tableUnit == .metric ? 0 : 1; let bs = Catalog.bushes[idx]; let cs = Catalog.cutters[idx]`. Rows over `bs` (label `b.label`), columns over `cs` (`c.label`). Cell value: `tableUnit == .metric ? fmtN(o) : fracIn(o).replacingOccurrences(of: "″", with: "")` (matches `index.html:514`).
- [ ] **Step 3: Dynamic highlights** — `let tops = topPairs(tableUnit)`. For female tables (`femHole`/`femPlug`) and non-impossible cells, if `tops.firstIndex(of: (o*10000).rounded()/10000)` is `i` (0,1,2), colour the cell blue/orange/purple by rank (reuse the v1 hex colours `aecdf7`/`f5c9a2`/`cbb3ec`).
- [ ] **Step 4: Dynamic legend** — an impossible-grey chip + one chip per top pair: `"\(tableUnit == .metric ? fmtN(t)+" mm" : fracIn(t)) inlay pair"` in the rank colour.
- [ ] **Step 5: Tap loads by Size** — on a possible cell tap, set `state.bushChoice = .standard(id: b.id)`, `state.cutterChoice = .standard(id: c.id)`, `state.scenario = scenario`, `state.selectedTab = 0`. (`CalculatorState.load(scenario:bush:cutter:)` from v1 took Doubles — replace its body/signature to accept size ids, or set the choices inline here.)
- [ ] **Step 6: Build** → SUCCEEDED.
- [ ] **Step 7: Commit** `git commit --no-gpg-sign -m "feat(v2): tables unit toggle + dynamic inlay highlights"`

## Task 9: Inlay finder — unit-aware, dual-unit

**Files:** Modify `ios/Views/InlayFinderView.swift`

Port `index.html:550-584`. Consumes `AppModel.tableUnit`, `pairOffsets`, `both`.

- [ ] **Step 1:** Source options from `pairOffsets(appModel.tableUnit)`; picker labels `tableUnit == .metric ? "\(fmtN(p.mm)) mm" : fracIn(p.mm)`; tag `p.mm`.
- [ ] **Step 2:** Template input gains a mm/in unit picker (`@State templateUnit`); compute `let T = toMM(template, templateUnit)`.
- [ ] **Step 3:** Result: find pair with `abs(p.mm - selected) < 0.001`; size = `T - 2*o` when `T > 2*o`; render "perfect-fit inlay" with `both(...)` values, else the warning; hole/plug lists show `pair.bush.label`/`pair.cutter.label` from `SizePair`.
- [ ] **Step 4: Build** → SUCCEEDED.
- [ ] **Step 5: Commit** `git commit --no-gpg-sign -m "feat(v2): inlay finder unit-aware + dual-unit"`

---

# PHASE 5 — My Kit tab + filtering + persistence

## Task 10: AppModel kit state + UserDefaults persistence

**Files:** Modify `ios/Models/AppModel.swift`

Port `index.html:298-315`. **Produces:**
- `var kit: Set<String>` (persisted key `"kit"` as `[String]`), `var kitFilterEnabled: Bool` (key `"kitFilter"`).
- `func kitActive(_ c: SizeCategory) -> Bool` (filter on AND ≥1 of that category owned), `func isVisible(_ c: SizeCategory, _ s: Size) -> Bool`, `func toggleKit(_ id: String)`, `func clearKit()`.

- [ ] **Step 1: Add persisted properties + didSet writes**
```swift
    var kit: Set<String> = AppModel.loadKit() { didSet { Self.save(Array(kit), "kit") } }
    var kitFilterEnabled: Bool = UserDefaults.standard.bool(forKey: "kitFilter") {
        didSet { UserDefaults.standard.set(kitFilterEnabled, forKey: "kitFilter") }
    }
    private static func loadKit() -> Set<String> {
        (try? JSONDecoder().decode([String].self, from: UserDefaults.standard.data(forKey: "kit") ?? Data())).map(Set.init) ?? []
    }
    private static func save<T: Encodable>(_ v: T, _ key: String) {
        UserDefaults.standard.set(try? JSONEncoder().encode(v), forKey: key)
    }
    func kitActive(_ c: SizeCategory) -> Bool {
        guard kitFilterEnabled else { return false }
        let arr = c == .bush ? Catalog.allBushes : Catalog.allCutters
        return arr.contains { kit.contains($0.id) }
    }
    func isVisible(_ c: SizeCategory, _ s: Size) -> Bool { kitActive(c) ? kit.contains(s.id) : true }
    func toggleKit(_ id: String) { if kit.contains(id) { kit.remove(id) } else { kit.insert(id) } }
    func clearKit() { kit.removeAll() }
```
(`@Observable` + `didSet` persistence is fine.)
- [ ] **Step 2: Build** → SUCCEEDED.
- [ ] **Step 3: Commit** `git commit --no-gpg-sign -m "feat(v2): AppModel kit state + persistence"`

## Task 11: Kit tab + 5-tab ContentView

**Files:** Create `ios/Views/KitView.swift`; modify `ios/Views/ContentView.swift`.

Port `index.html:198-208, 422-438`.

- [ ] **Step 1: KitView** — a `List`/`Form` with: a "Only show my kit" `Toggle` bound to `appModel.kitFilterEnabled`; a section of bush chips and a section of cutter chips (a wrapping layout — use a simple `FlowLayout` or `LazyVGrid(columns: [.adaptive(minimum: 90)])`) where each chip is a `Button` toggling `appModel.toggleKit(size.id)`, tinted when `appModel.kit.contains(size.id)`; a "Clear kit" button (confirmation dialog).
- [ ] **Step 2: ContentView** — insert the Kit tab as tag 3 (Calculator 0, Tables 1, Inlay 2, Kit 3, Maths 4). Update the Maths tag to 4. Use SF Symbols e.g. `hammer` for Kit.
- [ ] **Step 3: Build** → SUCCEEDED.
- [ ] **Step 4: Commit** `git commit --no-gpg-sign -m "feat(v2): My Kit tab, 5-tab layout"`

## Task 12: Apply kit filtering to calculator, tables, inlay

**Files:** Modify `CalculatorView.swift`, `TablesView.swift`, `InlayFinderView.swift`.

Port `index.html:315-328` (calc picker hide), `:513` (table dim), `:551-556` (inlay filter).

- [ ] **Step 1: Calculator pickers** — filter grouped size options by `appModel.isVisible(.bush, size)` / `.cutter` (read `@Environment(AppModel.self)`).
- [ ] **Step 2: Tables dimming** — when `appModel.kitActive(.bush) && !kit.contains(b.id)` OR the cutter equivalent, apply `.opacity(0.32)` to the cell; add the "Dimmed = not in my kit" legend entry when any category filter is active.
- [ ] **Step 3: Inlay filtering** — filter each pair's `holes`/`plugs` by kit (`kitActive`+`kit.contains`), drop pairs with empty holes or plugs; show "— none with current kit —" when the option list is empty.
- [ ] **Step 4: Build** → SUCCEEDED.
- [ ] **Step 5: Commit** `git commit --no-gpg-sign -m "feat(v2): kit filtering across calculator, tables, inlay"`

---

# PHASE 6 — Saved setups + Maths additions

## Task 13: SavedSetup model + AppModel setups persistence + CalculatorState.load

**Files:** Modify `ios/Models/AppModel.swift`, `ios/Models/CalculatorState.swift`.

Port `index.html:440-473`.

**Produces:** `struct SavedSetup: Codable, Identifiable { var id = UUID(); var name: String; var scenario: Scenario; var bushChoice; var cutterChoice; var bushCustom/Unit; var cutterCustom/Unit; var template; var templateUnit; var depth; var depthUnit; var mode }` — all `Codable`. (`Scenario`, `SizeChoice`, `CalcMode`, `UnitSystem` must be `Codable`; add conformances.) `AppModel.setups: [SavedSetup]` persisted key `"setups"`; `func addSetup(_:)`, `func deleteSetup(_:)`. `CalculatorState.apply(_ s: SavedSetup)` and `func snapshot(name:) -> SavedSetup`.

- [ ] **Step 1:** Make `Scenario`, `SizeChoice`, `CalcMode` conform to `Codable` (add `: Codable`). `UnitSystem` already Codable.
- [ ] **Step 2:** Add `SavedSetup` (in `AppModel.swift`), `setups` persisted property (JSON, key `"setups"`, load/save like kit), `addSetup`/`deleteSetup`.
- [ ] **Step 3:** Add `CalculatorState.snapshot(name:)` (build a `SavedSetup` from current state) and `apply(_:)` (set all fields from a setup).
- [ ] **Step 4: Build** → SUCCEEDED.
- [ ] **Step 5: Commit** `git commit --no-gpg-sign -m "feat(v2): SavedSetup model + persistence + apply/snapshot"`

## Task 14: Save/load/delete setups on the Calculator tab

**Files:** Modify `ios/Views/CalculatorView.swift`.

- [ ] **Step 1: Save button** — a "★ Save this setup" button that presents an alert with a `TextField` for the name; on confirm, `appModel.addSetup(state.snapshot(name: name))`.
- [ ] **Step 2: Setups list** — a horizontal `ScrollView` of chips (one per `appModel.setups`), each a `Button` that calls `state.apply(setup)`; a swipe/context-menu "Delete" calling `appModel.deleteSetup(setup)`. Show a "No saved setups yet" note when empty.
- [ ] **Step 3: Build** → SUCCEEDED.
- [ ] **Step 4: Commit** `git commit --no-gpg-sign -m "feat(v2): save/load/delete calculator setups"`

## Task 15: Maths explainer — corners + depth paragraphs

**Files:** Modify `ios/Views/MathsView.swift`.

Port `index.html:253-254`.

- [ ] **Step 1:** Add a "Corners" section (round cutter can't cut sharper internal corner than cutter radius; template corner radii ≥ half bush Ø) and a "Depth of cut" section (≤ ~half cutter Ø per pass in hardwood; the calculator suggests passes) — verbatim from `index.html:253-254`.
- [ ] **Step 2: Build** → SUCCEEDED; then `swift test` (regression) → all pass.
- [ ] **Step 3: Commit** `git commit --no-gpg-sign -m "feat(v2): maths explainer corners + depth"`

---

## Self-Review Notes

- **Spec coverage:** imperial+dual-unit (T1,T4,T8,T9), custom sizes (T3,T4), forward/reverse+depth+corners (T5,T6), My Kit + filter + persistence (T10,T11,T12), saved setups (T13,T14), unit-toggle tables + dynamic highlights (T8), inlay unit/kit-aware (T9,T12), Maths additions (T15), metric default (Global Constraints + T3/T7 defaults). All spec sections map to tasks.
- **Additive-then-migrate:** Phase 1 adds new logic beside v1 APIs; the old `Offsets` Double APIs and `CalculatorState.bush/cutter` are removed only once their callers move (T4). Old `Offsets.inlayPairs` (v1) is superseded by `pairOffsets` in T9 — remove it when InlayFinder migrates (note in T9).
- **Type consistency:** `SizeChoice`/`Size`/`UnitSystem`/`CalcMode`/`SizePair`/`InlayPairV2` names are defined in Phase 1–3 and consumed unchanged later; `Codable` conformances added in T13 before `SavedSetup` uses them.
- **Persistence:** UserDefaults keys `kit`/`kitFilter`/`setups` match the spec; `tableUnit` intentionally not persisted.
- **Placeholder scan:** UI-rendering tasks reference exact `index.html` line ranges (file is in the repo) plus explicit Swift interfaces/formulas/strings — no vague "add error handling"; logic tasks carry full code.
