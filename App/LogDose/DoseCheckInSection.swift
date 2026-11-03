// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct DoseCheckInSection: View {
    @Binding var checkIn: DoseCheckIn
    let medicationName: String

    var body: some View {
        Section {
            Toggle("Check in later", isOn: $checkIn.isOn)
                .accessibilityIdentifier("check-in-later")
            if checkIn.isOn {
                DoseCheckInMenu(delay: $checkIn.delay)
            }
        } footer: {
            footnote
                .font(.footnote)
                .accessibilityIdentifier("check-in-footnote")
        }
    }

    @ViewBuilder private var footnote: some View {
        if checkIn.isOn {
            Text("Saved for \(medicationName). Next time it starts the same.")
        } else {
            Text("Anky asks how your pain is after this long. Turn it on to choose a time.")
        }
    }
}
