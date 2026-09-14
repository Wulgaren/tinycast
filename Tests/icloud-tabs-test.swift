// iCloud Tabs grouping, access, and Safari wake / quit policy.
import Foundation

@main
@MainActor
struct ICloudTabsTests {
    static var failures = 0
    static var passes = 0

    static func main() {
        groupsByDevice()
        keepsThisMac()
        dropsEmptyDevices()
        filtersAcrossTitleURLAndDevice()
        accessStates()
        wakeAndQuit()

        print("\(passes)/\(passes + failures) passed")
        if failures > 0 { exit(1) }
    }

    static func groupsByDevice() {
        let devices = ICloudTabsPolicy.devices(from: [
            tab(uuid: "1", device: "phone", name: "iPhone", title: "A", url: "https://a.test"),
            tab(uuid: "2", device: "pad", name: "iPad", title: "B", url: "https://b.test"),
            tab(uuid: "3", device: "phone", name: "iPhone", title: "C", url: "https://c.test"),
        ])
        expect(devices.map(\.name) == ["iPhone", "iPad"], "devices keep first-seen order")
        expect(devices[0].tabs.map(\.title) == ["A", "C"], "iPhone keeps both tabs in order")
        expect(devices[1].tabs.map(\.title) == ["B"], "iPad keeps its one tab")
        expect(
            ICloudTabsPolicy.flatTabs(in: devices).map(\.uuid) == ["1", "3", "2"],
            "flat selection walks devices in order")
    }

    static func keepsThisMac() {
        let devices = ICloudTabsPolicy.devices(from: [
            tab(
                uuid: "1", device: "mac", name: "Natan’s MacBook Pro", title: "Local",
                url: "https://mac.test"),
            tab(
                uuid: "2", device: "phone", name: "iPhone", title: "Remote",
                url: "https://phone.test"),
        ])
        expect(
            devices.map(\.name) == ["Natan’s MacBook Pro", "iPhone"],
            "this Mac stays in the list when CloudTabs has tabs for it")
    }

    static func dropsEmptyDevices() {
        // Grouping only sees tabs, so a device with no rows never appears.
        let devices = ICloudTabsPolicy.devices(from: [
            tab(uuid: "1", device: "phone", name: "iPhone", title: "A", url: "https://a.test")
        ])
        expect(devices.count == 1 && devices[0].name == "iPhone", "only devices with tabs appear")
    }

    static func filtersAcrossTitleURLAndDevice() {
        let all = ICloudTabsPolicy.devices(from: [
            tab(uuid: "1", device: "phone", name: "iPhone", title: "Hacker News", url: "https://news.ycombinator.com"),
            tab(uuid: "2", device: "pad", name: "iPad", title: "Example", url: "https://example.com/x"),
        ])
        expect(
            ICloudTabsPolicy.filtered(devices: all, query: "hacker").flatMap(\.tabs).map(\.uuid)
                == ["1"],
            "title match keeps the tab")
        expect(
            ICloudTabsPolicy.filtered(devices: all, query: "example.com").flatMap(\.tabs).map(\.uuid)
                == ["2"],
            "URL match keeps the tab")
        expect(
            ICloudTabsPolicy.filtered(devices: all, query: "ipad").map(\.name) == ["iPad"],
            "device name match keeps the device")
        expect(
            ICloudTabsPolicy.filtered(devices: all, query: "zzz").isEmpty,
            "no match yields no devices")
    }

    static func accessStates() {
        expect(
            ICloudTabsPolicy.access(canReadDatabase: true, hasFullDiskAccess: false) == .ready,
            "a readable CloudTabs.db is ready even without the TCC.db FDA probe")
        expect(
            ICloudTabsPolicy.access(canReadDatabase: false, hasFullDiskAccess: false)
                == .needsFullDiskAccess,
            "unreadable CloudTabs without FDA asks for Full Disk Access")
        expect(
            ICloudTabsPolicy.access(canReadDatabase: false, hasFullDiskAccess: true)
                == .missingDatabase,
            "FDA without a readable CloudTabs.db is missing")
    }

    static func wakeAndQuit() {
        expect(
            ICloudTabsPolicy.shouldLaunchSafari(isSafariRunning: false),
            "launch when Safari is not running")
        expect(
            !ICloudTabsPolicy.shouldLaunchSafari(isSafariRunning: true),
            "do not launch when Safari is already up")
        expect(
            ICloudTabsPolicy.shouldQuitSafari(didLaunch: true),
            "quit only the Safari Tinycast started")
        expect(
            !ICloudTabsPolicy.shouldQuitSafari(didLaunch: false),
            "leave a pre-existing Safari alone")
    }

    static func tab(
        uuid: String, device: String, name: String, title: String, url: String
    ) -> ICloudTab {
        ICloudTab(
            uuid: uuid, deviceUUID: device, deviceName: name, title: title, url: url)
    }

    static func expect(_ condition: Bool, _ label: String) {
        if condition {
            passes += 1
        } else {
            print("FAIL: \(label)")
            failures += 1
        }
    }
}
