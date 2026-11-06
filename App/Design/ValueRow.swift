// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// With no action the row draws no chevron, so a caller can make it the label of a `NavigationLink`, whose own
/// chevron then shows.
struct ValueRow: View {
    let title: Text
    let value: Text
    var action: (() -> Void)?

    init(_ title: Text, value: Text, action: (() -> Void)? = nil) {
        self.title = title
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
            }
        }
        .rowHeight()
    }

    private func row(chevron: Bool) -> some View {
        LabeledContent {
            HStack {
                value.foregroundStyle(Color.ink2)
                if chevron {
                    RowChevron()
                }
            }
        } label: {
            title.foregroundStyle(Color.ink)
        }
    }
}
