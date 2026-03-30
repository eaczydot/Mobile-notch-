import Foundation

#if os(iOS)
import ActivityKit

public struct IslandAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var payload: IslandContentState

        public init(payload: IslandContentState) {
            self.payload = payload
        }
    }

    public var name: String

    public init(name: String) {
        self.name = name
    }
}
#endif
