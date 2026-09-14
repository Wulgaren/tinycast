import Foundation

/// Runs `/usr/bin/shortcuts` off the main actor. Pure argv shape lives in `AppleShortcutRunInvocation`.
enum AppleShortcutRunner {
    /// `shortcuts list --show-identifiers`, or an empty list when the tool is missing or fails.
    nonisolated static func list() async -> [AppleShortcut] {
        await Task.detached(priority: .utility) {
            let output = run(
                AppleShortcutRunInvocation.executablePath,
                arguments: ["list", "--show-identifiers"],
                stdin: nil)
            guard output.status == 0 else { return [] }
            return AppleShortcut.parseList(output.stdout)
        }.value
    }

    /// Runs one shortcut; `stdout` is trimmed. Throws a short user-facing reason on failure.
    nonisolated static func run(identifier: String, input: String) async throws -> String {
        let invocation = AppleShortcutRunInvocation.make(identifier: identifier, input: input)
        return try await Task.detached(priority: .userInitiated) {
            let output = run(invocation.executable, arguments: invocation.arguments, stdin: invocation.stdin)
            if output.status == 0 {
                return output.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            let reason = output.stderr.trimmingCharacters(in: .whitespacesAndNewlines)
            if reason.contains("not find") || reason.contains("No shortcut") {
                throw AppleShortcutRunError("That shortcut is no longer in the Shortcuts app.")
            }
            if reason.isEmpty {
                throw AppleShortcutRunError("The shortcut did not finish.")
            }
            throw AppleShortcutRunError(reason)
        }.value
    }

    private nonisolated static func run(
        _ executable: String, arguments: [String], stdin: String?
    ) -> ProcessOutput {
        let process = Process()
        let stdout = Pipe()
        let stderr = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = stdout
        process.standardError = stderr
        if let stdin {
            let input = Pipe()
            process.standardInput = input
            // Closed after writing so a shortcut reading to EOF can finish.
            input.fileHandleForWriting.write(Data(stdin.utf8))
            try? input.fileHandleForWriting.close()
        } else {
            process.standardInput = FileHandle.nullDevice
        }
        do {
            try process.run()
        } catch {
            return ProcessOutput(status: -1, stdout: "", stderr: error.localizedDescription)
        }
        process.waitUntilExit()
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        return ProcessOutput(
            status: process.terminationStatus,
            stdout: String(data: outData, encoding: .utf8) ?? "",
            stderr: String(data: errData, encoding: .utf8) ?? "")
    }

    private struct ProcessOutput: Sendable {
        let status: Int32
        let stdout: String
        let stderr: String
    }
}

struct AppleShortcutRunError: Error, LocalizedError {
    let message: String
    init(_ message: String) { self.message = message }
    var errorDescription: String? { message }
}
