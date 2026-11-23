// SPDX-License-Identifier: GPL-3.0-or-later
import SwiftUI

struct UnavailableDoseTip: View {
    let dismiss: () -> Void

    var body: some View {
        Section {
            TipCard(
                icon: RowSymbol.dose,
                title: Text("Medication not available"),
                message: Text("That medication is archived or no longer there."),
                dismiss: dismiss
            )
            .accessibilityIdentifier("dose-tap-unavailable-tip")
            .nonCardBlock()
        }
    }
}
