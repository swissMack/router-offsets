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
