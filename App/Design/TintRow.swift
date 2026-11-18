// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// A row in a list where one item is chosen. The chosen row has a semibold title and a tick in the tint colour. Every
/// row reserves the tick's slot, so the tick sits in the same place whichever row is chosen.
struct TintRow: View {
    let title: Text
    let subtitle: Text?
    let isSelected: Bool
    let action: () -> Void
    @ScaledMetric(relativeTo: .body) private var tickSide = Spacing.checkmark

    init(_ title: Text, subtitle: Text? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.subtitle = subtitle
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    title.fontWeight(isSelected ? .semibold : nil).foregroundStyle(Color.ink)
                    subtitle?.font(.footnote).foregroundStyle(Color.ink2)
                }
                Spacer()
                tick
            }
        }
        .padding(.vertical, subtitle == nil ? 0 : Spacing.twoLineRowPadding)
        .rowHeight(subtitle == nil ? Spacing.rowHeight : Spacing.twoLineRowHeight)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(subtitle ?? Text(verbatim: ""))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private var tick: some View {
        Image(systemName: "checkmark")
            .resizable()
            .scaledToFit()
            .frame(width: tickSide, height: tickSide)
            .foregroundStyle(isSelected ? Color.tint : Color.clear)
            .accessibilityHidden(true)
    }
}
