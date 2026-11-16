// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// One case per empty block, so a screen names its block and never passes a number of its own.
enum EmptyStateTop {
    case today
    case todayBelowChip

    fileprivate var portrait: CGFloat {
        switch self {
        case .today: Spacing.emptyTodayTop
        case .todayBelowChip: Spacing.emptyTodayTopBelowChip
        }
    }
}

private struct EmptyStateTopPadding: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let top: EmptyStateTop

    /// Only the value changes with the size class, so a turn keeps the view's identity and the list's state. Height
    /// alone decides, since a Plus or Max iPhone in landscape is wide but still short.
    func body(content: Content) -> some View {
        content.padding(.top, verticalSizeClass == .compact ? Spacing.emptyStateTopCompact : top.portrait)
    }
}

private struct EmptyStateMark: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    /// A width frame shrinks the layout, so the heading and hint under the mark move up with it.
    func body(content: Content) -> some View {
        content.frame(width: verticalSizeClass == .compact ? Spacing.emptyMarkWidthCompact : Spacing.emptyMarkWidth)
    }
}

extension View {
    func emptyStateTop(_ top: EmptyStateTop) -> some View {
        modifier(EmptyStateTopPadding(top: top))
    }

    func emptyStateMark() -> some View {
        modifier(EmptyStateMark())
    }
}
