// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private struct RowHeight: ViewModifier {
    @ScaledMetric private var height: CGFloat

    init(height: CGFloat) {
        _height = ScaledMetric(wrappedValue: height, relativeTo: .body)
    }

    func body(content: Content) -> some View {
        content
            .frame(minHeight: max(height, Spacing.rowMinimumHeight))
            .fillsCardRow()
    }
}

extension View {
    func rowHeight(_ height: CGFloat = Spacing.rowHeight) -> some View {
        modifier(RowHeight(height: height))
    }
}
