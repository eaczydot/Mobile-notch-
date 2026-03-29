import Foundation

#if os(iOS)
import ActivityKit
#endif

public enum IslandActivityEndReason: String, Codable, Sendable {
    case user
    case stale
    case system
}

public protocol IslandActivityControlling {
    func startActivity(initial: IslandContentState) async throws
    func updateActivity(_ state: IslandContentState) async
    func endActivity(reason: IslandActivityEndReason) async
}

public final class IslandActivityManager: IslandActivityControlling {
    #if os(iOS)
    @available(iOS 16.1, *)
    private var activeActivity: Activity<IslandAttributes>?
    #endif

    public init() {}

    public func startActivity(initial: IslandContentState) async throws {
        #if os(iOS)
        if #available(iOS 16.1, *) {
            if let existing = currentActivity() {
                await existing.update(.init(state: .init(payload: initial), staleDate: nil))
                activeActivity = existing
                return
            }

            let attributes = IslandAttributes(name: "Boring Notch")
            let state = IslandAttributes.ContentState(payload: initial)
            activeActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
        }
        #endif
    }

    public func updateActivity(_ state: IslandContentState) async {
        #if os(iOS)
        if #available(iOS 16.1, *),
           let activeActivity = currentActivity() {
            await activeActivity.update(.init(state: .init(payload: state), staleDate: nil))
        }
        #endif
    }

    public func endActivity(reason: IslandActivityEndReason) async {
        #if os(iOS)
        if #available(iOS 16.1, *),
           let activeActivity = currentActivity() {
            await activeActivity.end(
                .init(
                    state: .init(
                        payload: IslandContentState(
                            activeModule: .event,
                            event: .init(title: "Island Ended", detail: reason.rawValue.capitalized)
                        )
                    ),
                    staleDate: .now
                ),
                dismissalPolicy: .immediate
            )
            self.activeActivity = nil
        }
        #endif
    }

    #if os(iOS)
    @available(iOS 16.1, *)
    private func currentActivity() -> Activity<IslandAttributes>? {
        if let activeActivity {
            return activeActivity
        }

        let existing = Activity<IslandAttributes>.activities.first
        activeActivity = existing
        return existing
    }
    #endif
}
