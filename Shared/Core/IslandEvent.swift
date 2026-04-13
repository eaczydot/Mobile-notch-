import Foundation

public struct IslandEvent: Codable, Hashable, Sendable {
    public let module: IslandModuleID
    public let timestamp: Date
    public let payload: Payload

    public init(module: IslandModuleID, timestamp: Date = .now, payload: Payload) {
        self.module = module
        self.timestamp = timestamp
        self.payload = payload
    }

    public enum Payload: Codable, Hashable, Sendable {
        case media(MediaPayload)
        case battery(BatteryPayload)
        case calendar(CalendarPayload)
        case shelf(ShelfPayload)
        case event(EventPayload)
    }
}

public struct MediaPayload: Codable, Hashable, Sendable {
    public var title: String
    public var subtitle: String
    public var progress: Double
    public var isPlaying: Bool

    public init(title: String, subtitle: String, progress: Double, isPlaying: Bool) {
        self.title = title
        self.subtitle = subtitle
        self.progress = progress
        self.isPlaying = isPlaying
    }
}

public struct BatteryPayload: Codable, Hashable, Sendable {
    public var level: Double
    public var isCharging: Bool

    public init(level: Double, isCharging: Bool) {
        self.level = level
        self.isCharging = isCharging
    }
}

public struct CalendarPayload: Codable, Hashable, Sendable {
    public var title: String
    public var startsAt: Date

    public init(title: String, startsAt: Date) {
        self.title = title
        self.startsAt = startsAt
    }
}

public struct ShelfPayload: Codable, Hashable, Sendable {
    public var itemCount: Int
    public var lastItemName: String?
    public var highlightedTitle: String?
    public var highlightedDetail: String?
    public var highlightedKind: ShelfItemRecord.Kind?
    public var highlightedDueDate: Date?
    public var pendingReminderCount: Int

    public init(
        itemCount: Int,
        lastItemName: String?,
        highlightedTitle: String? = nil,
        highlightedDetail: String? = nil,
        highlightedKind: ShelfItemRecord.Kind? = nil,
        highlightedDueDate: Date? = nil,
        pendingReminderCount: Int = 0
    ) {
        self.itemCount = itemCount
        self.lastItemName = lastItemName
        self.highlightedTitle = highlightedTitle
        self.highlightedDetail = highlightedDetail
        self.highlightedKind = highlightedKind
        self.highlightedDueDate = highlightedDueDate
        self.pendingReminderCount = pendingReminderCount
    }
}

public struct EventPayload: Codable, Hashable, Sendable {
    public var title: String
    public var detail: String

    public init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }
}

public protocol IslandEventProvider {
    var eventStream: AsyncStream<IslandEvent> { get }
    func start() async
    func stop()
}
