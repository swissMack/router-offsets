import XCTest
@testable import RouterOffsetsLogic

final class OffsetsTests: XCTestCase {

    func testOffsetPerScenario() {
        XCTAssertEqual(Offsets.offset(.femHole, bush: 24, cutter: 8), 8)   // (24-8)/2
        XCTAssertEqual(Offsets.offset(.femPlug, bush: 10, cutter: 6), 8)   // (10+6)/2
        XCTAssertEqual(Offsets.offset(.maleHole, bush: 20, cutter: 4), 12) // (20+4)/2
        XCTAssertEqual(Offsets.offset(.malePlug, bush: 30, cutter: 12), 9) // (30-12)/2
    }

    func testImpossibleBoundary() {
        XCTAssertTrue(Offsets.impossible(bush: 12, cutter: 10))  // diff 2 -> impossible
        XCTAssertFalse(Offsets.impossible(bush: 12, cutter: 9))  // diff 3 -> ok
        XCTAssertTrue(Offsets.impossible(bush: 10, cutter: 8))   // diff 2 -> impossible
    }

    func testResultSize() {
        XCTAssertEqual(Scenario.femHole.resultSize(template: 60, offset: 8), 44)  // 60 - 16
        XCTAssertEqual(Scenario.maleHole.resultSize(template: 60, offset: 12), 84) // 60 + 24
    }

    func testFmtTrimsTrailingZeros() {
        XCTAssertEqual(Offsets.fmt(8), "8")
        XCTAssertEqual(Offsets.fmt(4.5), "4.5")
        XCTAssertEqual(Offsets.fmt(2.25), "2.25")
    }

    func testInlayPairsIncludesOffset8() {
        let pairs = Offsets.inlayPairs()
        XCTAssertEqual(pairs.map(\.offset), pairs.map(\.offset).sorted())  // ascending
        guard let eight = pairs.first(where: { $0.offset == 8 }) else {
            return XCTFail("no offset-8 pair")
        }
        XCTAssertTrue(eight.holes.contains(Setup(bush: 24, cutter: 8)))
        XCTAssertTrue(eight.plugs.contains(Setup(bush: 10, cutter: 6)))
    }
}
