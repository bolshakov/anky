// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private struct RowHeight: ViewModifier {
    @ScaledMetric(relativeTo: .body) private var height = Spacing.rowHeight

    func body(content: Content) -> some View {
        content.frame(minHeight: max(height, Spacing.rowMinimumHeight))
    }
}

extension View {
    func rowHeight() -> some View {
        modifier(RowHeight())
    }
}
