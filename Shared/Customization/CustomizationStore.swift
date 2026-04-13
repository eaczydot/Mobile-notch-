import Foundation

public enum CustomizationStoreError: Error {
    case notFound
    case invalidPayload
}

public protocol CustomizationStore {
    func loadPresets() throws -> [IslandPreset]
    func savePreset(_ preset: IslandPreset) throws
    func deletePreset(_ presetID: UUID) throws
    func export(_ presetIDs: [UUID]) throws -> Data
    func `import`(_ payload: Data) throws -> [IslandPreset]
}
