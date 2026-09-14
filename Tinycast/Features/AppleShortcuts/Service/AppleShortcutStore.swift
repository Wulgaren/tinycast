import Foundation

/// Lists shortcuts via `/usr/bin/shortcuts` and republishes when the library folder changes.
@MainActor
@Observable
final class AppleShortcutStore {
    private(set) var shortcuts: [AppleShortcut] = []
    /// Fires after every successful reload so the coordinator can republish the launcher slice.
    var onChange: (() -> Void)?

    @ObservationIgnored private var directoryWatcher: DispatchSourceFileSystemObject?
    @ObservationIgnored private var reloadTask: Task<Void, Never>?
    @ObservationIgnored private var started = false

    /// Home is injected so a harness never has to invent a library path.
    private let libraryDirectory: URL

    init(homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) {
        libraryDirectory = homeDirectory.appendingPathComponent("Library/Shortcuts", isDirectory: true)
    }

    func start() {
        guard !started else { return }
        started = true
        armDirectoryWatcher()
        reload()
    }

    func stop() {
        started = false
        reloadTask?.cancel()
        reloadTask = nil
        directoryWatcher?.cancel()
        directoryWatcher = nil
        if !shortcuts.isEmpty {
            shortcuts = []
            onChange?()
        }
    }

    /// Re-reads the library; coalesces overlapping calls into one trailing load.
    func reload() {
        guard started else { return }
        reloadTask?.cancel()
        reloadTask = Task { await self.reloadNow() }
    }

    private func reloadNow() async {
        let listed = await AppleShortcutRunner.list()
        guard !Task.isCancelled else { return }
        let next = listed.sorted {
            let order = $0.name.localizedCaseInsensitiveCompare($1.name)
            return order != .orderedSame
                ? order == .orderedAscending
                : $0.identifier < $1.identifier
        }
        guard next != shortcuts else { return }
        shortcuts = next
        onChange?()
    }

    func shortcut(identifier: String) -> AppleShortcut? {
        shortcuts.first { $0.identifier == identifier }
    }

    @discardableResult
    private func armDirectoryWatcher() -> Bool {
        let path = libraryDirectory.path
        let descriptor = Darwin.open(path, O_EVTONLY)
        guard descriptor >= 0 else { return false }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: descriptor,
            eventMask: [.write, .extend, .attrib, .delete, .rename, .revoke],
            queue: .main)
        source.setEventHandler { [weak self] in
            MainActor.assumeIsolated { self?.reload() }
        }
        source.setCancelHandler { Darwin.close(descriptor) }
        directoryWatcher = source
        source.resume()
        return true
    }
}
