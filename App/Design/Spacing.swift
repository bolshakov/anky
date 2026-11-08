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
    static let footnoteGap: CGFloat = 8
    static let inlineGap: CGFloat = 8
    static let tightGap: CGFloat = 4
    static let rowHeight: CGFloat = 52
    static let twoLineRowHeight: CGFloat = 60
    static let rowMinimumHeight: CGFloat = 44
    static let recentRowHeight: CGFloat = 32
    static let iconTile: CGFloat = 32
    static let iconSymbol: CGFloat = 20
    static let bottomClearance: CGFloat = 16
    static let primaryButtonHeight: CGFloat = 56
    static let primaryButtonSystemPadding: CGFloat = 15
    static let primaryButtonLabelHeight: CGFloat = primaryButtonHeight - 2 * primaryButtonSystemPadding
}
