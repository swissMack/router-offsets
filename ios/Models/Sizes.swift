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
