import Foundation

/// ⌘1…⌘9 then ⌘0 for the tenth; favorites past it are listed but carry no chord.
enum FavoriteSlots {
    static let digits: [Character] = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]

    /// The slot ⌘4 maps to; steals for clipboard history when that setting is on.
    static let clipboardHistoryIndex = 3

    /// ANSI number-row key codes in visual order 1…9,0. This is layout-independent.
    private static let numberRowKeyCodes: [UInt16] = [18, 19, 20, 21, 23, 22, 26, 28, 25, 29]

    /// The favorite a digit launches, or nil when that key is not a slot.
    static func index(for digit: Character) -> Int? { digits.firstIndex(of: digit) }

    /// The favorite a physical number-row key launches, or nil when that key is not a slot.
    static func index(forKeyCode keyCode: UInt16) -> Int? {
        numberRowKeyCodes.firstIndex(of: keyCode)
    }

    /// The digit shown on the row at `index`, or nil past the last slot / when ⌘4 is stolen.
    static func digit(at index: Int, clipboardStealsFour: Bool = false) -> Character? {
        if clipboardStealsFour, index == clipboardHistoryIndex { return nil }
        return digits.indices.contains(index) ? digits[index] : nil
    }
}
