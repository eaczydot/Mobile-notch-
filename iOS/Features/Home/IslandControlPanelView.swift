import SwiftUI

struct IslandControlPanelView: View {
    @EnvironmentObject private var runtimeStore: IslandRuntimeStore

    let openInbox: () -> Void
    let openSettings: () -> Void
    let startLinkCapture: () -> Void
    let startReminderCapture: () -> Void

    private var theme: IslandTheme {
        runtimeStore.selectedPreset.theme
    }

    private var recentItems: [ShelfItemRecord] {
        Array(runtimeStore.shelfItems.prefix(3))
    }

    private var activityDetailText: String {
        guard runtimeStore.capabilityMatrix.supportsLiveActivities else {
            return "Unavailable on this device"
        }

        switch runtimeStore.activityStatus {
        case .active:
            return "Auto-running and ready for quick launch."
        case .inactive:
            return "Will auto-resume when the app becomes active."
        case .unavailable:
            return "Unavailable on this device"
        case .failed(let message):
            return message
        }
    }

    private var statusItems: [StatusOverviewCard.Item] {
        [
            .init(
                title: "Persistent Live Activity",
                detail: runtimeStore.isPersistentLiveActivityEnabled ? activityDetailText : "Disabled in Settings",
                systemImage: runtimeStore.isPersistentLiveActivityEnabled ? "capsule.portrait.fill" : "capsule.portrait",
                trailing: runtimeStore.activityStatus.label
            ),
            .init(
                title: "Reminder Sync",
                detail: runtimeStore.reminderAccessStatus.canMirror
                    ? "New reminders mirror to Apple Reminders."
                    : "Local reminders save immediately. Enable sync in Settings.",
                systemImage: runtimeStore.reminderAccessStatus.canMirror ? "checkmark.icloud.fill" : "icloud.slash",
                trailing: runtimeStore.reminderAccessStatus.label
            ),
            .init(
                title: "Device Support",
                detail: runtimeStore.capabilityMatrix.supportsDynamicIsland
                    ? "Dynamic Island previews are active on this iPhone."
                    : "Live Activities work, but Dynamic Island needs supported hardware.",
                systemImage: runtimeStore.capabilityMatrix.supportsDynamicIsland
                    ? "iphone.gen3.radiowaves.left.and.right"
                    : "iphone",
                trailing: runtimeStore.capabilityMatrix.supportsDynamicIsland ? "Dynamic" : "Preview"
            ),
        ]
    }

    var body: some View {
        ZStack {
            LiquidGlassBackdrop(theme: theme)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ControlPanelHeader(theme: theme)
                    IslandHeroCard(
                        theme: theme,
                        state: runtimeStore.contentState,
                        activityStatus: runtimeStore.activityStatus
                    )

                    QuickActionsSection(
                        theme: theme,
                        openInbox: openInbox,
                        startLinkCapture: startLinkCapture,
                        startReminderCapture: startReminderCapture
                    )

                    StatusOverviewSection(theme: theme, items: statusItems)

                    RecentInboxSection(
                        theme: theme,
                        items: recentItems,
                        openInbox: openInbox
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 32)
            }
            .scrollIndicators(.hidden)
        }
        .navigationTitle("Boring Notch")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: openSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.headline)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.84), value: runtimeStore.contentState)
        .refreshable {
            await runtimeStore.sceneDidBecomeActive()
        }
    }
}

private struct ControlPanelHeader: View {
    let theme: IslandTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Persistent island, quick capture.")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(theme.foregroundColor)
            Text("Save links, collect notes, and create reminders without leaving the island flow.")
                .font(.subheadline)
                .foregroundStyle(theme.foregroundColor.opacity(0.74))
        }
        .padding(.horizontal, 4)
    }
}

private struct QuickActionsSection: View {
    let theme: IslandTheme
    let openInbox: () -> Void
    let startLinkCapture: () -> Void
    let startReminderCapture: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderRow(
                title: "Quick Actions",
                theme: theme,
                actionTitle: "Inbox",
                action: openInbox
            )

            LiquidGlassCluster(spacing: 12) {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        QuickGlassButton(
                            title: "Add Link",
                            subtitle: "Paste or capture",
                            systemImage: "link.badge.plus",
                            theme: theme,
                            action: startLinkCapture
                        )

                        QuickGlassButton(
                            title: "New Reminder",
                            subtitle: "Save for later",
                            systemImage: "checklist.checked",
                            theme: theme,
                            action: startReminderCapture
                        )
                    }
                }
            }
        }
    }
}

private struct StatusOverviewSection: View {
    let theme: IslandTheme
    let items: [StatusOverviewCard.Item]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderRow(title: "Status", theme: theme)

            LiquidGlassCluster(spacing: 12) {
                VStack(spacing: 12) {
                    ForEach(items) { item in
                        StatusOverviewCard(item: item, theme: theme)
                    }
                }
            }
        }
    }
}

private struct RecentInboxSection: View {
    let theme: IslandTheme
    let items: [ShelfItemRecord]
    let openInbox: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeaderRow(
                title: "Inbox",
                theme: theme,
                actionTitle: "Open",
                action: openInbox
            )

            if items.isEmpty {
                EmptyInboxCard(theme: theme)
            } else {
                LiquidGlassCluster(spacing: 12) {
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            InboxPreviewCard(item: item, theme: theme)
                        }
                    }
                }
            }
        }
    }
}

