import XCTest
@testable import BoringNotchShared

final class CustomizationStoreTests: XCTestCase {
    func testSaveLoadExportImportRoundTrip() throws {
        let suite = "tests.boringnotch.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)

        let store = UserDefaultsCustomizationStore(defaults: defaults, presetsKey: "presets")

        let first = IslandPreset.default
        try store.savePreset(first)

        let loaded = try store.loadPresets()
        XCTAssertFalse(loaded.isEmpty)

        let exported = try store.export([first.id])
        let imported = try store.import(exported)
        XCTAssertFalse(imported.isEmpty)
    }
}
