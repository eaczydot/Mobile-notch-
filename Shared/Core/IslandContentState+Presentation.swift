import Foundation

public extension IslandContentState {
    var displayTitle: String {
        switch activeModule {
        case .media:
            return media?.title ?? "Media"
        case .battery:
            return battery.map { "Battery \($0.percentage)%" } ?? "Battery"
        case .calendar:
            return calendar?.nextEventTitle ?? "Calendar"
        case .shelf:
            return shelfDisplayTitle
        case .event:
            return event?.title ?? "Event"
        }
    }

    var displaySubtitle: String {
        switch activeModule {
        case .media:
            return media?.subtitle ?? ""
        case .battery:
            return (battery?.isCharging ?? false) ? "Charging" : "On battery"
        case .calendar:
            return "Upcoming"
        case .shelf:
            return shelfDisplaySubtitle
        case .event:
            return event?.detail ?? ""
        }
    }

    var systemImageName: String {
        switch activeModule {
        case .media:
            return "music.note"
        case .battery:
            return "battery.100"
        case .calendar:
            return "calendar"
        case .shelf:
            return shelfSystemImageName
        case .event:
            return "sparkles"
        }
    }

    private var shelfDisplayTitle: String {
        guard let shelf else {
            return "Inbox"
        }

        switch shelf.highlightedKind {
        case .reminder:
            return shelf.highlightedTitle ?? "Reminder"
        case .url, .text:
            return shelf.highlightedTitle ?? shelf.latestItemName ?? "Inbox"
        case nil:
            return shelf.latestItemName ?? "Inbox"
        }
    }

    private var shelfDisplaySubtitle: String {
        guard let shelf else {
            return "No saved items"
        }

        if shelf.highlightedKind == .reminder,
           let dueDate = shelf.highlightedDueDate {
            return dueDate.relativeDueDescription()
        }

        if let detail = shelf.highlightedDetail?.trimmingCharacters(in: .whitespacesAndNewlines),
           !detail.isEmpty {
            return detail
        }

        if shelf.pendingReminderCount > 0 {
            return "\(shelf.pendingReminderCount) reminder\(shelf.pendingReminderCount == 1 ? "" : "s") pending"
        }

        return shelf.itemCount == 0 ? "No saved items" : "\(shelf.itemCount) saved"
    }

    private var shelfSystemImageName: String {
        switch shelf?.highlightedKind {
        case .reminder:
            return "checklist"
        case .url:
            return "link"
        case .text:
            return "text.alignleft"
        case nil:
            return "tray.full"
        }
    }
}

private extension Date {
    func relativeDueDescription(referenceDate: Date = .now) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        let relative = formatter.localizedString(for: self, relativeTo: referenceDate)
        return self < referenceDate ? "Due \(relative)" : "Due \(relative)"
    }
}
