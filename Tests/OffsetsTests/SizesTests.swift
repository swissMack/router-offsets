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
        XCTAssertEqual(Catalog.size(id: "i1-2")?.mm ?? -1, 12.7, accuracy: 1e-9)
    }
    func testFracIn() {
        // 25.4 mm = 1" exactly -> n=64,d=64 reduces to 1/1 -> whole "1", no fraction remainder.
        XCTAssertEqual(fracIn(25.4), "1″")
        // 25.4 * 5/16 mm = 5/16" exactly -> n=20,d=64 reduces to 5/16, w=0.
        XCTAssertEqual(fracIn(25.4 * 5 / 16), "5/16″")
        // 0 mm short-circuits to "0″" before the approx/reduction logic applies.
        XCTAssertEqual(fracIn(0), "0″")
        // 8 mm -> inches = 0.31496...; *64 = 20.157... rounds to 20 (5/16), but
        // |0.31496 - 20/64| = 0.00246 > 0.0005, so the "≈ " prefix applies (not exact).
        XCTAssertTrue(fracIn(8).hasPrefix("≈"))   // 8 mm is not an exact 1/64"
    }
    func testBothAndToMM() {
        // Hand-verified: 24 mm -> inches = 24/25.4 = 0.944881...; *64 = 60.4724... rounds to 60.
        // |0.944881 - 60/64(=0.9375)| = 0.007381 > 0.0005 -> "≈ " prefix applies.
        // 60/64 reduces (divide by 2 while even, d>1): 60/64 -> 30/32 -> 15/16 (15 is odd, stop).
        // w = 15/16 = 0 (int division), so no whole part; remainder fraction is "15/16".
        // Result: "≈ 15/16″"; fmtN(24) = Math.round(2400)/100 = 24 -> "24".
        XCTAssertEqual(both(24), "24 mm · ≈ 15/16″")
        XCTAssertEqual(toMM(1, .imperial), 25.4, accuracy: 1e-9)
        XCTAssertEqual(toMM(60, .metric), 60)
        // fmtN returns a display String (not a Double): round to 2dp, trim trailing zeros.
        XCTAssertEqual(fmtN(8.005), "8.01")
    }
}
