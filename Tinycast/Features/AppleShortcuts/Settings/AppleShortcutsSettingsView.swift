import SwiftUI

/// Master switch for Apple Shortcuts, plus per-shortcut hide and hotkey controls.
struct AppleShortcutsSettingsView: View {
    @Environment(AppleShortcutStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @State private var query = ""

    private var results: [AppleShortcut] {
        let scoped = store.shortcuts
        guard !query.isEmpty else { return scoped }
        let needle = FuzzyMatch.normalized(query)
        return scoped.filter { FuzzyMatch.normalized($0.name).contains(needle) }
    }

    var body: some View {
        @Bindable var settings = settings
        return Form {
            FeatureSwitchSection(
                anchor: .appleShortcutsAppleShortcuts,
                enableTitle: "Enable Apple Shortcuts",
                enableSubtitle:
                    "Run shortcuts from your Shortcuts library in the launcher or with a global "
                    + "shortcut. Optional text can be passed in when you run one.",
                launcherSubtitle: "Find your shortcuts in launcher search.",
                isEnabled: $settings.appleShortcutsEnabled,
                showsInLauncher: $settings.appleShortcutsShowInLauncher)

            Section {
                if !store.shortcuts.isEmpty {
                    SettingsFilterField(prompt: "Search Apple Shortcuts…", query: $query)
                }
                if results.isEmpty {
                    Text(
                        store.shortcuts.isEmpty
                            ? "No shortcuts on this Mac yet. Create some in the Shortcuts app."
                            : "No shortcut matches “\(query)”."
                    )
                    .foregroundStyle(.secondary)
                } else {
                    LazyVStack(spacing: 0) {
                        ForEach(results) { shortcut in
                            if shortcut.id != results.first?.id { Divider() }
                            AppleShortcutSettingsRow(shortcut: shortcut)
                                .padding(.vertical, 15)
                        }
                    }
                    .padding(.vertical, -15)
                }
            } header: {
                SettingsSectionHeader(.appleShortcutsItems)
            }
            .settingsEnabled(settings.appleShortcutsEnabled)
        }
        .formStyle(.grouped)
        .settingsScrollTarget(.appleShortcuts)
        .releasesFocusOnOutsideClick()
        .onAppear {
            if settings.appleShortcutsEnabled { store.reload() }
        }
    }
}

private struct AppleShortcutSettingsRow: View {
    let shortcut: AppleShortcut
    @Environment(VisibilityStore.self) private var visibility

    private var entry: AppEntry { AppEntry(shortcut) }

    var body: some View {
        SettingsRow(title: shortcut.name) {
            AppIconView(app: entry).frame(width: 18, height: 18)
        } trailing: {
            AliasField(entry: entry)
            ShortcutRecorder(action: .appleShortcut(id: shortcut.identifier))
            Toggle("", isOn: itemBinding)
                .labelsHidden()
                .toggleStyle(.checkbox)
                .accessibilityLabel("Show \(shortcut.name) in launcher")
        }
    }

    private var itemBinding: Binding<Bool> {
        Binding(
            get: { visibility.isItemVisible(entry) },
            set: { visibility.setItemVisible($0, for: entry) })
    }
}
