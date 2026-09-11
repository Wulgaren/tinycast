import Foundation

/// One shortcut from the Shortcuts app, identified by its stable Shortcuts identifier.
struct AppleShortcut: Hashable, Identifiable, Sendable, Equatable {
    static let entryIDPrefix = "apple-shortcut:"
    /// Optional stdin chip label in the palette header.
    static let inputArgumentName = "Text"
    /// Every row draws Shortcuts.app's icon from this path.
    static let appURL = URL(fileURLWithPath: "/System/Applications/Shortcuts.app")

    var name: String
    var identifier: String

    var id: String { identifier }
    var entryID: String { Self.entryIDPrefix + identifier }

    static func identifier(fromEntryID entryID: String) -> String? {
        guard entryID.hasPrefix(entryIDPrefix) else { return nil }
        let id = String(entryID.dropFirst(entryIDPrefix.count))
        return id.isEmpty ? nil : id
    }

    /// Parses `shortcuts list --show-identifiers` stdout into name/identifier pairs.
    static func parseList(_ text: String) -> [AppleShortcut] {
        text.split(whereSeparator: \.isNewline).compactMap { line in
            parseLine(String(line))
        }
    }

    /// `Name (UUID)` — the last parenthesized UUID is the identifier; empty/malformed lines yield nil.
    static func parseLine(_ line: String) -> AppleShortcut? {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard trimmed.last == ")",
            let open = trimmed.lastIndex(of: "("),
            open > trimmed.startIndex
        else { return nil }

        let idStart = trimmed.index(after: open)
        let idEnd = trimmed.index(before: trimmed.endIndex)
        let identifier = String(trimmed[idStart..<idEnd])
        guard UUID(uuidString: identifier) != nil else { return nil }

        let name = trimmed[..<open].trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return nil }
        return AppleShortcut(name: name, identifier: identifier)
    }
}

/// Argv and stdin for `shortcuts run`, kept pure so the harness can check shape without Process.
struct AppleShortcutRunInvocation: Equatable, Sendable {
    static let executablePath = "/usr/bin/shortcuts"

    let executable: String
    let arguments: [String]
    /// Nil when the shortcut should run with no text input.
    let stdin: String?

    static func make(identifier: String, input: String) -> AppleShortcutRunInvocation {
        let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return AppleShortcutRunInvocation(
                executable: executablePath,
                arguments: ["run", identifier],
                stdin: nil)
        }
        return AppleShortcutRunInvocation(
            executable: executablePath,
            arguments: ["run", identifier, "--input-path", "-"],
            stdin: input)
    }
}
