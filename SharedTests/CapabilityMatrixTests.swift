import XCTest
@testable import BoringNotchShared

final class CapabilityMatrixTests: XCTestCase {
    func testCurrentMatrixIsConsistent() {
        let matrix = CapabilityMatrix.current()
        if matrix.supportsDynamicIsland {
            XCTAssertTrue(matrix.supportsLiveActivities)
        }
    }

    func testSupportsDynamicIslandForKnownProModel() {
        XCTAssertTrue(CapabilityMatrix.supportsDynamicIsland(modelIdentifier: "iPhone15,2", isPhone: true))
    }

    func testSupportsDynamicIslandForFutureFamilies() {
        XCTAssertTrue(CapabilityMatrix.supportsDynamicIsland(modelIdentifier: "iPhone16,1", isPhone: true))
        XCTAssertTrue(CapabilityMatrix.supportsDynamicIsland(modelIdentifier: "iPhone18,4", isPhone: true))
    }

    func testDoesNotSupportDynamicIslandForNonPhoneOrOlderModel() {
        XCTAssertFalse(CapabilityMatrix.supportsDynamicIsland(modelIdentifier: "iPhone14,7", isPhone: true))
        XCTAssertFalse(CapabilityMatrix.supportsDynamicIsland(modelIdentifier: "iPad16,1", isPhone: false))
        XCTAssertFalse(CapabilityMatrix.supportsDynamicIsland(modelIdentifier: nil, isPhone: true))
    }
}
