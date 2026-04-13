import XCTest
@testable import BoringNotchShared

final class AppGroupShelfStoreTests: XCTestCase {
    func testMigratesLegacyStringArrayIntoStructuredRecords() throws {
        let suite = "tests.shelf.migration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        defaults.set(
            [
                "https://example.com/article",
                "A note from another app"
            ],
            forKey: CustomizationDefaultsKeys.shelfItems
        )

        let store = AppGroupShelfStore(defaults: defaults)
        let items = try store.loadItems()

        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.first?.kind, .url)
        XCTAssertEqual(items.last?.kind, .text)
        XCTAssertNotNil(defaults.data(forKey: CustomizationDefaultsKeys.shelfRecords))
    }

    func testAppendDeduplicatesByKindAndValueAndKeepsNewestFirst() throws {
        let suite = "tests.shelf.append.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = AppGroupShelfStore(defaults: defaults)
        _ = try store.append([
            ShelfItemRecord.from(text: "First", createdAt: Date(timeIntervalSince1970: 10)),
            ShelfItemRecord.from(url: URL(string: "https://example.com/one")!, createdAt: Date(timeIntervalSince1970: 20))
        ])

        let items = try store.append([
            ShelfItemRecord.from(text: "First", createdAt: Date(timeIntervalSince1970: 30)),
            ShelfItemRecord.from(text: "Second", createdAt: Date(timeIntervalSince1970: 25))
        ])

        XCTAssertEqual(items.map(\.title), ["First", "Second", "example.com"])
    }

    func testReminderItemsRemainDistinctByID() throws {
        let suite = "tests.shelf.reminders.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = AppGroupShelfStore(defaults: defaults)
        _ = try store.append([
            ShelfItemRecord.fromReminder(title: "Call Alex"),
            ShelfItemRecord.fromReminder(title: "Call Alex")
        ])

        let items = try store.loadItems()
        XCTAssertEqual(items.count, 2)
        XCTAssertEqual(items.filter { $0.kind == .reminder }.count, 2)
    }

    func testLatestEventReflectsCurrentShelf() throws {
        let suite = "tests.shelf.event.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = AppGroupShelfStore(defaults: defaults)
        _ = try store.append([
            ShelfItemRecord.from(text: "Inbox item")
        ])

        let event = try store.latestEvent()

        XCTAssertEqual(event?.module, .shelf)
        if case .shelf(let payload)? = event?.payload {
            XCTAssertEqual(payload.itemCount, 1)
            XCTAssertEqual(payload.lastItemName, "Inbox item")
            XCTAssertEqual(payload.highlightedKind, .text)
            XCTAssertEqual(payload.highlightedTitle, "Inbox item")
        } else {
            XCTFail("Expected shelf payload")
        }
    }

    func testLatestEventPrefersDueReminderOverNewerCapture() throws {
        let suite = "tests.shelf.priority.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = AppGroupShelfStore(defaults: defaults)
        _ = try store.append([
            ShelfItemRecord.fromReminder(
                title: "Renew TestFlight build",
                dueDate: Date(timeIntervalSince1970: 50),
                createdAt: Date(timeIntervalSince1970: 10)
            ),
            ShelfItemRecord.from(url: URL(string: "https://example.com/newer")!, createdAt: Date(timeIntervalSince1970: 100))
        ])

        let event = try store.latestEvent(now: Date(timeIntervalSince1970: 40))

        if case .shelf(let payload)? = event?.payload {
            XCTAssertEqual(payload.highlightedKind, .reminder)
            XCTAssertEqual(payload.highlightedTitle, "Renew TestFlight build")
            XCTAssertEqual(payload.pendingReminderCount, 1)
        } else {
            XCTFail("Expected shelf payload")
        }
    }
}
