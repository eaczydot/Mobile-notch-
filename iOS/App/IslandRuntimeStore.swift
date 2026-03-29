import ActivityKit
import EventKit
import Foundation
import SwiftUI

@MainActor
final class IslandRuntimeStore: ObservableObject {
    enum ActivityStatus: Equatable {
        case inactive
        case active
        case unavailable
        case failed(String)

        var label: String {
            switch self {
            case .inactive:
                return "Idle"
            case .active:
                return "Live"
            case .unavailable:
                return "Unavailable"
            case .failed(let message):
                return message
            }
        }
    }

    enum ReminderAccessStatus: Equatable {
        case notDetermined
        case denied
        case restricted
        case authorized
        case unavailable
        case failed(String)

        var label: String {
            switch self {
            case .notDetermined:
                return "Not Enabled"
            case .denied:
                return "Denied"
            case .restricted:
                return "Restricted"
            case .authorized:
                return "Synced"
            case .unavailable:
                return "Unavailable"
            case .failed(let message):
                return message
            }
        }

        var canMirror: Bool {
            if case .authorized = self {
                return true
            }
            return false
        }
    }

    @Published private(set) var capabilityMatrix = CapabilityMatrix.current()
    @Published private(set) var contentState = IslandRuntimeController.emptyCaptureState()
    @Published private(set) var shelfItems: [ShelfItemRecord] = []
    @Published private(set) var presets: [IslandPreset] = []
    @Published private(set) var activityStatus: ActivityStatus = .inactive
    @Published private(set) var reminderAccessStatus: ReminderAccessStatus = .notDetermined
    @Published var selectedPresetID: UUID?
    @Published var isPersistentLiveActivityEnabled = true

    private let appGroupDefaults = UserDefaults(suiteName: IslandAppGroup.suiteName) ?? .standard
    private lazy var presetStore = UserDefaultsCustomizationStore(defaults: appGroupDefaults)
    private lazy var stateStore = AppGroupIslandStateStore(defaults: appGroupDefaults)
    private lazy var shelfStore = AppGroupShelfStore(defaults: appGroupDefaults)
    private lazy var runtimeController = IslandRuntimeController(
        shelfStore: shelfStore,
        stateStore: stateStore
    )
    private lazy var eventStore = EKEventStore()

    private var hasBootstrapped = false

    var selectedPreset: IslandPreset {
        presets.first(where: { $0.id == selectedPresetID }) ?? presets.first ?? .default
    }

    func bootstrap() async {
        guard !hasBootstrapped else {
            await sceneDidBecomeActive()
            return
        }

        hasBootstrapped = true
        reloadPresets()
        isPersistentLiveActivityEnabled = stateStore.loadPersistentLiveActivityEnabled()
        contentState = runtimeController.bootstrapState()
        refreshReminderAccessStatus()
        refreshActivityStatus()
        refreshShelfState()
        await synchronizePersistentActivity()
    }

    func sceneDidBecomeActive() async {
        capabilityMatrix = CapabilityMatrix.current()
        refreshReminderAccessStatus()
        refreshActivityStatus()
        refreshShelfState()
        await synchronizePersistentActivity()
    }

    func reloadPresets() {
        do {
            presets = try presetStore.loadPresets()
        } catch {
            presets = [.default]
        }

        let persistedSelection = stateStore.loadSelectedPresetID()
        let resolvedSelection = persistedSelection.flatMap { id in
            presets.contains(where: { $0.id == id }) ? id : nil
        } ?? presets.first?.id
        selectedPresetID = resolvedSelection
        stateStore.saveSelectedPresetID(resolvedSelection)
    }

    func selectPreset(_ id: UUID) {
        selectedPresetID = id
        stateStore.saveSelectedPresetID(id)
        Task {
            await synchronizePersistentActivity()
        }
    }

    func savePreset(_ preset: IslandPreset) {
        do {
            try presetStore.savePreset(preset)
            reloadPresets()
            selectPreset(preset.id)
        } catch {
            activityStatus = .failed("Couldn’t save preset")
        }
    }

    func deletePreset(_ preset: IslandPreset) {
        do {
            try presetStore.deletePreset(preset.id)
            reloadPresets()
            if let nextID = presets.first?.id {
                selectPreset(nextID)
            }
        } catch {
            activityStatus = .failed("Couldn’t delete preset")
        }
    }

    func exportSelectedPresets() -> Data? {
        try? presetStore.export(presets.map(\.id))
    }

    func importPresets(data: Data) {
        do {
            _ = try presetStore.import(data)
            reloadPresets()
        } catch {
            activityStatus = .failed("Couldn’t import presets")
        }
    }

    func setPersistentLiveActivityEnabled(_ isEnabled: Bool) {
        isPersistentLiveActivityEnabled = isEnabled
        stateStore.savePersistentLiveActivityEnabled(isEnabled)
        Task {
            await synchronizePersistentActivity()
        }
    }

