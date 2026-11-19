// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    func screenSpacing() -> some View {
        contentColumn()
            .contentMargins(.top, Spacing.firstBlockTop, for: .scrollContent)
            .listSectionSpacing(.custom(Spacing.blockGap))
            .environment(\.defaultMinListRowHeight, 0)
            .scrollContentBackground(.hidden)
            .background(Color.surface)
    }

    func readingScreenSpacing() -> some View {
        contentColumn(measuredFromSafeArea: true)
            .contentMargins(.top, Spacing.firstBlockTop, for: .scrollContent)
            .contentMargins(.bottom, Spacing.bottomClearance, for: .scrollContent)
    }

    func firstBlockClearance() -> some View {
        contentMargins(.top, Spacing.firstBlockTop, for: .scrollContent)
    }

    func lastBlockClearance() -> some View {
        contentMargins(.bottom, Spacing.bottomClearance, for: .scrollContent)
    }

    func addButtonClearance() -> some View {
        contentMargins(.bottom, Spacing.addButtonClearance, for: .scrollContent)
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
