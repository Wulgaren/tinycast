import SwiftUI

/// Optional text chip for a selected Apple Shortcut — empty runs with no stdin.
@MainActor
enum AppleShortcutArgumentsAccessory {
    static let argument = SnippetTemplateEngine.MissingArgument(
        name: AppleShortcut.inputArgumentName, options: [])

    static func make(
        entry: AppEntry?,
        vm: PaletteState,
        focus: FocusState<String?>.Binding,
        onSubmit: @escaping () -> Void
    ) -> PaletteHeaderAccessory? {
        guard let entry, entry.kind == .appleShortcut else { return nil }
        let value = binding(entryID: entry.id, vm: vm)
        return PaletteHeaderAccessory(
            width: AppleShortcutArgumentsRow.totalWidth(hasIcon: true),
            fieldNames: [argument.name],
            firstIncompleteField: nil,
            placement: .afterQuery,
            view: AnyView(
                AppleShortcutArgumentsRow(
                    symbolURL: AppleShortcut.appURL,
                    text: value,
                    focused: focus,
                    onSubmit: onSubmit
                )
                .id(entry.id))
        )
    }

    /// Typed text for one shortcut row; blank means run with no input.
    static func input(for entryID: String, vm: PaletteState) -> String {
        vm.commandArguments[PaletteState.argumentKey(entryID, argument.name)] ?? ""
    }

    private static func binding(entryID: String, vm: PaletteState) -> Binding<String> {
        let key = PaletteState.argumentKey(entryID, argument.name)
        return Binding(get: { vm.commandArguments[key] ?? "" }, set: { vm.commandArguments[key] = $0 })
    }
}

/// One optional text field beside the search field.
private struct AppleShortcutArgumentsRow: View {
    let symbolURL: URL
    @Binding var text: String
    @FocusState.Binding var focused: String?
    let onSubmit: () -> Void
    @State private var hovered = false

    private var isFocused: Bool { focused == AppleShortcut.inputArgumentName }

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(nsImage: IconCache.icon(for: .file(stamp: 0), fileURL: symbolURL))
                .resizable()
                .frame(width: Self.height, height: Self.height)
            TextField(
                "", text: $text,
                prompt: Text(AppleShortcut.inputArgumentName)
                    .foregroundStyle(Theme.Colors.textTertiary)
            )
            .textFieldStyle(.plain)
            .font(Theme.Typography.rowTrailing)
            .tint(.white)
            .onSubmit(onSubmit)
            .multilineTextAlignment(.center)
            .frame(width: Self.fieldWidth)
            .padding(.horizontal, Theme.Spacing.sm)
            .frame(height: Self.height)
            .background(
                RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous).fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous)
                    .strokeBorder(stroke, lineWidth: 1)
            )
            .onHover { hovered = $0 }
            .focused($focused, equals: AppleShortcut.inputArgumentName)
            .help("Optional text input for the shortcut")
        }
    }

    static let height: CGFloat = 26
    static let fieldWidth: CGFloat = 100

    static func totalWidth(hasIcon: Bool) -> CGFloat {
        fieldWidth + Theme.Spacing.xs + (hasIcon ? height : 0)
    }

    private var fill: Color {
        if isFocused { return Theme.Colors.selection }
        if hovered { return Theme.Colors.rowHover }
        return Theme.Colors.cardFill
    }

    private var stroke: Color {
        isFocused ? Theme.Colors.textSecondary.opacity(0.45) : Theme.Colors.cardStroke
    }
}
