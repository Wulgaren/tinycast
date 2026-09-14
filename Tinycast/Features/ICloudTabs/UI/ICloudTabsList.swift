import SwiftUI

struct ICloudTabsList: View {
    let devices: [ICloudTabDevice]
    let selectedID: ICloudTab.ID?
    let scroll: ScrollIntent
    let onActivate: (ICloudTab) -> Void
    let onActions: (ICloudTab) -> Void

    private enum Row: Identifiable {
        case header(String)
        case tab(ICloudTab)
        var id: String {
            switch self {
            case .header(let title): return "header-" + title
            case .tab(let tab): return tab.id
            }
        }
    }

    private var rows: [Row] {
        var rows: [Row] = []
        for device in devices {
            rows.append(.header(device.name))
            for tab in device.tabs { rows.append(.tab(tab)) }
        }
        return rows
    }

    private var firstTabID: ICloudTab.ID? { devices.first?.tabs.first?.id }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(rows) { row in
                        switch row {
                        case .header(let title):
                            SectionHeader(title: title, isFirst: row.id == rows.first?.id)
                        case .tab(let tab):
                            ICloudTabRow(tab: tab, selected: tab.id == selectedID)
                                .contentShape(Rectangle())
                                .onTapGesture { onActivate(tab) }
                                .onRightClick { onActions(tab) }
                                .selectionFrame(tab.id == selectedID)
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.xs)
                .padding(.bottom, Theme.Spacing.md)
                .hideNativeScrollers()
                .scrollOriginAnchor()
            }
            .edgeDissolve()
            .thinScrollbar()
            .scrollFollowsSelection(
                scroll, row: selectedID, atOrigin: selectedID != nil && selectedID == firstTabID,
                proxy: proxy)
        }
    }
}

private struct ICloudTabRow: View {
    let tab: ICloudTab
    let selected: Bool
    @State private var hovered = false

    private var fill: Color {
        if selected { return Theme.Colors.selection }
        if hovered { return Theme.Colors.rowHover }
        return .clear
    }

    private var host: String {
        guard let host = URL(string: tab.url)?.host() else { return tab.url }
        if host.hasPrefix("www.") { return String(host.dropFirst(4)) }
        return host
    }

    var body: some View {
        HStack(spacing: Theme.Spacing.lg) {
            SymbolImage(name: "safari", size: Theme.Size.rowIcon * 0.7)
                .frame(width: Theme.Size.rowIcon, height: Theme.Size.rowIcon)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 2) {
                Text(tab.title)
                    .font(Theme.Typography.rowTitle)
                    .lineLimit(1)
                Text(host)
                    .font(Theme.Typography.rowTrailing)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: Theme.Spacing.md)
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.vertical, Theme.Spacing.sm)
        .background(fill, in: RoundedRectangle(cornerRadius: Theme.Radius.row, style: .continuous))
        .armedHover($hovered)
    }
}
