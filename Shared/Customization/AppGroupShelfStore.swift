import Foundation

public final class AppGroupShelfStore {
    private let defaults: UserDefaults
    private let recordsKey: String
    private let legacyKey: String
    private let decoder = JSONDecoder()
    private let encoder = JSONEncoder()

    public init(
        defaults: UserDefaults = UserDefaults(suiteName: IslandAppGroup.suiteName) ?? .standard,
        recordsKey: String = CustomizationDefaultsKeys.shelfRecords,
        legacyKey: String = CustomizationDefaultsKeys.shelfItems
    ) {
        self.defaults = defaults
        self.recordsKey = recordsKey
        self.legacyKey = legacyKey
        self.encoder.outputFormatting = [.sortedKeys]
    }

    public func loadItems() throws -> [ShelfItemRecord] {
        try migrateLegacyItemsIfNeeded()
        guard let data = defaults.data(forKey: recordsKey) else {
            return []
        }
        return try decoder.decode([ShelfItemRecord].self, from: data)
            .sorted { $0.createdAt > $1.createdAt }
    }

    @discardableResult
    public func append(_ newItems: [ShelfItemRecord]) throws -> [ShelfItemRecord] {
        guard !newItems.isEmpty else {
            return try loadItems()
        }

        let normalizedIncoming = newItems.sorted { $0.createdAt > $1.createdAt }
        var existing = try loadItems()

        for item in normalizedIncoming.reversed() {
            existing.removeAll { $0.deduplicationKey == item.deduplicationKey }
            existing.insert(item, at: 0)
        }

        try save(existing)
        return existing
    }

    @discardableResult
    public func upsert(_ item: ShelfItemRecord) throws -> [ShelfItemRecord] {
        var items = try loadItems()
        items.removeAll { $0.id == item.id }
        items.insert(item, at: 0)
        try save(items)
        return items
    }

    @discardableResult
    public func remove(id: UUID) throws -> [ShelfItemRecord] {
        var items = try loadItems()
        items.removeAll { $0.id == id }
        try save(items)
        return items
    }

    public func clear() {
        defaults.removeObject(forKey: recordsKey)
        defaults.removeObject(forKey: legacyKey)
    }

    public func latestEvent(now: Date = .now) throws -> IslandEvent? {
        let items = try loadItems()
        guard !items.isEmpty else { return nil }

        let pendingReminders = items.filter { $0.kind == .reminder && !$0.isCompleted }
        let dueReminder = pendingReminders
            .filter { $0.dueDate != nil }
            .sorted {
                ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture)
            }
            .first

        let newestCapture = items.first { $0.kind != .reminder }
        let fallbackReminder = pendingReminders.first
        let highlighted = dueReminder ?? newestCapture ?? fallbackReminder ?? items.first

        return IslandEvent(
            module: .shelf,
            timestamp: now,
            payload: .shelf(
                .init(
                    itemCount: items.count,
                    lastItemName: items.first?.title,
                    highlightedTitle: highlighted?.title,
                    highlightedDetail: highlighted?.highlightDetail,
                    highlightedKind: highlighted?.kind,
                    highlightedDueDate: highlighted?.dueDate,
                    pendingReminderCount: pendingReminders.count
                )
            )
        )
    }

    private func save(_ items: [ShelfItemRecord]) throws {
        let data = try encoder.encode(items.sorted { $0.createdAt > $1.createdAt })
        defaults.set(data, forKey: recordsKey)
    }

    private func migrateLegacyItemsIfNeeded() throws {
        guard defaults.data(forKey: recordsKey) == nil,
              let legacyItems = defaults.stringArray(forKey: legacyKey),
              !legacyItems.isEmpty else {
            return
        }

        let migrated = legacyItems.enumerated().map { index, value in
            let createdAt = Date().addingTimeInterval(TimeInterval(-index))
            if let url = URL(string: value), url.scheme != nil {
                return ShelfItemRecord.from(url: url, createdAt: createdAt)
            }
            return ShelfItemRecord.from(text: value, createdAt: createdAt)
        }
        try save(migrated)
    }
}

private extension ShelfItemRecord {
    var highlightDetail: String? {
        switch kind {
        case .url, .text:
            return value.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
        case .reminder:
            return reminderDetailText
        }
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
