import Foundation

/// Pure decisions for grouping CloudTabs rows, access, and whether to wake Safari.
enum ICloudTabsPolicy {
    /// Why the screen cannot show tabs yet, or `.ready` when a read may proceed.
    enum Access: Equatable, Sendable {
        case needsFullDiskAccess
        case missingDatabase
        case ready
    }

    /// Groups tabs by device, keeping device order from the first tab of each. Empty devices drop out.
    static func devices(from tabs: [ICloudTab]) -> [ICloudTabDevice] {
        var order: [String] = []
        var buckets: [String: (name: String, tabs: [ICloudTab])] = [:]
        for tab in tabs {
            if buckets[tab.deviceUUID] == nil {
                order.append(tab.deviceUUID)
                buckets[tab.deviceUUID] = (tab.deviceName, [])
            }
            buckets[tab.deviceUUID]?.tabs.append(tab)
        }
        return order.compactMap { uuid in
            guard let bucket = buckets[uuid], !bucket.tabs.isEmpty else { return nil }
            return ICloudTabDevice(uuid: uuid, name: bucket.name, tabs: bucket.tabs)
        }
    }

    /// Tabs matching the query across title and URL, still grouped by device.
    static func filtered(devices: [ICloudTabDevice], query: String) -> [ICloudTabDevice] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return devices }
        return devices.compactMap { device in
            let tabs = device.tabs.filter {
                $0.title.localizedCaseInsensitiveContains(trimmed)
                    || $0.url.localizedCaseInsensitiveContains(trimmed)
                    || device.name.localizedCaseInsensitiveContains(trimmed)
            }
            guard !tabs.isEmpty else { return nil }
            return ICloudTabDevice(uuid: device.uuid, name: device.name, tabs: tabs)
        }
    }

    /// Flat selection order for the palette: every tab across devices, headers stay out of `rows`.
    static func flatTabs(in devices: [ICloudTabDevice]) -> [ICloudTab] {
        devices.flatMap(\.tabs)
    }

    /// `canReadDatabase` wins: CloudTabs is sometimes readable without the TCC.db FDA probe.
    static func access(canReadDatabase: Bool, hasFullDiskAccess: Bool) -> Access {
        if canReadDatabase { return .ready }
        if hasFullDiskAccess { return .missingDatabase }
        return .needsFullDiskAccess
    }

    /// Wake Safari only when it is not already running, so a refresh can pull CloudKit.
    static func shouldLaunchSafari(isSafariRunning: Bool) -> Bool {
        !isSafariRunning
    }

    /// Quit only the Safari process Tinycast started for this refresh.
    static func shouldQuitSafari(didLaunch: Bool) -> Bool {
        didLaunch
    }
}
