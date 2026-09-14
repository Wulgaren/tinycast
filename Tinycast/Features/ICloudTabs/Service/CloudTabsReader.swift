import Foundation
import SQLite3

/// Read-only peek at Safari's CloudTabs.db. Never writes.
enum CloudTabsReader {
    static func databaseURL(home: String = NSHomeDirectory()) -> URL {
        URL(fileURLWithPath: home, isDirectory: true)
            .appendingPathComponent(
                "Library/Containers/com.apple.Safari/Data/Library/Safari/CloudTabs.db")
    }

    /// Whether the process can open the DB at all — the real gate for this feature.
    nonisolated static func canOpen(home: String = NSHomeDirectory()) -> Bool {
        let path = databaseURL(home: home).path
        var db: OpaquePointer?
        guard sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK else {
            return false
        }
        sqlite3_close(db)
        return true
    }

    /// Rows in device-join order. Returns nil when the file cannot be opened.
    nonisolated static func loadTabs(home: String = NSHomeDirectory()) -> [ICloudTab]? {
        let path = databaseURL(home: home).path
        var db: OpaquePointer?
        guard
            sqlite3_open_v2(path, &db, SQLITE_OPEN_READONLY, nil) == SQLITE_OK,
            let db
        else { return nil }
        defer { sqlite3_close(db) }

        let sql = """
            SELECT t.tab_uuid, t.device_uuid, d.device_name, t.title, t.url
            FROM cloud_tabs t
            INNER JOIN cloud_tab_devices d ON t.device_uuid = d.device_uuid
            """
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK, let stmt else {
            return nil
        }
        defer { sqlite3_finalize(stmt) }

        var tabs: [ICloudTab] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let uuid = string(stmt, 0) ?? ""
            let deviceUUID = string(stmt, 1) ?? ""
            let deviceName = string(stmt, 2) ?? "Unknown Device"
            let title = string(stmt, 3) ?? ""
            let url = string(stmt, 4) ?? ""
            guard !uuid.isEmpty, !deviceUUID.isEmpty, !url.isEmpty else { continue }
            tabs.append(
                ICloudTab(
                    uuid: uuid, deviceUUID: deviceUUID, deviceName: deviceName,
                    title: title.isEmpty ? url : title, url: url))
        }
        return tabs
    }

    private nonisolated static func string(_ stmt: OpaquePointer, _ index: Int32) -> String? {
        guard let c = sqlite3_column_text(stmt, index) else { return nil }
        return String(cString: c)
    }
}
