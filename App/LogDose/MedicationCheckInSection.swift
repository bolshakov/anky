// SPDX-License-Identifier: GPL-3.0-or-later
import AnkyDomain
import SwiftUI

struct MedicationCheckInSection: View {
    @Binding var checkIn: DoseCheckIn

    var body: some View {
        CardSection(footnote: footnote, id: "check-in") {
            SwitchRow(Text("Check in later"), isOn: $checkIn.isOn)
                .accessibilityIdentifier("check-in-later")
            if checkIn.isOn {
                DoseCheckInMenu(delay: $checkIn.delay)
                    .rowHeight()
            }
        }
    }

    private var footnote: Text {
        if checkIn.isOn {
            Text("Anky asks how you feel after this long.")
        } else {
            Text("Anky asks how you feel after this long. Turn it on to choose a time.")
        }
    }
}
