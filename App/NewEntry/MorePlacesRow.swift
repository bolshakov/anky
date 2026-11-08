// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MorePlacesRow: View {
    let value: MorePlacesValue
    let action: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(ShortcutsModel.self) private var shortcuts

    var body: some View {
        Button(action: action) {
            content
                .font(.body)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("More places")
        .accessibilityValue(value.listText)
        .accessibilityAddTraits(.isButton)
        .accessibilityIdentifier("more-places")
        .modifier(PinAllMenu(places: value.all, shortcuts: shortcuts))
    }

    @ViewBuilder
    private var content: some View {
        if dynamicTypeSize.isAccessibilitySize {
            stacked
        } else {
            ViewThatFits(in: .horizontal) {
                inline(value.namesText)
                inline(value.countText)
                stacked
            }
        }
    }

    private func inline(_ text: String) -> some View {
        HStack(spacing: Spacing.moreRowGap) {
            label.fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: 2)
            Text(text)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            chevron
        }
    }

    private var stacked: some View {
        HStack(spacing: Spacing.moreRowGap) {
            VStack(alignment: .leading, spacing: Spacing.tightGap) {
                label
                Text(value.listText)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 2)
            chevron
        }
    }

    private var label: some View {
        Text("More places")
            .foregroundStyle(.primary)
    }

    private var chevron: some View {
        Image(systemName: "chevron.forward")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.secondary)
            .frame(width: Spacing.chevronSlotWidth, height: Spacing.chevronSlotHeight)
    }
}

private struct PinAllMenu: ViewModifier {
    let places: [PlaceID]
    let shortcuts: ShortcutsModel

    func body(content: Content) -> some View {
        if places.isEmpty {
            content
        } else {
            content
                .contextMenu {
                    Button {
                        shortcuts.pin(all: places, event: .pinChangedByMenu)
                    } label: {
                        Label("Pin as shortcut", systemImage: "pin.fill")
                    }
                }
                .accessibilityAction(named: Text("Pin as shortcut")) {
                    shortcuts.pin(all: places, event: .pinChangedByAction)
                }
        }
    }
}
