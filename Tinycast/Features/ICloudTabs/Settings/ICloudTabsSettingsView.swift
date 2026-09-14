import SwiftUI

struct ICloudTabsSettingsView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        @Bindable var settings = settings
        Form {
            Section {
                Toggle(isOn: $settings.iCloudTabsEnabled) {
                    SettingsRowTitle(.iCloudTabsFeature, "Enable iCloud Tabs")
                    Text(
                        "Browse open Safari tabs from your other Apple devices. If Safari’s cache is locked, grant Full Disk Access below."
                    )
                }
            } header: {
                SettingsSectionHeader(.iCloudTabsFeature)
            }

            ICloudTabsCommandSection()
                .settingsEnabled(settings.iCloudTabsEnabled)

            Section {
                SettingsRow(
                    title: "Full Disk Access",
                    subtitle:
                        "Tinycast reads Safari’s CloudTabs database. Grant access under Privacy & Security.",
                    anchor: .iCloudTabsAccess
                ) {
                    Button("Open System Settings…") {
                        Permissions.openFullDiskAccessSettings()
                    }
                }
            } header: {
                SettingsSectionHeader(.iCloudTabsAccess)
            }
            .settingsEnabled(settings.iCloudTabsEnabled)
        }
        .formStyle(.grouped)
        .settingsScrollTarget(.iCloudTabs)
    }
}

private struct ICloudTabsCommandSection: View {
    @Environment(VisibilityStore.self) private var visibility

    private let entry = CommandCatalog.entry(for: .iCloudTabs)

    var body: some View {
        Section {
            if let entry {
                SettingsRow(title: entry.name) {
                    Image(systemName: CommandID.iCloudTabs.sfSymbol)
                        .frame(width: Theme.Size.settingsRowIcon)
                } trailing: {
                    ShortcutRecorder(action: .command(.iCloudTabs))
                    Toggle("", isOn: visibilityBinding(entry))
                        .labelsHidden()
                        .toggleStyle(.checkbox)
                        .accessibilityLabel("Show \(entry.name) in launcher")
                }
            }
        } header: {
            SettingsSectionHeader(.iCloudTabsCommand)
        } footer: {
            Text("The shortcut works even when the command is hidden from the launcher.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func visibilityBinding(_ entry: AppEntry) -> Binding<Bool> {
        Binding(
            get: { visibility.isItemVisible(entry) },
            set: { visibility.setItemVisible($0, for: entry) })
    }
}
