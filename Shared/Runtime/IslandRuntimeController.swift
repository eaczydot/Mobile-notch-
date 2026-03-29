import Foundation

public final class IslandRuntimeController {
    private let shelfStore: AppGroupShelfStore
    private let stateStore: AppGroupIslandStateStore
    private let activityController: IslandActivityControlling

    public init(
        shelfStore: AppGroupShelfStore = AppGroupShelfStore(),
        stateStore: AppGroupIslandStateStore = AppGroupIslandStateStore(),
        activityController: IslandActivityControlling = IslandActivityManager()
    ) {
        self.shelfStore = shelfStore
        self.stateStore = stateStore
        self.activityController = activityController
    }

    public func bootstrapState() -> IslandContentState {
        if let persisted = stateStore.loadLastKnownContentState() {
            return persisted
        }
        return Self.emptyCaptureState()
    }

    public func refreshShelfState(from currentState: IslandContentState) throws -> IslandContentState {
        let nextState: IslandContentState

        if let event = try shelfStore.latestEvent() {
            nextState = IslandStateMapper.apply(event: event, to: currentState)
        } else {
            nextState = Self.emptyCaptureState(from: currentState)
        }

        stateStore.saveLastKnownContentState(nextState)
        return nextState
    }

    public func apply(event: IslandEvent, to currentState: IslandContentState) -> IslandContentState {
        let nextState = IslandStateMapper.apply(event: event, to: currentState)
        stateStore.saveLastKnownContentState(nextState)
        return nextState
    }

    public func startActivity(state: IslandContentState) async throws {
        stateStore.saveLastKnownContentState(state)
        try await activityController.startActivity(initial: state)
    }

    public func updateActivity(state: IslandContentState) async {
        stateStore.saveLastKnownContentState(state)
        await activityController.updateActivity(state)
    }

    public func endActivity(reason: IslandActivityEndReason) async {
        await activityController.endActivity(reason: reason)
    }

    public static func emptyCaptureState(from currentState: IslandContentState? = nil) -> IslandContentState {
        IslandContentState(
            activeModule: .event,
            media: currentState?.media,
            battery: currentState?.battery,
            calendar: currentState?.calendar,
            shelf: ShelfState(itemCount: 0, latestItemName: nil),
            event: EventState(
                title: "Capture to Boring Notch",
                detail: "Save links and reminders in one tap."
            )
        )
    }
}
