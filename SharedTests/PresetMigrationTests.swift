import XCTest
@testable import BoringNotchShared

final class PresetMigrationTests: XCTestCase {
    func testMigratesMissingModulesToDefaults() {
        let legacy = IslandPreset(
            name: "Legacy",
            theme: .default,
            modules: [.media: .default(priority: 1)],
            behavior: .default,
            version: 0
        )

        let migrated = PresetMigrator.migrateIfNeeded(legacy)

        XCTAssertEqual(migrated.version, IslandPreset.currentVersion)
        XCTAssertEqual(migrated.modules.count, IslandModuleID.allCases.count)
        XCTAssertNotNil(migrated.modules[.battery])
        XCTAssertNotNil(migrated.modules[.event])
    }
}
