import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit

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
                    Link(destination: BoringNotchRoute.captureLink.url) {
                        ExpandedActionChip(
                            title: "Add Link",
                            systemImage: "link.badge.plus",
                            tint: preset.theme.accentColor
                        )
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Link(destination: BoringNotchRoute.captureReminder.url) {
                        ExpandedActionChip(
                            title: "Reminder",
                            systemImage: "checklist.checked",
                            tint: preset.theme.foregroundColor
                        )
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    Link(destination: BoringNotchRoute.island.url) {
                        VStack(alignment: .leading, spacing: 4) {
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
                            if let shelf = state.shelf {
                                Text("\(shelf.itemCount)")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(preset.theme.foregroundColor.opacity(0.84))
                    }
                }
            } compactLeading: {
                Image(systemName: state.systemImageName)
                    .foregroundStyle(preset.theme.foregroundColor)
            } compactTrailing: {
                Text(compactTrailingText(for: state))
                    .foregroundStyle(preset.theme.accentColor)
                    .font(.caption2)
            } minimal: {
                Image(systemName: state.systemImageName)
                    .foregroundStyle(preset.theme.foregroundColor)
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

        if let shelf = state.shelf, state.activeModule == .shelf {
            return "\(shelf.itemCount)"
        }

        return "•"
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
                Link(destination: BoringNotchRoute.captureLink.url) {
                    LockScreenChip(title: "Add Link", tint: theme.accentColor)
                }

                Link(destination: BoringNotchRoute.captureReminder.url) {
                    LockScreenChip(title: "Reminder", tint: theme.foregroundColor)
                }

                Link(destination: BoringNotchRoute.inbox.url) {
                    LockScreenChip(title: "Inbox", tint: theme.foregroundColor.opacity(0.86))
                }
            }
        }
        .padding(.horizontal)
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
#endif
