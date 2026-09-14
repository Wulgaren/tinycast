import Foundation

/// Transient state for the iCloud Tabs palette screen.
@MainActor
@Observable
final class ICloudTabsSession {
    enum State: Equatable {
        case idle
        case refreshing
        case needsFullDiskAccess
        case missingDatabase
        case ready
    }

    private(set) var state: State = .idle
    private(set) var devices: [ICloudTabDevice] = []
    private var generation = 0

    func cancel() {
        generation += 1
        state = .idle
        devices = []
    }

    func refresh(home: String = NSHomeDirectory()) {
        generation += 1
        let token = generation
        state = .refreshing
        devices = []

        let hasFDA = FullDiskAccess.isGranted(home: home)
        let canRead = CloudTabsReader.canOpen(home: home)
        switch ICloudTabsPolicy.access(canReadDatabase: canRead, hasFullDiskAccess: hasFDA) {
        case .needsFullDiskAccess:
            state = .needsFullDiskAccess
            return
        case .missingDatabase:
            state = .missingDatabase
            return
        case .ready:
            break
        }

        Task { @MainActor in
            let didLaunch = await SafariCloudSync.launchInBackgroundIfNeeded()
            if didLaunch {
                try? await Task.sleep(nanoseconds: SafariCloudSync.refreshDelayNanoseconds)
            }
            guard token == generation else {
                SafariCloudSync.quitIfLaunched(didLaunch)
                return
            }
            let tabs = await Task.detached(priority: .userInitiated) {
                CloudTabsReader.loadTabs(home: home) ?? []
            }.value
            SafariCloudSync.quitIfLaunched(didLaunch)
            guard token == generation else { return }
            devices = ICloudTabsPolicy.devices(from: tabs)
            state = .ready
        }
    }
}
