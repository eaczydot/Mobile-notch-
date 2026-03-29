import XCTest
@testable import BoringNotchShared

final class IslandRuntimeControllerTests: XCTestCase {
    func testRefreshShelfStateMapsLatestShelfItemAndPersistsState() throws {
        let suite = "tests.runtime.refresh.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let shelfStore = AppGroupShelfStore(defaults: defaults)
        let stateStore = AppGroupIslandStateStore(defaults: defaults)
        let activityController = MockActivityController()
        let controller = IslandRuntimeController(
            shelfStore: shelfStore,
            stateStore: stateStore,
            activityController: activityController
        )

        _ = try shelfStore.append([.from(text: "Imported note")])

        let nextState = try controller.refreshShelfState(from: controller.bootstrapState())

        XCTAssertEqual(nextState.activeModule, .shelf)
        XCTAssertEqual(nextState.shelf?.itemCount, 1)
        XCTAssertEqual(stateStore.loadLastKnownContentState(), nextState)
    }

    func testRefreshShelfStateFallsBackToCapturePromptWhenInboxIsEmpty() throws {
        let suite = "tests.runtime.empty.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let controller = IslandRuntimeController(
            shelfStore: AppGroupShelfStore(defaults: defaults),
            stateStore: AppGroupIslandStateStore(defaults: defaults),
            activityController: MockActivityController()
        )

        let nextState = try controller.refreshShelfState(from: controller.bootstrapState())

        XCTAssertEqual(nextState.activeModule, .event)
        XCTAssertEqual(nextState.event?.title, "Capture to Boring Notch")
        XCTAssertEqual(nextState.shelf?.itemCount, 0)
    }

    func testStartAndUpdateActivityForwardStateToActivityController() async throws {
        let suite = "tests.runtime.activity.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let activityController = MockActivityController()
        let controller = IslandRuntimeController(
            shelfStore: AppGroupShelfStore(defaults: defaults),
            stateStore: AppGroupIslandStateStore(defaults: defaults),
            activityController: activityController
        )

        let state = IslandContentState(
            activeModule: .event,
            event: EventState(title: "Shared", detail: "Ready")
        )

        try await controller.startActivity(state: state)
        await controller.updateActivity(state: state)

        XCTAssertEqual(activityController.startedState, state)
        XCTAssertEqual(activityController.updatedState, state)
    }
}

private final class MockActivityController: IslandActivityControlling {
    var startedState: IslandContentState?
    var updatedState: IslandContentState?
    var endedReason: IslandActivityEndReason?

    func startActivity(initial: IslandContentState) async throws {
        startedState = initial
    }

    func updateActivity(_ state: IslandContentState) async {
        updatedState = state
    }

    func endActivity(reason: IslandActivityEndReason) async {
        endedReason = reason
    }
}
