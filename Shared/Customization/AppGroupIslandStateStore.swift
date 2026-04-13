import Foundation

public final class AppGroupIslandStateStore {
    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(defaults: UserDefaults = UserDefaults(suiteName: IslandAppGroup.suiteName) ?? .standard) {
        self.defaults = defaults
    }

    public func loadSelectedPresetID() -> UUID? {
        guard let rawValue = defaults.string(forKey: CustomizationDefaultsKeys.selectedPresetID) else {
            return nil
        }
        return UUID(uuidString: rawValue)
    }

    public func saveSelectedPresetID(_ id: UUID?) {
        defaults.set(id?.uuidString, forKey: CustomizationDefaultsKeys.selectedPresetID)
    }

    public func loadLastKnownContentState() -> IslandContentState? {
        guard let data = defaults.data(forKey: CustomizationDefaultsKeys.lastKnownContentState) else {
            return nil
        }
        return try? decoder.decode(IslandContentState.self, from: data)
    }

    public func saveLastKnownContentState(_ state: IslandContentState) {
        guard let data = try? encoder.encode(state) else {
            return
        }
        defaults.set(data, forKey: CustomizationDefaultsKeys.lastKnownContentState)
    }

    public func loadPersistentLiveActivityEnabled() -> Bool {
        guard defaults.object(forKey: CustomizationDefaultsKeys.persistentLiveActivityEnabled) != nil else {
            return true
        }
        return defaults.bool(forKey: CustomizationDefaultsKeys.persistentLiveActivityEnabled)
    }

    public func savePersistentLiveActivityEnabled(_ isEnabled: Bool) {
        defaults.set(isEnabled, forKey: CustomizationDefaultsKeys.persistentLiveActivityEnabled)
    }
}
