import Foundation

public struct ShelfItemRecord: Codable, Hashable, Identifiable, Sendable {
    public enum Kind: String, Codable, CaseIterable, Sendable {
        case url
        case text
        case reminder
    }

    public enum ReminderMirrorStatus: String, Codable, CaseIterable, Sendable {
        case notRequested
        case localOnly
        case mirrored
        case failed
    }

    public var id: UUID
    public var kind: Kind
    public var title: String
    public var value: String
    public var createdAt: Date
    public var dueDate: Date?
    public var isCompleted: Bool
    public var notes: String?
    public var mirrorStatus: ReminderMirrorStatus?
    public var externalReminderID: String?

    public init(
        id: UUID = UUID(),
        kind: Kind,
        title: String,
        value: String,
        createdAt: Date = .now,
        dueDate: Date? = nil,
        isCompleted: Bool = false,
        notes: String? = nil,
        mirrorStatus: ReminderMirrorStatus? = nil,
        externalReminderID: String? = nil
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.value = value
        self.createdAt = createdAt
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.notes = notes
        self.mirrorStatus = mirrorStatus
        self.externalReminderID = externalReminderID
    }

    public static func from(url: URL, createdAt: Date = .now) -> ShelfItemRecord {
        let title = url.host ?? url.lastPathComponent.nonEmpty ?? url.absoluteString
        return ShelfItemRecord(
            kind: .url,
            title: title,
            value: url.absoluteString,
            createdAt: createdAt
        )
    }

    public static func from(text: String, createdAt: Date = .now) -> ShelfItemRecord {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = String(
            trimmed
                .split(whereSeparator: \.isNewline)
                .first
                .map(String.init)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .prefix(60) ?? "Shared Text"
        )
        return ShelfItemRecord(
            kind: .text,
            title: title.nonEmpty ?? "Shared Text",
            value: trimmed,
            createdAt: createdAt
        )
    }

    public static func fromReminder(
        title: String,
        notes: String? = nil,
        dueDate: Date? = nil,
        createdAt: Date = .now,
        mirrorStatus: ReminderMirrorStatus? = nil,
        externalReminderID: String? = nil
    ) -> ShelfItemRecord {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines).nonEmpty
        return ShelfItemRecord(
            kind: .reminder,
            title: trimmedTitle.nonEmpty ?? "Reminder",
            value: trimmedNotes ?? trimmedTitle,
            createdAt: createdAt,
            dueDate: dueDate,
            isCompleted: false,
            notes: trimmedNotes,
            mirrorStatus: mirrorStatus,
            externalReminderID: externalReminderID
        )
    }

    public var deduplicationKey: String {
        switch kind {
        case .reminder:
            return id.uuidString
        case .url, .text:
            return "\(kind.rawValue)::\(value)"
        }
    }

    public var reminderDetailText: String? {
        notes?.nonEmpty ?? value.nonEmpty
    }

    public var copyText: String {
        switch kind {
        case .reminder:
            let components = [title, notes].compactMap { $0?.nonEmpty }
            return components.joined(separator: "\n")
        case .url, .text:
            return value
        }
    }

    public func withMirrorStatus(
        _ status: ReminderMirrorStatus,
        externalReminderID: String? = nil
    ) -> ShelfItemRecord {
        var copy = self
        copy.mirrorStatus = status
        copy.externalReminderID = externalReminderID
        return copy
    }

    private enum CodingKeys: String, CodingKey {
        case id
        case kind
        case title
        case value
        case createdAt
        case dueDate
        case isCompleted
        case notes
        case mirrorStatus
        case externalReminderID
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        kind = try container.decode(Kind.self, forKey: .kind)
        title = try container.decode(String.self, forKey: .title)
        value = try container.decode(String.self, forKey: .value)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        dueDate = try container.decodeIfPresent(Date.self, forKey: .dueDate)
        isCompleted = try container.decodeIfPresent(Bool.self, forKey: .isCompleted) ?? false
        notes = try container.decodeIfPresent(String.self, forKey: .notes)
        mirrorStatus = try container.decodeIfPresent(ReminderMirrorStatus.self, forKey: .mirrorStatus)
        externalReminderID = try container.decodeIfPresent(String.self, forKey: .externalReminderID)
    }
}

private extension String {
    var nonEmpty: String? {
        isEmpty ? nil : self
    }
}
