import SwiftUI
import UIKit

struct ShelfFeatureView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var runtimeStore: IslandRuntimeStore

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
                } else {
                    Section("Recent") {
                        ForEach(runtimeStore.shelfItems) { item in
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
                        .background(theme.accentColor.opacity(0.15), in: Capsule())
                        .foregroundStyle(theme.accentColor)
                }
            }

            Text(detailText)
                .font(.subheadline)
                .foregroundStyle(theme.foregroundColor.opacity(0.76))
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
            return item.notes?.isEmpty == false ? item.notes! : "Reminder stored in your inbox."
        }
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
