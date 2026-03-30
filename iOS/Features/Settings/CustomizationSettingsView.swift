import SwiftUI
import UIKit

struct CustomizationSettingsView: View {
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var runtimeStore: IslandRuntimeStore

    @State private var draftPreset: IslandPreset = .default
    @State private var exportDocument: PresetDocument?
    @State private var isExporterPresented = false
    @State private var isImporterPresented = false

    var body: some View {
        let theme = runtimeStore.selectedPreset.theme

        ZStack {
            LiquidGlassBackdrop(theme: theme)

            Form {
                liveActivitySection
                reminderSection
                presetSection
                appearanceSection
                importExportSection
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(
            isPresented: $isExporterPresented,
            document: exportDocument,
            contentType: .boringNotchPreset,
            defaultFilename: "boringnotch-presets"
        ) { _ in }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.boringNotchPreset, .json]
        ) { result in
            guard case .success(let url) = result,
                  let data = try? Data(contentsOf: url) else {
                return
            }
            runtimeStore.importPresets(data: data)
            syncDraftPreset()
        }
        .onAppear {
            runtimeStore.reloadPresets()
            syncDraftPreset()
        }
        .onChange(of: runtimeStore.selectedPresetID) { _, _ in
            syncDraftPreset()
        }
    }

    private var liveActivitySection: some View {
        Section("Live Activity") {
            Toggle(
                "Persistent Live Activity",
                isOn: Binding(
                    get: { runtimeStore.isPersistentLiveActivityEnabled },
                    set: { runtimeStore.setPersistentLiveActivityEnabled($0) }
                )
            )

            LabeledContent("Status", value: runtimeStore.activityStatus.label)

            Text("When enabled, Boring Notch keeps the island surface alive and refreshes it whenever the app becomes active.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var reminderSection: some View {
        Section("Apple Reminders") {
            LabeledContent("Sync", value: runtimeStore.reminderAccessStatus.label)

            switch runtimeStore.reminderAccessStatus {
            case .authorized:
                Text("New reminders save locally first and then mirror into Apple Reminders.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            case .notDetermined:
                Button("Enable Reminder Sync") {
                    Task {
                        await runtimeStore.requestReminderAccess()
                    }
                }
            case .denied, .restricted:
                Button("Open System Settings") {
                    guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                    openURL(url)
                }
            case .unavailable, .failed:
                Text("Reminders sync isn’t available right now. Local reminders still save to your inbox.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var presetSelectionBinding: Binding<UUID> {
        Binding(
            get: { runtimeStore.selectedPresetID ?? runtimeStore.presets.first?.id ?? draftPreset.id },
            set: { runtimeStore.selectPreset($0) }
        )
    }

    private var presetSection: some View {
        Section("Preset") {
            Picker("Active preset", selection: presetSelectionBinding) {
                ForEach(runtimeStore.presets) { preset in
                    Text(preset.name).tag(preset.id)
                }
            }

            Button("Save Changes") {
                runtimeStore.savePreset(draftPreset)
            }

            Button("Duplicate Preset") {
                var copy = draftPreset
                copy.id = UUID()
                copy.name = "\(draftPreset.name) Copy"
                runtimeStore.savePreset(copy)
                syncDraftPreset()
            }

            Button("Delete Preset", role: .destructive) {
                runtimeStore.deletePreset(draftPreset)
                syncDraftPreset()
            }
            .disabled(runtimeStore.presets.count == 1)
        }
    }

    private var appearanceSection: some View {
        Section("Appearance") {
            ColorPicker("Background Tint", selection: colorBinding(\.backgroundHex, fallback: .black))
            ColorPicker("Foreground Tint", selection: colorBinding(\.foregroundHex, fallback: .white))
            ColorPicker("Accent Tint", selection: colorBinding(\.accentHex, fallback: .cyan))

            Stepper(
                "Glass Radius \(Int(draftPreset.theme.cornerRadius))",
                value: $draftPreset.theme.cornerRadius,
                in: 16...36
            )

            Picker("Typography", selection: $draftPreset.theme.typographyScale) {
                ForEach(IslandTheme.TypographyScale.allCases, id: \.self) { scale in
                    Text(scale.rawValue.capitalized).tag(scale)
                }
            }

            Picker("Motion", selection: $draftPreset.theme.animationStyle) {
                ForEach(IslandTheme.AnimationStyle.allCases, id: \.self) { style in
                    Text(style.rawValue.capitalized).tag(style)
                }
            }
        }
    }

    private var importExportSection: some View {
        Section("Import / Export") {
            Button("Export Presets") {
                if let data = runtimeStore.exportSelectedPresets() {
                    exportDocument = PresetDocument(data: data)
                    isExporterPresented = true
                }
            }

            Button("Import Presets") {
                isImporterPresented = true
            }
        }
    }

    private func syncDraftPreset() {
        draftPreset = runtimeStore.selectedPreset
    }

    private func colorBinding(
        _ keyPath: WritableKeyPath<IslandTheme, String>,
        fallback: Color
    ) -> Binding<Color> {
        Binding(
            get: { Color(hex: draftPreset.theme[keyPath: keyPath]) ?? fallback },
            set: { draftPreset.theme[keyPath: keyPath] = $0.hexString }
        )
    }
}
