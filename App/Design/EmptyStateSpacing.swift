// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// One case per empty block, so a screen names its block and never passes a number of its own.
enum EmptyStateTop {
    case today
    case todayBelowChip
    case history
    case medications

    fileprivate var portrait: CGFloat {
        switch self {
        case .today: Spacing.emptyTodayTop
        case .todayBelowChip: Spacing.emptyTodayTopBelowChip
        case .history: Spacing.emptyBlockGap
        case .medications: Spacing.emptyMedicationsTop
        }
    }

    fileprivate var compact: CGFloat {
        switch self {
        case .today: Spacing.emptyTodayTopCompact
        case .todayBelowChip: Spacing.emptyTodayTopBelowChipCompact
        case .history: Spacing.emptyHistoryTopCompact
        case .medications: Spacing.emptyMedicationsTopCompact
        }
    }
}

private struct EmptyStateTopPadding: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let top: EmptyStateTop

    /// Only the value changes with the size class, so a turn keeps the view's identity and the list's state. Height
    /// alone decides, since a Plus or Max iPhone in landscape is wide but still short.
    func body(content: Content) -> some View {
        content.padding(.top, verticalSizeClass == .compact ? top.compact : top.portrait)
    }
}

private struct EmptyStateListOffset: ViewModifier {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    let top: EmptyStateTop
    let isShowing: Bool
    let startsList: Bool

    /// The block's own padding cannot reach below the list's section gap and top margin, and a negative padding clips
    /// the block, so in compact height the list gives those up while the block shows. The same calls run in
    /// every state and only their values change, so a turn keeps the list's state.
    func body(content: Content) -> some View {
        let isOwning = isShowing && verticalSizeClass == .compact
        let spaced = content.listSectionSpacing(.custom(isOwning ? 0 : Spacing.blockGap))
        if top == .medications {
            spaced.contentMargins(.top, isOwning && startsList ? 0 : Spacing.firstBlockTop, for: .scrollContent)
        } else {
            spaced
        }
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

    func emptyStateListOffset(_ top: EmptyStateTop, isShowing: Bool, startsList: Bool = false) -> some View {
        modifier(EmptyStateListOffset(top: top, isShowing: isShowing, startsList: startsList))
    }

    func emptyStateMark() -> some View {
        modifier(EmptyStateMark())
    }
}
