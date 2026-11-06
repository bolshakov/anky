// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    func screenSpacing() -> some View {
        contentMargins(.horizontal, Spacing.screenMargin, for: .scrollContent)
            .contentMargins(.top, Spacing.firstBlockTop, for: .scrollContent)
            .listSectionSpacing(.custom(Spacing.blockGap))
            .scrollContentBackground(.hidden)
            .background(Color.surface)
    }

    func nonCardBlock() -> some View {
        listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
    }
}
