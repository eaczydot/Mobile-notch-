import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var runtimeStore: IslandRuntimeStore

    @State private var path: [Destination] = []
    @State private var activeSheet: SheetDestination?

    var body: some View {
        NavigationStack(path: $path) {
            IslandControlPanelView(
                openInbox: { path = [.inbox] },
                openSettings: { activeSheet = .settings },
                startLinkCapture: { activeSheet = .captureLink },
                startReminderCapture: { activeSheet = .captureReminder }
            )
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .inbox:
                    ShelfFeatureView(
                        startLinkCapture: { activeSheet = .captureLink },
                        startReminderCapture: { activeSheet = .captureReminder }
                    )
                }
            }
        }
        .sheet(item: $activeSheet) { destination in
            NavigationStack {
                switch destination {
                case .settings:
                    CustomizationSettingsView()
                case .captureLink:
                    LinkCaptureSheet()
                case .captureReminder:
                    ReminderCaptureSheet()
                }
            }
            .environmentObject(runtimeStore)
            .presentationBackground(.thinMaterial)
            .presentationDetents(destination.presentationDetents)
        }
        .onOpenURL { url in
            guard let route = BoringNotchRoute(url: url) else {
                return
            }
            handle(route)
        }
    }

    private func handle(_ route: BoringNotchRoute) {
        path.removeAll()

        switch route {
        case .island:
            activeSheet = nil
        case .captureLink:
            activeSheet = .captureLink
        case .captureReminder:
            activeSheet = .captureReminder
        case .inbox:
            activeSheet = nil
            path = [.inbox]
        }
    }
}

private enum Destination: Hashable {
    case inbox
}

private enum SheetDestination: String, Identifiable {
    case settings
    case captureLink
    case captureReminder

    var id: String { rawValue }

    var presentationDetents: Set<PresentationDetent> {
        switch self {
        case .settings:
            return [.medium, .large]
        case .captureLink:
            return [.fraction(0.38), .medium]
        case .captureReminder:
            return [.fraction(0.52), .large]
        }
    }
}

private struct LinkCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var runtimeStore: IslandRuntimeStore

    @State private var rawURL = ""
    @State private var showsValidationError = false

    var body: some View {
        let theme = runtimeStore.selectedPreset.theme

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Add Link")
                        .font(.title2.weight(.semibold))
                    Text("Paste a link to pin it into your inbox and island flow.")
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("URL")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))
                    TextField("https://example.com", text: $rawURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .padding(14)
                        .liquidGlassCard(theme: theme, cornerRadius: 20)
                }

                if showsValidationError {
                    Text("Enter a valid URL to save this link.")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                HStack(spacing: 12) {
                    Button("Paste Clipboard") {
                        rawURL = UIPasteboard.general.string ?? rawURL
                    }
                    .buttonStyle(.bordered)

                    Spacer()

                    Button("Save Link") {
                        Task {
                            guard let url = normalizedURL(from: rawURL) else {
                                showsValidationError = true
                                return
                            }

                            await runtimeStore.captureLink(url)
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding(24)
        }
        .background(LiquidGlassBackdrop(theme: theme))
        .navigationTitle("Quick Capture")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func normalizedURL(from rawValue: String) -> URL? {
        let trimmed = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return nil
        }

        if let url = URL(string: trimmed), url.scheme != nil {
            return url
        }

        let withHTTPS = "https://\(trimmed)"
        guard let url = URL(string: withHTTPS), url.scheme != nil else {
            return nil
        }
        return url
    }
}

private struct ReminderCaptureSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var runtimeStore: IslandRuntimeStore

    @State private var title = ""
    @State private var notes = ""
    @State private var duePreset: ReminderDuePreset = .none
    @State private var customDueDate = Calendar.current.date(byAdding: .hour, value: 2, to: .now) ?? .now

    var body: some View {
        let theme = runtimeStore.selectedPreset.theme

        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("New Reminder")
                        .font(.title2.weight(.semibold))
                    Text("Create a reminder for your inbox and mirror it to Apple Reminders when sync is enabled.")
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Title")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))
                    TextField("Follow up on launch notes", text: $title, axis: .vertical)
                        .lineLimit(1...3)
                        .padding(14)
                        .liquidGlassCard(theme: theme, cornerRadius: 20)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Notes")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))
                    TextField("Optional details", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .padding(14)
                        .liquidGlassCard(theme: theme, cornerRadius: 20)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Due")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))

                    Picker("Due preset", selection: $duePreset) {
                        ForEach(ReminderDuePreset.allCases, id: \.self) { preset in
                            Text(preset.label).tag(preset)
                        }
                    }
                    .pickerStyle(.segmented)

                    if duePreset == .pickDate {
                        DatePicker(
                            "Custom Date",
                            selection: $customDueDate,
                            displayedComponents: [.date, .hourAndMinute]
                        )
                        .datePickerStyle(.compact)
                    }
                }

                HStack {
                    Label("Reminder Sync", systemImage: runtimeStore.reminderAccessStatus.canMirror ? "checkmark.icloud" : "icloud.slash")
                        .foregroundStyle(theme.foregroundColor.opacity(0.8))
                    Spacer()
                    Text(runtimeStore.reminderAccessStatus.label)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(runtimeStore.reminderAccessStatus.canMirror ? theme.accentColor : theme.foregroundColor.opacity(0.72))
                }
                .padding(16)
                .liquidGlassCard(theme: theme, cornerRadius: 22)

                HStack(spacing: 12) {
                    Spacer()
                    Button("Save Reminder") {
                        Task {
                            let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmedTitle.isEmpty else {
                                return
                            }

                            await runtimeStore.captureReminder(
                                title: trimmedTitle,
                                notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                                dueDate: duePreset.resolveDate(customDate: customDueDate)
                            )
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
        }
        .background(LiquidGlassBackdrop(theme: theme))
        .navigationTitle("Quick Reminder")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private enum ReminderDuePreset: CaseIterable {
    case none
    case laterToday
    case tonight
    case tomorrow
    case pickDate

    var label: String {
        switch self {
        case .none:
            return "None"
        case .laterToday:
            return "Later Today"
        case .tonight:
            return "Tonight"
        case .tomorrow:
            return "Tomorrow"
        case .pickDate:
            return "Pick Date"
        }
    }

    func resolveDate(customDate: Date) -> Date? {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .none:
            return nil
        case .laterToday:
            return calendar.date(byAdding: .hour, value: 3, to: now)
        case .tonight:
            let tonight = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: now)
            if let tonight, tonight > now {
                return tonight
            }
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))?.addingTimeInterval(20 * 60 * 60)
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))?.addingTimeInterval(9 * 60 * 60)
        case .pickDate:
            return customDate
        }
    }
}
