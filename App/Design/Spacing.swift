// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// Every spacing and size is written once, here.
enum Spacing {
    static let screenMargin: CGFloat = 16
    static let firstBlockTop: CGFloat = 16
    static let titleToDatePull: CGFloat = 4.7
    static let titleToDatePullPerTitlePoint: CGFloat = 0.25
    static let largeTitleSize: CGFloat = 34
    static let blockGap: CGFloat = 32
    static let emptyBlockGap: CGFloat = 96
    static let labelGap: CGFloat = 12
    static let readingBlockGap: CGFloat = 16
    static let listItemGap: CGFloat = 8
    static let footnoteGap: CGFloat = 8
    static let inlineGap: CGFloat = 8
    static let tightGap: CGFloat = 4
    static let textLinesGap: CGFloat = 2
    static let rowContentGap: CGFloat = 12
    static let cardContentGap: CGFloat = 12
    static let cardInset: CGFloat = 16
    static let pairGap: CGFloat = 12
    static let moreRowGap: CGFloat = 6
    static let chipInnerGap: CGFloat = 6
    static let chevronSlotWidth: CGFloat = 8
    static let chevronSlotHeight: CGFloat = 14
    static let tapTarget: CGFloat = 44
    static let weekdayRowHeight: CGFloat = 80
    static let weekdayRowPadding: CGFloat = 12
    static let weekdayLetterSize: CGFloat = 17
    static let weekdayDot: CGFloat = 6
    static let weekdayChosenCircle: CGFloat = 40
    static let tipGap: CGFloat = 12
    static let tipInset: CGFloat = 4
    static let tipIcon: CGFloat = 22
    static let tipIconNudge: CGFloat = 1
    static let tipDismissGlyph: CGFloat = 14
    static let emptyStateGap: CGFloat = 12
    static let emptyStateIconGap: CGFloat = 16
    static let emptyStateTextGap: CGFloat = 8
    static let emptyStateInset: CGFloat = 32
    static let emptyMarkWidth: CGFloat = 120
    static let aboutMarkWidth: CGFloat = 56
    static let emptyTodayTop: CGFloat = 48
    static let emptyTodayTopBelowChip: CGFloat = 64
    static let emptyTodayBottom: CGFloat = 48
    static let rowHeight: CGFloat = 52
    static let twoLineRowHeight: CGFloat = 60
    static let twoLineRowPadding: CGFloat = 8
    static let rowMinimumHeight: CGFloat = 44
    static let recentRowHeight: CGFloat = 32
    static let iconTile: CGFloat = 32
    static let iconSymbol: CGFloat = 20
    static let bottomClearance: CGFloat = 16
    static let primaryButtonHeight: CGFloat = 56
    static let primaryButtonSystemPadding: CGFloat = 15
    static let primaryButtonLabelHeight: CGFloat = primaryButtonHeight - 2 * primaryButtonSystemPadding
    static let repeatChipSystemPadding: CGFloat = 7
    static let repeatChipLabelHeight: CGFloat = rowMinimumHeight - 2 * repeatChipSystemPadding
}
