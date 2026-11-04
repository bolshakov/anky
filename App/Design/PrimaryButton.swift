// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

extension View {
    /// The prominent style sets its label to white on the accent, so the label colour is set here with it.
    func primaryButton() -> some View {
        buttonStyle(.glassProminent)
            .foregroundStyle(Color("OnAccent"))
    }
}
