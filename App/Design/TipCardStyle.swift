// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI
import TipKit

/// TipKit keeps deciding whether a tip shows and stores that it was dismissed. `TipCard` draws it.
struct TipCardStyle: TipViewStyle {
    var icon: String?

    init(icon: String? = nil) {
        self.icon = icon
    }

    func makeBody(configuration: Configuration) -> some View {
        TipCard(
            icon: icon,
            title: configuration.title,
            message: configuration.message,
            dismiss: { configuration.tip.invalidate(reason: .tipClosed) }
        )
    }
}
