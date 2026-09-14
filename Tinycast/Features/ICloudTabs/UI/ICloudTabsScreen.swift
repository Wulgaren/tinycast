import SwiftUI

struct ICloudTabsScreen: PaletteScreen {
    let session: ICloudTabsSession
    let core: AppCore
    let vm: PaletteState
    let openActions: () -> Void

    private var visibleDevices: [ICloudTabDevice] {
        ICloudTabsPolicy.filtered(devices: session.devices, query: vm.query)
    }

    var rows: [ICloudTab] { ICloudTabsPolicy.flatTabs(in: visibleDevices) }

    var primaryActionTitle: String {
        switch session.state {
        case .needsFullDiskAccess: return "Open System Settings"
        default: return "Open"
        }
    }

    var actsWithoutRows: Bool { session.state == .needsFullDiskAccess }

    private func tab(at selection: Int) -> ICloudTab? {
        rows.indices.contains(selection) ? rows[selection] : nil
    }

    func hasPrimaryAction(at selection: Int) -> Bool {
        session.state == .needsFullDiskAccess || tab(at: selection) != nil
    }

    func actions(at selection: Int) -> PopoverMenuContent? {
        guard let tab = tab(at: selection) else { return nil }
        return ICloudTabsActionsMenu.content(tab: tab, core: core)
    }

    func activate(at selection: Int) {
        if session.state == .needsFullDiskAccess {
            core.iCloudTabsCoordinator.openFullDiskAccessSettings()
            return
        }
        guard let tab = tab(at: selection) else { return }
        core.iCloudTabsCoordinator.open(tab)
    }

    func secondary(at selection: Int) -> Bool {
        guard let tab = tab(at: selection) else { return false }
        core.iCloudTabsCoordinator.copyURL(tab)
        return true
    }

    func body(selection: Int, scroll: ScrollIntent) -> AnyView {
        AnyView(content(selection: selection, scroll: scroll))
    }

    @ViewBuilder
    private func content(selection: Int, scroll: ScrollIntent) -> some View {
        switch session.state {
        case .idle, .refreshing:
            EmptyResults(text: "Refreshing iCloud Tabs…")
        case .needsFullDiskAccess:
            VStack(spacing: Theme.Spacing.md) {
                Image(systemName: "magnifyingglass").font(.largeTitle)
                    .symbolRenderingMode(.hierarchical).foregroundStyle(.tertiary)
                Text("Full Disk Access is required to read Safari’s iCloud Tabs")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                Button("Open System Settings…") {
                    core.iCloudTabsCoordinator.openFullDiskAccessSettings()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(Theme.Spacing.xl)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .missingDatabase:
            EmptyResults(text: "Safari’s iCloud Tabs database wasn’t found")
        case .ready:
            let devices = visibleDevices
            let tabs = rows
            if tabs.isEmpty {
                EmptyResults(
                    text: vm.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? "No iCloud Tabs" : "No matching tabs")
            } else {
                ICloudTabsList(
                    devices: devices,
                    selectedID: tabs.indices.contains(selection) ? tabs[selection].id : nil,
                    scroll: scroll,
                    onActivate: { core.iCloudTabsCoordinator.open($0) },
                    onActions: { tab in
                        if let index = tabs.firstIndex(of: tab) { vm.selection = index }
                        openActions()
                    })
            }
        }
    }
}

@MainActor
enum ICloudTabsActionsMenu {
    static func content(tab: ICloudTab, core: AppCore) -> PopoverMenuContent {
        PopoverMenuContent(
            header: tab.title,
            items: [
                PopoverMenuItem(
                    title: "Open", systemImage: "safari", shortcut: "↵"
                ) { core.iCloudTabsCoordinator.open(tab) },
                PopoverMenuItem(
                    title: "Copy URL", systemImage: "doc.on.clipboard", shortcut: "⌘↵"
                ) { core.iCloudTabsCoordinator.copyURL(tab) },
            ])
    }
}
