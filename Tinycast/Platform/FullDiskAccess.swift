import Darwin
import Foundation

/// Silent Full Disk Access probe — opening TCC.db succeeds only when the process holds FDA.
enum FullDiskAccess {
    static func isGranted(home: String = NSHomeDirectory()) -> Bool {
        let descriptor = open(home + "/Library/Application Support/com.apple.TCC/TCC.db", O_RDONLY)
        guard descriptor >= 0 else { return false }
        close(descriptor)
        return true
    }
}
