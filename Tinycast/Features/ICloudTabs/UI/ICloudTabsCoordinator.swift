import AppKit

@MainActor
final class ICloudTabsCoordinator {
    private let settings: AppSettings
    private let appIndex: AppIndex
    private let session: ICloudTabsSession
    private let palette: PaletteState
    private let paletteCoordinator: PaletteCoordinator
    private unowned let core: AppCore
    private var activationObserver: NotificationToken?

    init(
        settings: AppSettings, appIndex: AppIndex, session: ICloudTabsSession,
        palette: PaletteState, paletteCoordinator: PaletteCoordinator, core: AppCore
    ) {
        self.settings = settings
        self.appIndex = appIndex
        self.session = session
        self.palette = palette
        self.paletteCoordinator = paletteCoordinator
        self.core = core
        let token = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.reprobeIfWaitingOnAccess() }
        }
        activationObserver = NotificationToken(token, center: .default)
    }

    func applyEnabled() {
        appIndex.setCommandsVisible([.iCloudTabs], settings.iCloudTabsEnabled)
        guard !settings.iCloudTabsEnabled else { return }
        session.cancel()
        if palette.mode == .iCloudTabs { palette.prepare(mode: .launcher) }
    }

    func show() {
        guard settings.iCloudTabsEnabled else { return }
        paletteCoordinator.togglePalette(mode: .iCloudTabs)
        session.refresh()
    }

    /// After System Settings, the same screen must notice a newly granted (or already-readable) DB.
    private func reprobeIfWaitingOnAccess() {
        guard settings.iCloudTabsEnabled, palette.mode == .iCloudTabs else { return }
        guard session.state == .needsFullDiskAccess || session.state == .missingDatabase else {
            return
        }
        session.refresh()
    }

    func open(_ tab: ICloudTab) {
        guard let url = URL(string: tab.url) else {
            core.showMessage("Couldn’t open tab", tone: .danger)
            return
        }
        paletteCoordinator.hidePalette(restoreFocus: false)
        Task {
            do {
                _ = try await NSWorkspace.shared.open(
                    url, configuration: NSWorkspace.OpenConfiguration())
            } catch {
                await core.showNotice(
                    title: "Couldn’t Open Tab", message: error.localizedDescription,
                    symbol: "safari", tone: .danger)
            }
        }
    }

    func copyURL(_ tab: ICloudTab) {
        Paster.copyPlainText(tab.url)
        core.showMessage("Copied URL")
    }

    func openFullDiskAccessSettings() {
        Permissions.openFullDiskAccessSettings()
    }
}
