import SwiftUI
import UIKit

struct RootView: View {
    @EnvironmentObject private var runtimeStore: IslandRuntimeStore

    @State private var path: [Destination] = []
    @State private var activeSheet: SheetDestination?

    var body: some View {
        NavigationStack(path: $path) {
            IslandControlPanelView(
                openInbox: openInbox,
                openSettings: openSettings,
                startLinkCapture: startLinkCapture,
                startReminderCapture: startReminderCapture
            )
            .navigationDestination(for: Destination.self) { destination in
                switch destination {
                case .inbox:
                    ShelfFeatureView(
                        startLinkCapture: startLinkCapture,
                        startReminderCapture: startReminderCapture
                    )
                }
            }
        }
        .sheet(item: $activeSheet) { destination in
            NavigationStack {
                sheetView(for: destination)
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

    @ViewBuilder
    private func sheetView(for destination: SheetDestination) -> some View {
        switch destination {
        case .settings:
            CustomizationSettingsView()
        case .captureLink:
            LinkCaptureSheet()
        case .captureReminder:
            ReminderCaptureSheet()
        }
    }

    private func openInbox() {
        path = [.inbox]
    }

    private func openSettings() {
        activeSheet = .settings
    }

    private func startLinkCapture() {
        activeSheet = .captureLink
    }

    private func startReminderCapture() {
        activeSheet = .captureReminder
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

    private var theme: IslandTheme {
        runtimeStore.selectedPreset.theme
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                CaptureSheetHeader(
                    title: "Add Link",
                    subtitle: "Paste a link to pin it into your inbox and island flow.",
                    theme: theme
                )

                LiquidGlassCluster(spacing: 18) {
                    VStack(alignment: .leading, spacing: 18) {
                        CaptureFieldSection(title: "URL", theme: theme) {
                            TextField("https://example.com", text: $rawURL)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .padding(14)
                                .liquidGlassCard(
                                    theme: theme,
                                    cornerRadius: 20,
                                    isInteractive: true
                                )
                        }

                        if showsValidationError {
                            Text("Enter a valid URL to save this link.")
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        LinkCaptureActions(
                            saveLink: saveLink,
                            pasteClipboard: pasteClipboard,
                            theme: theme
                        )
                    }
                }
            }
            .padding(24)
        }
        .background(LiquidGlassBackdrop(theme: theme))
        .navigationTitle("Quick Capture")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func pasteClipboard() {
        rawURL = UIPasteboard.general.string ?? rawURL
    }

    private func saveLink() {
        Task {
            guard let url = normalizedURL(from: rawURL) else {
                showsValidationError = true
                return
            }

            await runtimeStore.captureLink(url)
            dismiss()
        }
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

    private var theme: IslandTheme {
        runtimeStore.selectedPreset.theme
    }

    private var canSaveReminder: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                CaptureSheetHeader(
                    title: "New Reminder",
                    subtitle: "Create a reminder for your inbox and mirror it to Apple Reminders when sync is enabled.",
                    theme: theme
                )

                LiquidGlassCluster(spacing: 18) {
                    VStack(alignment: .leading, spacing: 18) {
                        CaptureFieldSection(title: "Title", theme: theme) {
                            TextField("Follow up on launch notes", text: $title, axis: .vertical)
                                .lineLimit(1...3)
                                .padding(14)
                                .liquidGlassCard(
                                    theme: theme,
                                    cornerRadius: 20,
                                    isInteractive: true
                                )
                        }

                        CaptureFieldSection(title: "Notes", theme: theme) {
                            TextField("Optional details", text: $notes, axis: .vertical)
                                .lineLimit(2...4)
                                .padding(14)
                                .liquidGlassCard(
                                    theme: theme,
                                    cornerRadius: 20,
                                    isInteractive: true
                                )
                        }

                        ReminderDueSection(
                            duePreset: $duePreset,
                            customDueDate: $customDueDate,
                            theme: theme
                        )

                        ReminderSyncCard(
                            canMirror: runtimeStore.reminderAccessStatus.canMirror,
                            statusLabel: runtimeStore.reminderAccessStatus.label,
                            theme: theme
                        )

                        ReminderCaptureActions(
                            canSave: canSaveReminder,
                            saveReminder: saveReminder,
                            theme: theme
                        )
                    }
                }
            }
            .padding(24)
        }
        .background(LiquidGlassBackdrop(theme: theme))
        .navigationTitle("Quick Reminder")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveReminder() {
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
}

private struct CaptureSheetHeader: View {
    let title: String
    let subtitle: String
    let theme: IslandTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.weight(.semibold))
            Text(subtitle)
                .foregroundStyle(theme.foregroundColor.opacity(0.72))
        }
    }
}

private struct CaptureFieldSection<Content: View>: View {
    let title: String
    let theme: IslandTheme
    let content: Content

    init(
        title: String,
        theme: IslandTheme,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.foregroundColor.opacity(0.72))
            content
        }
    }
}

private struct LinkCaptureActions: View {
    let saveLink: () -> Void
    let pasteClipboard: () -> Void
    let theme: IslandTheme

    var body: some View {
        HStack(spacing: 12) {
            Button("Paste Clipboard", action: pasteClipboard)
                .liquidGlassButtonStyle()

            Spacer()

            Button("Save Link", action: saveLink)
                .liquidGlassButtonStyle(prominent: true)
        }
    }
}

private struct ReminderDueSection: View {
    @Binding var duePreset: ReminderDuePreset
    @Binding var customDueDate: Date
    let theme: IslandTheme

    var body: some View {
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
    }
}

private struct ReminderSyncCard: View {
    let canMirror: Bool
    let statusLabel: String
    let theme: IslandTheme

    var body: some View {
        HStack {
            Label(
                "Reminder Sync",
                systemImage: canMirror ? "checkmark.icloud" : "icloud.slash"
            )
            .foregroundStyle(theme.foregroundColor.opacity(0.8))

            Spacer()

            Text(statusLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(canMirror ? theme.accentColor : theme.foregroundColor.opacity(0.72))
        }
        .padding(16)
        .liquidGlassCard(theme: theme, cornerRadius: 22)
    }
}

private struct ReminderCaptureActions: View {
    let canSave: Bool
    let saveReminder: () -> Void
    let theme: IslandTheme

    var body: some View {
        HStack(spacing: 12) {
            Spacer()

            Button("Save Reminder", action: saveReminder)
                .liquidGlassButtonStyle(prominent: true)
                .disabled(!canSave)
        }
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
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))?
                .addingTimeInterval(20 * 60 * 60)
        case .tomorrow:
            return calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: now))?
                .addingTimeInterval(9 * 60 * 60)
        case .pickDate:
            return customDate
        }
    }
}
