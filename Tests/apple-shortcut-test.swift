// Apple Shortcuts list parsing, run argv/stdin shape, and entry ids.
import Foundation

@main
@MainActor
struct AppleShortcutTests {
    static var failures = 0
    static var passes = 0

    static func main() {
        parsesListLines()
        runInvocationWithoutInput()
        runInvocationWithInput()
        entryIDFromIdentifier()

        print("\(passes)/\(passes + failures) passed")
        if failures > 0 { exit(1) }
    }

    static func parsesListLines() {
        let text = """
            Toggle Dark Mode (60E0E047-3D63-4443-809F-E2B65CAADC69)

            Water Eject 💧 (7D71FA07-FA4C-489E-B7F3-274218725865)
            not a shortcut line
            Name With (parens) Inside (9BAA6865-283F-4AF7-901D-7B82732D67E4)
            (60E0E047-3D63-4443-809F-E2B65CAADC69)
            """
        let parsed = AppleShortcut.parseList(text)
        expect(parsed.count == 3, "skips empty and malformed lines")
        expect(
            parsed[0] == AppleShortcut(
                name: "Toggle Dark Mode", identifier: "60E0E047-3D63-4443-809F-E2B65CAADC69"),
            "normal name and identifier")
        expect(
            parsed[1] == AppleShortcut(
                name: "Water Eject 💧", identifier: "7D71FA07-FA4C-489E-B7F3-274218725865"),
            "emoji in the name is kept")
        expect(
            parsed[2] == AppleShortcut(
                name: "Name With (parens) Inside",
                identifier: "9BAA6865-283F-4AF7-901D-7B82732D67E4"),
            "trailing identifier wins over earlier parentheses")
    }

    static func runInvocationWithoutInput() {
        let run = AppleShortcutRunInvocation.make(
            identifier: "60E0E047-3D63-4443-809F-E2B65CAADC69", input: "")
        expect(run.executable == "/usr/bin/shortcuts", "runs the system shortcuts binary")
        expect(
            run.arguments == ["run", "60E0E047-3D63-4443-809F-E2B65CAADC69"],
            "no input means no --input-path")
        expect(run.stdin == nil, "empty input leaves stdin unset")

        let whitespace = AppleShortcutRunInvocation.make(
            identifier: "60E0E047-3D63-4443-809F-E2B65CAADC69", input: "  \n")
        expect(whitespace.stdin == nil, "whitespace-only input is treated as no input")
        expect(
            whitespace.arguments == ["run", "60E0E047-3D63-4443-809F-E2B65CAADC69"],
            "whitespace-only input omits --input-path")
    }

    static func runInvocationWithInput() {
        let run = AppleShortcutRunInvocation.make(
            identifier: "60E0E047-3D63-4443-809F-E2B65CAADC69",
            input: "https://example.com")
        expect(
            run.arguments
                == ["run", "60E0E047-3D63-4443-809F-E2B65CAADC69", "--input-path", "-"],
            "non-empty input adds --input-path -")
        expect(run.stdin == "https://example.com", "stdin carries the typed payload")
    }

    static func entryIDFromIdentifier() {
        let shortcut = AppleShortcut(
            name: "Toggle Dark Mode", identifier: "60E0E047-3D63-4443-809F-E2B65CAADC69")
        expect(
            shortcut.entryID == "apple-shortcut:60E0E047-3D63-4443-809F-E2B65CAADC69",
            "entry id is stable from the Shortcuts identifier")
        expect(
            AppleShortcut.identifier(fromEntryID: shortcut.entryID)
                == "60E0E047-3D63-4443-809F-E2B65CAADC69",
            "identifier round-trips from the entry id")
        expect(
            AppleShortcut.identifier(fromEntryID: "quicklink:abc") == nil,
            "a foreign entry id is rejected")
    }

    static func expect(_ condition: Bool, _ label: String) {
        if condition {
            passes += 1
        } else {
            fail(label)
        }
    }

    static func fail(_ label: String) {
        print("FAIL: \(label)")
        failures += 1
    }
}
