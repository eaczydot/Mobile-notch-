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

public final class IslandActionController {
    private let shelfStore: AppGroupShelfStore
    private let stateStore: AppGroupIslandStateStore
    private let runtimeController: IslandRuntimeController

    public init(
        shelfStore: AppGroupShelfStore = AppGroupShelfStore(),
        stateStore: AppGroupIslandStateStore = AppGroupIslandStateStore(),
        activityController: IslandActivityControlling = IslandActivityManager()
    ) {
        self.shelfStore = shelfStore
        self.stateStore = stateStore
        self.runtimeController = IslandRuntimeController(
            shelfStore: shelfStore,
            stateStore: stateStore,
            activityController: activityController
        )
    }

    @discardableResult
    public func append(_ items: [ShelfItemRecord]) async throws -> IslandContentState {
        _ = try shelfStore.append(items)
        return try await refreshActivityFromShelf()
    }

    @discardableResult
    public func upsert(_ item: ShelfItemRecord) async throws -> IslandContentState {
        _ = try shelfStore.upsert(item)
        return try await refreshActivityFromShelf()
    }

    @discardableResult
    public func remove(id: UUID) async throws -> IslandContentState {
        _ = try shelfStore.remove(id: id)
        return try await refreshActivityFromShelf()
    }

    @discardableResult
    public func clear() async -> IslandContentState {
        shelfStore.clear()
        return await (try? refreshActivityFromShelf()) ?? runtimeController.bootstrapState()
    }

    @discardableResult
    public func refreshActivityFromShelf() async throws -> IslandContentState {
        let currentState = stateStore.loadLastKnownContentState() ?? runtimeController.bootstrapState()
        let nextState = try runtimeController.refreshShelfState(from: currentState)

        guard stateStore.loadPersistentLiveActivityEnabled(),
              CapabilityMatrix.current().supportsLiveActivities else {
            return nextState
        }

        try await runtimeController.startActivity(state: nextState)
        return nextState
    }

    public func captureClipboardValue(_ rawValue: String?) async throws -> ShelfItemRecord? {
        guard let item = Self.shelfItem(fromClipboardValue: rawValue) else {
            return nil
        }

        _ = try await append([item])
        return item
    }

    public func completeTopReminder() async throws -> ShelfItemRecord? {
        guard let reminder = try nextPendingReminder() else {
            return nil
        }

        return try await setReminderCompletion(id: reminder.id, isCompleted: true)
    }

    public func setReminderCompletion(id: UUID, isCompleted: Bool) async throws -> ShelfItemRecord? {
        let items = try shelfStore.loadItems()
        guard var reminder = items.first(where: { $0.id == id && $0.kind == .reminder }) else {
            return nil
        }

        reminder.isCompleted = isCompleted
        _ = try await upsert(reminder)
        return reminder
    }

    public func nextPendingReminder() throws -> ShelfItemRecord? {
        let items = try shelfStore.loadItems()
        let pendingReminders = items.filter { $0.kind == .reminder && !$0.isCompleted }

        let dueReminder = pendingReminders
            .filter { $0.dueDate != nil }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first

        return dueReminder ?? pendingReminders.first
    }

    public static func shelfItem(fromClipboardValue rawValue: String?) -> ShelfItemRecord? {
        let trimmed = rawValue?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !trimmed.isEmpty else {
            return nil
        }

        if let url = normalizedURL(from: trimmed) {
            return .from(url: url)
        }

        return .from(text: trimmed)
    }

    private static func normalizedURL(from rawValue: String) -> URL? {
        if let url = URL(string: rawValue), url.scheme != nil {
            return url
        }

        guard !rawValue.contains(" "),
              rawValue.contains(".") else {
            return nil
        }

        return URL(string: "https://\(rawValue)")
    }
}
