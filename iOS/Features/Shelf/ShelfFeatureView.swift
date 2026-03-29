import SwiftUI
import UIKit

struct ShelfFeatureView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var runtimeStore: IslandRuntimeStore

    @State private var filter: InboxFilter = .all

    let startLinkCapture: () -> Void
    let startReminderCapture: () -> Void

    var body: some View {
        let theme = runtimeStore.selectedPreset.theme

        ZStack {
            LiquidGlassBackdrop(theme: theme)

            List {
                Section {
                    inboxHeader(theme: theme)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }

                if runtimeStore.shelfItems.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Your inbox is empty", systemImage: "tray")
                                .font(.headline)
                            Text("Share a link from another app or save a reminder from the island to start building your capture queue.")
                                .font(.subheadline)
                                .foregroundStyle(theme.foregroundColor.opacity(0.72))
                        }
                        .padding(18)
                        .liquidGlassCard(theme: theme, cornerRadius: 26)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                } else if filteredShelfItems.isEmpty {
                    Section {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Nothing in \(filter.title.lowercased())", systemImage: filter.systemImage)
                                .font(.headline)
                            Text("Switch filters or save something new from the island to keep your queue moving.")
                                .font(.subheadline)
                                .foregroundStyle(theme.foregroundColor.opacity(0.72))
                        }
                        .padding(18)
                        .liquidGlassCard(theme: theme, cornerRadius: 26)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                        .listRowBackground(Color.clear)
                    }
                } else {
                    Section(filter.sectionTitle) {
                        ForEach(filteredShelfItems) { item in
                            InboxItemRow(item: item, theme: theme)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if item.kind == .url, let url = URL(string: item.value) {
                                        openURL(url)
                                    }
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        runtimeStore.deleteShelfItem(item)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                                .swipeActions(edge: .leading) {
                                    if item.kind == .reminder {
                                        Button {
                                            runtimeStore.setReminderCompletion(item, isCompleted: !item.isCompleted)
                                        } label: {
                                            Label(item.isCompleted ? "Reopen" : "Done", systemImage: item.isCompleted ? "arrow.uturn.backward.circle" : "checkmark.circle")
                                        }
                                        .tint(item.isCompleted ? .blue : .green)
                                    }

                                    Button {
                                        copy(item)
                                    } label: {
                                        Label("Copy", systemImage: "doc.on.doc")
                                    }
                                    .tint(.blue)
                                }
                                .contextMenu {
                                    Button("Copy") {
                                        copy(item)
                                    }

                                    if item.kind == .reminder {
                                        Button(item.isCompleted ? "Reopen Reminder" : "Complete Reminder") {
                                            runtimeStore.setReminderCompletion(item, isCompleted: !item.isCompleted)
                                        }
                                    }

                                    if item.kind == .url, let url = URL(string: item.value) {
                                        Button("Open Link") {
                                            openURL(url)
                                        }
                                    }

                                    Button("Delete", role: .destructive) {
                                        runtimeStore.deleteShelfItem(item)
                                    }
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                                .listRowBackground(Color.clear)
                        }
                        .onDelete(perform: runtimeStore.deleteShelfItems)
                    }
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Inbox")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(action: startLinkCapture) {
                    Image(systemName: "link.badge.plus")
                }

                Button(action: startReminderCapture) {
                    Image(systemName: "checklist.checked")
                }

                if !runtimeStore.shelfItems.isEmpty {
                    Button("Clear", role: .destructive) {
                        runtimeStore.clearShelf()
                    }
                }
            }
        }
        .refreshable {
            await runtimeStore.sceneDidBecomeActive()
        }
    }

    private func copy(_ item: ShelfItemRecord) {
        UIPasteboard.general.string = item.copyText
    }

    @ViewBuilder
    private func inboxHeader(theme: IslandTheme) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Button(action: startLinkCapture) {
                    inboxActionChip(
                        title: "Add Link",
                        systemImage: "link.badge.plus",
                        tint: theme.accentColor,
                        theme: theme
                    )
                }
                .buttonStyle(.plain)

                Button(action: startReminderCapture) {
                    inboxActionChip(
                        title: "Reminder",
                        systemImage: "checklist.checked",
                        tint: theme.foregroundColor,
                        theme: theme
                    )
                }
                .buttonStyle(.plain)
            }

            if !runtimeStore.shelfItems.isEmpty {
                Picker("Filter", selection: $filter) {
                    ForEach(InboxFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
        .padding(.top, 4)
    }

    @ViewBuilder
    private func inboxActionChip(title: String, systemImage: String, tint: Color, theme: IslandTheme) -> some View {
        Label(title, systemImage: systemImage)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .foregroundStyle(tint)
            .liquidGlassCard(theme: theme, cornerRadius: 24, tint: tint.opacity(0.16))
    }
}

private enum InboxFilter: CaseIterable {
    case all
    case links
    case notes
    case reminders

    var title: String {
        switch self {
        case .all:
            return "All"
        case .links:
            return "Links"
        case .notes:
            return "Notes"
        case .reminders:
            return "Reminders"
        }
    }

    var systemImage: String {
        switch self {
        case .all:
            return "tray.full"
        case .links:
            return "link"
        case .notes:
            return "text.alignleft"
        case .reminders:
            return "checklist"
        }
    }

    var sectionTitle: String {
        switch self {
        case .all:
            return "Recent"
        case .links:
            return "Links"
        case .notes:
            return "Notes"
        case .reminders:
            return "Reminders"
        }
    }

    func includes(_ item: ShelfItemRecord) -> Bool {
        switch self {
        case .all:
            return true
        case .links:
            return item.kind == .url
        case .notes:
            return item.kind == .text
        case .reminders:
            return item.kind == .reminder
        }
    }
}

private struct InboxItemRow: View {
    let item: ShelfItemRecord
    let theme: IslandTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(theme.accentColor)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.headline)
                        .strikethrough(item.isCompleted)
                        .foregroundStyle(item.isCompleted ? theme.foregroundColor.opacity(0.62) : theme.foregroundColor)
                    Text(item.createdAt, style: .relative)
                        .font(.caption)
                        .foregroundStyle(theme.foregroundColor.opacity(0.6))
                }

                Spacer()

                if let dueDate = item.dueDate, item.kind == .reminder {
                    Text(dueDate.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(dueDateTint.opacity(0.15), in: Capsule())
                        .foregroundStyle(dueDateTint)
                }
            }

            Text(detailText)
                .font(.subheadline)
                .foregroundStyle(item.isCompleted ? theme.foregroundColor.opacity(0.5) : theme.foregroundColor.opacity(0.76))
                .lineLimit(4)

            if item.kind == .reminder {
                HStack(spacing: 8) {
                    if let status = item.mirrorStatus {
                        statusBadge(status)
                    }

                    if item.isCompleted {
                        statusText("Completed", tint: .green)
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
            if item.isCompleted {
                return item.notes?.isEmpty == false ? item.notes! : "Completed reminder."
            }
            return item.notes?.isEmpty == false ? item.notes! : "Reminder stored in your inbox."
        }
    }

    private var dueDateTint: Color {
        guard let dueDate = item.dueDate else {
            return theme.accentColor
        }

        if !item.isCompleted, dueDate < .now {
            return .orange
        }

        return theme.accentColor
    }

    @ViewBuilder
    private func statusBadge(_ status: ShelfItemRecord.ReminderMirrorStatus) -> some View {
        switch status {
        case .notRequested:
            statusText("Local", tint: theme.foregroundColor.opacity(0.78))
        case .localOnly:
            statusText("Inbox", tint: theme.foregroundColor.opacity(0.78))
        case .mirrored:
            statusText("Synced", tint: theme.accentColor)
        case .failed:
            statusText("Mirror Failed", tint: .orange)
        }
    }

    @ViewBuilder
    private func statusText(_ text: String, tint: Color) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.15), in: Capsule())
            .foregroundStyle(tint)
    }
}

private extension ShelfFeatureView {
    var filteredShelfItems: [ShelfItemRecord] {
        runtimeStore.shelfItems.filter(filter.includes)
    }
}
