// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

/// The one row that shows an entry, a dose or a reading: a tile, two lines and a trailing item. It stacks in one
/// column exactly when `dynamicTypeSize.isAccessibilitySize`, which `DoseRow`'s overlay alignment relies on. It sets
/// no accessibility label, so each caller's wrapper keeps its own.
struct IconRow<Trailing: View>: View {
    let symbol: String
    let title: Text
    let time: String
    let detail: String?
    @ViewBuilder let trailing: Trailing
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: Spacing.tightGap) {
                IconTile(symbol: symbol)
                lines
                trailing
            }
        } else {
            HStack(spacing: Spacing.rowContentGap) {
                IconTile(symbol: symbol)
                lines
                Spacer()
                trailing
            }
        }
    }

    private var lines: some View {
        VStack(alignment: .leading, spacing: Spacing.textLinesGap) {
            title
                .font(.body)
                .foregroundStyle(.primary)
            Text(RowSecondLine.text(time: time, detail: detail))
                .font(.footnote)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
    }
}
