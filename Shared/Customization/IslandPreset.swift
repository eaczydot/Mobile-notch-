import Foundation

public struct IslandPreset: Codable, Hashable, Identifiable, Sendable {
    public static let currentVersion = 1

    public var id: UUID
    public var name: String
    public var theme: IslandTheme
    public var modules: [IslandModuleID: IslandModuleConfig]
    public var behavior: IslandBehaviorConfig
    public var version: Int

    public init(
        id: UUID = UUID(),
        name: String,
        theme: IslandTheme,
        modules: [IslandModuleID: IslandModuleConfig],
        behavior: IslandBehaviorConfig,
        version: Int = IslandPreset.currentVersion
    ) {
        self.id = id
        self.name = name
        self.theme = theme
        self.modules = modules
        self.behavior = behavior
        self.version = version
    }

    public static let `default` = IslandPreset(
        name: "Default",
        theme: .default,
        modules: [
            .media: .default(priority: 10),
            .battery: .default(priority: 9),
            .calendar: .default(priority: 8),
            .shelf: .default(priority: 7),
            .event: .default(priority: 6),
        ],
        behavior: .default
    )
}
