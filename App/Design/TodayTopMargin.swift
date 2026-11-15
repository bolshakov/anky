// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

private struct TodayTopMargin: ViewModifier {
    @ScaledMetric(relativeTo: .largeTitle) private var titleSize = Spacing.largeTitleSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// The list starts a nearly fixed distance below the bar while the large title grows with its font, so the pull up
    /// toward the title shrinks as the title grows.
    private var growth: CGFloat {
        Spacing.titleToDatePullPerTitlePoint * (titleSize - Spacing.largeTitleSize)
    }

    /// Compact height has no large title to pull toward: the bar is inline and the list starts a block gap below it,
    /// as every other card screen does.
    func body(content: Content) -> some View {
        if verticalSizeClass == .compact {
            content.contentMargins(.top, Spacing.firstBlockTop, for: .scrollContent)
        } else {
            largeTitleBody(content)
        }
    }

    /// A negative content margin leaves the first row undrawn while the list is pulled past the top, so every pull up
    /// is the list's own padding and the content margin never goes below zero.
    private func largeTitleBody(_ content: Content) -> some View {
        content
            .contentMargins(.top, max(0, growth), for: .scrollContent)
            .padding(.top, min(0, growth) - Spacing.titleToDatePull)
    }
}

extension View {
    func todayTopMargin() -> some View {
        modifier(TodayTopMargin())
    }
}
