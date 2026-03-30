import XCTest
@testable import BoringNotchShared

final class IslandActionControllerTests: XCTestCase {
    func testCaptureClipboardNormalizesHostnameIntoURLRecord() async throws {
        let suite = "tests.actions.clipboard.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let controller = IslandActionController(
            shelfStore: AppGroupShelfStore(defaults: defaults),
            stateStore: AppGroupIslandStateStore(defaults: defaults),
            activityController: MockActivityController()
        )

        let item = try await controller.captureClipboardValue("example.com/product")
        let storedItems = try AppGroupShelfStore(defaults: defaults).loadItems()

        XCTAssertEqual(item?.kind, .url)
        XCTAssertEqual(item?.value, "https://example.com/product")
        XCTAssertEqual(storedItems.first?.value, "https://example.com/product")
    }

    func testCompleteTopReminderPrefersDueReminder() async throws {
        let suite = "tests.actions.complete.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let shelfStore = AppGroupShelfStore(defaults: defaults)
        _ = try shelfStore.append([
            ShelfItemRecord.fromReminder(
                title: "Ship beta build",
                dueDate: Date(timeIntervalSince1970: 50),
                createdAt: Date(timeIntervalSince1970: 10)
            ),
            ShelfItemRecord.fromReminder(
                title: "Later cleanup",
                dueDate: Date(timeIntervalSince1970: 100),
                createdAt: Date(timeIntervalSince1970: 20)
            )
        ])

        let controller = IslandActionController(
            shelfStore: shelfStore,
            stateStore: AppGroupIslandStateStore(defaults: defaults),
            activityController: MockActivityController()
        )

        let completed = try await controller.completeTopReminder()
        let items = try shelfStore.loadItems()

        XCTAssertEqual(completed?.title, "Ship beta build")
        XCTAssertEqual(items.first(where: { $0.title == "Ship beta build" })?.isCompleted, true)
        XCTAssertEqual(try controller.nextPendingReminder()?.title, "Later cleanup")
    }

    func testCompleteTopReminderReturnsNilWhenNoPendingReminderExists() async throws {
        let suite = "tests.actions.none.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let controller = IslandActionController(
            shelfStore: AppGroupShelfStore(defaults: defaults),
            stateStore: AppGroupIslandStateStore(defaults: defaults),
            activityController: MockActivityController()
        )

        let reminder = try await controller.completeTopReminder()
        XCTAssertNil(reminder)
    }
}

private final class MockActivityController: IslandActivityControlling {
    func startActivity(initial: IslandContentState) async throws {}
    func updateActivity(_ state: IslandContentState) async {}
    func endActivity(reason: IslandActivityEndReason) async {}
}
