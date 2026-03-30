import Foundation

public enum PresetMigrator {
    public static func migrateIfNeeded(_ preset: IslandPreset) -> IslandPreset {
        guard preset.version < IslandPreset.currentVersion else {
            return preset
        }

        var migrated = preset
        migrated.version = IslandPreset.currentVersion

        for module in IslandModuleID.allCases where migrated.modules[module] == nil {
            migrated.modules[module] = .default(priority: defaultPriority(for: module))
        }

        return migrated
    }

    private static func defaultPriority(for module: IslandModuleID) -> Int {
        switch module {
        case .media:
            return 10
        case .battery:
            return 9
        case .calendar:
            return 8
        case .shelf:
            return 7
        case .event:
            return 6
        }
    }
}
