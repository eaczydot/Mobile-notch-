import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit
import AppIntents
import UIKit

struct IslandLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: IslandAttributes.self) { context in
            let preset = WidgetPresetResolver.activePreset()

            LockScreenIslandView(state: context.state.payload, theme: preset.theme)
                .activityBackgroundTint(preset.theme.backgroundColor.opacity(0.76))
                .activitySystemActionForegroundColor(preset.theme.foregroundColor)
                .widgetURL(BoringNotchRoute.island.url)
        } dynamicIsland: { context in
            let preset = WidgetPresetResolver.activePreset()
            let state = context.state.payload

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Button(intent: CaptureClipboardIntent()) {
                        ExpandedActionChip(
                            title: "Save Clipboard",
                            systemImage: "square.and.arrow.down.on.square",
                            tint: preset.theme.accentColor
                        )
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    trailingAction(for: state, theme: preset.theme)
                }

                DynamicIslandExpandedRegion(.center) {
                    Link(destination: BoringNotchRoute.island.url) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(summaryLabel(for: state))
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(preset.theme.accentColor)
                            Text(state.displayTitle)
                                .font(.headline)
                                .lineLimit(1)
                            Text(state.displaySubtitle)
                                .font(.caption)
                                .foregroundStyle(preset.theme.foregroundColor.opacity(0.74))
                                .lineLimit(2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }

                DynamicIslandExpandedRegion(.bottom) {
                    Link(destination: BoringNotchRoute.inbox.url) {
                        HStack {
                            Label(bottomLabel(for: state), systemImage: state.systemImageName)
                            Spacer()
                            Text(queueSummary(for: state))
                        }
                        .font(.caption)
                        .foregroundStyle(preset.theme.foregroundColor.opacity(0.84))
                    }
                }
            } compactLeading: {
                Image(systemName: compactLeadingSymbol(for: state))
                    .symbolRenderingMode(.hierarchical)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(compactLeadingTint(for: state, theme: preset.theme))
            } compactTrailing: {
                Text(compactTrailingText(for: state))
                    .foregroundStyle(compactTrailingTint(for: state, theme: preset.theme))
                    .font(.caption2.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            } minimal: {
                Image(systemName: compactLeadingSymbol(for: state))
                    .symbolRenderingMode(.hierarchical)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(compactLeadingTint(for: state, theme: preset.theme))
            }
            .widgetURL(BoringNotchRoute.island.url)
            .keylineTint(preset.theme.accentColor)
        }
    }

    private func bottomLabel(for state: IslandContentState) -> String {
        if state.activeModule == .shelf {
            return "Open Inbox"
        }
        return state.displaySubtitle
    }

    private func compactTrailingText(for state: IslandContentState) -> String {
        if let dueDate = state.shelf?.highlightedDueDate,
           state.shelf?.highlightedKind == .reminder {
            return dueDate < .now ? "Due" : "Soon"
        }

        if let shelf = state.shelf, shelf.itemCount > 0 {
            return "\(shelf.itemCount)"
        }

        switch state.activeModule {
        case .media:
            return state.media?.isPlaying == true ? "Now" : "Play"
        case .battery:
            return state.battery.map { "\($0.percentage)" } ?? "Bat"
        case .calendar:
            return "Next"
        case .shelf:
            return "Open"
        case .event:
            return "Tap"
        }
    }

    private func compactLeadingSymbol(for state: IslandContentState) -> String {
        if state.activeModule == .event {
            return "sparkles.circle.fill"
        }

        if state.activeModule == .shelf,
           state.shelf?.pendingReminderCount ?? 0 > 0 {
            return "checklist.checked"
        }

        return state.systemImageName
    }

    private func compactLeadingTint(for state: IslandContentState, theme: IslandTheme) -> Color {
        switch state.activeModule {
        case .battery:
            return state.battery?.isCharging == true ? .green : theme.accentColor
        case .calendar:
            return .orange
        case .event, .media, .shelf:
            return theme.accentColor
        }
    }

    private func compactTrailingTint(for state: IslandContentState, theme: IslandTheme) -> Color {
        if shouldShowReminderCompletion(for: state) {
            return .green
        }

        switch state.activeModule {
        case .event:
            return theme.foregroundColor
        case .battery:
            return state.battery?.isCharging == true ? .green : theme.accentColor
        case .calendar, .media, .shelf:
            return theme.accentColor
        }
    }
}

