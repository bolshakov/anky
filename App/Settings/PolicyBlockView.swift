// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct PolicyBlockView: View {
    let block: PolicyBlock

    var body: some View {
        switch block {
        case let .heading(level, text):
            Text(text)
                .font(level == 1 ? .title : .title2)
                .bold()
                .accessibilityAddTraits(.isHeader)
                .foregroundStyle(Color.ink)
        case let .paragraph(text), let .listItem(text):
            Text(text)
                .font(.body)
                .foregroundStyle(Color.ink)
        }
    }
}
