import Foundation

public enum IslandStateMapper {
    public static func apply(event: IslandEvent, to state: IslandContentState) -> IslandContentState {
        var next = state
        next.lastUpdated = event.timestamp
        next.activeModule = event.module

        switch event.payload {
        case .media(let media):
            next.media = MediaState(
                title: media.title,
                subtitle: media.subtitle,
                progress: min(max(media.progress, 0), 1),
                isPlaying: media.isPlaying
            )
        case .battery(let battery):
            next.battery = BatteryState(
                percentage: min(max(Int((battery.level * 100).rounded()), 0), 100),
                isCharging: battery.isCharging
            )
        case .calendar(let calendar):
            next.calendar = CalendarState(nextEventTitle: calendar.title, startDate: calendar.startsAt)
        case .shelf(let shelf):
            next.shelf = ShelfState(
                itemCount: shelf.itemCount,
                latestItemName: shelf.lastItemName,
                highlightedTitle: shelf.highlightedTitle,
                highlightedDetail: shelf.highlightedDetail,
                highlightedKind: shelf.highlightedKind,
                highlightedDueDate: shelf.highlightedDueDate,
                pendingReminderCount: shelf.pendingReminderCount
            )
        case .event(let event):
            next.event = EventState(title: event.title, detail: event.detail)
        }

        return next
    }
}