private struct LockScreenIslandView: View {
    let state: IslandContentState
    let theme: IslandTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: state.systemImageName)
                    .foregroundStyle(theme.accentColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(state.displayTitle)
                        .font(.headline)
                        .foregroundStyle(theme.foregroundColor)
                        .lineLimit(1)
                    Text(state.displaySubtitle)
                        .font(.caption)
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))
                        .lineLimit(2)
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button(intent: CaptureClipboardIntent()) {
                    LockScreenChip(title: "Save Clipboard", tint: theme.accentColor)
                }

                lockScreenTrailingAction

                Link(destination: BoringNotchRoute.inbox.url) {
                    LockScreenChip(title: queueSummary(for: state), tint: theme.foregroundColor.opacity(0.86))
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private var lockScreenTrailingAction: some View {
        if shouldShowReminderCompletion(for: state) {
            Button(intent: CompleteTopReminderIntent()) {
                LockScreenChip(title: "Done", tint: .green)
            }
        } else {
            Link(destination: BoringNotchRoute.captureReminder.url) {
                LockScreenChip(title: "Reminder", tint: theme.foregroundColor)
            }
        }
    }
}

private struct ExpandedActionChip: View {
    let title: String
    let systemImage: String
    let tint: Color

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(tint.opacity(0.16), in: Capsule())
            .foregroundStyle(tint)
    }
}

private struct LockScreenChip: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.16), in: Capsule())
            .foregroundStyle(tint)
    }
}

private enum WidgetPresetResolver {
    static func activePreset() -> IslandPreset {
        let defaults = UserDefaults(suiteName: IslandAppGroup.suiteName) ?? .standard
        let presetStore = UserDefaultsCustomizationStore(defaults: defaults)
        let stateStore = AppGroupIslandStateStore(defaults: defaults)

        let presets = (try? presetStore.loadPresets()) ?? [.default]
        let selectedPresetID = stateStore.loadSelectedPresetID()
        return presets.first(where: { $0.id == selectedPresetID }) ?? presets.first ?? .default
    }
}

@ViewBuilder
private func trailingAction(for state: IslandContentState, theme: IslandTheme) -> some View {
    if shouldShowReminderCompletion(for: state) {
        Button(intent: CompleteTopReminderIntent()) {
            ExpandedActionChip(
                title: "Done",
                systemImage: "checkmark.circle.fill",
                tint: .green
            )
        }
    } else {
        Link(destination: BoringNotchRoute.captureReminder.url) {
            ExpandedActionChip(
                title: "Reminder",
                systemImage: "checklist.checked",
                tint: theme.foregroundColor
            )
        }
    }
}

private func shouldShowReminderCompletion(for state: IslandContentState) -> Bool {
    state.shelf?.pendingReminderCount ?? 0 > 0
}

private func summaryLabel(for state: IslandContentState) -> String {
    if shouldShowReminderCompletion(for: state) {
        return "Actionable Reminder"
    }

    if state.activeModule == .shelf {
        return "Cross-App Capture"
    }

    return "Island Home"
}

private func queueSummary(for state: IslandContentState) -> String {
    if let shelf = state.shelf, shelf.pendingReminderCount > 0 {
        return "\(shelf.pendingReminderCount) due"
    }

    if let shelf = state.shelf {
        return "\(shelf.itemCount) saved"
    }

    return "Inbox"
}

@available(iOS 17.0, *)
private struct CaptureClipboardIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Save Clipboard"
    static var description = IntentDescription("Capture the current clipboard into your Boring Notch inbox without leaving the current app.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let controller = IslandActionController()
        let pasteboard = UIPasteboard.general
        let clipboardValue = pasteboard.url?.absoluteString ?? pasteboard.string

        guard let item = try await controller.captureClipboardValue(clipboardValue) else {
            return .result(dialog: "Nothing usable on the clipboard.")
        }

        switch item.kind {
        case .url:
            return .result(dialog: "Saved link to Inbox.")
        case .text:
            return .result(dialog: "Saved note to Inbox.")
        case .reminder:
            return .result(dialog: "Saved reminder to Inbox.")
        }
    }
}

@available(iOS 17.0, *)
private struct CompleteTopReminderIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Complete Reminder"
    static var description = IntentDescription("Mark the next pending Boring Notch reminder as complete from the Live Activity.")

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let controller = IslandActionController()

        guard let reminder = try await controller.completeTopReminder() else {
            return .result(dialog: "No pending reminders right now.")
        }

        return .result(dialog: "Completed \(reminder.title).")
    }
}
#endif
