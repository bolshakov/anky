// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// A row in a list where one item is chosen. The chosen row has a bold title and a tick in the tint colour.
struct TintRow: View {
    let title: Text
    let value: Text?
    let isSelected: Bool
    let action: () -> Void

    init(_ title: Text, value: Text? = nil, isSelected: Bool, action: @escaping () -> Void) {
        self.title = title
        self.value = value
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            LabeledContent {
                HStack {
                    value?.foregroundStyle(Color.ink2)
                    if isSelected {
                        Image(systemName: "checkmark")
                            .foregroundStyle(Color.tint)
                            .accessibilityHidden(true)
                    }
                }
            } label: {
                title.bold(isSelected).foregroundStyle(Color.ink)
            }
        }
        .rowHeight()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(value ?? Text(verbatim: ""))
        .accessibilityAddTraits(.isButton)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
