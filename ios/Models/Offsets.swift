import Foundation

enum Scenario: String, CaseIterable, Identifiable {
    case femHole, femPlug, maleHole, malePlug

    var id: String { rawValue }

    var name: String {
        switch self {
        case .femHole:  return "Female template → Hole"
        case .femPlug:  return "Female template → Plug"
        case .maleHole: return "Male template → Hole"
        case .malePlug: return "Male template → Plug"
        }
    }

    /// true → offset uses (B − C)/2, false → (B + C)/2
    var isDiff: Bool {
        switch self {
        case .femHole, .malePlug: return true
        case .femPlug, .maleHole: return false
        }
    }

    /// -1 → result = template − 2×offset, +1 → template + 2×offset
    var sign: Int {
        switch self {
        case .femHole, .femPlug: return -1
        case .maleHole, .malePlug: return +1
        }
    }

    var piece: String {
        switch self {
        case .femHole, .maleHole: return "Hole"
        case .femPlug, .malePlug: return "Plug"
        }
    }

    var rel: String { sign < 0 ? "smaller than template" : "bigger than template" }

    var formula: String { isDiff ? "(B − C) / 2" : "(B + C) / 2" }

    var resultFormula: String { sign < 0 ? "Template − 2×offset" : "Template + 2×offset" }

    func resultSize(template t: Double, offset o: Double) -> Double {
        t + Double(sign) * 2 * o
    }
}

struct Setup: Identifiable, Equatable {
    let bush: Double
    let cutter: Double
    var id: String { "\(bush)-\(cutter)" }
}

struct InlayPair: Identifiable {
    let offset: Double
    let holes: [Setup]
    let plugs: [Setup]
    var id: Double { offset }
}

enum Offsets {
    static let bushes: [Double]  = [10, 12, 14, 16, 18, 20, 24, 30]
    static let cutters: [Double] = [4, 5, 6, 7, 8, 10, 12]

    /// Cutter must clear the bush bore (matches grey cells in the source chart).
    static func impossible(bush b: Double, cutter c: Double) -> Bool { (b - c) <= 2 }

    static func offset(_ s: Scenario, bush b: Double, cutter c: Double) -> Double {
        s.isDiff ? (b - c) / 2 : (b + c) / 2
    }

    /// Integer values print without a decimal; others print up to 2 dp with trailing zeros trimmed.
    static func fmt(_ n: Double) -> String {
        if n == n.rounded() { return String(Int(n)) }
        var s = String(format: "%.2f", n)
        while s.hasSuffix("0") { s.removeLast() }
        if s.hasSuffix(".") { s.removeLast() }
        return s
    }

    static func inlayPairs() -> [InlayPair] {
        var holes: [Double: [Setup]] = [:]
        var plugs: [Double: [Setup]] = [:]
        for b in bushes {
            for c in cutters where !impossible(bush: b, cutter: c) {
                holes[(b - c) / 2, default: []].append(Setup(bush: b, cutter: c))
                plugs[(b + c) / 2, default: []].append(Setup(bush: b, cutter: c))
            }
        }
        return holes.keys
            .filter { plugs[$0] != nil }
            .sorted()
            .map { InlayPair(offset: $0, holes: holes[$0]!, plugs: plugs[$0]!) }
    }
}

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
            let kd = String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), (b.mm - c.mm) / 2)
            let ks = String(format: "%.4f", locale: Locale(identifier: "en_US_POSIX"), (b.mm + c.mm) / 2)
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
