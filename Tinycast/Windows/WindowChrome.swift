import AppKit

/// Stacking for Tinycast panels: above system modals, under Dock and menu bar.
enum WindowLevels {
    /// Just under Dock / menu bar (`kCGUtilityWindowLevel`).
    private static let underChrome = Int(CGWindowLevelForKey(.utilityWindow))

    /// Palette, Notes, camera, quick actions, HUDs.
    static let surface = NSWindow.Level(rawValue: underChrome - 1)
    /// Confirmations and value dialogs — one step above every other Tinycast surface.
    static let dialog = NSWindow.Level(rawValue: underChrome)
    /// Palette drop guides — one step under the panel being dragged.
    static let dropGuide = NSWindow.Level(rawValue: surface.rawValue - 1)
}

/// Held by `AppWindowController` for the window's lifetime, so the chrome dies with the window.
@MainActor
protocol WindowChrome: AnyObject {
    func install(in window: NSWindow)
}
