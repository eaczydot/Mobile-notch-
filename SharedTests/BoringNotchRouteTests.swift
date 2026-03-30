import XCTest
@testable import BoringNotchShared

final class BoringNotchRouteTests: XCTestCase {
    func testParsesCaptureLinkRoute() {
        let route = BoringNotchRoute(url: URL(string: "boringnotch://capture/link")!)

        XCTAssertEqual(route, .captureLink)
        XCTAssertEqual(route?.url.absoluteString, "boringnotch://capture/link")
    }

    func testParsesInboxRoute() {
        XCTAssertEqual(BoringNotchRoute(url: URL(string: "boringnotch://inbox")!), .inbox)
    }

    func testRejectsUnknownRoute() {
        XCTAssertNil(BoringNotchRoute(url: URL(string: "boringnotch://capture/unknown")!))
    }
}
