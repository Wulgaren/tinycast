import Foundation

/// Owns feature presence, palette refresh, and the single run funnel for Apple Shortcuts.
@MainActor
final class AppleShortcutCoordinator {
    private let store: AppleShortcutStore
    private let appIndex: AppIndex
    private let settings: AppSettings
    private let paletteCoordinator: PaletteCoordinator
    private unowned let core: AppCore

    init(
        store: AppleShortcutStore,
        appIndex: AppIndex,
        settings: AppSettings,
        paletteCoordinator: PaletteCoordinator,
        core: AppCore
    ) {
        self.store = store
        self.appIndex = appIndex
        self.settings = settings
        self.paletteCoordinator = paletteCoordinator
        self.core = core
    }

    /// Publishes or withdraws the launcher slice and starts or stops the library watcher.
    func applyEnabled() {
        guard settings.appleShortcutsEnabled else {
            store.onChange = nil
            store.stop()
            appIndex.setAppleShortcuts([])
            return
        }
        store.onChange = { [weak self] in self?.publishEntries() }
        store.start()
        publishEntries()
    }

    /// Library goes stale while the palette is closed.
    func paletteDidShow() {
        guard settings.appleShortcutsEnabled else { return }
        publishEntries()
        store.reload()
    }

    /// Palette activation and global shortcuts both land here.
    func runShortcut(identifier: String, input: String = "") {
        guard settings.appleShortcutsEnabled else { return }
        paletteCoordinator.hidePalette(restoreFocus: false)
        Task {
            do {
                let output = try await AppleShortcutRunner.run(identifier: identifier, input: input)
                if !output.isEmpty {
                    // Short HUD: a multi-line dump would outgrow the pill.
                    let line =
                        output.split(whereSeparator: \.isNewline).first.map(String.init) ?? output
                    core.showMessage(String(line.prefix(120)))
                }
            } catch {
                report(error.localizedDescription, tone: .danger)
            }
        }
    }

    private func publishEntries() {
        guard settings.appleShortcutsEnabled, settings.appleShortcutsShowInLauncher else {
            appIndex.setAppleShortcuts([])
            return
        }
        appIndex.setAppleShortcuts(store.shortcuts.map(AppEntry.init))
    }

    private func report(_ message: String, tone: DialogTone) {
        paletteCoordinator.hidePalette(restoreFocus: false)
        core.showMessage(message, tone: tone)
    }
}
