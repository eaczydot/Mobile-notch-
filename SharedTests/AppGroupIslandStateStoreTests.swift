import XCTest
@testable import BoringNotchShared

final class AppGroupIslandStateStoreTests: XCTestCase {
    func testPersistsSelectedPresetIDLastKnownStateAndPersistentActivityPreference() {
        let suite = "tests.state.store.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = AppGroupIslandStateStore(defaults: defaults)
        let presetID = UUID()
        let state = IslandContentState(
            activeModule: .event,
            event: EventState(title: "Shared", detail: "From tests")
        )

        store.saveSelectedPresetID(presetID)
        store.saveLastKnownContentState(state)
        store.savePersistentLiveActivityEnabled(false)

        XCTAssertEqual(store.loadSelectedPresetID(), presetID)
        XCTAssertEqual(store.loadLastKnownContentState(), state)
        XCTAssertFalse(store.loadPersistentLiveActivityEnabled())
    }
}
