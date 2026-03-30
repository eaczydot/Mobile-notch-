import XCTest
@testable import BoringNotchShared

final class IslandStateMapperTests: XCTestCase {
    func testMediaEventMapsToMediaStateAndModule() {
        let initial = IslandContentState(activeModule: .event)
        let event = IslandEvent(
            module: .media,
            payload: .media(.init(title: "Song", subtitle: "Artist", progress: 0.4, isPlaying: true))
        )

        let next = IslandStateMapper.apply(event: event, to: initial)

        XCTAssertEqual(next.activeModule, .media)
        XCTAssertEqual(next.media?.title, "Song")
        XCTAssertEqual(next.media?.subtitle, "Artist")
    }

    func testShelfEventMapsHighlightedReminderDetails() {
        let initial = IslandContentState(activeModule: .event)
        let event = IslandEvent(
            module: .shelf,
            payload: .shelf(
                .init(
                    itemCount: 3,
                    lastItemName: "Newest capture",
                    highlightedTitle: "Ship TestFlight",
                    highlightedDetail: "Due soon",
                    highlightedKind: .reminder,
                    highlightedDueDate: Date(timeIntervalSince1970: 100),
                    pendingReminderCount: 2
                )
            )
        )

        let next = IslandStateMapper.apply(event: event, to: initial)

        XCTAssertEqual(next.activeModule, .shelf)
        XCTAssertEqual(next.shelf?.highlightedKind, .reminder)
        XCTAssertEqual(next.shelf?.pendingReminderCount, 2)
        XCTAssertEqual(next.shelf?.highlightedTitle, "Ship TestFlight")
    }
}
