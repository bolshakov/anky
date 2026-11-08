// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

/// A fixed-size tile that tells a row apart by shape. It is decoration: the row's own label carries the meaning.
struct IconTile: View {
    let symbol: String

    var body: some View {
        Image(systemName: symbol)
            .resizable()
            .scaledToFit()
            .frame(width: Spacing.iconSymbol, height: Spacing.iconSymbol)
            .foregroundStyle(.secondary)
            .frame(width: Spacing.iconTile, height: Spacing.iconTile)
            .background(Color.fill, in: RoundedRectangle(cornerRadius: Corner.iconTile))
            .accessibilityHidden(true)
    }
}
