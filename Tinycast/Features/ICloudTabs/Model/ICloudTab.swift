import Foundation

/// One tab row from Safari's CloudTabs database.
struct ICloudTab: Identifiable, Hashable, Sendable {
    var id: String { uuid }
    let uuid: String
    let deviceUUID: String
    let deviceName: String
    let title: String
    let url: String
}

/// Tabs under one synced device, in database order.
struct ICloudTabDevice: Identifiable, Hashable, Sendable {
    var id: String { uuid }
    let uuid: String
    let name: String
    let tabs: [ICloudTab]
}
