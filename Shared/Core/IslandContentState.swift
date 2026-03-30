import Foundation

public struct IslandContentState: Codable, Hashable, Sendable {
    public var lastUpdated: Date
    public var activeModule: IslandModuleID
    public var media: MediaState?
    public var battery: BatteryState?
    public var calendar: CalendarState?
    public var shelf: ShelfState?
    public var event: EventState?

    public init(
        lastUpdated: Date = .now,
        activeModule: IslandModuleID = .event,
        media: MediaState? = nil,
        battery: BatteryState? = nil,
        calendar: CalendarState? = nil,
        shelf: ShelfState? = nil,
        event: EventState? = nil
    ) {
        self.lastUpdated = lastUpdated
        self.activeModule = activeModule
        self.media = media
        self.battery = battery
        self.calendar = calendar
        self.shelf = shelf
        self.event = event
    }
}

public struct MediaState: Codable, Hashable, Sendable {
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

public struct BatteryState: Codable, Hashable, Sendable {
    public var percentage: Int
    public var isCharging: Bool

    public init(percentage: Int, isCharging: Bool) {
        self.percentage = percentage
        self.isCharging = isCharging
    }
}

public struct CalendarState: Codable, Hashable, Sendable {
    public var nextEventTitle: String
    public var startDate: Date

    public init(nextEventTitle: String, startDate: Date) {
        self.nextEventTitle = nextEventTitle
        self.startDate = startDate
    }
}

public struct ShelfState: Codable, Hashable, Sendable {
    public var itemCount: Int
    public var latestItemName: String?
    public var highlightedTitle: String?
    public var highlightedDetail: String?
    public var highlightedKind: ShelfItemRecord.Kind?
    public var highlightedDueDate: Date?
    public var pendingReminderCount: Int

    public init(
        itemCount: Int,
        latestItemName: String?,
        highlightedTitle: String? = nil,
        highlightedDetail: String? = nil,
        highlightedKind: ShelfItemRecord.Kind? = nil,
        highlightedDueDate: Date? = nil,
        pendingReminderCount: Int = 0
    ) {
        self.itemCount = itemCount
        self.latestItemName = latestItemName
        self.highlightedTitle = highlightedTitle
        self.highlightedDetail = highlightedDetail
        self.highlightedKind = highlightedKind
        self.highlightedDueDate = highlightedDueDate
        self.pendingReminderCount = pendingReminderCount
    }
}

public struct EventState: Codable, Hashable, Sendable {
    public var title: String
    public var detail: String

    public init(title: String, detail: String) {
        self.title = title
        self.detail = detail
    }
}

public enum BoringNotchRoute: Hashable, Sendable, Identifiable {
    case island
    case captureLink
    case captureReminder
    case inbox

    public var id: String {
        url.absoluteString
    }

    public var url: URL {
        switch self {
        case .island:
            return URL(string: "boringnotch://island")!
        case .captureLink:
            return URL(string: "boringnotch://capture/link")!
        case .captureReminder:
            return URL(string: "boringnotch://capture/reminder")!
        case .inbox:
            return URL(string: "boringnotch://inbox")!
        }
    }

    public init?(url: URL) {
        guard url.scheme?.lowercased() == "boringnotch" else {
            return nil
        }

        let host = (url.host ?? "").lowercased()
        let path = url.path.lowercased()

        switch (host, path) {
        case ("island", ""):
            self = .island
        case ("capture", "/link"):
            self = .captureLink
        case ("capture", "/reminder"):
            self = .captureReminder
        case ("inbox", ""):
            self = .inbox
        default:
            return nil
        }
    }
}