    func requestReminderAccess() async {
        do {
            let granted = try await eventStore.requestFullAccessToReminders()
            reminderAccessStatus = granted ? .authorized : .denied
        } catch {
            reminderAccessStatus = .failed("Couldn’t access Reminders")
        }
    }

    func refreshShelfState() {
        do {
            shelfItems = try shelfStore.loadItems()
            contentState = try runtimeController.refreshShelfState(from: contentState)
        } catch {
            activityStatus = .failed("Couldn’t load inbox")
        }
    }

    func deleteShelfItems(at offsets: IndexSet) {
        for index in offsets {
            guard shelfItems.indices.contains(index) else { continue }
            _ = try? shelfStore.remove(id: shelfItems[index].id)
        }
        refreshShelfState()
        Task {
            await synchronizePersistentActivity()
        }
    }

    func deleteShelfItem(_ item: ShelfItemRecord) {
        _ = try? shelfStore.remove(id: item.id)
        refreshShelfState()
        Task {
            await synchronizePersistentActivity()
        }
    }

    func clearShelf() {
        shelfStore.clear()
        refreshShelfState()
        Task {
            await synchronizePersistentActivity()
        }
    }

    func captureLink(_ url: URL) async {
        do {
            _ = try shelfStore.append([.from(url: url)])
            refreshShelfState()
            await synchronizePersistentActivity()
        } catch {
            activityStatus = .failed("Couldn’t save link")
        }
    }

    func captureReminder(
        title: String,
        notes: String?,
        dueDate: Date?
    ) async {
        let normalizedNotes = notes?.trimmingCharacters(in: .whitespacesAndNewlines)
        var reminder = ShelfItemRecord.fromReminder(
            title: title,
            notes: normalizedNotes,
            dueDate: dueDate,
            mirrorStatus: initialReminderMirrorStatus()
        )

        do {
            _ = try shelfStore.append([reminder])
            refreshShelfState()
            await synchronizePersistentActivity()
        } catch {
            activityStatus = .failed("Couldn’t save reminder")
            return
        }

        guard reminderAccessStatus.canMirror else {
            return
        }

        reminder = await mirrorReminder(reminder)
        do {
            _ = try shelfStore.upsert(reminder)
            refreshShelfState()
            await synchronizePersistentActivity()
        } catch {
            activityStatus = .failed("Couldn’t update reminder sync")
        }
    }

    func endActivity() async {
        await runtimeController.endActivity(reason: .user)
        activityStatus = .inactive
    }

    private func synchronizePersistentActivity() async {
        refreshActivityStatus()

        guard capabilityMatrix.supportsLiveActivities else {
            activityStatus = .unavailable
            return
        }

        guard isPersistentLiveActivityEnabled else {
            if activityStatus == .active {
                await runtimeController.endActivity(reason: .user)
            }
            activityStatus = .inactive
            return
        }

        if activityStatus == .active {
            await runtimeController.updateActivity(state: contentState)
        } else {
            do {
                try await runtimeController.startActivity(state: contentState)
                activityStatus = .active
            } catch {
                activityStatus = .failed("Couldn’t start Live Activity")
            }
        }
    }

    private func refreshActivityStatus() {
        if !capabilityMatrix.supportsLiveActivities {
            activityStatus = .unavailable
            return
        }

        if #available(iOS 16.1, *) {
            activityStatus = Activity<IslandAttributes>.activities.isEmpty ? .inactive : .active
        } else {
            activityStatus = .unavailable
        }
    }

    private func refreshReminderAccessStatus() {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess, .writeOnly, .authorized:
            reminderAccessStatus = .authorized
        case .notDetermined:
            reminderAccessStatus = .notDetermined
        case .restricted:
            reminderAccessStatus = .restricted
        case .denied:
            reminderAccessStatus = .denied
        @unknown default:
            reminderAccessStatus = .unavailable
        }
    }

    private func initialReminderMirrorStatus() -> ShelfItemRecord.ReminderMirrorStatus {
        switch reminderAccessStatus {
        case .authorized:
            return .localOnly
        case .notDetermined:
            return .notRequested
        case .denied, .restricted, .unavailable, .failed:
            return .localOnly
        }
    }

    private func mirrorReminder(_ reminderItem: ShelfItemRecord) async -> ShelfItemRecord {
        let reminder = EKReminder(eventStore: eventStore)
        reminder.title = reminderItem.title
        reminder.notes = reminderItem.notes ?? reminderItem.value
        reminder.calendar = eventStore.defaultCalendarForNewReminders()

        if let dueDate = reminderItem.dueDate {
            reminder.dueDateComponents = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: dueDate
            )
        }

        guard reminder.calendar != nil else {
            return reminderItem.withMirrorStatus(.failed)
        }

        do {
            try eventStore.save(reminder, commit: true)
            return reminderItem.withMirrorStatus(.mirrored, externalReminderID: reminder.calendarItemIdentifier)
        } catch {
            return reminderItem.withMirrorStatus(.failed)
        }
    }
}
