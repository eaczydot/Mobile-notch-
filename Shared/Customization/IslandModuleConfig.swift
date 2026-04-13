import Foundation

public struct IslandModuleConfig: Codable, Hashable, Sendable {
    public var isVisible: Bool
    public var priority: Int
    public var compactStyle: IslandModuleCompactStyle
    public var expandedStyle: IslandModuleExpandedStyle
    public var threshold: Double?
    public var enabledActions: [IslandActionID]

    public init(
        isVisible: Bool,
        priority: Int,
        compactStyle: IslandModuleCompactStyle,
        expandedStyle: IslandModuleExpandedStyle,
        threshold: Double?,
        enabledActions: [IslandActionID]
    ) {
        self.isVisible = isVisible
        self.priority = priority
        self.compactStyle = compactStyle
        self.expandedStyle = expandedStyle
        self.threshold = threshold
        self.enabledActions = enabledActions
    }

    public static func `default`(priority: Int) -> IslandModuleConfig {
        IslandModuleConfig(
            isVisible: true,
            priority: priority,
            compactStyle: .iconAndText,
            expandedStyle: .rich,
            threshold: nil,
            enabledActions: [.openApp]
        )
    }
}
