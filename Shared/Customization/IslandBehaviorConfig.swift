import Foundation

public struct IslandBehaviorConfig: Codable, Hashable, Sendable {
    public var updateIntervalSeconds: Int
    public var hapticsEnabled: Bool
    public var staleTimeoutSeconds: Int
    public var autoDismiss: Bool

    public init(
        updateIntervalSeconds: Int,
        hapticsEnabled: Bool,
        staleTimeoutSeconds: Int,
        autoDismiss: Bool
    ) {
        self.updateIntervalSeconds = updateIntervalSeconds
        self.hapticsEnabled = hapticsEnabled
        self.staleTimeoutSeconds = staleTimeoutSeconds
        self.autoDismiss = autoDismiss
    }

    public static let `default` = IslandBehaviorConfig(
        updateIntervalSeconds: 5,
        hapticsEnabled: true,
        staleTimeoutSeconds: 120,
        autoDismiss: false
    )
}
