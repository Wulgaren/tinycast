import AppKit

/// Background-launches Safari so CloudKit can refresh CloudTabs, then quits it if we started it.
enum SafariCloudSync {
    static let safariBundleID = "com.apple.Safari"
    /// Fixed pause after launch so Safari can pull iCloud tabs before we read the DB.
    static let refreshDelayNanoseconds: UInt64 = 1_500_000_000

    static func isSafariRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == safariBundleID
        }
    }

    /// Starts Safari without activating it. Returns whether this call launched it.
    @discardableResult
    static func launchInBackgroundIfNeeded() async -> Bool {
        guard ICloudTabsPolicy.shouldLaunchSafari(isSafariRunning: isSafariRunning()) else {
            return false
        }
        guard
            let url = NSWorkspace.shared.urlForApplication(
                withBundleIdentifier: safariBundleID)
        else { return false }
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        // Same as `open -jg`: start hidden so session restore does not flash windows.
        configuration.hides = true
        do {
            _ = try await NSWorkspace.shared.openApplication(
                at: url, configuration: configuration)
            return true
        } catch {
            return false
        }
    }

    static func quitIfLaunched(_ didLaunch: Bool) {
        guard ICloudTabsPolicy.shouldQuitSafari(didLaunch: didLaunch) else { return }
        for app in NSWorkspace.shared.runningApplications
        where app.bundleIdentifier == safariBundleID {
            app.terminate()
        }
    }
}
