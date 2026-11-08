// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private struct TodayTopMargin: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = Spacing.largeTitleSize

    /// The list starts a nearly fixed distance below the bar while the large title grows with its font, so the pull up
    /// toward the title shrinks as the title grows.
    private var margin: CGFloat {
        Spacing.titleToDatePullPerTitlePoint * (titleSize - Spacing.largeTitleSize) - Spacing.titleToDatePull
    }

    func body(content: Content) -> some View {
        content.contentMargins(.top, margin, for: .scrollContent)
    }
}

extension View {
    func todayTopMargin() -> some View {
        modifier(TodayTopMargin())
    }
}
