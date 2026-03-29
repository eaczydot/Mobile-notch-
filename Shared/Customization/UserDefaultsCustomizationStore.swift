import Foundation

public final class UserDefaultsCustomizationStore: CustomizationStore {
    private let defaults: UserDefaults
    private let presetsKey: String
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(
        defaults: UserDefaults = .standard,
        presetsKey: String = CustomizationDefaultsKeys.presets
    ) {
        self.defaults = defaults
        self.presetsKey = presetsKey
        self.encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
    }

    public func loadPresets() throws -> [IslandPreset] {
        guard let data = defaults.data(forKey: presetsKey) else {
            return [IslandPreset.default]
        }

        let decoded = try decoder.decode([IslandPreset].self, from: data)
        let migrated = decoded.map(PresetMigrator.migrateIfNeeded)
        return migrated.isEmpty ? [IslandPreset.default] : migrated
    }

    public func savePreset(_ preset: IslandPreset) throws {
        var presets = try loadPresets()
        if let index = presets.firstIndex(where: { $0.id == preset.id }) {
            presets[index] = PresetMigrator.migrateIfNeeded(preset)
        } else {
            presets.append(PresetMigrator.migrateIfNeeded(preset))
        }
        let data = try encoder.encode(presets)
        defaults.set(data, forKey: presetsKey)
    }

    public func deletePreset(_ presetID: UUID) throws {
        var presets = try loadPresets()
        presets.removeAll { $0.id == presetID }
        if presets.isEmpty {
            presets = [.default]
        }
        let data = try encoder.encode(presets)
        defaults.set(data, forKey: presetsKey)
    }

    public func export(_ presetIDs: [UUID]) throws -> Data {
        let presets = try loadPresets().filter { presetIDs.contains($0.id) }
        guard !presets.isEmpty else {
            throw CustomizationStoreError.notFound
        }
        return try encoder.encode(presets)
    }

    public func `import`(_ payload: Data) throws -> [IslandPreset] {
        let imported = try decoder.decode([IslandPreset].self, from: payload)
        guard !imported.isEmpty else {
            throw CustomizationStoreError.invalidPayload
        }

        var existing = try loadPresets()
        for preset in imported.map(PresetMigrator.migrateIfNeeded) {
            if let index = existing.firstIndex(where: { $0.id == preset.id }) {
                existing[index] = preset
            } else {
                existing.append(preset)
            }
        }

        let data = try encoder.encode(existing)
        defaults.set(data, forKey: presetsKey)

        return existing
    }
}
