// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    func screenSpacing() -> some View {
        contentMargins(.horizontal, Spacing.screenMargin, for: .scrollContent)
            .contentMargins(.top, Spacing.firstBlockTop, for: .scrollContent)
            .listSectionSpacing(.custom(Spacing.blockGap))
            .environment(\.defaultMinListRowHeight, 0)
            .scrollContentBackground(.hidden)
            .background(Color.surface)
    }

    func readingScreenSpacing() -> some View {
        contentMargins(.horizontal, Spacing.screenMargin, for: .scrollContent)
            .contentMargins(.top, Spacing.firstBlockTop, for: .scrollContent)
            .contentMargins(.bottom, Spacing.bottomClearance, for: .scrollContent)
    }

    func lastBlockClearance() -> some View {
        contentMargins(.bottom, Spacing.bottomClearance, for: .scrollContent)
    }

    func emptyBlockGap() -> some View {
        listSectionSpacing(.custom(Spacing.emptyBlockGap))
    }

    func blockGapBetweenSections() -> some View {
        listSectionSpacing(.custom(Spacing.blockGap))
    }

    func nonCardBlock() -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
    }
}