private struct SectionHeaderRow: View {
    let title: String
    let theme: IslandTheme
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        theme: IslandTheme,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.theme = theme
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(theme.foregroundColor.opacity(0.84))

            Spacer()

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal, 4)
    }
}

private struct IslandHeroCard: View {
    let theme: IslandTheme
    let state: IslandContentState
    let activityStatus: IslandRuntimeStore.ActivityStatus

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Island Home")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.foregroundColor.opacity(0.7))
                    Text(state.displayTitle)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundStyle(theme.foregroundColor)
                        .lineLimit(2)
                    Text(state.displaySubtitle)
                        .font(.subheadline)
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))
                        .lineLimit(3)
                }

                Spacer()

                Image(systemName: state.systemImageName)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .padding(14)
                    .background(theme.foregroundColor.opacity(0.08), in: Circle())
            }

            LiquidGlassCluster(spacing: 10) {
                HStack(spacing: 10) {
                    StatusPill(title: activityStatus.label, tint: statusTint)

                    if let shelf = state.shelf, shelf.pendingReminderCount > 0 {
                        StatusPill(
                            title: "\(shelf.pendingReminderCount) reminders",
                            tint: theme.foregroundColor.opacity(0.85)
                        )
                    }

                    if let latestName = state.shelf?.latestItemName {
                        StatusPill(title: latestName, tint: theme.foregroundColor.opacity(0.72))
                    }
                }
            }
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(heroGradient, in: heroShape)
        .liquidGlassCard(
            theme: theme,
            cornerRadius: theme.cornerRadius + 6,
            tint: theme.accentColor.opacity(0.24)
        )
    }

    private var heroShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: theme.cornerRadius + 6, style: .continuous)
    }

    private var heroGradient: LinearGradient {
        LinearGradient(
            colors: [
                theme.backgroundColor.opacity(0.72),
                theme.backgroundColor.opacity(0.36),
                theme.accentColor.opacity(0.24)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var statusTint: Color {
        switch activityStatus {
        case .inactive:
            return theme.foregroundColor.opacity(0.74)
        case .active:
            return theme.accentColor
        case .unavailable:
            return .orange
        case .failed:
            return .red
        }
    }
}

private struct StatusOverviewCard: View {
    struct Item: Identifiable {
        let title: String
        let detail: String
        let systemImage: String
        let trailing: String

        var id: String { title }
    }

    let item: Item
    let theme: IslandTheme

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: item.systemImage)
                .font(.headline)
                .foregroundStyle(theme.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                Text(item.detail)
                    .font(.footnote)
                    .foregroundStyle(theme.foregroundColor.opacity(0.72))
            }

            Spacer()

            Text(item.trailing)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.foregroundColor.opacity(0.84))
        }
        .padding(16)
        .liquidGlassCard(theme: theme, cornerRadius: 24)
    }
}

private struct QuickGlassButton: View {
    let title: String
    let subtitle: String
    let systemImage: String
    let theme: IslandTheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.accentColor)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.footnote)
                        .foregroundStyle(theme.foregroundColor.opacity(0.72))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 94, alignment: .leading)
            .padding(18)
            .liquidGlassCard(
                theme: theme,
                cornerRadius: 26,
                isInteractive: true
            )
        }
        .buttonStyle(.plain)
    }
}

private struct EmptyInboxCard: View {
    let theme: IslandTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Nothing captured yet", systemImage: "tray")
                .font(.headline)
            Text("Share a link from Safari or create a quick reminder to start filling the island.")
                .font(.subheadline)
                .foregroundStyle(theme.foregroundColor.opacity(0.72))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(theme: theme, cornerRadius: 26)
    }
}

private struct InboxPreviewCard: View {
    let item: ShelfItemRecord
    let theme: IslandTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(item.title, systemImage: iconName)
                    .font(.headline)
                Spacer()
                Text(item.createdAt, style: .relative)
                    .font(.caption)
                    .foregroundStyle(theme.foregroundColor.opacity(0.66))
            }

            Text(detailText)
                .font(.subheadline)
                .foregroundStyle(theme.foregroundColor.opacity(0.74))
                .lineLimit(3)

            if item.kind == .reminder {
                LiquidGlassCluster(spacing: 8) {
                    HStack(spacing: 8) {
                        if let dueDate = item.dueDate {
                            StatusPill(
                                title: dueDate.formatted(date: .abbreviated, time: .shortened),
                                tint: theme.accentColor
                            )
                        }

                        if let mirrorStatus = item.mirrorStatus {
                            StatusPill(
                                title: mirrorStatusLabel(mirrorStatus),
                                tint: theme.foregroundColor.opacity(0.78)
                            )
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(theme: theme, cornerRadius: 26)
    }

    private var iconName: String {
        switch item.kind {
        case .url:
            return "link"
        case .text:
            return "text.alignleft"
        case .reminder:
            return "checklist"
        }
    }

    private var detailText: String {
        switch item.kind {
        case .url, .text:
            return item.value
        case .reminder:
            return item.notes?.isEmpty == false ? item.notes! : "Reminder saved to your inbox."
        }
    }

    private func mirrorStatusLabel(_ status: ShelfItemRecord.ReminderMirrorStatus) -> String {
        switch status {
        case .notRequested:
            return "Local"
        case .localOnly:
            return "Inbox"
        case .mirrored:
            return "Synced"
        case .failed:
            return "Retry"
        }
    }
}

private struct StatusPill: View {
    let title: String
    let tint: Color

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(tint.opacity(0.16), in: Capsule())
            .foregroundStyle(tint)
    }
}
