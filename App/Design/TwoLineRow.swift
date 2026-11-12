// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct TwoLineRow: View {
    let title: Text
    let subtitle: Text
    let value: Text?
    var action: (() -> Void)?

    init(_ title: Text, subtitle: Text, value: Text? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.subtitle = subtitle
        self.value = value
        self.action = action
    }

    var body: some View {
        Group {
            if let action {
                Button(action: action) {
                    row(chevron: true)
                }
            } else {
                row(chevron: false)
                    .accessibilityElement(children: .combine)
            }
        }
        .padding(.vertical, Spacing.twoLineRowPadding)
        .rowHeight(Spacing.twoLineRowHeight)
    }

    private func row(chevron: Bool) -> some View {
        LabeledContent {
            HStack {
                value?.foregroundStyle(Color.ink2)
                if chevron {
                    RowChevron()
                }
            }
        } label: {
            VStack(alignment: .leading) {
                title.foregroundStyle(Color.ink)
                subtitle.font(.footnote).foregroundStyle(Color.ink2)
            }
        }
    }
}
